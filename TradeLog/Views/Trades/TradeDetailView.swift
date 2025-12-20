import SwiftUI

struct TradeDetailView: View {
    @State private var trade: Trade
    @Environment(\.dismiss) var dismiss
    @State private var showEditSheet = false
    
    init(trade: Trade) {
        _trade = State(initialValue: trade)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text(trade.symbol)
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                    
                    HStack {
                        StatusPill(status: trade.status)
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(trade.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top)
                
                // P&L Highlight (if exited)
                if let pnl = trade.pnl {
                    VStack(spacing: 5) {
                        Text(pnl >= 0 ? "Profit" : "Loss")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        
                        Text(String(format: "₹%.2f", pnl))
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(pnl >= 0 ? .green : .red)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemBackground))
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, y: 5)
                    .padding(.horizontal)
                }
                
                // Trade Specs Grid
                VStack(alignment: .leading, spacing: 15) {
                    Text("Trade Specifications")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                        DetailTile(title: "Type", value: trade.type.rawValue, color: trade.type == .buy ? .green : .red)
                        DetailTile(title: "Category", value: trade.category.rawValue)
                        
                        if let quantity = trade.quantity {
                            DetailTile(title: "Quantity", value: "\(quantity)")
                        }
                        
                         if let charges = trade.charges {
                            DetailTile(title: "Charges", value: String(format: "₹%.2f", charges), color: .red)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Execution Details (Hide for Dividend, or show differently)
                if trade.category != .dividend {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Execution Levels")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            ExecutionRow(label: "Entry Price", value: trade.entryPrice)
                            ExecutionRow(label: "Target", value: trade.targetPrice, color: .green)
                            ExecutionRow(label: "Stop Loss", value: trade.stopLoss, color: .red)
                            
                            if let exit = trade.exitPrice {
                                Divider()
                                ExecutionRow(label: "Exit Price", value: exit, color: .blue)
                            }
                        }
                        .padding(20)
                        .background(Color(.systemBackground))
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.05), radius: 10, y: 5)
                        .padding(.horizontal)
                    }
                } else {
                    // Dividend Specific Details
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Dividend Details")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            ExecutionRow(label: "Dividend Per Share", value: trade.entryPrice)
                            if let qty = trade.quantity {
                                // Manual row for quantity if desired, or relying on Specs Grid.
                                // Let's just show the total amount logic here clearly
                                HStack {
                                    Text("Total Amount")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(String(format: "₹%.2f", (trade.entryPrice * Double(qty))))
                                        .font(.headline)
                                        .foregroundColor(.green)
                                }
                            }
                        }
                        .padding(20)
                        .background(Color(.systemBackground))
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.05), radius: 10, y: 5)
                        .padding(.horizontal)
                    }
                }
                
                // Notes
                if !trade.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Notes")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        Text(trade.notes)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemBackground))
                            .cornerRadius(20)
                            .padding(.horizontal)
                    }
                }
                
                // Risk / Reward (Hide for Dividend)
                if trade.category != .dividend {
                    VStack(spacing: 5) {
                        Text("Risk Reward Ratio")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "1 : %.2f", trade.riskRewardRatio))
                            .font(.headline)
                    }
                    .padding(.bottom, 30)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("Edit") {
                showEditSheet = true
            }
        }
        .sheet(isPresented: $showEditSheet) {
            AddTradeView(trade: trade)
                .onDisappear {
                    Task { await refreshTrade() }
                }
        }
    }
    
    func refreshTrade() async {
        guard let id = trade.id else { return }
        if let updated = try? await FirestoreService.shared.getTrade(id: id) {
            self.trade = updated
        }
    }
}

// Subcomponents for Detail View
struct DetailTile: View {
    let title: String
    let value: String
    var color: Color? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline)
                .foregroundColor(color ?? .primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.03), radius: 5, y: 2)
    }
}

struct ExecutionRow: View {
    let label: String
    let value: Double
    var color: Color = .primary
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(String(format: "₹%.2f", value))
                .font(.headline)
                .foregroundColor(color)
        }
    }
}
