//
//  WorktreeRowView.swift
//  Arborist
//
//  Created by Isaac Shea on 2/2/2026.
//

import SwiftUI

struct WorktreeRowView: View {
  let worktree: Worktree
  let isSelected: Bool
  
  var body: some View {
    HStack(spacing: 8) {
      Image(systemName: worktree.isMainWorktree ? "tray.full.fill" : "tray.fill")
        .foregroundStyle(isSelected ? .white : branchColor)
      
      VStack(alignment: .leading, spacing: 2) {
        Text(worktree.branch)
          .lineLimit(1)
          .foregroundStyle(isSelected ? .white : .primary)
        
        Text(worktree.folderName)
          .font(.caption)
          .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
          .lineLimit(1)
      }
      
      Spacer()
      
      statusIndicator
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
    .background(
      RoundedRectangle(cornerRadius: 6)
        .fill(isSelected ? Color.accentColor : Color.clear)
    )
    .contentShape(Rectangle())
  }
  
  private var branchColor: Color {
    if worktree.isMainWorktree {
      return .blue
    } else if worktree.remoteBranchStatus.isStale {
      return .orange
    } else if worktree.isPrunable {
      return .red
    } else {
      return .secondary
    }
  }
  
  @ViewBuilder
  private var statusIndicator: some View {
    if worktree.isLocked {
      Image(systemName: "lock.fill")
        .foregroundStyle(isSelected ? .white : .orange)
        .font(.caption)
        .help("Worktree is locked")
    } else if worktree.remoteBranchStatus.isStale {
      Image(systemName: "exclamationmark.triangle.fill")
        .foregroundStyle(isSelected ? .white :  .orange)
        .font(.caption)
        .help("Remote branch deleted")
    } else if worktree.isPrunable {
      Image(systemName: "exclamationmark.triangle.fill")
        .foregroundStyle(isSelected ? .white :  .red)
        .font(.caption)
        .help("Worktree is prunable")
    } else if case .tracking(_, let ahead, let behind) = worktree.remoteBranchStatus {
      if ahead > 0 || behind > 0 {
        HStack(spacing: 2) {
          if ahead > 0 {
            Text("↑\(ahead)")
              .font(.caption2)
              .foregroundStyle(isSelected ? .white : .green)
          }
          if behind > 0 {
            Text("↓\(behind)")
              .font(.caption2)
              .foregroundStyle(isSelected ? .white : .orange)
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
      ),
      isSelected: false
    )
    
    WorktreeRowView(
      worktree: Worktree(
        path: URL(filePath: "/Users/test/my-project-feature"),
        branch: "feature/ABC-123-add-login",
        commitHash: "def456",
        remoteBranchStatus: .tracking(remote: "origin", ahead: 2, behind: 0)
      ),
      isSelected: false
    )
    
    WorktreeRowView(
      worktree: Worktree(
        path: URL(filePath: "/Users/test/my-project-bugfix"),
        branch: "bugfix/DEF-456",
        commitHash: "ghi789",
        isLocked: true
      ),
      isSelected: false
    )
    
    WorktreeRowView(
      worktree: Worktree(
        path: URL(filePath: "/Users/test/my-project-stale"),
        branch: "feature/old-branch",
        commitHash: "jkl012",
        remoteBranchStatus: .remoteDeleted
      ),
      isSelected: false
    )
  }
  .padding()
  .frame(width: 280)
}
