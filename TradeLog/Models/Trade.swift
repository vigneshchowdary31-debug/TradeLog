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

struct Trade: Identifiable, Codable, Hashable {
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
    var imagePaths: [String]?
    var date: Date
    var exitPrice: Double?
    var status: TradeStatus
    var charges: Double?
    var interestPerDay: Double?
    var exitDate: Date?
    
    // Computed Properties for Analytics
    var daysHeld: Int {
        let end = exitDate ?? Date()
        let components = Calendar.current.dateComponents([.day], from: date, to: end)
        return max(1, components.day ?? 1)
    }
    
    var calculatedInterest: Double {
        guard let interest = interestPerDay, category == .mtf else { return 0 }
        return interest * Double(daysHeld)
    }
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
        
        var totalCost = charges ?? 0
        if category == .mtf {
            totalCost += calculatedInterest
        }
        
        return gross - totalCost
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
         exitDate: Date? = nil,
         charges: Double? = nil,
         interestPerDay: Double? = nil,
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
        self.exitDate = exitDate
        self.charges = charges
        self.interestPerDay = interestPerDay
        self.status = status
    }
    // Equatable & Hashable
    static func == (lhs: Trade, rhs: Trade) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
