//
//  SettingsView.swift
//  Arborist
//
//  Created by Isaac Shea on 2/2/2026.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            OpenPresetsSettingsView()
                .tabItem {
                    Label("Open Presets", systemImage: "arrow.up.forward.app")
                }
        }
        .frame(width: 500, height: 300)
    }
}

struct GeneralSettingsView: View {
    @AppStorage("autoRefreshOnLaunch") private var autoRefreshOnLaunch = true
    @AppStorage("showStaleWorktreeWarnings") private var showStaleWorktreeWarnings = true

    var body: some View {
        Form {
            Toggle("Refresh repositories on launch", isOn: $autoRefreshOnLaunch)

            Toggle("Show warnings for stale worktrees", isOn: $showStaleWorktreeWarnings)
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct OpenPresetsSettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Built-in Presets")
                .font(.headline)

            List {
                ForEach(OpenPreset.defaultPresets) { preset in
                    HStack {
                        Image(systemName: preset.icon)
                            .frame(width: 24)

                        VStack(alignment: .leading) {
                            Text(preset.name)
                            Text(preset.command.displayDescription)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .listStyle(.bordered)

            Text("Custom presets coming soon...")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    SettingsView()
}
