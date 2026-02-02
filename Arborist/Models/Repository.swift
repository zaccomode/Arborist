//
//  Repository.swift
//  Arborist
//
//  Created by Isaac Shea on 2/2/2026.
//

import Foundation
import SwiftData

/// Represents a git repository being managed by Arborist
struct Repository: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var name: String
    var path: URL
    var bookmarkData: Data?
    var worktrees: [Worktree]
    var lastRefreshed: Date?

    init(
        id: UUID = UUID(),
        name: String,
        path: URL,
        bookmarkData: Data? = nil,
        worktrees: [Worktree] = [],
        lastRefreshed: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.path = path
        self.bookmarkData = bookmarkData
        self.worktrees = worktrees
        self.lastRefreshed = lastRefreshed
    }

    /// Number of worktrees in this repository
    var worktreeCount: Int {
        worktrees.count
    }

    /// Number of worktrees with stale remote branches
    var staleWorktreeCount: Int {
        worktrees.filter { $0.remoteBranchStatus.isStale }.count
    }

    /// Whether the repository has any stale worktrees
    var hasStaleWorktrees: Bool {
        staleWorktreeCount > 0
    }
}

// MARK: - SwiftData Persistence Model

@Model
final class PersistedRepository {
    @Attribute(.unique) var id: UUID
    var name: String
    var pathString: String
    var bookmarkData: Data?
    var addedAt: Date

    init(id: UUID, name: String, pathString: String, bookmarkData: Data?, addedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.pathString = pathString
        self.bookmarkData = bookmarkData
        self.addedAt = addedAt
    }

    convenience init(from repository: Repository) {
        self.init(
            id: repository.id,
            name: repository.name,
            pathString: repository.path.path(percentEncoded: false),
            bookmarkData: repository.bookmarkData
        )
    }

    func toRepository() -> Repository {
        Repository(
            id: id,
            name: name,
            path: URL(filePath: pathString),
            bookmarkData: bookmarkData,
            worktrees: [],
            lastRefreshed: nil
        )
    }
}
