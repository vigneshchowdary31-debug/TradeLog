import SwiftUI
import FirebaseFirestore

struct AddTradeView: View {
    @StateObject var viewModel: AddTradeViewModel
    @Environment(\.dismiss) var dismiss
    
    init(trade: Trade? = nil) {
        _viewModel = StateObject(wrappedValue: AddTradeViewModel(trade: trade))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text(viewModel.category == .dividend ? "Share Name" : "Symbol")
                            .fontWeight(.medium)
                        Spacer()
                        TextField("e.g. AAPL", text: $viewModel.symbol)
                            .textInputAutocapitalization(.characters)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    DatePicker("Date", selection: $viewModel.date, displayedComponents: [.date, .hourAndMinute])
                    
                    if viewModel.category != .delivery && viewModel.category != .ipo && viewModel.category != .buyback && viewModel.category != .dividend {
                        Picker("Type", selection: $viewModel.type) {
                            ForEach(TradeType.allCases) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                        .listRowBackground(Color.clear)
                        .padding(.vertical, 5)
                    }
                    
                    Picker("Category", selection: $viewModel.category) {
                        ForEach(TradeCategory.allCases) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                } header: {
                    Text("Details")
                }
                
                Section {
                    HStack {
                        if viewModel.category == .dividend {
                            Text("Dividend Price")
                        } else if viewModel.category == .ipo {
                            Text("Allotted Price")
                        } else {
                            Text("Entry Price")
                        }
                        Spacer()
                        TextField("0.0", text: $viewModel.entryPrice)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    // Hide Target/SL for Dividend AND Delivery AND IPO AND Buyback
                    if viewModel.category != .dividend && viewModel.category != .delivery && viewModel.category != .ipo && viewModel.category != .buyback {
                        HStack {
                            Text("Target")
                            Spacer()
                            TextField("0.0", text: $viewModel.targetPrice)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                        
                        HStack {
                            Text("Stop Loss")
                            Spacer()
                            TextField("0.0", text: $viewModel.stopLoss)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    
                    HStack {
                        Text("Quantity")
                        Spacer()
                        TextField("1", text: $viewModel.quantity)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                } header: {
                    Text(viewModel.category == .dividend ? "Dividend Information" : "Execution")
                }
                
                if viewModel.category != .dividend {
                    Section {
                        HStack {
                            Text(viewModel.category == .buyback ? "Buyback Price" : "Exit Price")
                            Spacer()
                            TextField("Optional", text: $viewModel.exitPrice)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                        
                        HStack {
                            Text("Charges")
                            Spacer()
                            TextField("Optional", text: $viewModel.charges)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                    } header: {
                        Text("Outcome")
                    }
                }
                
                if viewModel.category == .dividend || (!viewModel.exitPrice.isEmpty && !viewModel.quantity.isEmpty) {
                    Section {
                        if viewModel.category != .dividend {
                            HStack {
                                Text("Gross P&L")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(String(format: "₹%.2f", viewModel.calculatedGrossPnL))
                                    .fontWeight(.bold)
                                    .foregroundColor(viewModel.calculatedGrossPnL >= 0 ? .green : .red)
                            }
                            
                            HStack {
                                Text("Net P&L")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(String(format: "₹%.2f", viewModel.calculatedNetPnL))
                                    .fontWeight(.bold)
                                    .foregroundColor(viewModel.calculatedNetPnL >= 0 ? .green : .red)
                            }
                        } else {
                            HStack {
                                Text("Total Dividend Amount")
                                    .foregroundColor(.secondary)
                                Spacer()
                                // Logic for dividend total is entryPrice (div/share) * quantity
                                let divPerShare = Double(viewModel.entryPrice) ?? 0
                                let qty = Double(viewModel.quantity) ?? 0
                                let total = divPerShare * qty
                                Text(String(format: "₹%.2f", total))
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            }
                        }
                    } header: {
                        Text(viewModel.category == .dividend ? "Total" : "Projected P&L")
                    }
                }
                
                Section {
                    if viewModel.category != .dividend {
                        Picker("Status", selection: $viewModel.status) {
                            ForEach(TradeStatus.allCases) { status in
                                Text(status.rawValue).tag(status)
                            }
                        }
                    }
                    
                    ZStack(alignment: .topLeading) {
                        if viewModel.notes.isEmpty {
                            Text("Add notes here...")
                                .foregroundColor(.gray)
                                .padding(.top, 8)
                                .padding(.leading, 5)
                        }
                        TextEditor(text: $viewModel.notes)
                            .frame(minHeight: 100)
                    }
                } header: {
                    Text("Management")
                }
            }
            .navigationTitle(viewModel.isEditing ? "Edit Trade" : "New Trade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: {
                        Task {
                            if await viewModel.saveTrade() {
                                dismiss()
                            }
                        }
                    }) {
                        Text("Save")
                            .fontWeight(.bold)
                    }
                    .disabled(viewModel.symbol.isEmpty || viewModel.entryPrice.isEmpty)
                }
            }
        }
    }
}
