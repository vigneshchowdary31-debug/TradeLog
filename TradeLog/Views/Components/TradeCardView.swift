import SwiftUI

struct TradeCardView: View {
    let trade: Trade
    
    // Helper for P&L State
    private var isProfit: Bool {
        (trade.netPnL ?? 0) >= 0
    }
    
    private var statusColor: Color {
        if let _ = trade.exitPrice {
            return isProfit ? .green : .red
        }
        return trade.status == .planned ? .orange : .blue
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Status Strip
            Rectangle()
                .fill(statusColor)
                .frame(width: 5)
            
            VStack(alignment: .leading, spacing: 10) {
                // Header
                HStack {
                    Text(trade.symbol)
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(trade.type.rawValue)
                        .font(.system(size: 9, weight: .bold))
                        .textCase(.uppercase)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(trade.type == .buy ? Color.blue.opacity(0.1) : Color.red.opacity(0.1))
                        .foregroundColor(trade.type == .buy ? .blue : .red)
                        .clipShape(Capsule())
                }
                
                // Data Points
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("ENTRY")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.secondary)
                        Text(String(format: "₹%.1f", trade.entryPrice))
                            .font(.system(.subheadline, design: .rounded))
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    if let netPnL = trade.netPnL {
                        VStack(alignment: .trailing, spacing: 0) {
                            Text(isProfit ? "PROFIT" : "LOSS")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(isProfit ? .green : .red)
                                .padding(.bottom, 2)
                            
                            Text(String(format: "₹%.1f", abs(netPnL)))
                                .font(.system(.headline, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(isProfit ? .green : .red)
                        }
                    } else {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("STATUS")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.secondary)
                            
                            Text(trade.status == .planned ? "Planned" : "Open")
                                .font(.system(.subheadline, design: .rounded))
                                .fontWeight(.medium)
                                .foregroundColor(trade.status == .planned ? .orange : .blue)
                        }
                    }
                }
                
                // Footer
                HStack {
                    Text(trade.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if let _ = trade.exitPrice {
                         Image(systemName: isProfit ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(isProfit ? .green : .red)
                            .frame(width: 20, height: 20)
                            .background(isProfit ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
            }
            .padding(12)
        }
        .frame(width: 175)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
         // Clip content for stripe
        .clipShape(RoundedRectangle(cornerRadius: 16)) 
    }
}
