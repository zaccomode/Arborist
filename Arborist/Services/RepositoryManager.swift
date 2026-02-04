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
  
  func createWorktree(
    in repository: Repository,
    branch: String,
    customPath: URL?
  ) async throws {
    guard let index = repositories.firstIndex(where: { $0.id == repository.id }) else {
      return
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
}
