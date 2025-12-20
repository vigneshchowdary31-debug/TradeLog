import SwiftUI
import Charts

struct AnalyticsView: View {
    @EnvironmentObject var viewModel: DashboardViewModel
    @State private var selectedEdgeCategory: TradeCategory = .intraday
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Dashboard")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                        Text("Deep dive into your trading metrics")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                    // Filters
                    HStack(spacing: 0) {
                        // Month (Left Half)
                        Menu {
                            Picker("Month", selection: $viewModel.selectedMonth) {
                                Text("All Months").tag(Int?.none)
                                ForEach(1...12, id: \.self) { month in
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
                        
                        // Year (Right Half)
                        Menu {
                            Picker("Year", selection: $viewModel.selectedYear) {
                                Text("All Years").tag(Int?.none)
                                ForEach(viewModel.availableYears, id: \.self) { year in
                                    Text(String(format: "%d", year)).tag(Int?.some(year))
                                }
                            }
                        } label: {
                            HStack {
                                Text(viewModel.selectedYear != nil ? String(format: "%d", viewModel.selectedYear!) : "Year")
                                    .font(.subheadline)
                                    .fontWeight(viewModel.selectedYear != nil ? .semibold : .medium)
                                    .foregroundColor(viewModel.selectedYear != nil ? .blue : .primary)
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
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, y: 2)
                    .padding(.horizontal)
                    .onChange(of: viewModel.selectedMonth) { _ in viewModel.calculateStats() }
                    .onChange(of: viewModel.selectedYear) { _ in viewModel.calculateStats() }

                    // 1. Core Performance Card
                    PerformanceCard(gross: viewModel.grossPnL, charges: viewModel.totalCharges, net: viewModel.netPnL)
                        .padding(.horizontal)
                    


                    // 3. Key Metrics Grid (Trading Edge)
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
                    
                    // 4. Category Breakdown
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Category Performance")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 0) {
                            ForEach(TradeCategory.allCases) { category in
                                HStack {
                                    Text(category.rawValue)
                                        .font(.system(.body, design: .rounded))
                                        .fontWeight(.medium)
                                    Spacer()
                                    let amount = viewModel.categoryPnL[category] ?? 0
                                    Text(String(format: "₹%.2f", amount))
                                        .font(.system(.body, design: .rounded))
                                        .fontWeight(.bold)
                                        .foregroundColor(amount == 0 ? .secondary : (amount > 0 ? .green : .red))
                                }
                                .padding()
                                
                                if category != TradeCategory.allCases.last {
                                    Divider()
                                        .padding(.leading)
                                }
                            }
                        }
                        .background(Color(.systemBackground))
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
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
    let gross: Double
    let charges: Double
    let net: Double
    
    var body: some View {
        VStack(spacing: 20) {
            // Net P&L Main Display
            VStack(spacing: 5) {
                Text("Net P&L")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                
                Text(String(format: "₹%.2f", net))
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(net >= 0 ? .green : .red)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 10)
            
            Divider()
            
            // Secondary Stats
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Gross P&L")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "₹%.2f", gross))
                        .font(.headline)
                        .fontDesign(.rounded)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Charges")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "-₹%.2f", charges))
                        .font(.headline)
                        .foregroundColor(.red)
                        .fontDesign(.rounded)
                }
            }
            .padding(.horizontal, 10)
        }
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: 5)
    }
}
