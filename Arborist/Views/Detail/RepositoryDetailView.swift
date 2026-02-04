//
//  RepositoryDetailView.swift
//  Arborist
//
//  Created by Isaac Shea on 2/2/2026.
//

import SwiftUI

struct RepositoryDetailView: View {
  @Environment(RepositoryManager.self) private var repositoryManager
  @Environment(NavigationManager.self) private var navigationManager
  
  let repository: Repository
  
  @State private var isCreatingWorktree = false
  @State private var isShowingDeleteConfirmation = false
  
  private func handleDelete() {
    repositoryManager.removeRepository(repository)
    navigationManager.clearSelection()
  }
  
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        header
        
        if repository.hasStaleWorktrees {
          staleWorktreesWarning
        }
        
        worktreesSection
        
        Spacer(minLength: 40)
        
        dangerZone
      }
      .padding(24)
    }
    .navigationTitle(repository.name)
    .toolbar {
      ToolbarItemGroup {
        Button {
          Task {
            await repositoryManager.refreshRepository(repository)
          }
        } label: {
          Label("Refresh", systemImage: "arrow.clockwise")
        }
        .help("Refresh worktrees")
        
        Button {
          isCreatingWorktree = true
        } label: {
          Label("New Worktree", systemImage: "plus")
        }
        .help("Create a new worktree")
      }
    }
    .sheet(isPresented: $isCreatingWorktree) {
      CreateWorktreeSheet(repository: repository)
    }
    .confirmationDialog(
      "Remove Repository",
      isPresented: $isShowingDeleteConfirmation,
      titleVisibility: .visible
    ) {
      Button("Remove", role: .destructive) {
        handleDelete()
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("This will remove the repository from Arborist. Your files will not be deleted.")
    }
  }
  
  private var header: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 12) {
        Image(systemName: "folder.fill")
          .font(.largeTitle)
          .foregroundStyle(.blue)
        
        VStack(alignment: .leading, spacing: 4) {
          Text(repository.name)
            .font(.title)
            .fontWeight(.semibold)
          
          CopiableText(text: repository.path.path(percentEncoded: false))
            .font(.callout)
            .foregroundStyle(.secondary)
            .textSelection(.enabled)
            .monospaced()
        }
      }
      
      if let lastRefreshed = repository.lastRefreshed {
        Text("Last refreshed: \(lastRefreshed.formatted(date: .abbreviated, time: .shortened))")
          .font(.caption)
          .foregroundStyle(.tertiary)
      }
    }
  }
  
  @ViewBuilder
  private var staleWorktreesWarning: some View {
    HStack(spacing: 12) {
      Image(systemName: "exclamationmark.triangle.fill")
        .foregroundStyle(.orange)
        .font(.title2)
      
      VStack(alignment: .leading, spacing: 2) {
        Text("\(repository.staleWorktreeCount) Stale Worktree\(repository.staleWorktreeCount == 1 ? "" : "s")")
          .fontWeight(.medium)
        
        Text("These worktrees have branches that no longer exist on the remote.")
          .font(.callout)
          .foregroundStyle(.secondary)
      }
      
      Spacer()
    }
    .padding()
    .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
  }
  
  private var worktreesSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Worktrees")
        .font(.headline)
      
      LazyVGrid(columns: [GridItem(.adaptive(minimum: 280, maximum: 400), spacing: 12)], spacing: 12) {
        ForEach(repository.worktrees) { worktree in
          WorktreeCardView(worktree: worktree, repository: repository)
        }
      }
    }
  }
  
  private var dangerZone: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Danger Zone")
        .font(.headline)
        .foregroundStyle(.secondary)
      
      HStack {
        VStack(alignment: .leading, spacing: 2) {
          Text("Remove Repository")
            .fontWeight(.medium)
          
          Text("Remove this repository from Arborist. Your files will not be affected.")
            .font(.callout)
            .foregroundStyle(.secondary)
        }
        
        Spacer()
        
        Button("Remove", role: .destructive) {
          isShowingDeleteConfirmation = true
        }
      }
      .padding()
      .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
    }
  }
}

#Preview {
  NavigationStack {
    RepositoryDetailView(
      repository: Repository(
        name: "my-project",
        path: URL(filePath: "/Users/test/my-project"),
        worktrees: [
          Worktree(
            path: URL(filePath: "/Users/test/my-project"),
            branch: "main",
            commitHash: "abc123def456789",
            isMainWorktree: true,
            remoteBranchStatus: .tracking(remote: "origin", ahead: 0, behind: 0)
          ),
          Worktree(
            path: URL(filePath: "/Users/test/my-project-feature"),
            branch: "feature/ABC-123",
            commitHash: "def456abc789012",
            remoteBranchStatus: .tracking(remote: "origin", ahead: 2, behind: 1)
          ),
          Worktree(
            path: URL(filePath: "/Users/test/my-project-stale"),
            branch: "feature/old-branch",
            commitHash: "ghi789def012345",
            remoteBranchStatus: .remoteDeleted
          )
        ],
        lastRefreshed: Date()
      )
    )
    .environment(RepositoryManager())
    .environment(NavigationManager())
  }
}
