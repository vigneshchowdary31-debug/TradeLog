import SwiftUI

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var trend: Double? = nil // Optional trend percentage
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .padding(10)
                    .background(color.opacity(0.15))
                    .clipShape(Circle())
                
                Spacer()
                
                if let trend = trend {
                    HStack(spacing: 2) {
                        Image(systemName: trend >= 0 ? "arrow.up.right" : "arrow.down.right")
                        Text("\(abs(trend), specifier: "%.1f")%")
                    }
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(trend >= 0 ? .green : .red)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(trend >= 0 ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .frame(height: 140)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(20)
        // subtle shadow
        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
}

struct TradeListCard: View {
    let trade: Trade
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // Left: Icon/Type indicator
            ZStack {
                Circle()
                    .fill(trade.type == .buy ? Color.blue.opacity(0.1) : Color.red.opacity(0.1))
                    .frame(width: 48, height: 48)
                
                Text(trade.type.rawValue.prefix(1))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(trade.type == .buy ? .blue : .red)
            }
            
            // Middle: Info
            VStack(alignment: .leading, spacing: 4) {
                Text(trade.symbol)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                HStack(spacing: 6) {
                    Text(trade.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(trade.status.rawValue)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(statusColor(for: trade.status).opacity(0.1))
                        .foregroundColor(statusColor(for: trade.status))
                        .clipShape(Capsule())
                }
            }
            
            Spacer()
            
            // Right: P&L
            VStack(alignment: .trailing, spacing: 2) {
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
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(20)
        // Removed shadow for flatter list look, or keep very subtle
        .shadow(color: Color.black.opacity(0.02), radius: 5, x: 0, y: 2)
    }
    
    private func statusColor(for status: TradeStatus) -> Color {
        switch status {
        case .planned: return .blue
        case .executed: return .orange
        case .closed: return .secondary
        }
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
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundColor(color)
            .background(color.opacity(0.1))
            .clipShape(Capsule())
    }
}


// End of file
