import SwiftUI
import UniformTypeIdentifiers

struct ImportView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showFileImporter = false
    @State private var importedTrades: [Trade] = []
    @State private var isImporting = false
    @State private var importError: String?
    
    var body: some View {
        NavigationStack {
            VStack {
                if importedTrades.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Import Trades")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Select a CSV file to import trades. \nEnsure format matches the export format.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        Button {
                            showFileImporter = true
                        } label: {
                            Text("Select CSV File")
                                .bold()
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 40)
                        
                        if let error = importError {
                            Text("Error: \(error)")
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding()
                        }
                    }
                } else {
                    // Preview List
                    VStack {
                        HStack {
                            Text("Preview: \(importedTrades.count) Trades")
                                .font(.headline)
                            Spacer()
                            Button("Clear") {
                                importedTrades = []
                                importError = nil
                            }
                            .font(.subheadline)
                            .foregroundColor(.red)
                        }
                        .padding()
                        
                        List(importedTrades) { trade in
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(trade.symbol).bold()
                                    Spacer()
                                    Text(trade.date.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                HStack {
                                    Text(trade.type.rawValue)
                                        .foregroundColor(trade.type == .buy ? .green : .red)
                                    Spacer()
                                    Text(String(format: "₹%.2f", trade.entryPrice))
                                }
                                .font(.caption)
                            }
                        }
                        .listStyle(.plain)
                        
                        Button {
                            confirmImport()
                        } label: {
                             HStack {
                                if isImporting {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Confirm Import")
                                }
                            }
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(isImporting)
                        .padding()
                    }
                }
            }
            .navigationTitle("Import Trades")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [.commaSeparatedText, .plainText],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        // Access security scoped resource for iCloud/Files compatibility
                        if url.startAccessingSecurityScopedResource() {
                            defer { url.stopAccessingSecurityScopedResource() }
                            do {
                                let trades = try CSVManager.shared.parseCSV(url: url)
                                if trades.isEmpty {
                                    importError = "No valid trades found in CSV."
                                } else {
                                    importedTrades = trades
                                    importError = nil
                                }
                            } catch {
                                importError = error.localizedDescription
                            }
                        } else {
                            importError = "Permission denied to access file."
                        }
                    }
                case .failure(let error):
                    importError = error.localizedDescription
                }
            }
        }
    }
    
    func confirmImport() {
        isImporting = true
        Task {
            // Save one by one or batch if supported. FirestoreService supports single add.
            // Ideally add batch support, but loop is fine for MVP (speed might be slow for 1000s)
            
            var successCount = 0
            for trade in importedTrades {
                do {
                    try await FirestoreService.shared.addTrade(trade)
                    successCount += 1
                } catch {
                    print("Failed to save trade: \(error)")
                }
            }
            
            await MainActor.run {
                isImporting = false
                dismiss() // Close on completion
            }
        }
    }
}
