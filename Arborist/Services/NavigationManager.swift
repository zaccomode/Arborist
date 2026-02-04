//
//  NavigationManager.swift
//  Arborist
//
//  Created by Isaac Shea on 4/2/2026.
//

import Observation
import SwiftUI

enum DetailDestination: Hashable {
  case repository(id: UUID)
  case worktree(repositoryId: UUID, worktreeId: URL)
}

@Observable
final class NavigationManager {
  var navigationPath: [DetailDestination] = []
  
  private var repositoryManager: RepositoryManager
  
  init(repositoryManager: RepositoryManager) {
    self.repositoryManager = repositoryManager
  }
  
  // MARK: - Live Data Lookups
  
  var selectedRepository: Repository? {
    guard let destination = navigationPath.last else { return nil }
    switch destination {
    case .repository(let id):
      return repositoryManager.repository(withId: id)
    case .worktree(let repositoryId, _):
      return repositoryManager.repository(withId: repositoryId)
    }
  }
  
  var selectedWorktree: Worktree? {
    guard case .worktree(let repositoryId, let worktreeId) = navigationPath.last,
          let repository = repositoryManager.repository(withId: repositoryId) else {
      return nil
    }
    return repository.worktrees.first { $0.id == worktreeId }
  }
  
  // MARK: - Navigation
  
  /// Navigate to a repository
  func navigate(to repository: Repository) {
    navigationPath.append(DetailDestination.repository(id: repository.id))
  }
  
  /// Navigate to a worktree within a repository
  func navigate(to worktree: Worktree, in repository: Repository) {
    navigationPath
      .append(
        DetailDestination
          .worktree(repositoryId: repository.id, worktreeId: worktree.id)
      )
  }
  
  /// Clears all selections
  func clearSelection() {
    navigationPath.removeAll()
  }
}
