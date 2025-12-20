import SwiftUI

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var trend: Double? = nil // Optional trend percentage
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundColor(color)
                    .padding(8)
                    .background(color.opacity(0.1))
                    .clipShape(Circle())
                
                Spacer()
                
                if let trend = trend {
                    HStack(spacing: 4) {
                        Image(systemName: trend >= 0 ? "arrow.up.right" : "arrow.down.right")
                        Text("\(abs(trend), specifier: "%.1f")%")
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(trend >= 0 ? .green : .red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(trend >= 0 ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

struct TradeListCard: View {
    let trade: Trade
    
    var body: some View {
        VStack(spacing: 12) {
            // Header: Symbol & Status
            HStack(alignment: .center) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(trade.type == .buy ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    
                    Text(trade.symbol)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                StatusPill(status: trade.status)
            }
            
            Divider()
                .opacity(0.5)
            
            // Stats Row
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("P&L")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fontWeight(.medium)
                    
                    if let pnl = trade.pnl {
                        Text(String(format: "₹%.2f", pnl))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(pnl >= 0 ? .green : .red)
                    } else {
                        Text("—")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Date")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fontWeight(.medium)
                    
                    Text(trade.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
    }
}

struct StatusPill: View {
    let status: TradeStatus
    
    var color: Color {
        switch status {
        case .planned: return .blue
        case .executed: return .orange
        case .closed: return .secondary
        }
    }
    
    var body: some View {
        Text(status.rawValue)
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .foregroundColor(color)
            .background(color.opacity(0.1))
            .clipShape(Capsule())
    }
}

// End of file
