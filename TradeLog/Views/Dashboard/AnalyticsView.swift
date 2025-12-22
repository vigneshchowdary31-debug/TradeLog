import SwiftUI
import Charts

struct AnalyticsView: View {
    @EnvironmentObject var viewModel: DashboardViewModel
    @State private var selectedEdgeCategory: TradeCategory = .intraday
    @State private var showCapitalSheet = false
    @State private var tempCapital = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Dashboard")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                            Text("Deep dive into your trading metrics")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)

                    // Filters
                    HStack(spacing: 0) {
                        // Month (Left Half)
                        Menu {
                            Picker("Month", selection: $viewModel.selectedMonth) {
                                Text("All Months").tag(Int?.none)
                                // Standard FY Order: Apr -> Mar
                                ForEach([4, 5, 6, 7, 8, 9, 10, 11, 12, 1, 2, 3], id: \.self) { month in
                                    Text(Calendar.current.monthSymbols[month - 1]).tag(Int?.some(month))
                                }
                            }
                        } label: {
                            HStack {
                                Text(viewModel.selectedMonth != nil ? Calendar.current.monthSymbols[viewModel.selectedMonth! - 1] : "Month")
                                    .font(.subheadline)
                                    .fontWeight(viewModel.selectedMonth != nil ? .semibold : .medium)
                                    .foregroundColor(viewModel.selectedMonth != nil ? .blue : .primary)
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity)
                            .contentShape(Rectangle())
                        }
                        
                        Divider()
                            .frame(height: 24)
                        
                        // Financial Year (Right Half)
                        Menu {
                            Picker("Financial Year", selection: $viewModel.selectedFinancialYear) {
                                Text("All Time").tag(Int?.none)
                                ForEach(viewModel.availableFinancialYears, id: \.self) { year in
                                    Text(String(format: "FY %02d-%02d", year % 100, (year + 1) % 100)).tag(Int?.some(year))
                                }
                            }
                        } label: {
                            HStack {
                                if let fy = viewModel.selectedFinancialYear {
                                    Text(String(format: "FY %02d-%02d", fy % 100, (fy + 1) % 100))
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.blue)
                                } else {
                                    Text("Fin. Year")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                }
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity)
                            .contentShape(Rectangle())
                        }
                    }
                    .background(Color(uiColor: .systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, y: 2)
                    .padding(.horizontal)
                    .onChange(of: viewModel.selectedMonth) { _ in viewModel.calculateStats() }
                    .onChange(of: viewModel.selectedFinancialYear) { _ in viewModel.calculateStats() }

                    // 1. Core Performance Card (Net & Gross, No ROI/Capital)
                    PerformanceCard(
                        charges: viewModel.totalCharges,
                        net: viewModel.netPnL,
                        gross: viewModel.grossPnL
                    )
                    .padding(.horizontal)
                    
                    // 2. Key Metrics Grid (Trading Edge)
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Text("Trading Edge")
                                .font(.headline)
                            
                            Spacer()
                            
                            Picker("Edge Category", selection: $selectedEdgeCategory) {
                                Text("Intraday").tag(TradeCategory.intraday)
                                Text("F&O").tag(TradeCategory.fno)
                                Text("MTF").tag(TradeCategory.mtf)
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 160)
                        }
                        .padding(.horizontal)
                            
                        let edgeStats = viewModel.getEdgeStats(for: selectedEdgeCategory)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                            MetricCard(
                                title: "Win Rate",
                                value: String(format: "%.1f%%", edgeStats.winRate),
                                icon: "chart.pie.fill",
                                color: .blue
                            )
                            MetricCard(
                                title: "Total Trades",
                                value: "\(edgeStats.totalTrades)",
                                icon: "number.circle.fill",
                                color: .purple
                            )
                            
                            MetricCard(
                                title: "Avg Win",
                                value: String(format: "₹%.0f", edgeStats.avgWin),
                                icon: "arrow.up.circle.fill",
                                color: .green
                            )
                            MetricCard(
                                title: "Avg Loss",
                                value: String(format: "₹%.0f", abs(edgeStats.avgLoss)),
                                icon: "arrow.down.circle.fill",
                                color: .red
                            )
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top)
                .padding(.bottom, 40)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
            .refreshable {
                await viewModel.fetchStats()
            }
         }
        .onAppear {
            Task {
                await viewModel.fetchStats()
            }
        }
    }
}

// Subcomponents

struct PerformanceCard: View {
    let charges: Double
    let net: Double
    let gross: Double? // Optional Gross P&L
    let roi: Double?   // Optional ROI
    let capital: Double? // Optional Capital
    var onTapCapital: (() -> Void)? = nil
    
    init(charges: Double, net: Double, gross: Double? = nil, roi: Double? = nil, capital: Double? = nil, onTapCapital: (() -> Void)? = nil) {
        self.charges = charges
        self.net = net
        self.gross = gross
        self.roi = roi
        self.capital = capital
        self.onTapCapital = onTapCapital
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Net P&L Main Display
            VStack(spacing: 8) {
                Text("NET P&L")
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .tracking(1)
                
                Text(String(format: "₹%.2f", net))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(net >= 0 ? .green : .red)
                
                // Show ROI only if available and Capital is present
                if let roi = roi, let capital = capital, capital > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: roi >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption2)
                        Text(String(format: "%.2f%% ROI", roi))
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(roi >= 0 ? .green : .red)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(roi >= 0 ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                    )
                }
            }
            .frame(maxWidth: .infinity)
            
            // Secondary Stats
            HStack(alignment: .firstTextBaseline) {
                // Left Side: Gross P&L OR Capital
                if let gross = gross {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("GROSS P&L")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        Text(String(format: "₹%.2f", gross))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .fontDesign(.rounded)
                            .foregroundColor(gross >= 0 ? .green : .red)
                    }
                } else if let capital = capital, capital > 0 {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("CAPITAL")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            Text(String(format: "₹%.0f", capital))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .fontDesign(.rounded)
                                .foregroundColor(onTapCapital != nil ? .blue : .primary)
                            
                            if onTapCapital != nil {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.caption2)
                                    .foregroundColor(.blue.opacity(0.7))
                            }
                        }
                    }
                    .onTapGesture {
                        onTapCapital?()
                    }
                }
                
                Spacer()
                
                // Right Side: Charges (Always Shown)
                VStack(alignment: .trailing, spacing: 4) {
                    Text("CHARGES")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    Text(String(format: "-₹%.2f", charges))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .fontDesign(.rounded)
                        .foregroundColor(.red.opacity(0.8))
                }
            }
            .padding(.top, 8)
            .padding(.horizontal, 32)
        }
        .padding(.vertical, 32)
        .padding(.horizontal, 24)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
    }
}
