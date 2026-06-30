import SwiftUI
import SwiftData

struct RootTabView: View {
    let baby: Baby
    @State private var selectedTab = 0
    @State private var previousTab = 0
    @State private var showingQuickLog = false
    @State private var homePath = NavigationPath()

    private var tabSelection: Binding<Int> {
        Binding(
            get: { selectedTab },
            set: { newValue in
                if newValue == 2 {           // center "Log" tab → present sheet, don't switch
                    showingQuickLog = true
                } else {
                    previousTab = newValue
                    selectedTab = newValue
                }
            })
    }

    var body: some View {
        TabView(selection: tabSelection) {
            HomeView(baby: baby, path: $homePath)
                .tabItem { Label("Home", systemImage: "house.fill") }.tag(0)
            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }.tag(1)
            Color.clear
                .tabItem { Label("Log", systemImage: "plus.circle.fill") }.tag(2)
            HistoryView()
                .tabItem { Label("History", systemImage: "calendar") }.tag(3)
            SettingsView(baby: baby)
                .tabItem { Label("Settings", systemImage: "gearshape") }.tag(4)
        }
        .tint(.moduleSleep)
        .sheet(isPresented: $showingQuickLog) {
            QuickLogView { route in
                showingQuickLog = false
                homePath = NavigationPath()
                homePath.append(route)
                selectedTab = 0
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
}
