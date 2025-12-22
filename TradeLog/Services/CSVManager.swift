import Foundation

class CSVManager {
    static let shared = CSVManager()
    
    private init() {}
    
    func generateCSV(from trades: [Trade]) -> URL? {
        var csvString = "Date,Symbol,Type,Category,Quantity,Entry Price,Exit Price,Charges,Gross P&L,Net P&L,Status,Notes\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        for trade in trades {
            let date = dateFormatter.string(from: trade.date)
            let symbol = trade.symbol.replacingOccurrences(of: ",", with: " ")
            let type = trade.type.rawValue
            let category = trade.category.rawValue
            let quantity = trade.quantity.map { String($0) } ?? ""
            let entryPrice = String(format: "%.2f", trade.entryPrice)
            let exitPrice = trade.exitPrice.map { String(format: "%.2f", $0) } ?? ""
            let charges = trade.charges.map { String(format: "%.2f", $0) } ?? "0.00"
            let grossPnl = trade.grossPnL.map { String(format: "%.2f", $0) } ?? ""
            let netPnl = trade.netPnL.map { String(format: "%.2f", $0) } ?? ""
            let status = trade.status.rawValue
            let notes = trade.notes.replacingOccurrences(of: ",", with: " ").replacingOccurrences(of: "\n", with: " ")
            
            let row = "\(date),\(symbol),\(type),\(category),\(quantity),\(entryPrice),\(exitPrice),\(charges),\(grossPnl),\(netPnl),\(status),\(notes)\n"
            csvString.append(row)
        }
        
        // Save to temporary file
        let fileName = "TradeLog_Export_\(Int(Date().timeIntervalSince1970)).csv"
        let path = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try csvString.write(to: path, atomically: true, encoding: .utf8)
            return path
        } catch {
            print("Error creating CSV file: \(error)")
            return nil
        }
    }
    func parseCSV(url: URL) throws -> [Trade] {
        let data = try String(contentsOf: url, encoding: .utf8)
        var rows = data.components(separatedBy: .newlines)
        
        // Remove Header
        if !rows.isEmpty { rows.removeFirst() }
        
        // Remove empty last row if any
        if let last = rows.last, last.isEmpty {
            rows.removeLast()
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        var trades: [Trade] = []
        
        for row in rows {
            // Handle simple CSV splitting (commas within fields not supported in this simple version)
            // Ideally use extensive CSV parser, but for MVP/Generic format this suffices
            let columns = row.components(separatedBy: ",")
            
            if columns.count >= 11 {
                // Columns: Date, Symbol, Type, Category, Quantity, Entry, Exit, Charges, Gross, Net, Status, Notes
                let dateString = columns[0]
                let symbol = columns[1]
                let typeRaw = columns[2]
                let categoryRaw = columns[3]
                let qtyString = columns[4]
                let entryString = columns[5]
                let exitString = columns[6]
                let chargesString = columns[7]
                // 8, 9 are P&L (skip)
                let statusRaw = columns[10]
                let notes = columns.count > 11 ? columns[11] : ""
                
                if let date = dateFormatter.date(from: dateString),
                   let type = TradeType(rawValue: typeRaw),
                   let category = TradeCategory(rawValue: categoryRaw),
                   let status = TradeStatus(rawValue: statusRaw),
                   let entryPrice = Double(entryString) {
                    
                    let quantity = Int(qtyString)
                    let exitPrice = Double(exitString)
                    let charges = Double(chargesString)
                    
                    let trade = Trade(
                        id: UUID().uuidString,
                        userId: FirestoreService.shared.currentUserId,
                        symbol: symbol,
                        type: type,
                        category: category,
                        entryPrice: entryPrice,
                        quantity: quantity,
                        timeframe: nil,
                        notes: notes,
                        tags: [],
                        date: date,
                        exitPrice: exitPrice,
                        charges: charges,
                        status: status
                    )
                    trades.append(trade)
                }
            }
        }
        return trades
    }
}
