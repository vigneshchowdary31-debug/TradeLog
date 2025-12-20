import Foundation
import Combine

@MainActor
class TradeListViewModel: ObservableObject {
    @Published var trades: [Trade] = []
    @Published var filteredTrades: [Trade] = []
    @Published var selectedCategory: TradeCategory? = nil
    @Published var selectedStatus: TradeStatus? = nil
    @Published var selectedMonth: Int? = nil
    @Published var selectedYear: Int? = nil
    @Published var searchText: String = ""
    @Published var sortOption: SortOption = .dateDesc
    
    var availableYears: [Int] {
        let years = Set(trades.map { Calendar.current.component(.year, from: $0.date) })
        return Array(years).sorted(by: >)
    }

    enum SortOption: String, CaseIterable, Identifiable {
        case dateDesc = "Newest First"
        case dateAsc = "Oldest First"
        case nameAsc = "Symbol (A-Z)"
        case profitDesc = "Highest Profit"
        case profitAsc = "Lowest Profit" // or Highest Loss
        
        var id: String { self.rawValue }
    }
    
    init() {
        Task {
            await fetchTrades()
        }
    }
    
    func fetchTrades() async {
        do {
            self.trades = try await FirestoreService.shared.fetchTrades()
            filterTrades()
        } catch {
            print("DEBUG: Failed to fetch trades with error: \(error.localizedDescription)")
        }
    }
    
    func filterTrades() {
        var result = trades
        
        // 1. Category Filter
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }
        
        // 2. Status Filter
        if let status = selectedStatus {
            result = result.filter { $0.status == status }
        }
        
        // 3. Month Filter
        if let month = selectedMonth {
             result = result.filter { Calendar.current.component(.month, from: $0.date) == month }
        }
        
        // 4. Year Filter
        if let year = selectedYear {
            result = result.filter { Calendar.current.component(.year, from: $0.date) == year }
        }
        
        // 5. Search Filter
        if !searchText.isEmpty {
            result = result.filter { $0.symbol.localizedCaseInsensitiveContains(searchText) }
        }
        
        // 3. Sort
        switch sortOption {
        case .dateDesc:
            result.sort { $0.date > $1.date }
        case .dateAsc:
            result.sort { $0.date < $1.date }
        case .nameAsc:
            result.sort { $0.symbol < $1.symbol }
        case .profitDesc:
            result.sort { ($0.netPnL ?? 0) > ($1.netPnL ?? 0) }
        case .profitAsc:
            result.sort { ($0.netPnL ?? 0) < ($1.netPnL ?? 0) }
        }
        
        self.filteredTrades = result
    }
    
    func deleteTrade(at offsets: IndexSet) {
        let tradesToDelete = offsets.map { filteredTrades[$0] }
        
        for trade in tradesToDelete {
            deleteTrade(trade)
        }
    }
    
    func deleteTrade(_ trade: Trade) {
        guard let id = trade.id else { return }
        
        Task {
            do {
                try await FirestoreService.shared.deleteTrade(withId: id)
                await fetchTrades()
            } catch {
                print("Error deleting trade: \(error)")
            }
        }
    }
}
