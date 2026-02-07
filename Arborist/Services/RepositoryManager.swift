//
//  RepositoryManager.swift
//  Arborist
//
//  Created by Isaac Shea on 2/2/2026.
//

import Foundation
import SwiftData

/// Manages the collection of repositories and their worktrees
@Observable
@MainActor
final class RepositoryManager {
  private(set) var repositories: [Repository] = []
  private(set) var isLoading = false

  /// Active setup automation runners, keyed by worktree path string
  private(set) var activeSetupRunners: [String: SetupAutomationRunner] = [:]

  private let gitService: GitService
  private let modelContainer: ModelContainer?
  
  nonisolated init(gitService: GitService? = nil, modelContainer: ModelContainer? = nil) {
    self.gitService = gitService ?? GitService.shared
    self.modelContainer = modelContainer
  }
  
  // MARK: - Persistence
  
  func loadRepositories() async {
    guard let container = modelContainer else { return }
    
    isLoading = true
    defer { isLoading = false }
    
    do {
      let context = ModelContext(container)
      let descriptor = FetchDescriptor<PersistedRepository>(
        sortBy: [SortDescriptor(\.addedAt)]
      )
      let persisted = try context.fetch(descriptor)
      
      var loadedRepos: [Repository] = []
      for persistedRepo in persisted {
        var repo = persistedRepo.toRepository()
        // Try to refresh worktrees
        if let worktrees = try? await gitService.listWorktrees(in: repo.path) {
          repo.worktrees = worktrees
          repo.lastRefreshed = Date()
        }
        loadedRepos.append(repo)
      }
      
      repositories = loadedRepos
    } catch {
      print("Failed to load repositories: \(error)")
    }
  }
  
  private func saveRepository(_ repository: Repository) {
    guard let container = modelContainer else { return }
    
    do {
      let context = ModelContext(container)
      let persisted = PersistedRepository(from: repository)
      context.insert(persisted)
      try context.save()
    } catch {
      print("Failed to save repository: \(error)")
    }
  }
  
  private func deletePersistedRepository(_ repository: Repository) {
    guard let container = modelContainer else { return }
    
    do {
      let context = ModelContext(container)
      let id = repository.id
      let descriptor = FetchDescriptor<PersistedRepository>(
        predicate: #Predicate { $0.id == id }
      )
      if let persisted = try context.fetch(descriptor).first {
        context.delete(persisted)
        try context.save()
      }
    } catch {
      print("Failed to delete repository: \(error)")
    }
  }
  
  // MARK: - Repository Management
  
  func addRepository(at url: URL) async throws -> Repository? {
    print("[RepositoryManager] Adding repository at: \(url)")
    print("[RepositoryManager] URL path: \(url.path(percentEncoded: false))")
    
    // Validate it's a git repository
    let isGitRepo = try await gitService.isGitRepository(at: url)
    print("[RepositoryManager] isGitRepository result: \(isGitRepo)")
    
    guard isGitRepo else {
      throw GitError.notAGitRepository(path: url)
    }
    
    // Check if already added
    guard !repositories.contains(where: { $0.path == url }) else {
      return nil
    }
    
    // Get worktrees
    let worktrees = try await gitService.listWorktrees(in: url)
    
    let repository = Repository(
      name: url.lastPathComponent,
      path: url,
      worktrees: worktrees,
      lastRefreshed: Date()
    )
    
    repositories.append(repository)
    saveRepository(repository)
    return repository
  }
  
  func removeRepository(_ repository: Repository) {
    repositories.removeAll { $0.id == repository.id }
    deletePersistedRepository(repository)
  }
  
  // MARK: - Refresh
  
  func refreshRepository(_ repository: Repository) async {
    guard let index = repositories.firstIndex(where: { $0.id == repository.id }) else {
      return
    }
    
    do {
      let worktrees = try await gitService.listWorktrees(in: repository.path)
      repositories[index].worktrees = worktrees
      repositories[index].lastRefreshed = Date()
      
      // Update remote branch status for each worktree
      for (worktreeIndex, worktree) in repositories[index].worktrees.enumerated() {
        let status = try await gitService.getRemoteBranchStatus(
          in: repository.path,
          branch: worktree.branch
        )
        repositories[index].worktrees[worktreeIndex].remoteBranchStatus = status
      }
    } catch {
      print("Failed to refresh repository: \(error)")
    }
  }
  
  func refreshAllRepositories() async {
    for repository in repositories {
      await refreshRepository(repository)
    }
  }
  
  // MARK: - Worktree Operations
  
  @discardableResult
  func createWorktree(
    in repository: Repository,
    branch: String,
    customPath: URL?
  ) async throws -> Worktree? {
    guard let index = repositories.firstIndex(where: { $0.id == repository.id }) else {
      return nil
    }

    // Determine the worktree path
    let worktreePath: URL
    if let customPath {
      worktreePath = customPath
    } else {
      // Default: sibling directory with branch name as folder
      let folderName = BranchNameParser.sanitizeForFolder(branch)
      worktreePath = repository.path.deletingLastPathComponent().appending(path: folderName)
    }

    // Check if branch exists
    let branchExists = try await gitService.branchExists(in: repository.path, name: branch)

    // Create the worktree
    try await gitService.addWorktree(
      in: repository.path,
      branch: branch,
      path: worktreePath,
      createBranch: !branchExists
    )

    // Refresh to get updated worktree list
    await refreshRepository(repositories[index])

    // Return the newly created worktree
    return repositories[index].worktrees.first { $0.branch == branch }
  }
  
  func deleteWorktree(_ worktree: Worktree, in repository: Repository, force: Bool) async throws {
    guard let index = repositories.firstIndex(where: { $0.id == repository.id }) else {
      return
    }
    
    try await gitService.removeWorktree(
      in: repository.path,
      path: worktree.path,
      force: force
    )
    
    // Remove from local state
    repositories[index].worktrees.removeAll { $0.id == worktree.id }
  }
  
  func pruneWorktrees(for repository: Repository) async throws {
    try await gitService.pruneWorktrees(in: repository.path)
    await refreshRepository(repository)
  }
  
  func repository(withId id: UUID) -> Repository? {
    repositories.first { $0.id == id }
  }

  // MARK: - Notes Management

  /// Get the notes for a repository
  func getRepositoryNotes(_ repository: Repository) -> String? {
    guard let container = modelContainer else { return nil }

    do {
      let context = ModelContext(container)
      let id = repository.id
      let descriptor = FetchDescriptor<PersistedRepository>(
        predicate: #Predicate { $0.id == id }
      )
      return try context.fetch(descriptor).first?.notes
    } catch {
      print("Failed to fetch repository notes: \(error)")
      return nil
    }
  }

  /// Save notes for a repository
  func saveRepositoryNotes(_ repository: Repository, notes: String?) {
    guard let container = modelContainer else { return }

    do {
      let context = ModelContext(container)
      let id = repository.id
      let descriptor = FetchDescriptor<PersistedRepository>(
        predicate: #Predicate { $0.id == id }
      )
      if let persisted = try context.fetch(descriptor).first {
        persisted.notes = notes?.isEmpty == true ? nil : notes
        try context.save()
      }
    } catch {
      print("Failed to save repository notes: \(error)")
    }
  }

  // MARK: - Setup Automation Management

  /// Get the setup automation script for a repository
  func getSetupAutomation(_ repository: Repository) -> String? {
    guard let container = modelContainer else { return nil }

    do {
      let context = ModelContext(container)
      let id = repository.id
      let descriptor = FetchDescriptor<PersistedRepository>(
        predicate: #Predicate { $0.id == id }
      )
      return try context.fetch(descriptor).first?.setupAutomation
    } catch {
      print("Failed to fetch setup automation: \(error)")
      return nil
    }
  }

  /// Save setup automation script for a repository
  func saveSetupAutomation(_ repository: Repository, script: String?) {
    guard let container = modelContainer else { return }

    do {
      let context = ModelContext(container)
      let id = repository.id
      let descriptor = FetchDescriptor<PersistedRepository>(
        predicate: #Predicate { $0.id == id }
      )
      if let persisted = try context.fetch(descriptor).first {
        persisted.setupAutomation = script?.isEmpty == true ? nil : script
        try context.save()
      }
    } catch {
      print("Failed to save setup automation: \(error)")
    }
  }

  /// Start a setup automation for a newly created worktree
  func startSetupAutomation(
    for worktree: Worktree,
    in repository: Repository
  ) {
    guard let script = getSetupAutomation(repository),
          !script.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      return
    }

    let runner = SetupAutomationRunner()
    let key = worktree.path.path(percentEncoded: false)
    activeSetupRunners[key] = runner

    Task {
      await runner.run(
        script: script,
        worktree: worktree,
        repository: repository
      )
    }
  }

  /// Get the runner for a worktree if setup is in progress or recently completed
  func setupRunner(for worktree: Worktree) -> SetupAutomationRunner? {
    activeSetupRunners[worktree.path.path(percentEncoded: false)]
  }

  /// Dismiss and clean up a setup runner
  func dismissSetupRunner(for worktree: Worktree) {
    activeSetupRunners.removeValue(forKey: worktree.path.path(percentEncoded: false))
  }

  /// Get notes for a worktree
  func getWorktreeNotes(_ worktree: Worktree, in repository: Repository) -> String? {
    guard let container = modelContainer else { return nil }

    do {
      let context = ModelContext(container)
      let pathString = worktree.path.path(percentEncoded: false)
      let repoId = repository.id
      let descriptor = FetchDescriptor<PersistedWorktreeNote>(
        predicate: #Predicate { $0.worktreePathString == pathString && $0.repositoryId == repoId }
      )
      return try context.fetch(descriptor).first?.notes
    } catch {
      print("Failed to fetch worktree notes: \(error)")
      return nil
    }
  }

  /// Save notes for a worktree
  func saveWorktreeNotes(_ worktree: Worktree, in repository: Repository, notes: String?) {
    guard let container = modelContainer else { return }

    do {
      let context = ModelContext(container)
      let pathString = worktree.path.path(percentEncoded: false)
      let repoId = repository.id
      let descriptor = FetchDescriptor<PersistedWorktreeNote>(
        predicate: #Predicate { $0.worktreePathString == pathString && $0.repositoryId == repoId }
      )

      if let existing = try context.fetch(descriptor).first {
        if let notes, !notes.isEmpty {
          existing.notes = notes
        } else {
          context.delete(existing)
        }
      } else if let notes, !notes.isEmpty {
        let newNote = PersistedWorktreeNote(
          worktreePathString: pathString,
          repositoryId: repoId,
          notes: notes
        )
        context.insert(newNote)
      }

      try context.save()
    } catch {
      print("Failed to save worktree notes: \(error)")
    }
  }
}
