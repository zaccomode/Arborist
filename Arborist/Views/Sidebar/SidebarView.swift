//
//  SidebarView.swift
//  Arborist
//
//  Created by Isaac Shea on 2/2/2026.
//

import SwiftUI

struct SidebarView: View {
  @Environment(RepositoryManager.self) private var repositoryManager
  @Binding var selectedRepository: Repository?
  @Binding var selectedWorktree: Worktree?
  
  @State private var isAddingRepository = false
  @State private var expandedRepositories: Set<UUID> = []
  
  var body: some View {
    Group {
      if repositoryManager.repositories.isEmpty {
        emptyState
      } else {
        repositoryList
      }
    }
    .navigationTitle("Repositories")
    .toolbar {
      ToolbarItemGroup {
        Button {
          Task {
            await repositoryManager.refreshAllRepositories()
          }
        } label: {
          Label("Refresh", systemImage: "arrow.clockwise")
        }
        .help("Refresh all repositories")
        
        Button {
          isAddingRepository = true
        } label: {
          Label("Add Repository", systemImage: "plus")
        }
        .help("Add a repository")
      }
    }
    .sheet(isPresented: $isAddingRepository) {
      AddRepositorySheet()
    }
  }
  
  private var emptyState: some View {
    ContentUnavailableView {
      Label("No Repositories", systemImage: "folder.badge.questionmark")
    } description: {
      Text("Add a git repository to start managing worktrees.")
    } actions: {
      Button("Add Repository") {
        isAddingRepository = true
      }
      .buttonStyle(.borderedProminent)
    }
  }
  
  private var repositoryList: some View {
    List(selection: $selectedWorktree) {
      ForEach(repositoryManager.repositories) { repository in
        Section {
          ForEach(repository.worktrees) { worktree in
            WorktreeRowView(worktree: worktree)
              .tag(worktree)
          }
        } header: {
          RepositoryRowView(
            repository: repository,
            isSelected: selectedRepository?.id == repository.id
          )
          .onTapGesture {
            selectedRepository = repository
            selectedWorktree = nil
          }
        }
      }
    }
    .listStyle(.sidebar)
  }
}

#Preview {
  SidebarView(
    selectedRepository: .constant(nil),
    selectedWorktree: .constant(nil)
  )
  .environment(RepositoryManager())
}
