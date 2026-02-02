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

    var body: some View {
        Group {
            if let worktree, let repository {
                WorktreeDetailView(worktree: worktree, repository: repository)
            } else if let repository {
                RepositoryDetailView(repository: repository)
            } else {
                EmptyStateView()
            }
        }
    }
}

#Preview("Empty") {
    DetailView(repository: nil, worktree: nil)
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
        worktree: nil
    )
}
