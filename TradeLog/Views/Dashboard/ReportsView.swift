import SwiftUI

struct ReportsView: View {
    @EnvironmentObject var viewModel: DashboardViewModel
    @State private var showExportSheet = false
    @State private var showImportSheet = false
    @State private var showCapitalSheet = false
    @State private var tempCapital = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 1. Performance Card
                    HStack {
                        Text("Overall Performance")
                            .font(.headline)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    PerformanceCard(
                        charges: viewModel.fyTotalCharges,
                        net: viewModel.fyNetPnL,
                        roi: viewModel.fyRoi,
                        capital: viewModel.capital,
                        onTapCapital: {
                            tempCapital = String(format: "%.0f", viewModel.capital)
                            showCapitalSheet = true
                        }
                    )
                    .padding(.horizontal)
                    
                    // 2. Consistency Heatmap (Live / Current Month)
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Consistency Heatmap")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        CalendarHeatmap(
                            dailyPnL: viewModel.fyDailyPnL,
                            month: Calendar.current.component(.month, from: Date()),
                            year: Calendar.current.component(.year, from: Date())
                        )
                        .padding(.horizontal)
                    }
                    
                    // 3. Category Breakdown (Full FY)
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
                                    let amount = viewModel.fyCategoryPnL[category] ?? 0
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
                        .background(Color(uiColor: .systemBackground))
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
                        .padding(.horizontal)
                    }
                    
                    // 4. Data Management
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Data Management")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        HStack(spacing: 16) {
                            Button {
                                showImportSheet = true
                            } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: "square.and.arrow.down")
                                        .font(.title2)
                                    Text("Import")
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.blue)
                                .cornerRadius(16)
                                .shadow(color: Color.blue.opacity(0.3), radius: 6, x: 0, y: 4)
                            }
                            
                            Button {
                                showExportSheet = true
                            } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.title2)
                                    Text("Export")
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.blue)
                                .cornerRadius(16)
                                .shadow(color: Color.blue.opacity(0.3), radius: 6, x: 0, y: 4)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 40)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Analytics")

            .sheet(isPresented: $showExportSheet) {
                // We pass all trades to export view, filtering happens there
                ExportView(trades: viewModel.allTrades)
                    .presentationDetents([.medium])
            }
            .sheet(isPresented: $showImportSheet) {
                ImportView()
                    .onDisappear {
                        Task { await viewModel.fetchStats() }
                    }
            }
            .sheet(isPresented: $showCapitalSheet) {
                NavigationStack {
                    Form {
                        Section("Total Trading Capital") {
                            TextField("Enter amount (e.g. 500000)", text: $tempCapital)
                                .keyboardType(.decimalPad)
                        }
                        
                        Button("Update Capital") {
                            if let amount = Double(tempCapital) {
                                viewModel.updateCapital(amount)
                                showCapitalSheet = false
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .bold()
                    }
                    .navigationTitle("Set Capital")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showCapitalSheet = false }
                        }
                    }
                }
                .presentationDetents([.fraction(0.3)])
            }
        }
    }
}
