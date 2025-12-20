import Foundation
import Combine

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var recentTrades: [Trade] = []
    @Published var winRate: Double = 0
    @Published var grossPnL: Double = 0
    @Published var netPnL: Double = 0
    @Published var totalCharges: Double = 0
    @Published var totalTrades: Int = 0
    @Published var openTradesCount: Int = 0
    @Published var tradesByCategory: [TradeCategory: [Trade]] = [:]
    
    // Advanced Analytics
    @Published var avgWin: Double = 0
    @Published var avgLoss: Double = 0
    @Published var categoryPnL: [TradeCategory: Double] = [:]

    
    // Filter State
    private var allTrades: [Trade] = [] // Cache
    @Published var selectedMonth: Int?
    @Published var selectedYear: Int?
    
    var availableYears: [Int] {
        let years = allTrades.map { Calendar.current.component(.year, from: $0.date) }
        return Array(Set(years)).sorted(by: >)
    }
    
    // Backward compatibility if needed by Views
    var totalPnL: Double { netPnL }
    
    func fetchStats() async {
        do {
            // Fetch ALL trades
            let trades = try await FirestoreService.shared.fetchTrades()
            self.allTrades = trades
            
            // Calculate initial stats (filtered by whatever is selected, usually empty/all at start)
            calculateStats()
        } catch {
            print("Error fetching dashboard data: \(error)")
        }
    }
    
    func calculateStats() {
        var filteredTrades = allTrades
        
        // 1. Month Filter
        if let month = selectedMonth {
             filteredTrades = filteredTrades.filter { Calendar.current.component(.month, from: $0.date) == month }
        }
        
        // 2. Year Filter
        if let year = selectedYear {
            filteredTrades = filteredTrades.filter { Calendar.current.component(.year, from: $0.date) == year }
        }
        
        self.recentTrades = Array(filteredTrades.prefix(20))
        self.openTradesCount = filteredTrades.filter { $0.status != .closed }.count
        self.totalTrades = filteredTrades.count
        
        // --- Calculate P&L & Win Rate ---
        let closedTrades = filteredTrades.filter { $0.status == .closed || $0.exitPrice != nil }
        let winningTrades = closedTrades.filter { ($0.netPnL ?? $0.grossPnL ?? 0) > 0 }
        
        self.grossPnL = closedTrades.reduce(0) { $0 + ($1.grossPnL ?? 0) }
        self.totalCharges = closedTrades.reduce(0) { $0 + ($1.charges ?? 0) }
        self.netPnL = grossPnL - totalCharges
        
        self.winRate = closedTrades.isEmpty ? 0 : (Double(winningTrades.count) / Double(closedTrades.count)) * 100
        
        // Group by category for category breakdown
        self.tradesByCategory = Dictionary(grouping: filteredTrades, by: { $0.category })
        
        // --- Advanced Calculations ---
        calculateAdvancedStats(trades: filteredTrades)
    }
    
    private func calculateAdvancedStats(trades: [Trade]) {
        var wins: [Double] = []
        var losses: [Double] = []
        var catPnL: [TradeCategory: Double] = [:]
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
                
                // Daily P&L - Use NET P&L for equity curve
                let day = Calendar.current.startOfDay(for: trade.date)
                dayPnL[day, default: 0] += (trade.netPnL ?? pnl)
            }
        }
        
        self.avgWin = wins.isEmpty ? 0 : wins.reduce(0, +) / Double(wins.count)
        self.avgLoss = losses.isEmpty ? 0 : losses.reduce(0, +) / Double(losses.count)
        self.categoryPnL = catPnL
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
