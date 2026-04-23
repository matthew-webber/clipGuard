import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsTab()
                .tabItem { Label("General", systemImage: "gearshape") }
            URLRulesSettingsTab()
                .tabItem { Label("URL Rules", systemImage: "link") }
            BlacklistSettingsTab()
                .tabItem { Label("Blacklist", systemImage: "nosign") }
            AboutTab()
                .tabItem { Label("About", systemImage: "info.circle") }
        }
        .padding(18)
    }
}
