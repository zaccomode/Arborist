//
//  OpenPreset.swift
//  Arborist
//
//  Created by Isaac Shea on 2/2/2026.
//

import Foundation
import SwiftData

/// The type of command to execute when opening a worktree
enum OpenCommand: Codable, Hashable, Sendable {
  /// Open with a specific application by bundle identifier
  case application(bundleIdentifier: String)
  /// Execute a custom bash script ({{path}} is replaced with worktree path)
  case bash(script: String)
  /// Open a URL in the default browser ({{path}} is replaced with worktree path)
  case url(template: String)
  
  var displayDescription: String {
    switch self {
    case .application(let bundleId):
      return "Open with \(bundleId)"
    case .bash(let script):
      return script
    case .url(let template):
      return template
    }
  }
  
  var typeDisplayName: String {
    switch self {
    case .application:
      return "Application"
    case .bash:
      return "Bash Script"
    case .url:
      return "URL"
    }
  }
}

/// Represents a preset for opening worktrees in external applications
struct OpenPreset: Identifiable, Codable, Hashable, Sendable {
  let id: UUID
  var name: String
  var icon: String
  var command: OpenCommand
  var isBuiltIn: Bool
  var sortOrder: Int
  /// Whether this preset is enabled by default (only applies to built-in presets)
  var defaultEnabled: Bool

  init(
    id: UUID = UUID(),
    name: String,
    icon: String,
    command: OpenCommand,
    isBuiltIn: Bool = false,
    sortOrder: Int = 0,
    defaultEnabled: Bool = true
  ) {
    self.id = id
    self.name = name
    self.icon = icon
    self.command = command
    self.isBuiltIn = isBuiltIn
    self.sortOrder = sortOrder
    self.defaultEnabled = defaultEnabled
  }
  
  // MARK: - Built-in Presets
  
  static let finder = OpenPreset(
    id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
    name: "Finder",
    icon: "folder",
    command: .application(bundleIdentifier: "com.apple.Finder"),
    isBuiltIn: true,
    sortOrder: 0
  )
  
  static let terminal = OpenPreset(
    id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
    name: "Terminal",
    icon: "terminal",
    command: .application(bundleIdentifier: "com.apple.Terminal"),
    isBuiltIn: true,
    sortOrder: 1
  )
  
  static let vscode = OpenPreset(
    id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
    name: "VS Code",
    icon: "chevron.left.forwardslash.chevron.right",
    command: .bash(script: "code \"{{path}}\""),
    isBuiltIn: true,
    sortOrder: 2
  )
  
  static let xcode = OpenPreset(
    id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
    name: "Xcode",
    icon: "hammer",
    command: .application(bundleIdentifier: "com.apple.dt.Xcode"),
    isBuiltIn: true,
    sortOrder: 3,
    defaultEnabled: false
  )

  static let warp = OpenPreset(
    id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!,
    name: "Warp",
    icon: "terminal.fill",
    command: .application(bundleIdentifier: "dev.warp.Warp-Stable"),
    isBuiltIn: true,
    sortOrder: 4,
    defaultEnabled: false
  )
  
  static let defaultPresets: [OpenPreset] = [
    .finder,
    .terminal,
    .vscode,
    .xcode,
    .warp,
  ]
  
  /// All built-in preset IDs for easy lookup
  static let builtInPresetIds: Set<UUID> = Set(defaultPresets.map { $0.id })
}

// MARK: - Preset Configuration (App-Level)

/// Tracks the enabled/disabled state and sort order for a preset at the app level
struct PresetConfiguration: Identifiable, Codable, Hashable, Sendable {
  var id: UUID { presetId }
  let presetId: UUID
  var isEnabled: Bool
  var sortOrder: Int
  
  init(presetId: UUID, isEnabled: Bool = true, sortOrder: Int = 0) {
    self.presetId = presetId
    self.isEnabled = isEnabled
    self.sortOrder = sortOrder
  }
}

// MARK: - Repository Preset Override

/// Tracks repository-level overrides for preset visibility
struct RepositoryPresetOverride: Identifiable, Codable, Hashable, Sendable {
  var id: UUID { presetId }
  let presetId: UUID
  /// nil = use app default, true = force enabled, false = force disabled
  var isEnabled: Bool?
  
  init(presetId: UUID, isEnabled: Bool?) {
    self.presetId = presetId
    self.isEnabled = isEnabled
  }
}

// MARK: - SwiftData Persistence Model

@Model
final class PersistedOpenPreset {
  @Attribute(.unique) var id: UUID
  var name: String
  var icon: String
  var commandType: String
  var commandValue: String
  var isBuiltIn: Bool
  var sortOrder: Int
  
  init(
    id: UUID,
    name: String,
    icon: String,
    commandType: String,
    commandValue: String,
    isBuiltIn: Bool,
    sortOrder: Int
  ) {
    self.id = id
    self.name = name
    self.icon = icon
    self.commandType = commandType
    self.commandValue = commandValue
    self.isBuiltIn = isBuiltIn
    self.sortOrder = sortOrder
  }
  
  convenience init(from preset: OpenPreset) {
    let (type, value): (String, String) = {
      switch preset.command {
      case .application(let bundleId):
        return ("application", bundleId)
      case .bash(let script):
        return ("bash", script)
      case .url(let template):
        return ("url", template)
      }
    }()
    
    self.init(
      id: preset.id,
      name: preset.name,
      icon: preset.icon,
      commandType: type,
      commandValue: value,
      isBuiltIn: preset.isBuiltIn,
      sortOrder: preset.sortOrder
    )
  }
  
  func toOpenPreset() -> OpenPreset {
    let command: OpenCommand = {
      switch commandType {
      case "application":
        return .application(bundleIdentifier: commandValue)
      case "bash":
        return .bash(script: commandValue)
      case "url":
        return .url(template: commandValue)
      default:
        return .bash(script: commandValue)
      }
    }()
    
    return OpenPreset(
      id: id,
      name: name,
      icon: icon,
      command: command,
      isBuiltIn: isBuiltIn,
      sortOrder: sortOrder
    )
  }
}

// MARK: - SwiftData Persistence for Preset Configuration

@Model
final class PersistedPresetConfiguration {
  @Attribute(.unique) var presetId: UUID
  var isEnabled: Bool
  var sortOrder: Int
  
  init(presetId: UUID, isEnabled: Bool, sortOrder: Int) {
    self.presetId = presetId
    self.isEnabled = isEnabled
    self.sortOrder = sortOrder
  }
  
  convenience init(from config: PresetConfiguration) {
    self.init(
      presetId: config.presetId,
      isEnabled: config.isEnabled,
      sortOrder: config.sortOrder
    )
  }
  
  func toPresetConfiguration() -> PresetConfiguration {
    PresetConfiguration(
      presetId: presetId,
      isEnabled: isEnabled,
      sortOrder: sortOrder
    )
  }
}
