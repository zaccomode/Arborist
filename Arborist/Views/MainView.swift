//
//  MainView.swift
//  Arborist
//
//  Created by Isaac Shea on 2/2/2026.
//

import SwiftUI

struct MainView: View {
  @Environment(NavigationManager.self) private var navigationManager
  @State private var columnVisibility: NavigationSplitViewVisibility = .all
  
  var body: some View {
    @Bindable var navigationManager = navigationManager
    
    NavigationSplitView(columnVisibility: $columnVisibility) {
      SidebarView()
      .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 320)
    } detail: {
      NavigationStack(path: $navigationManager.navigationPath) {
        EmptyStateView()
          .navigationDestination(for: DetailDestination.self) { destination in
            switch destination {
            case .repository(let repository):
              RepositoryDetailView(repository: repository)
            case .worktree(let repository, let worktree):
              WorktreeDetailView(
                worktree: worktree,
                repository: repository
              )
            }
          }
      }
    }
    .navigationSplitViewStyle(.balanced)
  }
}

#Preview {
  MainView()
}
