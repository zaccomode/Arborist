//
//  RepositorySettingsView.swift
//  Arborist
//
//  Created by Isaac Shea on 2/4/2026.
//

import SwiftUI

enum RepositorySettingsPage: Hashable, CaseIterable, Identifiable {
  case openPresets
  
  var id: String { name }
  
  var name: String {
    switch self {
    case .openPresets: return "Open Presets"
    }
  }
  
  var systemImage: String {
    switch self {
    case .openPresets: return "arrow.up.forward.app"
    }
  }
}

struct RepositorySettingsView: View {
  @Environment(PresetManager.self) private var presetManager
  @Environment(RepositoryManager.self) private var repositoryManager
  @Environment(NavigationManager.self) private var navigationManager
  
  let repository: Repository
  
  @State private var settingsPage: RepositorySettingsPage = .openPresets
  
  @State private var isShowingPresetEditor = false
  @State private var editingPreset: OpenPreset?
  
  
  var body: some View {
    NavigationSplitView {
      List(
        RepositorySettingsPage.allCases,
        selection: $settingsPage
      ) { settingsPage in
        NavigationLink(value: settingsPage) {
          Label(settingsPage.name, systemImage: settingsPage.systemImage)
        }
      }
      .navigationTitle("Repository Settings")
      .navigationSplitViewColumnWidth(min: 200, ideal: 200)
    } detail: {
      NavigationStack {
        switch settingsPage {
        case .openPresets: RepoSettingsOpenPresetsView(repository: repository)
        }
      }
    }
    .frame(minWidth: 650, minHeight: 400)
  }
}

#Preview {
  RepositorySettingsView(
    repository: Repository(
      name: "Test Repo",
      path: URL(filePath: "/Users/test/repo")
    )
  )
  .environment(PresetManager())
}
