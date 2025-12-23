import Foundation
import Combine
import SwiftUI
import FirebaseFirestore


@MainActor
class AddTradeViewModel: ObservableObject {
    @Published var symbol = ""
    @Published var type: TradeType = .buy
    @Published var category: TradeCategory = .intraday
    @Published var entryPrice = ""
    @Published var targetPrice = ""
    @Published var stopLoss = ""
    @Published var quantity = ""
    @Published var exitPrice = ""
    @Published var charges = ""
    @Published var interestPerDay = ""
    @Published var notes = ""
    @Published var status: TradeStatus = .planned
    @Published var date: Date = Date()
    @Published var exitDate: Date = Date()

    
    private var editingTrade: Trade?
    private var cancellables = Set<AnyCancellable>()
    
    // Computed props for live update
    var calculatedGrossPnL: Double {
        guard let entry = Double(entryPrice),
              let qty = Double(quantity) else { return 0 }
        
        if category == .dividend {
             return entry * qty
        }
        
        guard let exit = Double(exitPrice) else { return 0 }
        
        if type == .buy {
            return (exit - entry) * qty
        } else {
            return (entry - exit) * qty
        }
    }
    
    var calculatedNetPnL: Double {
        let chargeVal = Double(charges) ?? 0
        var net = calculatedGrossPnL - chargeVal
        
        if category == .mtf {
             net -= projectedInterest
        }
        
        return net
    }
    
    var projectedDaysHeld: Int {
        let end = (status == .closed || !exitPrice.isEmpty) ? exitDate : Date()
        // If end date is before start date, default to 1
        let components = Calendar.current.dateComponents([.day], from: date, to: end)
        return max(1, components.day ?? 1)
    }
    
    var projectedInterest: Double {
        guard let interest = Double(interestPerDay), category == .mtf else { return 0 }
        return interest * Double(projectedDaysHeld)
    }
    
    init(trade: Trade? = nil) {
        if let trade = trade {
            self.editingTrade = trade
            self.symbol = trade.symbol
            self.type = trade.type
            self.category = trade.category
            self.entryPrice = String(trade.entryPrice)
            self.targetPrice = String(trade.targetPrice)
            self.stopLoss = String(trade.stopLoss)
            self.quantity = trade.quantity.map { String($0) } ?? ""
            self.exitPrice = trade.exitPrice.map { String($0) } ?? ""
            self.charges = trade.charges.map { String($0) } ?? ""
            self.interestPerDay = trade.interestPerDay.map { String($0) } ?? ""
            self.notes = trade.notes
            self.status = trade.status
            self.date = trade.date
            self.exitDate = trade.exitDate ?? Date()
        }
        
        // Auto-set status for specific categories
        $category
            .sink { [weak self] newCategory in
                if [.delivery, .buyback, .ipo, .dividend].contains(newCategory) {
                    self?.status = .closed
                }
            }
            .store(in: &cancellables)
    }
    
    var isEditing: Bool { editingTrade != nil }
    
    func saveTrade() async -> Bool {
        guard let entry = Double(entryPrice) else { return false }
        
        // For Dividend, we don't need target/stop. optimize validaton.
        let target = Double(targetPrice) ?? 0.0
        let stop = Double(stopLoss) ?? 0.0
        
        if category != .dividend && category != .delivery && category != .ipo && category != .buyback && category != .mtf {
             // For normal trades (Intraday, F&O), enforce target/stop if they should be mandatory
             if targetPrice.isEmpty || stopLoss.isEmpty {
                 guard let _ = Double(targetPrice), let _ = Double(stopLoss) else { return false }
             }
        } else {
             // For Delivery/Dividend/IPO/Buyback/MTF, ensure Type is Buy if hidden
             // (MTF type picker is hidden, so force type to avoid issues)
             if category == .delivery || category == .ipo || category == .buyback || category == .dividend || category == .mtf { 
                 type = .buy 
             }
        }
        
        let qty = Int(quantity)
        
        // For dividend, exitPrice is not relevant, but let's just parse what we can
        let exit = Double(exitPrice)
        let chargeVal = Double(charges)
        let interestVal = Double(interestPerDay)
        
        let trade = Trade(
            id: editingTrade?.id,
            userId: editingTrade?.userId ?? "",
            symbol: symbol.uppercased(),
            type: type,
            category: category,
            entryPrice: entry,
            targetPrice: target,
            stopLoss: stop,
            quantity: qty,
            timeframe: nil,
            notes: notes,
            tags: [],
            date: date,
            exitPrice: exit,
            exitDate: exitDate,
            charges: chargeVal,
            interestPerDay: interestVal,
            status: status
        )
        
        do {
            if isEditing {
                try await FirestoreService.shared.updateTrade(trade)
            } else {
                try await FirestoreService.shared.addTrade(trade)
            }
            return true
        } catch {
            return false
        }
    }
}
