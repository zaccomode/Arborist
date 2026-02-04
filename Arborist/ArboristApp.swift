//
//  ArboristApp.swift
//  Arborist
//
//  Created by Isaac Shea on 2/2/2026.
//

import SwiftData
import SwiftUI

@main
struct ArboristApp: App {
  private let modelContainer: ModelContainer
  private let repositoryManager: RepositoryManager
  private let navigationManager: NavigationManager
  private let presetManager: PresetManager

  init() {
    // Set up SwiftData container
    let schema = Schema([
      PersistedRepository.self,
      PersistedOpenPreset.self,
      PersistedPresetConfiguration.self,
      PersistedRepositoryPresetOverride.self,
      PersistedRepositoryCustomPreset.self,
      PersistedWorktreeNote.self,
    ])
    
    let modelConfiguration = ModelConfiguration(
      schema: schema,
      isStoredInMemoryOnly: false
    )
    
    do {
      modelContainer = try ModelContainer(
        for: schema,
        configurations: [modelConfiguration]
      )
    } catch {
      fatalError("Failed to create ModelContainer: \(error)")
    }
    
    // Initialize managers with container
    repositoryManager = RepositoryManager(modelContainer: modelContainer)
    navigationManager = NavigationManager(repositoryManager: repositoryManager)
    presetManager = PresetManager(modelContainer: modelContainer)
  }
  
  var body: some Scene {
    WindowGroup {
      MainView()
        .environment(repositoryManager)
        .environment(navigationManager)
        .environment(presetManager)
        .task {
          await repositoryManager.loadRepositories()
          await presetManager.loadPresets()
        }
    }
    .modelContainer(modelContainer)
    .commands {
      CommandGroup(after: .newItem) {
        Button("Refresh All") {
          Task {
            await repositoryManager.refreshAllRepositories()
          }
        }
        .keyboardShortcut("r", modifiers: [.command])
      }
    }

#if os(macOS)
    Settings {
      SettingsView()
        .environment(presetManager)
    }
#endif
  }
}
