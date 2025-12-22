import SwiftUI
import PhotosUI

struct TradeDetailView: View {
    @State private var trade: Trade
    @Environment(\.dismiss) var dismiss
    @State private var showEditSheet = false
    @State private var selectedItem: PhotosPickerItem?
    
    init(trade: Trade) {
        _trade = State(initialValue: trade)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text(trade.symbol)
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                    
                    HStack {
                        StatusPill(status: trade.status)
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(trade.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top)
                
                // Hero P&L Card (if exited)
                if let pnl = trade.pnl {
                    VStack(spacing: 8) {
                        Text(pnl >= 0 ? "Net Profit" : "Net Loss")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .textCase(.uppercase)
                            .opacity(0.8)
                        
                        Text(String(format: "₹%.2f", abs(pnl)))
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                        
                        // Icon highlight
                        Image(systemName: pnl >= 0 ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill")
                            .font(.title)
                            .padding(.top, 4)
                            .opacity(0.8)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .background(
                        ZStack {
                            pnl >= 0 ? Color.green : Color.red
                            // Gradient overlay for depth
                            LinearGradient(colors: [.white.opacity(0.1), .clear], startPoint: .topLeading, endPoint: .bottomTrailing)
                        }
                    )
                    .cornerRadius(24)
                    .shadow(color: (pnl >= 0 ? Color.green : Color.red).opacity(0.3), radius: 15, x: 0, y: 8)
                    .padding(.horizontal)
                }
                
                // Trade Specs Grid
                VStack(alignment: .leading, spacing: 20) {
                    Text("Overview")
                        .font(.title3)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        DetailTile(title: "Type", value: trade.type.rawValue, color: trade.type == .buy ? .green : .red, icon: "cart.fill")
                        DetailTile(title: "Category", value: trade.category.rawValue, icon: "tag.fill")
                        
                        if let quantity = trade.quantity {
                            DetailTile(title: "Quantity", value: "\(quantity)", icon: "circle.grid.2x2.fill")
                        }
                        
                         if let charges = trade.charges {
                            DetailTile(title: "Charges", value: String(format: "₹%.2f", charges), color: .red, icon: "creditcard.fill")
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Execution Levels
                if trade.category != .dividend {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Execution")
                            .font(.title3)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        VStack(spacing: 0) {
                            ExecutionRow(label: "Entry Price", value: trade.entryPrice)
                            Divider().padding(.vertical, 12).opacity(0.5)
                            ExecutionRow(label: "Target", value: trade.targetPrice, color: .green)
                            Divider().padding(.vertical, 12).opacity(0.5)
                            ExecutionRow(label: "Stop Loss", value: trade.stopLoss, color: .red)
                            
                            if let exit = trade.exitPrice {
                                Divider().padding(.vertical, 12).opacity(0.5)
                                ExecutionRow(label: "Exit Price", value: exit, color: .blue)
                            }
                        }
                        .padding(20)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(20)
                        .padding(.horizontal)
                    }
                } else {
                    // Dividend
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Dividend Details")
                            .font(.title3)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        VStack(spacing: 0) {
                            ExecutionRow(label: "Dividend Per Share", value: trade.entryPrice)
                            if let qty = trade.quantity {
                                Divider().padding(.vertical, 12).opacity(0.5)
                                HStack {
                                    Text("Total Amount")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(String(format: "₹%.2f", (trade.entryPrice * Double(qty))))
                                        .font(.headline)
                                        .foregroundColor(.green)
                                }
                            }
                        }
                        .padding(20)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(20)
                        .padding(.horizontal)
                    }
                }
                
                // Chart Screenshots
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Text("Chart Screenshots")
                            .font(.title3)
                            .fontWeight(.bold)
                        Spacer()
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            HStack(spacing: 6) {
                                Image(systemName: "photo.badge.plus")
                                Text("Add")
                            }
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal)
                    
                    if let imagePaths = trade.imagePaths, !imagePaths.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(imagePaths, id: \.self) { path in
                                    if let image = ImageStorageService.shared.loadImage(fileName: path) {
                                        ZStack(alignment: .topTrailing) {
                                            Image(uiImage: image)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 200, height: 140)
                                                .cornerRadius(12)
                                                .clipped()
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
                                                )
                                            
                                            Button {
                                                // Delete Logic
                                                ImageStorageService.shared.deleteImage(fileName: path)
                                                if var paths = trade.imagePaths {
                                                    paths.removeAll { $0 == path }
                                                    trade.imagePaths = paths
                                                    Task { try? await FirestoreService.shared.updateTrade(trade) }
                                                }
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .symbolRenderingMode(.palette)
                                                    .foregroundStyle(.white, .black.opacity(0.6))
                                                    .font(.system(size: 22))
                                                    .background(Circle().fill(.white).padding(2))
                                            }
                                            .padding(6)
                                        }
                                        .onTapGesture {
                                            // TODO: Open full screen viewer
                                        }
                                        .contextMenu {
                                            Button(role: .destructive) {
                                                ImageStorageService.shared.deleteImage(fileName: path)
                                                if var paths = trade.imagePaths {
                                                    paths.removeAll { $0 == path }
                                                    trade.imagePaths = paths
                                                    Task { try? await FirestoreService.shared.updateTrade(trade) }
                                                }
                                            } label: {
                                                Label("Delete Image", systemImage: "trash")
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    } else {
                        Text("No screenshots attached")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                    }
                }
                .onChange(of: selectedItem) { newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self),
                           let image = UIImage(data: data),
                           let filename = ImageStorageService.shared.saveImage(image) {
                            
                            // Update Local Trade
                            var currentPaths = trade.imagePaths ?? []
                            currentPaths.append(filename)
                            trade.imagePaths = currentPaths
                            
                            // Update Firestore
                            try? await FirestoreService.shared.updateTrade(trade)
                        }
                        selectedItem = nil
                    }
                }
                
                // Notes
                if !trade.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Notes")
                            .font(.title3)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        Text(trade.notes)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .cornerRadius(20)
                            .padding(.horizontal)
                    }
                }
            }
            .padding(.bottom, 40)
        }
        .background(Color(uiColor: .systemGroupedBackground)) // Cleaner plain background
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("Edit") {
                showEditSheet = true
            }
        }
        .sheet(isPresented: $showEditSheet) {
            AddTradeView(trade: trade)
                .onDisappear {
                    Task { await refreshTrade() }
                }
        }
    }
    
    func refreshTrade() async {
        guard let id = trade.id else { return }
        if let updated = try? await FirestoreService.shared.getTrade(id: id) {
            self.trade = updated
        }
    }
}

// Subcomponents for Detail View
struct DetailTile: View {
    let title: String
    let value: String
    var color: Color? = nil
    var icon: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fontWeight(.medium)
            }
            
            Text(value)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(color ?? .primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

struct ExecutionRow: View {
    let label: String
    let value: Double
    var color: Color = .primary
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(String(format: "₹%.2f", value))
                .font(.headline)
                .foregroundColor(color)
        }
    }
}
