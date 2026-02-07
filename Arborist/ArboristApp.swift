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
  @Environment(\.openWindow) private var openWindow
  
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
      CommandGroup(after: .appSettings) {
        Button("Settings...") {
          openWindow(id: "settings")
        }
        .keyboardShortcut(",", modifiers: [.command])
      }
    }
    
    // MARK: - Window Settings
    WindowGroup("Repository Settings", id: "repository-settings", for: Repository.ID.self) { $repositoryId in
      if let repositoryId,
         let repository = repositoryManager.repository(withId: repositoryId) {
        RepositorySettingsView(repository: repository)
          .environment(repositoryManager)
          .environment(navigationManager)
          .environment(presetManager)
      }
    }
    
    // MARK: - App Settings
    Window("Arborist Settings", id: "settings") {
      SettingsView()
        .environment(presetManager)
    }
  }
}
