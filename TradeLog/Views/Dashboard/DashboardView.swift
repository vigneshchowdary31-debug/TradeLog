import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var viewModel: DashboardViewModel
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Section
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Overview")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                        Text("Your trading performance at a glance")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    // Key Metrics Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        MetricCard(
                            title: "Total P&L",
                            value: String(format: "₹%.2f", viewModel.totalPnL),
                            icon: "indianrupeesign.circle.fill",
                            color: viewModel.totalPnL >= 0 ? .green : .red,
                            trend: nil // Could calculate trend if data available
                        )
                        
                        MetricCard(
                            title: "Win Rate",
                            value: String(format: "%.1f%%", viewModel.winRate),
                            icon: "chart.pie.fill",
                            color: .blue
                        )
                        
                        MetricCard(
                            title: "Active Trades",
                            value: "\(viewModel.openTradesCount)",
                            icon: "bolt.fill",
                            color: .orange
                        )
                        
                        MetricCard(
                            title: "Total Trades",
                            value: "\(viewModel.totalTrades)",
                            icon: "number.circle.fill",
                            color: .purple
                        )
                    }
                    .padding(.horizontal)
                    
                    // Categorized Trades
                    VStack(alignment: .leading, spacing: 20) {
                        ForEach(TradeCategory.allCases) { category in
                            if let trades = viewModel.tradesByCategory[category], !trades.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Text(category.rawValue)
                                            .font(.title3)
                                            .fontWeight(.bold)
                                            .fontDesign(.rounded)
                                        
                                        Spacer()
                                        
                                        Text("\(trades.count)")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.secondary)
                                            .padding(6)
                                            .background(Color(.systemGray6))
                                            .clipShape(Circle())
                                    }
                                    .padding(.horizontal)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 16) {
                                            ForEach(trades) { trade in
                                                TradeCardView(trade: trade)
                                            }
                                        }
                                        .padding(.horizontal)
                                        .padding(.bottom, 10) // Space for shadow
                                    }
                                }
                            }
                        }
                    }
                    
                    // Empty State
                    if viewModel.recentTrades.isEmpty {
                        VStack(spacing: 15) {
                            Image(systemName: "notebook.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.secondary.opacity(0.5))
                            Text("No trades recorded yet")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("Start your journey by adding your first trade.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 50)
                    }
                }
                .padding(.top)
                .padding(.bottom, 40)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Dashboard") // Keep standard title for collapse behavior or hide if using custom header
            .toolbar(.hidden, for: .navigationBar) // Hide standard nav bar to use our custom large header if desired, or keep it.
            // Let's keep standard nav title but hide it in favor of our custom one or just remove our custom one.
            // Decision: Use standard .navigationTitle displayMode .inline or .large.
            // Reverting to standard safe navigation title usage.
            .navigationBarTitleDisplayMode(.inline)
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


