import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var viewModel: DashboardViewModel
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Overview")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        Text("Your trading performance at a glance")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    // Key Metrics Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        MetricCard(
                            title: "Total P&L",
                            value: String(format: "₹%.2f", viewModel.totalPnL),
                            icon: "indianrupeesign",
                            color: viewModel.totalPnL >= 0 ? .green : .red
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
                    VStack(alignment: .leading, spacing: 24) {
                        ForEach(TradeCategory.allCases) { category in
                            let trades = viewModel.tradesByCategory[category] ?? []
                            
                            VStack(alignment: .leading, spacing: 16) {
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(category.rawValue)
                                                .font(.title2)
                                                .fontWeight(.bold)
                                                .fontDesign(.rounded)
                                            
                                            Text("\(trades.count)")
                                                .font(.caption2)
                                                .fontWeight(.bold)
                                                .foregroundColor(.secondary)
                                                .padding(6)
                                                .background(Color(uiColor: .secondarySystemGroupedBackground))
                                                .clipShape(Circle())
                                        }
                                        
                                        // P&L and Charges Summary
                                        HStack(spacing: 12) {
                                            if let pnl = viewModel.categoryPnL[category] {
                                                HStack(spacing: 4) {
                                                    Text("P&L:")
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                    Text(String(format: "₹%.2f", pnl))
                                                        .font(.caption)
                                                        .fontWeight(.bold)
                                                        .foregroundColor(pnl >= 0 ? .green : .red)
                                                }
                                            }
                                            
                                            if let charges = viewModel.categoryCharges[category], charges > 0 {
                                                HStack(spacing: 4) {
                                                    Text("Charges:")
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                    Text(String(format: "₹%.2f", charges))
                                                        .font(.caption)
                                                        .fontWeight(.bold)
                                                        .foregroundColor(.red)
                                                }
                                            }
                                        }
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.horizontal)
                                
                                if trades.isEmpty {
                                    Text("No trades recorded")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal)
                                        .padding(.bottom, 10)
                                } else {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 16) {
                                            ForEach(trades) { trade in
                                                NavigationLink(destination: TradeDetailView(trade: trade)) {
                                                    TradeCardView(trade: trade)
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                            }
                                        }
                                        .padding(.horizontal)
                                        .padding(.bottom, 20) // Space for shadow
                                    }
                                }
                            }
                        }
                    }
                    
                    // Empty State
                    if viewModel.recentTrades.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "notebook")
                                .font(.system(size: 60))
                                .foregroundColor(.secondary.opacity(0.3))
                            Text("No trades recorded yet")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("Start your journey by adding your first trade.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    }
                }
                .padding(.bottom, 40)
            }
            .background(Color(uiColor: .systemGroupedBackground))
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


