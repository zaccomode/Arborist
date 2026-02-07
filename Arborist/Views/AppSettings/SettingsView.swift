//
//  SettingsView.swift
//  Arborist
//
//  Created by Isaac Shea on 2/2/2026.
//

import SwiftUI

enum AppSettingsPage: Hashable, CaseIterable, Identifiable {
  case general
  case openPresets
  
  var id: String { name }
  
  var name: String {
    switch self {
    case .general: return "General"
    case .openPresets: return "Open Presets"
    }
  }
  
  var systemImage: String {
    switch self {
    case .general: return "gearshape"
    case .openPresets: return "arrow.up.forward.app"
    }
  }
}

struct SettingsView: View {
  @State private var settingsPage: AppSettingsPage = .general
  
  var body: some View {
    NavigationSplitView {
      List(
        AppSettingsPage.allCases,
        selection: $settingsPage
      ) { settingsPage in
        NavigationLink(value: settingsPage) {
          Label(settingsPage.name, systemImage: settingsPage.systemImage)
        }
      }
      .navigationTitle("Arborist Settings")
      .navigationSplitViewColumnWidth(min: 200, ideal: 200)
    } detail: {
      NavigationStack {
        switch settingsPage {
        case .general:
          SettingsGeneralView()
        case .openPresets:
          SettingsOpenPresetsView()
        }
      }
    }
    .frame(minWidth: 650, minHeight: 400)
  }
}

#Preview {
  SettingsView()
}
