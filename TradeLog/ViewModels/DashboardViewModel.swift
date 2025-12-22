import Foundation
import Combine

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var recentTrades: [Trade] = []
    @Published var winRate: Double = 0
    // Dashboard Specific Stats (Filtered by FY + Month)
    @Published var grossPnL: Double = 0
    @Published var netPnL: Double = 0
    @Published var totalCharges: Double = 0
    @Published var totalTrades: Int = 0
    @Published var openTradesCount: Int = 0
    @Published var tradesByCategory: [TradeCategory: [Trade]] = [:]
    
    // Analytics Tab Stats (Filtered ONLY by FY, ignoring Month)
    @Published var fyGrossPnL: Double = 0
    @Published var fyNetPnL: Double = 0
    @Published var fyTotalCharges: Double = 0
    @Published var fyCategoryPnL: [TradeCategory: Double] = [:]
    @Published var fyDailyPnL: [Date: Double] = [:]
    
    // Advanced Analytics (Dashboard)
    @Published var avgWin: Double = 0
    @Published var avgLoss: Double = 0
    @Published var categoryPnL: [TradeCategory: Double] = [:] // Dashboard specific
    @Published var categoryCharges: [TradeCategory: Double] = [:]
    @Published var dailyPnL: [Date: Double] = [:]
    
    // Capital & ROI
    @Published var capital: Double = 0
    
    var roi: Double {
        guard capital > 0 else { return 0 }
        return (netPnL / capital) * 100
    }
    
    var fyRoi: Double {
        guard capital > 0 else { return 0 }
        return (fyNetPnL / capital) * 100
    }

    
    // Filter State
    var allTrades: [Trade] = [] // Cache
    @Published var selectedMonth: Int?
    @Published var selectedFinancialYear: Int?
    
    // Helper to get FY Start Year (e.g., Apr 2024 -> 2024, Jan 2025 -> 2024)
    private func getFinancialYear(for date: Date) -> Int {
        let year = Calendar.current.component(.year, from: date)
        let month = Calendar.current.component(.month, from: date)
        // FY starts in April (4)
        return month >= 4 ? year : year - 1
    }
    
    var availableFinancialYears: [Int] {
        let years = allTrades.map { getFinancialYear(for: $0.date) }
        return Array(Set(years)).sorted(by: >)
    }
    
    // Backward compatibility if needed by Views
    var totalPnL: Double { netPnL }
    
    func fetchStats() async {
        do {
            // Fetch User for Capital
            if let userId = allTrades.first?.userId { // Small optimization/hack, or assume current user.
                // ideally fetch current user ID from Auth service.
                // For now, let's try to fetch if we have trades, or rely on a proper UserSession manager.
                // Let's assume FirestoreService can fetch current user if we had auth. 
                // Since this app might be single user for now or we rely on the trades... 
                // Actually, let's just try to fetch user if we know the ID, or implement a fetchCurrentUser in Service.
                // Assuming "user_id_here" for demo or getting it from shared auth. 
                // For this step, I'll add a helper to fetch trades AND user settings.
            }
            // Better: Just fetch trades first.
            let trades = try await FirestoreService.shared.fetchTrades()
            self.allTrades = trades
            
            // Always fetch user settings using the current user ID
            let uid = FirestoreService.shared.currentUserId
            if let user = try? await FirestoreService.shared.fetchUser(userId: uid) {
                 self.capital = user.capital ?? 0
            }
            
            // Set default FY if none selected (Optional: typically current FY)
            if selectedFinancialYear == nil, let newestTrade = allTrades.first {
                selectedFinancialYear = getFinancialYear(for: newestTrade.date)
            }
            
            // Calculate initial stats (filtered by whatever is selected, usually empty/all at start)
            calculateStats()
        } catch {
            print("Error fetching dashboard data: \(error)")
        }
    }
    
    func updateCapital(_ amount: Double) {
        self.capital = amount
        // Save to Firestore using consistent User ID
        let uid = FirestoreService.shared.currentUserId
        Task {
            try? await FirestoreService.shared.updateUserCapital(userId: uid, capital: amount)
        }
    }
    
    func calculateStats() {
        var baseTrades = allTrades
        
        // --- 1. Filter by Financial Year (Base for both Dashboard and Analytics) ---
        if let fy = selectedFinancialYear {
            baseTrades = baseTrades.filter { getFinancialYear(for: $0.date) == fy }
        }
        
        // --- A. ANALYTICS STATS (Full FY Data) ---
        // Use baseTrades directly (which is FY filtered only)
        calculateAnalyticsStats(trades: baseTrades)
        
        // --- B. DASHBOARD STATS (Month Filtered) ---
        var dashboardTrades = baseTrades
        if let month = selectedMonth {
             dashboardTrades = dashboardTrades.filter { Calendar.current.component(.month, from: $0.date) == month }
        }
        
        self.recentTrades = Array(dashboardTrades.prefix(20))
        self.openTradesCount = dashboardTrades.filter { $0.status != .closed }.count
        self.totalTrades = dashboardTrades.count
        
        // Dashboard P&L
        let realizedTrades = dashboardTrades.filter { $0.grossPnL != nil }
        self.grossPnL = realizedTrades.reduce(0) { $0 + ($1.grossPnL ?? 0) }
        self.totalCharges = realizedTrades.reduce(0) { $0 + ($1.charges ?? 0) }
        self.netPnL = grossPnL - totalCharges
        
        // Dashboard Advanced
        calculateAdvancedStats(trades: dashboardTrades)
        
        // Win Rate logic (same as before)
        let winningTrades = realizedTrades.filter { ($0.netPnL ?? $0.grossPnL ?? 0) > 0 }
        self.winRate = realizedTrades.isEmpty ? 0 : (Double(winningTrades.count) / Double(realizedTrades.count)) * 100
        self.tradesByCategory = Dictionary(grouping: dashboardTrades, by: { $0.category })
    }
    
    private func calculateAnalyticsStats(trades: [Trade]) {
        let realized = trades.filter { $0.grossPnL != nil }
        self.fyGrossPnL = realized.reduce(0) { $0 + ($1.grossPnL ?? 0) }
        self.fyTotalCharges = realized.reduce(0) { $0 + ($1.charges ?? 0) }
        self.fyNetPnL = fyGrossPnL - fyTotalCharges
        
        // FY Category P&L & Daily P&L
        var catPnL: [TradeCategory: Double] = [:]
        var dayPnL: [Date: Double] = [:]
        
         for trade in realized {
             if let pnl = trade.grossPnL {
                 catPnL[trade.category, default: 0] += (trade.netPnL ?? pnl)
                 let day = Calendar.current.startOfDay(for: trade.date)
                 dayPnL[day, default: 0] += (trade.netPnL ?? pnl)
             }
         }
        self.fyCategoryPnL = catPnL
        self.fyDailyPnL = dayPnL
    }
    
    private func calculateAdvancedStats(trades: [Trade]) {
        var wins: [Double] = []
        var losses: [Double] = []
        var catPnL: [TradeCategory: Double] = [:]
        var catCharges: [TradeCategory: Double] = [:]
        var dayPnL: [Date: Double] = [:]
        
        for trade in trades {
            // Only consider trades that have a P&L (closed or exited)
            // Use Gross P&L for stats as requested to exclude charges impact on "Ave Loss"
            if let pnl = trade.grossPnL {
                // Avg Win/Loss
                if pnl >= 0 {
                    wins.append(pnl)
                } else {
                    losses.append(pnl)
                }
                
                // Category P&L - Use NET P&L for actual money made
                catPnL[trade.category, default: 0] += (trade.netPnL ?? pnl)
                
                // Category Charges
                catCharges[trade.category, default: 0] += (trade.charges ?? 0)
                
                // Daily P&L - Use NET P&L for equity curve
                let day = Calendar.current.startOfDay(for: trade.date)
                dayPnL[day, default: 0] += (trade.netPnL ?? pnl)
            }
        }
        
        self.avgWin = wins.isEmpty ? 0 : wins.reduce(0, +) / Double(wins.count)
        self.avgLoss = losses.isEmpty ? 0 : losses.reduce(0, +) / Double(losses.count)
        self.categoryPnL = catPnL
        self.categoryCharges = catCharges
        self.dailyPnL = dayPnL
    }
    
    // Helper for Edge Section (Intraday vs F&O)
    func getEdgeStats(for category: TradeCategory) -> (winRate: Double, totalTrades: Int, avgWin: Double, avgLoss: Double) {
        // Use filtered trades to respect date selection, but then filter by category
        // Note: tradesByCategory is already populated in calculateStats() with filtered trades
        let trades = tradesByCategory[category] ?? []
        
        let closedTopTrades = trades.filter { $0.status == .closed || $0.exitPrice != nil }
        
        // Win Rate based on Gross P&L to reflect strategy accuracy
        let winningTrades = closedTopTrades.filter { ($0.grossPnL ?? 0) > 0 }
        
        let winRate = closedTopTrades.isEmpty ? 0 : (Double(winningTrades.count) / Double(closedTopTrades.count)) * 100
        
        // Calculate Avg Win / Avg Loss
        var wins: [Double] = []
        var losses: [Double] = []
        
        for trade in closedTopTrades {
            if let pnl = trade.grossPnL {
                if pnl >= 0 { wins.append(pnl) }
                else { losses.append(pnl) }
            }
        }
        
        let avgWin = wins.isEmpty ? 0 : wins.reduce(0, +) / Double(wins.count)
        let avgLoss = losses.isEmpty ? 0 : losses.reduce(0, +) / Double(losses.count)
        
        return (winRate, trades.count, avgWin, avgLoss)
    }
}
