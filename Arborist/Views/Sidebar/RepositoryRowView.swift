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
  let isExpanded: Bool
  let onToggleExpand: () -> Void
  var onShowPresetSettings: (() -> Void)?
  var onRemove: (() -> Void)?

  var body: some View {
    HStack(spacing: 4) {
      Button {
        onToggleExpand()
      } label: {
        Image(systemName: "chevron.right")
          .font(.caption)
          .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
          .rotationEffect(.degrees(isExpanded ? 90 : 0))
          .animation(.easeInOut(duration: 0.2), value: isExpanded)
          .padding(8)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)

      Text(repository.name)
        .font(.headline)
        .foregroundStyle(isSelected ? .white : .primary)

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
    .padding(.trailing, 8)
    .background(
      RoundedRectangle(cornerRadius: 6)
        .fill(isSelected ? Color.accentColor : Color.clear)
    )
    .contentShape(Rectangle())
    .contextMenu {
      if let onShowPresetSettings {
        Button {
          onShowPresetSettings()
        } label: {
          Label("Preset Settings...", systemImage: "arrow.up.forward.app")
        }

        Divider()
      }

      if let onRemove {
        Button(role: .destructive) {
          onRemove()
        } label: {
          Label("Remove Repository", systemImage: "trash")
        }
      }
    }
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
      isSelected: false,
      isExpanded: false,
      onToggleExpand: { }
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
      isSelected: true,
      isExpanded: false,
      onToggleExpand: { }
    )
  }
  .padding()
  .frame(width: 280)
}
