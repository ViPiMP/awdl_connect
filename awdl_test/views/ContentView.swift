import SwiftUI

/// Main content view with tab-based navigation.
struct ContentView: View {
    @StateObject private var multipeerManager = MultipeerManager()

    var body: some View {
        TabView {
            ConnectionView()
                .tabItem {
                    Label("Connect", systemImage: "antenna.radiowaves.left.and.right")
                }

            ChatView()
                .tabItem {
                    Label("Chat", systemImage: "message.fill")
                }

            StatusView()
                .tabItem {
                    Label("Status", systemImage: "info.circle.fill")
                }
        }
        .environmentObject(multipeerManager)
        .tint(.blue)
    }
}

#Preview {
    ContentView()
}
