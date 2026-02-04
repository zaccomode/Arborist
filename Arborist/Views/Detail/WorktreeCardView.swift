//
//  WorktreeCardView.swift
//  Arborist
//
//  Created by Isaac Shea on 2/2/2026.
//

import SwiftUI

struct WorktreeCardView: View {
  let worktree: Worktree
  let repository: Repository

  @Environment(NavigationManager.self) private var navigationManager
  @Environment(PresetManager.self) private var presetManager
  @State private var alertInfo: AlertInfo? = nil
  
  var body: some View {
    Button(action: {
      navigationManager.navigate(to: worktree, in: repository)
    }) {
      VStack(alignment: .leading, spacing: 12) {
        // Header
        HStack(spacing: 8) {
          Image(systemName: worktree.isMainWorktree ? "tray.full.fill" : "tray.fill")
            .foregroundStyle(worktree.isMainWorktree ? .blue : .secondary)
          
          VStack(alignment: .leading, spacing: 2) {
            Text(worktree.branch)
              .fontWeight(.medium)
              .lineLimit(1)
            
            Text(worktree.folderName)
              .font(.caption)
              .foregroundStyle(.secondary)
              .lineLimit(1)
          }
          
          Spacer()
          
          statusBadge
        }
        
        // Commit info
        HStack {
          Text(worktree.shortCommitHash)
            .font(.system(.caption, design: .monospaced))
            .foregroundStyle(.secondary)
          
          Spacer()
          
          Text(worktree.remoteBranchStatus.displayText)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        
        Divider()
        
        // Actions
        HStack(spacing: 8) {
          Button {
            copyPath()
          } label: {
            Label("Copy Path", systemImage: "doc.on.doc")
          }
          .buttonStyle(.bordered)
          
          Spacer()
          
          let presets = presetManager.presetsForRepository(repository)
          if !presets.isEmpty {
            Menu {
              ForEach(presets) { preset in
                Button {
                  openWith(preset)
                } label: {
                  Label(preset.name, systemImage: preset.icon)
                }
              }
            } label: {
              Label("Open In", systemImage: "arrow.up.forward.app")
            }
            .menuStyle(.borderlessButton)
          }
        }
      }
      .padding()
      .background(.background, in: RoundedRectangle(cornerRadius: 12))
      .overlay {
        RoundedRectangle(cornerRadius: 12)
          .stroke(.quaternary, lineWidth: 1)
      }
      .alert(item: $alertInfo) { info in
        Alert(
          title: Text(info.title),
          message: Text(info.message),
          dismissButton: .default(Text("OK"))
        )
      }
    }
    .buttonStyle(.plain)
  }
  
  @ViewBuilder
  private var statusBadge: some View {
    if worktree.isLocked {
      Label("Locked", systemImage: "lock.fill")
        .font(.caption)
        .foregroundStyle(.orange)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.orange.opacity(0.15), in: Capsule())
    } else if worktree.remoteBranchStatus.isStale {
      Label("Stale", systemImage: "exclamationmark.triangle.fill")
        .font(.caption)
        .foregroundStyle(.orange)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.orange.opacity(0.15), in: Capsule())
    } else if worktree.isMainWorktree {
      Text("Main")
        .font(.caption)
        .foregroundStyle(.blue)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.blue.opacity(0.15), in: Capsule())
    }
  }
  
  private func copyPath() {
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(worktree.path.path(percentEncoded: false), forType: .string)
  }
  
  private func openWith(_ preset: OpenPreset) {
    Task {
      do {
        try await OpenService.shared.open(
          worktree: worktree,
          with: preset
        )
      } catch {
        alertInfo = AlertInfo(
          title: "Cannot open application",
          message: error.localizedDescription
        )
      }
    }
  }
}

#Preview {
  VStack(spacing: 16) {
    WorktreeCardView(
      worktree: Worktree(
        path: URL(filePath: "/Users/test/my-project"),
        branch: "main",
        commitHash: "abc123def456789",
        isMainWorktree: true,
        remoteBranchStatus: .tracking(remote: "origin", ahead: 0, behind: 0)
      ),
      repository: Repository(
        name: "my-project",
        path: URL(filePath: "/Users/test/my-project")
      )
    )

    WorktreeCardView(
      worktree: Worktree(
        path: URL(filePath: "/Users/test/my-project-feature"),
        branch: "feature/ABC-123-implement-auth",
        commitHash: "def456abc789012",
        remoteBranchStatus: .tracking(remote: "origin", ahead: 3, behind: 0)
      ),
      repository: Repository(
        name: "my-project",
        path: URL(filePath: "/Users/test/my-project")
      )
    )

    WorktreeCardView(
      worktree: Worktree(
        path: URL(filePath: "/Users/test/my-project-stale"),
        branch: "feature/old-branch",
        commitHash: "ghi789def012345",
        remoteBranchStatus: .remoteDeleted
      ),
      repository: Repository(
        name: "my-project",
        path: URL(filePath: "/Users/test/my-project")
      )
    )
  }
  .padding()
  .frame(width: 360)
  .background(.windowBackground)
  .environment(PresetManager())
}
