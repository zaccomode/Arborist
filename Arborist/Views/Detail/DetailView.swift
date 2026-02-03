//
//  DetailView.swift
//  Arborist
//
//  Created by Isaac Shea on 2/2/2026.
//

import SwiftUI

struct DetailView: View {
  let repository: Repository?
  let worktree: Worktree?
  let onDeleteRepository: () -> Void
  let onDeleteWorktree: () -> Void
  
  var body: some View {
    Group {
      if let worktree, let repository {
        WorktreeDetailView(
          worktree: worktree,
          repository: repository,
          onDelete: { onDeleteWorktree() }
        )
      } else if let repository {
        RepositoryDetailView(
          repository: repository,
          onDelete: { onDeleteRepository()}
        )
      } else {
        EmptyStateView()
      }
    }
  }
}

#Preview("Empty") {
  DetailView(
    repository: nil,
    worktree: nil,
    onDeleteRepository: {},
    onDeleteWorktree: {}
  )
}

#Preview("Repository Selected") {
  DetailView(
    repository: Repository(
      name: "my-project",
      path: URL(filePath: "/Users/test/my-project"),
      worktrees: [
        Worktree(
          path: URL(filePath: "/Users/test/my-project"),
          branch: "main",
          commitHash: "abc123",
          isMainWorktree: true
        )
      ]
    ),
    worktree: nil,
    onDeleteRepository: {},
    onDeleteWorktree: {}
  )
}
