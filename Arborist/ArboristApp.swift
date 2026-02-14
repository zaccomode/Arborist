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
    // Set up SwiftData container with explicit store location and migration plan
    let schema = Schema(SchemaV1.models)

    // Store in an app-specific directory to avoid collisions with other apps
    let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    let arboristDirectory = appSupportURL.appending(path: "Arborist", directoryHint: .isDirectory)

    // Ensure the directory exists
    try? FileManager.default.createDirectory(at: arboristDirectory, withIntermediateDirectories: true)

    let storeURL = arboristDirectory.appending(path: "Arborist.store")

    let modelConfiguration = ModelConfiguration(
      schema: schema,
      url: storeURL
    )

    do {
      modelContainer = try ModelContainer(
        for: schema,
        migrationPlan: ArboristMigrationPlan.self,
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
          await repositoryManager.refreshAllRepositories()
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
