import SwiftUI

struct TradeCardView: View {
    let trade: Trade
    
    // Helper for P&L State
    private var isProfit: Bool {
        (trade.netPnL ?? 0) >= 0
    }
    
    private var color: Color {
        if let _ = trade.exitPrice {
            return isProfit ? .green : .red
        }
        return trade.status == .planned ? .orange : .blue
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: trade.type == .buy ? "arrow.up" : "arrow.down")
                            .font(.caption.bold())
                            .foregroundColor(color)
                    )
                
                Spacer()
                
                Text(trade.date.formatted(date: .numeric, time: .omitted))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(trade.symbol)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(trade.type.rawValue.uppercased())
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Footer P&L
            if let pnl = trade.netPnL {
                Text(String(format: "₹%.1f", abs(pnl)))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(isProfit ? .green : .red)
            } else {
                Text(trade.status.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(Capsule())
            }
        }
        .padding(16)
        .frame(width: 160, height: 160)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}
