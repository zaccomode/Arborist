//
//  EmptyStateView.swift
//  Arborist
//
//  Created by Isaac Shea on 2/2/2026.
//

import SwiftUI

struct EmptyStateView: View {
    var body: some View {
        ContentUnavailableView {
            Label("No Selection", systemImage: "sidebar.left")
        } description: {
            Text("Select a repository or worktree from the sidebar to view details.")
        }
    }
}

#Preview {
    EmptyStateView()
}
