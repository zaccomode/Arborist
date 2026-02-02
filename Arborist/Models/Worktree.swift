//
//  Worktree.swift
//  Arborist
//
//  Created by Isaac Shea on 2/2/2026.
//

import Foundation

/// Represents the tracking status of a branch relative to its remote
enum RemoteBranchStatus: Codable, Hashable, Sendable {
    case tracking(remote: String, ahead: Int, behind: Int)
    case noUpstream
    case remoteDeleted
    case unknown

    var isStale: Bool {
        if case .remoteDeleted = self { return true }
        return false
    }

    var displayText: String {
        switch self {
        case .tracking(let remote, let ahead, let behind):
            if ahead == 0 && behind == 0 {
                return "Up to date with \(remote)"
            } else if ahead > 0 && behind > 0 {
                return "↑\(ahead) ↓\(behind) from \(remote)"
            } else if ahead > 0 {
                return "↑\(ahead) ahead of \(remote)"
            } else {
                return "↓\(behind) behind \(remote)"
            }
        case .noUpstream:
            return "No upstream branch"
        case .remoteDeleted:
            return "Remote branch deleted"
        case .unknown:
            return "Unknown status"
        }
    }
}

/// Represents a git worktree
struct Worktree: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var path: URL
    var branch: String
    var commitHash: String
    var isMainWorktree: Bool
    var isLocked: Bool
    var isPrunable: Bool
    var remoteBranchStatus: RemoteBranchStatus

    nonisolated init(
        id: UUID = UUID(),
        path: URL,
        branch: String,
        commitHash: String,
        isMainWorktree: Bool = false,
        isLocked: Bool = false,
        isPrunable: Bool = false,
        remoteBranchStatus: RemoteBranchStatus = .unknown
    ) {
        self.id = id
        self.path = path
        self.branch = branch
        self.commitHash = commitHash
        self.isMainWorktree = isMainWorktree
        self.isLocked = isLocked
        self.isPrunable = isPrunable
        self.remoteBranchStatus = remoteBranchStatus
    }

    /// The folder name of the worktree
    var folderName: String {
        path.lastPathComponent
    }

    /// Short commit hash (first 7 characters)
    var shortCommitHash: String {
        String(commitHash.prefix(7))
    }

    /// Whether this worktree can be safely deleted
    var canDelete: Bool {
        !isMainWorktree && !isLocked
    }
}
