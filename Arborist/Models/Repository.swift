//
//  Repository.swift
//  Arborist
//
//  Created by Isaac Shea on 2/2/2026.
//

import Foundation
import SwiftData

/// Represents a git repository being managed by Arborist
struct Repository: Identifiable, Codable, Hashable, Sendable {
  let id: UUID
  var name: String
  var path: URL
  var bookmarkData: Data?
  var worktrees: [Worktree]
  var lastRefreshed: Date?
  
  init(
    id: UUID = UUID(),
    name: String,
    path: URL,
    bookmarkData: Data? = nil,
    worktrees: [Worktree] = [],
    lastRefreshed: Date? = nil
  ) {
    self.id = id
    self.name = name
    self.path = path
    self.bookmarkData = bookmarkData
    self.worktrees = worktrees
    self.lastRefreshed = lastRefreshed
  }
  
  /// Number of worktrees in this repository
  var worktreeCount: Int {
    worktrees.count
  }
  
  /// Number of worktrees with stale remote branches
  var staleWorktreeCount: Int {
    worktrees.filter { $0.remoteBranchStatus.isStale }.count
  }
  
  /// Whether the repository has any stale worktrees
  var hasStaleWorktrees: Bool {
    staleWorktreeCount > 0
  }
  
  /// The number of prunable worktrees  in this repository
  var prunableWorktreeCount: Int {
    worktrees.filter { $0.isPrunable }.count
  }
  
  /// Whether the repository has any prunable worktrees
  var hasPrunableWorktrees: Bool {
    prunableWorktreeCount > 0
  }
  
  /// All worktrees that are prunable
  var prunableWorktrees: [Worktree] {
    worktrees.filter { $0.isPrunable }
  }
}

// MARK: - SwiftData Persistence Model

@Model
final class PersistedRepository {
  @Attribute(.unique) var id: UUID
  var name: String
  var pathString: String
  var bookmarkData: Data?
  var addedAt: Date

  /// Relationship to preset overrides for this repository
  @Relationship(deleteRule: .cascade) var presetOverrides: [PersistedRepositoryPresetOverride] = []

  /// Relationship to repository-specific custom presets
  @Relationship(deleteRule: .cascade) var customPresets: [PersistedRepositoryCustomPreset] = []

  init(id: UUID, name: String, pathString: String, bookmarkData: Data?, addedAt: Date = Date()) {
    self.id = id
    self.name = name
    self.pathString = pathString
    self.bookmarkData = bookmarkData
    self.addedAt = addedAt
  }

  convenience init(from repository: Repository) {
    self.init(
      id: repository.id,
      name: repository.name,
      pathString: repository.path.path(percentEncoded: false),
      bookmarkData: repository.bookmarkData
    )
  }

  func toRepository() -> Repository {
    Repository(
      id: id,
      name: name,
      path: URL(filePath: pathString),
      bookmarkData: bookmarkData,
      worktrees: [],
      lastRefreshed: nil
    )
  }
}

// MARK: - Repository Preset Override Persistence

@Model
final class PersistedRepositoryPresetOverride {
  @Attribute(.unique) var id: UUID
  var presetId: UUID
  /// Stored as optional Int: nil = use default, 1 = enabled, 0 = disabled
  var enabledState: Int?

  var repository: PersistedRepository?

  init(id: UUID = UUID(), presetId: UUID, enabledState: Int?) {
    self.id = id
    self.presetId = presetId
    self.enabledState = enabledState
  }

  convenience init(from override: RepositoryPresetOverride) {
    let state: Int? = override.isEnabled.map { $0 ? 1 : 0 }
    self.init(presetId: override.presetId, enabledState: state)
  }

  func toRepositoryPresetOverride() -> RepositoryPresetOverride {
    let enabled: Bool? = enabledState.map { $0 == 1 }
    return RepositoryPresetOverride(presetId: presetId, isEnabled: enabled)
  }
}

// MARK: - Repository-Specific Custom Preset Persistence

@Model
final class PersistedRepositoryCustomPreset {
  @Attribute(.unique) var id: UUID
  var name: String
  var icon: String
  var commandType: String
  var commandValue: String
  var sortOrder: Int

  var repository: PersistedRepository?

  init(
    id: UUID = UUID(),
    name: String,
    icon: String,
    commandType: String,
    commandValue: String,
    sortOrder: Int
  ) {
    self.id = id
    self.name = name
    self.icon = icon
    self.commandType = commandType
    self.commandValue = commandValue
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
      isBuiltIn: false,
      sortOrder: sortOrder
    )
  }
}
