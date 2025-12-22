import SwiftUI

struct ContentView: View {
    @StateObject var dashboardViewModel = DashboardViewModel()
    
    var body: some View {
        Group {
            TabView {
                AnalyticsView()
                    .environmentObject(dashboardViewModel)
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                
                TradeListView()
                    .environmentObject(dashboardViewModel)
                    .tabItem {
                        Label("Trades", systemImage: "list.bullet")
                    }
                
                ReportsView()
                    .environmentObject(dashboardViewModel)
                    .tabItem {
                        Label("Analytics", systemImage: "chart.bar.xaxis")
                    }
            }
        }
    }
}
