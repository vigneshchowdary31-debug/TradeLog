import SwiftUI

struct ContentView: View {
    @StateObject var dashboardViewModel = DashboardViewModel()
    
    var body: some View {
        Group {
            TabView {
                AnalyticsView()
                    .environmentObject(dashboardViewModel)
                    .tabItem {
                        Label("Dashboard", systemImage: "house.fill")
                    }
                
                TradeListView()
                    .environmentObject(dashboardViewModel)
                    .tabItem {
                        Label("Trades", systemImage: "list.bullet")
                    }
            }
        }
    }
}
