//
//  WorktreeDetailView.swift
//  Arborist
//
//  Created by Isaac Shea on 2/2/2026.
//

import SwiftUI

struct WorktreeDetailView: View {
  @Environment(RepositoryManager.self) private var repositoryManager
  
  let worktree: Worktree
  let repository: Repository
  
  @State private var isShowingDeleteConfirmation = false
  @State private var isDeleting = false
  @State private var alertInfo: AlertInfo? = nil
  
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        header
        
        if worktree.remoteBranchStatus.isStale {
          staleBranchWarning
        }
        
        openPresetsSection
        
        infoSection
        
        if worktree.canDelete {
          dangerZone
        }
      }
      .padding(24)
    }
    .navigationTitle(worktree.branch)
    .confirmationDialog(
      "Delete Worktree",
      isPresented: $isShowingDeleteConfirmation,
      titleVisibility: .visible
    ) {
      Button("Delete", role: .destructive) {
        deleteWorktree(force: false)
      }
      Button("Force Delete", role: .destructive) {
        deleteWorktree(force: true)
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("This will delete the worktree directory and all uncommitted changes.")
    }
    .alert(item: $alertInfo) { info in
      Alert(
        title: Text(info.title),
        message: Text(info.message),
        dismissButton: .default(Text("OK"))
      )
    }
  }
  
  private var header: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 12) {
        Image(systemName: worktree.isMainWorktree ? "tray.full.fill" : "tray.fill")
          .font(.largeTitle)
          .foregroundStyle(worktree.isMainWorktree ? .blue : .secondary)
        
        VStack(alignment: .leading, spacing: 4) {
          Text(worktree.branch)
            .font(.title)
            .fontWeight(.semibold)
            .textSelection(.enabled)
          
          CopiableText(text: worktree.path.path(percentEncoded: false))
            .font(.callout)
            .foregroundStyle(.secondary)
            .textSelection(.enabled)
            .monospaced()
        }
        
        Spacer()
        
        statusBadges
      }
      
      HStack(spacing: 16) {
        Label(worktree.shortCommitHash, systemImage: "number")
          .font(.system(.body, design: .monospaced))
        
        Text(worktree.remoteBranchStatus.displayText)
          .foregroundStyle(.secondary)
      }
    }
  }
  
  @ViewBuilder
  private var statusBadges: some View {
    HStack(spacing: 8) {
      if worktree.isLocked {
        Label("Locked", systemImage: "lock.fill")
          .font(.callout)
          .foregroundStyle(.orange)
          .padding(.horizontal, 10)
          .padding(.vertical, 6)
          .background(.orange.opacity(0.15), in: Capsule())
      }
      
      if worktree.remoteBranchStatus.isStale {
        Label("Stale", systemImage: "exclamationmark.triangle.fill")
          .font(.callout)
          .foregroundStyle(.orange)
          .padding(.horizontal, 10)
          .padding(.vertical, 6)
          .background(.orange.opacity(0.15), in: Capsule())
      }
      
      if worktree.isMainWorktree {
        Text("Main")
          .font(.callout)
          .fontWeight(.medium)
          .foregroundStyle(.blue)
          .padding(.horizontal, 10)
          .padding(.vertical, 6)
          .background(.blue.opacity(0.15), in: Capsule())
      }
    }
  }
  
  @ViewBuilder
  private var staleBranchWarning: some View {
    HStack(spacing: 12) {
      Image(systemName: "exclamationmark.triangle.fill")
        .foregroundStyle(.orange)
        .font(.title2)
      
      VStack(alignment: .leading, spacing: 4) {
        Text("Remote Branch Deleted")
          .fontWeight(.medium)
        
        Text("The remote branch for this worktree has been deleted. Consider removing this worktree if it's no longer needed.")
          .font(.callout)
          .foregroundStyle(.secondary)
      }
      
      Spacer()
    }
    .padding()
    .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
  }
  
  private var openPresetsSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Open In")
        .font(.headline)
      
      LazyVGrid(columns: [GridItem(.adaptive(minimum: 100, maximum: 140), spacing: 12)], spacing: 12) {
        ForEach(OpenPreset.defaultPresets) { preset in
          Button {
            openWith(preset)
          } label: {
            VStack(spacing: 8) {
              Image(systemName: preset.icon)
                .font(.title2)
              Text(preset.name)
                .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
          }
          .buttonStyle(.bordered)
        }
      }
    }
  }
  
  private var infoSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Information")
        .font(.headline)
      
      Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
        GridRow {
          Text("Branch")
            .foregroundStyle(.secondary)
          CopiableText(text: worktree.branch)
        }
        
        GridRow {
          Text("Commit")
            .foregroundStyle(.secondary)
          CopiableText(text: worktree.commitHash)
            .font(.system(.body, design: .monospaced))
        }
        
        GridRow {
          Text("Path")
            .foregroundStyle(.secondary)
          CopiableText(text: worktree.path.path(percentEncoded: false))
            .font(.system(.body, design: .monospaced))
        }
        
        GridRow {
          Text("Status")
            .foregroundStyle(.secondary)
          Text(worktree.remoteBranchStatus.displayText)
        }
      }
      .padding()
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
    }
  }
  
  @ViewBuilder
  private var dangerZone: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Danger Zone")
        .font(.headline)
        .foregroundStyle(.secondary)
      
      HStack {
        VStack(alignment: .leading, spacing: 2) {
          Text("Delete Worktree")
            .fontWeight(.medium)
          
          Text("Permanently delete this worktree and all its files.")
            .font(.callout)
            .foregroundStyle(.secondary)
        }
        
        Spacer()
        
        Button("Delete", role: .destructive) {
          isShowingDeleteConfirmation = true
        }
        .disabled(isDeleting)
      }
      .padding()
      .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
    }
  }
  
  private func openWith(_ preset: OpenPreset) {
    Task {
      do {
        try await OpenService.shared.open(worktree: worktree, with: preset)
      } catch {
        alertInfo = AlertInfo(
          title: "Cannot open application",
          message: error.localizedDescription
        )
      }
    }
  }
  
  private func deleteWorktree(force: Bool) {
    isDeleting = true
    Task {
      do {
        try await repositoryManager.deleteWorktree(worktree, in: repository, force: force)
      } catch {
        // TODO: Show error alert
        print("Failed to delete worktree: \(error)")
      }
      isDeleting = false
    }
  }
}

#Preview {
  NavigationStack {
    WorktreeDetailView(
      worktree: Worktree(
        path: URL(filePath: "/Users/test/my-project-feature"),
        branch: "feature/ABC-123-implement-auth",
        commitHash: "abc123def456789012345678901234567890",
        remoteBranchStatus: .tracking(remote: "origin", ahead: 2, behind: 1)
      ),
      repository: Repository(
        name: "my-project",
        path: URL(filePath: "/Users/test/my-project")
      )
    )
    .environment(RepositoryManager())
  }
}
