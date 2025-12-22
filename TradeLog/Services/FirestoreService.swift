import Foundation
import FirebaseFirestore

class FirestoreService {
    static let shared = FirestoreService()
    let db = Firestore.firestore()
    
    func addTrade(_ trade: Trade) async throws {
        var newTrade = trade
        // Force demo user for now
        newTrade.userId = "demo_user"
        try db.collection("trades").addDocument(from: newTrade)
    }
    
    func fetchTrades() async throws -> [Trade] {
        // Fetch all trades for demo_user
        let snapshot = try await db.collection("trades")
            .whereField("userId", isEqualTo: "demo_user")
            .getDocuments()
        
        return snapshot.documents.compactMap { try? $0.data(as: Trade.self) }
            .sorted(by: { $0.date > $1.date }) // Sort in memory
    }
    
    func updateTrade(_ trade: Trade) async throws {
        guard let id = trade.id else { return }
        try db.collection("trades").document(id).setData(from: trade)
    }
    
    func saveUser(_ user: User) throws {
        try db.collection("users").document(user.id ?? UUID().uuidString).setData(from: user)
    }
    
    var currentUserId: String { "demo_user" }
    
    // ... (existing methods using hardcoded "demo_user" can be updated later or now, but focus on the fix)
    
    func updateUserCapital(userId: String, capital: Double) async throws {
        try await db.collection("users").document(userId).setData(["capital": capital], merge: true)
    }
    
    func fetchUser(userId: String) async throws -> User? {
        do {
            let document = try await db.collection("users").document(userId).getDocument()
            return try document.data(as: User.self)
        } catch {
            print("Error fetching user: \(error.localizedDescription)")
            throw error
        }
    }
    
    func getTrade(id: String) async throws -> Trade? {
        do {
            let document = try await db.collection("trades").document(id).getDocument()
            return try document.data(as: Trade.self)
        } catch {
            print("Error fetching trade: \(error.localizedDescription)")
            throw error
        }
    }
    
    func deleteTrade(withId id: String) async throws {
        do {
            try await db.collection("trades").document(id).delete()
        } catch {
            print("Error deleting trade: \(error.localizedDescription)")
            throw error
        }
    }
    
    func fetchAnalyticsStats() async throws -> (winRate: Double, grossPnL: Double, netPnL: Double, charges: Double, totalTrades: Int) {
        let trades = try await fetchTrades()
        
        // Include Closed trades OR any trade that has a valid Exit Price (realized profit)
        let closedTrades = trades.filter { $0.status == .closed || $0.exitPrice != nil }

        // Use netPnL for winning trade determination if available, else gross
        let winningTrades = closedTrades.filter { ($0.netPnL ?? $0.grossPnL ?? 0) > 0 }
        
        let grossPnL = closedTrades.reduce(0) { $0 + ($1.grossPnL ?? 0) }
        let charges = closedTrades.reduce(0) { $0 + ($1.charges ?? 0) }
        let netPnL = grossPnL - charges
        
        let winRate = closedTrades.isEmpty ? 0 : (Double(winningTrades.count) / Double(closedTrades.count)) * 100
        
        return (winRate, grossPnL, netPnL, charges, closedTrades.count)
    }
}
