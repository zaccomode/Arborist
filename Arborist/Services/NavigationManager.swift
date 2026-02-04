//
//  NavigationManager.swift
//  Arborist
//
//  Created by Isaac Shea on 4/2/2026.
//

import Observation
import SwiftUI

enum DetailDestination: Hashable {
  case repository(Repository)
  case worktree(repository: Repository, worktree: Worktree)
}

@Observable
final class NavigationManager {
  var navigationPath: [DetailDestination] = []
  
  /// Navigate to a repository
  func navigate(to repository: Repository) {
    navigationPath.append(DetailDestination.repository(repository))
  }
  
  /// Navigate to a worktree within a repository
  func navigate(to worktree: Worktree, in repository: Repository) {
    navigationPath
      .append(
        DetailDestination.worktree(repository: repository, worktree: worktree)
      )
  }
  
  /// Clears all selections
  func clearSelection() {
    navigationPath.removeAll()
  }
  
  /// The currently selected repository (from either destination type)
  var selectedRepository: Repository? {
    guard let last = navigationPath.last else { return nil }
    switch last {
    case .repository(let repo):
      return repo
    case .worktree(let repo, _):
      return repo
    }
  }
  
  /// The currently selected worktree (only if on a worktree detail)
  var selectedWorktree: Worktree? {
    guard case .worktree(_, let worktree) = navigationPath.last else { return nil }
    return worktree
  }
}
