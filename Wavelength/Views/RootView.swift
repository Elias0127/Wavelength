import SwiftUI

// MARK: - Root View
struct RootView: View {
    @StateObject private var appViewModel = AppViewModel()
    @State private var selectedTab: TabSelection = .home
    
    var body: some View {
        Group {
            if appViewModel.hasCompletedOnboarding {
                TabView(selection: $selectedTab) {
                    HomeView(appViewModel: appViewModel)
                        .tabItem {
                            Image(systemName: TabSelection.home.rawValue)
                            Text(TabSelection.home.title)
                        }
                        .tag(TabSelection.home)
                    
                    JournalView(appViewModel: appViewModel)
                        .tabItem {
                            Image(systemName: TabSelection.journal.rawValue)
                            Text(TabSelection.journal.title)
                        }
                        .tag(TabSelection.journal)
                    
                    WeeklyView(appViewModel: appViewModel)
                        .tabItem {
                            Image(systemName: TabSelection.weekly.rawValue)
                            Text(TabSelection.weekly.title)
                        }
                        .tag(TabSelection.weekly)
                    
                    SettingsView(appViewModel: appViewModel)
                        .tabItem {
                            Image(systemName: TabSelection.settings.rawValue)
                            Text(TabSelection.settings.title)
                        }
                        .tag(TabSelection.settings)
                }
                .accentColor(DesignTokens.Colors.primary)
            } else {
                OnboardingView(appViewModel: appViewModel)
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Preview
#Preview {
    RootView()
}
