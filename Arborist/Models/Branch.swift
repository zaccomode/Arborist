//
//  Branch.swift
//  Arborist
//
//  Created by Isaac Shea on 2/2/2026.
//

import Foundation

/// Represents a git branch
struct Branch: Identifiable, Hashable, Sendable {
    var id: String { name }

    let name: String
    let isRemote: Bool
    let remoteName: String?
    let isHead: Bool

    nonisolated init(name: String, isRemote: Bool = false, remoteName: String? = nil, isHead: Bool = false) {
        self.name = name
        self.isRemote = isRemote
        self.remoteName = remoteName
        self.isHead = isHead
    }

    /// The local branch name without remote prefix
    var localName: String {
        if isRemote, let remote = remoteName {
            return String(name.dropFirst(remote.count + 1)) // Drop "origin/" prefix
        }
        return name
    }

    /// Display name for UI
    var displayName: String {
        if isRemote {
            return "[\(remoteName ?? "remote")] \(localName)"
        }
        return name
    }
}
