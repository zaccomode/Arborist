//
//  RepositoryRowView.swift
//  Arborist
//
//  Created by Isaac Shea on 2/2/2026.
//

import SwiftUI

struct RepositoryRowView: View {
    let repository: Repository
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "folder.fill")
                .foregroundStyle(.secondary)

            Text(repository.name)
                .fontWeight(.medium)

            Spacer()

            if repository.hasStaleWorktrees {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.orange)
                    .help("\(repository.staleWorktreeCount) stale worktree(s)")
            }

            Text("\(repository.worktreeCount)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.quaternary, in: Capsule())
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    VStack(spacing: 12) {
        RepositoryRowView(
            repository: Repository(
                name: "my-project",
                path: URL(filePath: "/Users/test/my-project"),
                worktrees: [
                    Worktree(
                        path: URL(filePath: "/Users/test/my-project"),
                        branch: "main",
                        commitHash: "abc123"
                    )
                ]
            ),
            isSelected: false
        )

        RepositoryRowView(
            repository: Repository(
                name: "another-repo",
                path: URL(filePath: "/Users/test/another-repo"),
                worktrees: [
                    Worktree(
                        path: URL(filePath: "/Users/test/another-repo"),
                        branch: "main",
                        commitHash: "abc123",
                        remoteBranchStatus: .remoteDeleted
                    ),
                    Worktree(
                        path: URL(filePath: "/Users/test/another-repo-feature"),
                        branch: "feature/test",
                        commitHash: "def456"
                    )
                ]
            ),
            isSelected: true
        )
    }
    .padding()
    .frame(width: 280)
}
