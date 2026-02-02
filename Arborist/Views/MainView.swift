//
//  MainView.swift
//  Arborist
//
//  Created by Isaac Shea on 2/2/2026.
//

import SwiftUI

struct MainView: View {
    @State private var selectedRepository: Repository?
    @State private var selectedWorktree: Worktree?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(
                selectedRepository: $selectedRepository,
                selectedWorktree: $selectedWorktree
            )
            .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 320)
        } detail: {
            DetailView(
                repository: selectedRepository,
                worktree: selectedWorktree
            )
        }
        .navigationSplitViewStyle(.balanced)
    }
}

#Preview {
    MainView()
}
