import SwiftUI

struct ExportView: View {
    let trades: [Trade]
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedRange: ExportDateRange = .allTime
    @State private var csvURL: URL?
    @State private var isGenerating = false
    
    enum ExportDateRange: String, CaseIterable, Identifiable {
        case allTime = "All Time"
        case thisMonth = "This Month"
        case last3Months = "Last 3 Months"
        case thisFinancialYear = "This Financial Year"
        var id: String { rawValue }
    }
    
    var filteredTrades: [Trade] {
        switch selectedRange {
        case .allTime:
            return trades
        case .thisMonth:
            return trades.filter { Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month) }
        case .last3Months:
            guard let date = Calendar.current.date(byAdding: .month, value: -3, to: Date()) else { return trades }
            return trades.filter { $0.date >= date }
        case .thisFinancialYear:
             // Simple approximation: if current month >= 4, start is Apr 1 this year. Else Apr 1 last year.
             let currentMonth = Calendar.current.component(.month, from: Date())
             let currentYear = Calendar.current.component(.year, from: Date())
             let startYear = currentMonth >= 4 ? currentYear : currentYear - 1
             let startComponents = DateComponents(year: startYear, month: 4, day: 1)
             guard let startDate = Calendar.current.date(from: startComponents) else { return trades }
             return trades.filter { $0.date >= startDate }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Range Picker
                VStack(alignment: .leading, spacing: 10) {
                    Text("Select Time Range")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Picker("Time Range", selection: $selectedRange) {
                        ForEach(ExportDateRange.allCases) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 120)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                // Summary
                HStack {
                    VStack {
                        Text("\(filteredTrades.count)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.blue)
                        Text("Trades to Export")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                
                Spacer()
                
                // Action Button
                if let url = csvURL {
                    ShareLink(item: url) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share CSV File")
                        }
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                } else {
                    Button {
                        generateCSV()
                    } label: {
                        HStack {
                            if isGenerating {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "doc.text.fill")
                                Text("Generate CSV")
                            }
                        }
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(filteredTrades.isEmpty ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(filteredTrades.isEmpty || isGenerating)
                    .padding(.horizontal)
                }
            }
            .padding(.top)
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Export Trades")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .onChange(of: selectedRange) { _ in
                csvURL = nil // Reset URL if range changes
            }
        }
    }
    
    func generateCSV() {
        isGenerating = true
        DispatchQueue.global(qos: .userInitiated).async {
            let url = CSVManager.shared.generateCSV(from: filteredTrades)
            DispatchQueue.main.async {
                self.csvURL = url
                self.isGenerating = false
            }
        }
    }
}
