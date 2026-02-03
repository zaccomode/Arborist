//
//  WorktreeRowView.swift
//  Arborist
//
//  Created by Isaac Shea on 2/2/2026.
//

import SwiftUI

struct WorktreeRowView: View {
  let worktree: Worktree
  
  var body: some View {
    HStack(spacing: 8) {
      Image(systemName: worktree.isMainWorktree ? "tray.full.fill" : "tray.fill")
        .foregroundStyle(branchColor)
        .font(.caption)
      
      VStack(alignment: .leading, spacing: 2) {
        Text(worktree.branch)
          .lineLimit(1)
        
        Text(worktree.folderName)
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }
      
      Spacer()
      
      statusIndicator
    }
    .contentShape(Rectangle())
  }
  
  private var branchColor: Color {
    if worktree.isMainWorktree {
      return .blue
    } else if worktree.remoteBranchStatus.isStale {
      return .orange
    } else {
      return .secondary
    }
  }
  
  @ViewBuilder
  private var statusIndicator: some View {
    if worktree.isLocked {
      Image(systemName: "lock.fill")
        .foregroundStyle(.orange)
        .font(.caption)
        .help("Worktree is locked")
    } else if worktree.remoteBranchStatus.isStale {
      Image(systemName: "exclamationmark.triangle.fill")
        .foregroundStyle(.orange)
        .font(.caption)
        .help("Remote branch deleted")
    } else if worktree.isPrunable {
      Image(systemName: "exclamationmark.triangle.fill")
        .foregroundStyle(.red)
        .font(.caption)
        .help("Worktree is prunable")
    } else if case .tracking(_, let ahead, let behind) = worktree.remoteBranchStatus {
      if ahead > 0 || behind > 0 {
        HStack(spacing: 2) {
          if ahead > 0 {
            Text("↑\(ahead)")
              .font(.caption2)
              .foregroundStyle(.green)
          }
          if behind > 0 {
            Text("↓\(behind)")
              .font(.caption2)
              .foregroundStyle(.orange)
          }
        }
      }
    }
  }
}

#Preview {
  VStack(alignment: .leading, spacing: 8) {
    WorktreeRowView(
      worktree: Worktree(
        path: URL(filePath: "/Users/test/my-project"),
        branch: "main",
        commitHash: "abc123",
        isMainWorktree: true
      )
    )
    
    WorktreeRowView(
      worktree: Worktree(
        path: URL(filePath: "/Users/test/my-project-feature"),
        branch: "feature/ABC-123-add-login",
        commitHash: "def456",
        remoteBranchStatus: .tracking(remote: "origin", ahead: 2, behind: 0)
      )
    )
    
    WorktreeRowView(
      worktree: Worktree(
        path: URL(filePath: "/Users/test/my-project-bugfix"),
        branch: "bugfix/DEF-456",
        commitHash: "ghi789",
        isLocked: true
      )
    )
    
    WorktreeRowView(
      worktree: Worktree(
        path: URL(filePath: "/Users/test/my-project-stale"),
        branch: "feature/old-branch",
        commitHash: "jkl012",
        remoteBranchStatus: .remoteDeleted
      )
    )
  }
  .padding()
  .frame(width: 280)
}
