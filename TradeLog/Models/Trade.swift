import Foundation
import FirebaseFirestore

enum TradeCategory: String, CaseIterable, Codable, Identifiable {
    case delivery = "Delivery"
    case intraday = "Intraday"
    case mtf = "MTF"
    case fno = "F&O"
    case buyback = "Buyback"
    case ipo = "IPO"
    case dividend = "Dividend"
    
    var id: String { self.rawValue }
}

enum TradeType: String, CaseIterable, Codable, Identifiable {
    case buy = "Buy"
    case sell = "Sell"
    
    var id: String { self.rawValue }
}

enum TradeStatus: String, CaseIterable, Codable, Identifiable {
    case planned = "Planned"
    case executed = "Executed"
    case closed = "Closed"
    
    var id: String { self.rawValue }
}

struct Trade: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var symbol: String
    var type: TradeType
    var category: TradeCategory
    var entryPrice: Double
    var targetPrice: Double
    var stopLoss: Double
    var quantity: Int?
    var timeframe: String? // e.g., "5m", "1H", "Daily"
    var notes: String
    var tags: [String]
    var date: Date
    var exitPrice: Double?
    var status: TradeStatus
    var charges: Double?
    
    // Computed Properties for Analytics
    var riskRewardRatio: Double {
        let risk = abs(entryPrice - stopLoss)
        let reward = abs(targetPrice - entryPrice)
        return risk == 0 ? 0 : reward / risk
    }
    
    var grossPnL: Double? {
        if category == .dividend {
            // entryPrice stores Dividend Per Share
            let qty = Double(quantity ?? 0)
            return entryPrice * qty
        }
        
        guard let exit = exitPrice else { return nil }
        let qty = Double(quantity ?? 1)
        if type == .buy {
            return (exit - entryPrice) * qty
        } else {
            return (entryPrice - exit) * qty
        }
    }
    
    var netPnL: Double? {
        guard let gross = grossPnL else { return nil }
        return gross - (charges ?? 0)
    }
    
    // Backward compatibility alias preference
    var pnl: Double? { netPnL ?? grossPnL }
    
    // Explicit Init
    init(id: String? = nil,
         userId: String = "",
         symbol: String = "",
         type: TradeType = .buy,
         category: TradeCategory = .intraday,
         entryPrice: Double = 0,
         targetPrice: Double = 0,
         stopLoss: Double = 0,
         quantity: Int? = nil,
         timeframe: String? = nil,
         notes: String = "",
         tags: [String] = [],
         date: Date = Date(),
         exitPrice: Double? = nil,
         charges: Double? = nil,
         status: TradeStatus = .planned) {
        
        self.id = id
        self.userId = userId
        self.symbol = symbol
        self.type = type
        self.category = category
        self.entryPrice = entryPrice
        self.targetPrice = targetPrice
        self.stopLoss = stopLoss
        self.quantity = quantity
        self.timeframe = timeframe
        self.notes = notes
        self.tags = tags
        self.date = date
        self.exitPrice = exitPrice
        self.charges = charges
        self.status = status
    }
}
