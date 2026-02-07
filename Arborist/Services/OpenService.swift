//
//  OpenService.swift
//  Arborist
//
//  Created by Isaac Shea on 2/2/2026.
//

import AppKit
import Foundation

/// Errors that can occur when opening worktrees
enum OpenError: LocalizedError {
  case applicationNotFound(bundleIdentifier: String)
  case failedToOpen(message: String)
  
  var errorDescription: String? {
    switch self {
    case .applicationNotFound(let bundleId):
      return "Application not found: \(bundleId)"
    case .failedToOpen(let message):
      return "Failed to open: \(message)"
    }
  }
}

/// Service for opening worktrees in external applications
actor OpenService {
  static nonisolated let shared = OpenService()
  
  private let shell: ShellExecutor
  
  private init() {
    self.shell = ShellExecutor.shared
  }
  
  /// Open a worktree with a preset
  func open(worktree: Worktree, repository: Repository, with preset: OpenPreset) async throws {
    switch preset.command {
    case .application(let bundleIdentifier):
      try await openWithApplication(path: worktree.path, bundleIdentifier: bundleIdentifier)
    case .bash(let script):
      try await openWithBashScript(
        worktree: worktree,
        repository: repository,
        script: script
      )
    case .url(let template):
      try await openWithURL(
        worktree: worktree,
        repository: repository,
        template: template
      )
    }
  }
  
  /// Open path with a specific application
  private func openWithApplication(path: URL, bundleIdentifier: String) async throws {
    try await MainActor.run {
      guard let appURL = NSWorkspace.shared.urlForApplication(
        withBundleIdentifier: bundleIdentifier
      ) else {
        throw OpenError.applicationNotFound(bundleIdentifier: bundleIdentifier)
      }
      
      let configuration = NSWorkspace.OpenConfiguration()
      configuration.activates = true
      NSWorkspace.shared.open(
        [path],
        withApplicationAt: appURL,
        configuration: configuration
      )
    }
  }
  
  /// Open path by executing a bash script
  private func openWithBashScript(
    worktree: Worktree,
    repository: Repository,
    script: String
  ) async throws {
    let expandedScript = substituteTemplateString(
      worktree: worktree,
      repository: repository,
      template: script
    )
    
    do {
      let result = try await shell.execute(
        command: "/bin/bash",
        arguments: ["-l", "-i", "-c", expandedScript],
        workingDirectory: worktree.path,
        environment: nil
      )
      
      if !result.succeeded {
        throw OpenError.failedToOpen(message: result.stderr)
      }
    } catch {
      print("Failed to execute bash script: \(error)")
      throw OpenError.failedToOpen(message: error.localizedDescription)
    }
  }
  
  /// Open a URL with path substitution in the default browser
  private func openWithURL(
    worktree: Worktree,
    repository: Repository,
    template: String
  ) async throws {
    let expandedURL = substituteTemplateString(
      worktree: worktree,
      repository: repository,
      template: template
    )
    
    guard let url = URL(string: expandedURL) else {
      throw OpenError.failedToOpen(message: "Invalid URL: \(expandedURL)")
    }
    
    try await MainActor.run {
      let success = NSWorkspace.shared.open(url)
      if !success {
        throw OpenError.failedToOpen(message: "Failed to open URL: \(expandedURL)")
      }
    }
  }
  
  /// Substituting template strings for worktree and repository properties.
  private func substituteTemplateString(
    worktree: Worktree,
    repository: Repository,
    template: String
  ) -> String {
    SubstitutableString.substituteAll(
      in: template,
      worktree: worktree,
      repository: repository
    )
  }
  
  /// Reveal path in Finder
  func revealInFinder(path: URL) async {
    await MainActor.run {
      NSWorkspace.shared.activateFileViewerSelecting([path])
    }
  }
}

nonisolated enum SubstitutableString: CaseIterable, Identifiable {
  case path
  case branch
  case commitHash
  case repoName
  case repoPath
  
  var id: String { self.substitutionString }
  
  var substitutionString: String {
    switch self {
    case .path: return "{{path}}"
    case .branch: return "{{branch}}"
    case .commitHash: return "{{commitHash}}"
    case .repoName: return "{{repoName}}"
    case .repoPath: return "{{repoPath}}"
    }
  }
  
  func replacementString(worktree: Worktree, repository: Repository) -> String {
    switch self {
    case .path: return worktree.path.path(percentEncoded: false)
    case .branch: return worktree.branch
    case .commitHash: return worktree.commitHash
    case .repoName: return repository.name
    case .repoPath: return repository.path.path(percentEncoded: false)
    }
  }
  
  var description: String {
    switch self {
    case .path: return "The path of the worktree on your filesystem"
    case .branch: return "The name of the branch to which the worktree is associated"
    case .commitHash: return "The hash of the most recent commit in the branch"
    case .repoName: return "The name of the repository"
    case .repoPath: return "The path of the repository on your filesystem"
    }
  }

  /// Substitute all template placeholders in a string with worktree and repository values.
  static func substituteAll(
    in template: String,
    worktree: Worktree,
    repository: Repository
  ) -> String {
    allCases.reduce(template) { result, substitution in
      result.replacingOccurrences(
        of: substitution.substitutionString,
        with: substitution.replacementString(worktree: worktree, repository: repository)
      )
    }
  }
}
