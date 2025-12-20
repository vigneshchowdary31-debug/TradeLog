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
    @Published var notes = ""
    @Published var status: TradeStatus = .planned
    @Published var date: Date = Date()

    
    private var editingTrade: Trade?
    
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
        return calculatedGrossPnL - chargeVal
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
            self.notes = trade.notes
            self.status = trade.status
            self.date = trade.date
        }
    }
    
    var isEditing: Bool { editingTrade != nil }
    
    func saveTrade() async -> Bool {
        guard let entry = Double(entryPrice) else { return false }
        
        // For Dividend, we don't need target/stop. optimize validaton.
        let target = Double(targetPrice) ?? 0.0
        let stop = Double(stopLoss) ?? 0.0
        
        if category != .dividend && category != .delivery && category != .ipo && category != .buyback {
             // For normal trades, enforce target/stop if you strictly want them, 
             // but user flow might rely on them being optional? 
             // Previous code: guard let target = ..., let stop = ... else return false
             // New flow: If fields are hidden, they might be empty strings.
             // If they are mandatory for other types, check them:
             if targetPrice.isEmpty || stopLoss.isEmpty {
                 guard let _ = Double(targetPrice), let _ = Double(stopLoss) else { return false }
             }
        } else {
             // For Delivery/Dividend/IPO/Buyback, ensure Type is Buy if hidden
             if category == .delivery || category == .ipo || category == .buyback || category == .dividend { type = .buy }
        }
        
        let qty = Int(quantity)
        
        // For dividend, exitPrice is not relevant, but let's just parse what we can
        let exit = Double(exitPrice)
        let chargeVal = Double(charges)
        
        var trade = Trade(
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
            charges: chargeVal,
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
