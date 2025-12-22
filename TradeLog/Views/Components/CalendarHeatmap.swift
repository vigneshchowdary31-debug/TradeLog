import SwiftUI

struct CalendarHeatmap: View {
    let dailyPnL: [Date: Double]
    let month: Int?
    let year: Int?
    
    // Calendar Helpers
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    
    private var daysInMonth: [Date] {
        let currentYear = year ?? calendar.component(.year, from: Date())
        let currentMonth = month ?? calendar.component(.month, from: Date())
        
        var components = DateComponents()
        components.year = currentYear
        components.month = currentMonth
        components.day = 1
        
        guard let startOfMonth = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: startOfMonth) else { return [] }
        
        // Adjust for weekday start padding
        let weekday = calendar.component(.weekday, from: startOfMonth)
        let padding = Array(repeating: Date.distantPast, count: weekday - 1)
        
        let days = range.compactMap { day -> Date? in
            components.day = day
            return calendar.date(from: components)
        }
        
        return padding + days
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Weekday Headers
            HStack {
                ForEach(calendar.shortWeekdaySymbols, id: \.self) { day in
                    Text(day.prefix(1))
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(daysInMonth.indices, id: \.self) { index in
                    let date = daysInMonth[index]
                    
                    if date == Date.distantPast {
                         // Padding
                         Color.clear
                             .aspectRatio(1, contentMode: .fit)
                    } else {
                        // Day Cell
                        let dayStart = calendar.startOfDay(for: date)
                        let pnl = dailyPnL[dayStart]
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(colorFor(pnl: pnl))
                                .aspectRatio(1, contentMode: .fit)
                            
                            if let pnl = pnl, pnl != 0 {
                                // Optional: simple indicator or just color
                            }
                            
                            Text("\(calendar.component(.day, from: date))")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(pnl == nil ? .primary : .white)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, y: 2)
    }
    
    private func colorFor(pnl: Double?) -> Color {
        guard let pnl = pnl, pnl != 0 else {
            return Color(uiColor: .systemFill).opacity(0.3)
        }
        
        if pnl > 0 {
            // Intensity based on amount? For simplicity, just Green/Red
            // Or use opacity based on max value if available.
            return .green.opacity(0.8)
        } else {
            return .red.opacity(0.8)
        }
    }
}
