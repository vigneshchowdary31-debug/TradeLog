import SwiftUI

struct TradeListView: View {
    @StateObject var viewModel = TradeListViewModel()
    @EnvironmentObject var dashboardViewModel: DashboardViewModel
    @State private var showAddTrade = false
    

    @State private var showCategoryStatusFilter = false
    @State private var showDateFilter = false
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(spacing: 20) {
                    // Custom Search & Filter Toggle Bar
                    HStack(spacing: 12) {
                        // Search Field
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            
                            TextField("Search symbol", text: $viewModel.searchText)
                                .submitLabel(.done)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
                        
                        // Filter Toggle 1 (Category/Status)
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                showCategoryStatusFilter.toggle()
                                if showCategoryStatusFilter { showDateFilter = false }
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .font(.system(size: 24))
                                .foregroundColor(showCategoryStatusFilter ? .blue : .secondary)
                                .frame(width: 44, height: 44)
                                .background(showCategoryStatusFilter ? Color.blue.opacity(0.1) : Color(.systemBackground))
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
                        }
                        
                        // Filter Toggle 2 (Month/Year)
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                showDateFilter.toggle()
                                if showDateFilter { showCategoryStatusFilter = false }
                            }
                        } label: {
                            Image(systemName: "calendar.circle")
                                .font(.system(size: 24))
                                .foregroundColor(showDateFilter ? .blue : .secondary)
                                .frame(width: 44, height: 44)
                                .background(showDateFilter ? Color.blue.opacity(0.1) : Color(.systemBackground))
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
                        }
                    }
                    .padding(.horizontal)

                    // 1. Category & Status Row
                    if showCategoryStatusFilter {
                        HStack(spacing: 0) {
                            // Category (Left Half)
                            Menu {
                                Picker("Category", selection: $viewModel.selectedCategory) {
                                    Text("All Category").tag(TradeCategory?.none)
                                    ForEach(TradeCategory.allCases) { category in
                                        Text(category.rawValue).tag(TradeCategory?.some(category))
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(viewModel.selectedCategory?.rawValue ?? "Category")
                                        .font(.subheadline)
                                        .fontWeight(viewModel.selectedCategory != nil ? .semibold : .medium)
                                        .foregroundColor(viewModel.selectedCategory != nil ? .blue : .primary)
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
                            
                            // Status (Right Half)
                            Menu {
                                Picker("Status", selection: $viewModel.selectedStatus) {
                                    Text("All Status").tag(TradeStatus?.none)
                                    ForEach(TradeStatus.allCases) { status in
                                        Text(status.rawValue).tag(TradeStatus?.some(status))
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(viewModel.selectedStatus?.rawValue ?? "Status")
                                        .font(.subheadline)
                                        .fontWeight(viewModel.selectedStatus != nil ? .semibold : .medium)
                                        .foregroundColor(viewModel.selectedStatus != nil ? .blue : .primary)
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
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // 2. Month & Year Row
                    if showDateFilter {
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
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // Trade List
                    if viewModel.filteredTrades.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "list.bullet.rectangle.portrait")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary.opacity(0.3))
                            Text("No trades found")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 50)
                    } else {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.filteredTrades) { trade in
                                SwipeToDeleteRow(content: {
                                    TradeListCard(trade: trade)
                                        .contentShape(Rectangle()) // Ensure tap works on whole card
                                        .onTapGesture {
                                            navigationPath.append(trade)
                                        }
                                }, onDelete: {
                                    viewModel.deleteTrade(trade)
                                })
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
                .padding(.top)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Journal")
            .onChange(of: viewModel.searchText) { _ in viewModel.filterTrades() }
            .onChange(of: viewModel.selectedCategory) { _ in viewModel.filterTrades() }
            .onChange(of: viewModel.selectedStatus) { _ in viewModel.filterTrades() }
            .onChange(of: viewModel.selectedMonth) { _ in viewModel.filterTrades() }
            .onChange(of: viewModel.selectedYear) { _ in viewModel.filterTrades() }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        Menu {
                            Picker("Sort By", selection: $viewModel.sortOption) {
                                ForEach(TradeListViewModel.SortOption.allCases) { option in
                                    Text(option.rawValue).tag(option)
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.up.arrow.down.circle")
                                .font(.title3)
                                .foregroundColor(.blue)
                        }
                        .onChange(of: viewModel.sortOption) { _ in viewModel.filterTrades() }
                        
                        Button {
                            showAddTrade.toggle()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddTrade) {
                AddTradeView()
                    .onDisappear {
                        Task { 
                            await viewModel.fetchTrades() 
                            await dashboardViewModel.fetchStats()
                        }
                    }
            }
            .refreshable {
                await viewModel.fetchTrades()
                await dashboardViewModel.fetchStats()
            }
            .navigationDestination(for: Trade.self) { trade in
                TradeDetailView(trade: trade)
            }
        }
        .onAppear {
            Task { 
                await viewModel.fetchTrades()
                // Also fetch dashboard stats to ensure they are ready if user switches tab
                await dashboardViewModel.fetchStats()
            }
        }
    }
}




