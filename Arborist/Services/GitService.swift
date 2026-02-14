//
//  GitService.swift
//  Arborist
//
//  Created by Isaac Shea on 2/2/2026.
//

import Foundation

/// Errors that can occur during git operations
enum GitError: LocalizedError {
    case notAGitRepository(path: URL)
    case worktreeNotFound(path: URL)
    case branchAlreadyExists(name: String)
    case branchNotFound(name: String)
    case worktreeAlreadyExists(path: URL)
    case worktreeLocked(path: URL)
    case worktreeDirty(path: URL)
    case commandFailed(message: String)

    var errorDescription: String? {
        switch self {
        case .notAGitRepository(let path):
            return "'\(path.lastPathComponent)' is not a git repository"
        case .worktreeNotFound(let path):
            return "Worktree not found at '\(path.path)'"
        case .branchAlreadyExists(let name):
            return "Branch '\(name)' already exists"
        case .branchNotFound(let name):
            return "Branch '\(name)' not found"
        case .worktreeAlreadyExists(let path):
            return "Worktree already exists at '\(path.path)'"
        case .worktreeLocked(let path):
            return "Worktree at '\(path.path)' is locked"
        case .worktreeDirty(let path):
            return "Worktree at '\(path.path)' contains modified or untracked files"
        case .commandFailed(let message):
            return message
        }
    }
}

/// Protocol for git operations
protocol GitServiceProtocol: Sendable {
    func isGitRepository(at path: URL) async throws -> Bool
    func listWorktrees(in repository: URL) async throws -> [Worktree]
    func addWorktree(in repository: URL, branch: String, path: URL, createBranch: Bool) async throws
    func removeWorktree(in repository: URL, path: URL, force: Bool) async throws
    func pruneWorktrees(in repository: URL) async throws

    func listBranches(in repository: URL, includeRemote: Bool) async throws -> [Branch]
    func branchExists(in repository: URL, name: String) async throws -> Bool
    func getRemoteBranchStatus(in repository: URL, branch: String) async throws -> RemoteBranchStatus

    func fetch(in repository: URL, prune: Bool) async throws
}

/// Service for executing git commands
actor GitService: GitServiceProtocol {
    static let shared = GitService()

    private let shell: ShellExecutor
    private nonisolated let gitPath = "/usr/bin/git"

    private init() {
        self.shell = ShellExecutor.shared
    }

    /// Build git arguments with -C flag for repository path
    private nonisolated func gitArgs(in repository: URL, _ args: [String]) -> [String] {
        let repoPath = repository.path(percentEncoded: false)
        return ["-C", repoPath] + args
    }

    // MARK: - Repository Validation

    func isGitRepository(at path: URL) async throws -> Bool {
        let args = gitArgs(in: path, ["rev-parse", "--git-dir"])
        print("[GitService] isGitRepository args: \(args)")
        let result = try await shell.execute(
            command: gitPath,
            arguments: args
        )
        return result.succeeded
    }

    // MARK: - Worktree Operations

    func listWorktrees(in repository: URL) async throws -> [Worktree] {
        let output = try await shell.executeOrThrow(
            command: gitPath,
            arguments: gitArgs(in: repository, ["worktree", "list", "--porcelain"])
        )

        return parseWorktreeList(output)
    }

    func addWorktree(in repository: URL, branch: String, path: URL, createBranch: Bool) async throws {
        var arguments = ["worktree", "add"]

        if createBranch {
            arguments.append(contentsOf: ["-b", branch])
        }

        arguments.append(path.path(percentEncoded: false))

        if !createBranch {
            arguments.append(branch)
        }

        let result = try await shell.execute(
            command: gitPath,
            arguments: gitArgs(in: repository, arguments)
        )

        guard result.succeeded else {
            throw GitError.commandFailed(message: result.stderr)
        }
    }

    func removeWorktree(in repository: URL, path: URL, force: Bool) async throws {
        var arguments = ["worktree", "remove"]

        if force {
            arguments.append("--force")
        }

        arguments.append(path.path(percentEncoded: false))

        let result = try await shell.execute(
            command: gitPath,
            arguments: gitArgs(in: repository, arguments)
        )

        guard result.succeeded else {
            if result.stderr.contains("locked") {
                throw GitError.worktreeLocked(path: path)
            }
            if result.stderr.contains("modified or untracked files") {
                throw GitError.worktreeDirty(path: path)
            }
            throw GitError.commandFailed(message: result.stderr)
        }
    }

    func pruneWorktrees(in repository: URL) async throws {
        let result = try await shell.execute(
            command: gitPath,
            arguments: gitArgs(in: repository, ["worktree", "prune"])
        )

        guard result.succeeded else {
            throw GitError.commandFailed(message: result.stderr)
        }
    }

    // MARK: - Branch Operations

    func listBranches(in repository: URL, includeRemote: Bool) async throws -> [Branch] {
        let localOutput = try await shell.executeOrThrow(
            command: gitPath,
            arguments: gitArgs(in: repository, ["branch", "--list", "--format=%(refname:short)%(HEAD)"])
        )

        var branches = parseLocalBranches(localOutput)

        if includeRemote {
            let remoteOutput = try await shell.executeOrThrow(
                command: gitPath,
                arguments: gitArgs(in: repository, ["branch", "-r", "--list", "--format=%(refname:short)"])
            )
            branches.append(contentsOf: parseRemoteBranches(remoteOutput))
        }

        return branches
    }

    func branchExists(in repository: URL, name: String) async throws -> Bool {
        let result = try await shell.execute(
            command: gitPath,
            arguments: gitArgs(in: repository, ["show-ref", "--verify", "--quiet", "refs/heads/\(name)"])
        )
        return result.succeeded
    }

    func getRemoteBranchStatus(in repository: URL, branch: String) async throws -> RemoteBranchStatus {
        // First check if there's an upstream
        let upstreamResult = try await shell.execute(
            command: gitPath,
            arguments: gitArgs(in: repository, ["rev-parse", "--abbrev-ref", "\(branch)@{upstream}"])
        )

        guard upstreamResult.succeeded else {
            return .noUpstream
        }

        let upstream = upstreamResult.stdout

        // Check if the remote branch still exists
        let remoteExistsResult = try await shell.execute(
            command: gitPath,
            arguments: gitArgs(in: repository, ["show-ref", "--verify", "--quiet", "refs/remotes/\(upstream)"])
        )

        guard remoteExistsResult.succeeded else {
            return .remoteDeleted
        }

        // Get ahead/behind counts
        let countResult = try await shell.execute(
            command: gitPath,
            arguments: gitArgs(in: repository, ["rev-list", "--count", "--left-right", "\(branch)...\(upstream)"])
        )

        guard countResult.succeeded else {
            return .unknown
        }

        let parts = countResult.stdout.split(separator: "\t")
        guard parts.count == 2,
              let ahead = Int(parts[0]),
              let behind = Int(parts[1]) else {
            return .unknown
        }

        let remoteName = String(upstream.split(separator: "/").first ?? "origin")
        return .tracking(remote: remoteName, ahead: ahead, behind: behind)
    }

    // MARK: - Fetch Operations

    func fetch(in repository: URL, prune: Bool) async throws {
        var arguments = ["fetch", "--all"]

        if prune {
            arguments.append("--prune")
        }

        let result = try await shell.execute(
            command: gitPath,
            arguments: gitArgs(in: repository, arguments)
        )

        guard result.succeeded else {
            throw GitError.commandFailed(message: result.stderr)
        }
    }

    // MARK: - Parsing Helpers

    private func parseWorktreeList(_ output: String) -> [Worktree] {
        var worktrees: [Worktree] = []
        var currentPath: URL?
        var currentBranch = ""
        var currentCommit = ""
        var isMain = false
        var isLocked = false
        var isPrunable = false

        let lines = output.components(separatedBy: .newlines)

        for line in lines {
            if line.isEmpty {
                // End of worktree entry
                if let path = currentPath {
                    let worktree = Worktree(
                        path: path,
                        branch: currentBranch,
                        commitHash: currentCommit,
                        isMainWorktree: isMain,
                        isLocked: isLocked,
                        isPrunable: isPrunable
                    )
                    worktrees.append(worktree)
                }
                // Reset for next entry
                currentPath = nil
                currentBranch = ""
                currentCommit = ""
                isMain = false
                isLocked = false
                isPrunable = false
            } else if line.hasPrefix("worktree ") {
                currentPath = URL(filePath: String(line.dropFirst(9)))
            } else if line.hasPrefix("HEAD ") {
                currentCommit = String(line.dropFirst(5))
            } else if line.hasPrefix("branch ") {
                let branchRef = String(line.dropFirst(7))
                // Remove refs/heads/ prefix
                currentBranch = branchRef.replacingOccurrences(of: "refs/heads/", with: "")
            } else if line == "bare" {
                isMain = true
            } else if line == "locked" {
                isLocked = true
            } else if line.hasPrefix("prunable ") {
                isPrunable = true
            } else if line == "detached" {
                currentBranch = "(detached HEAD)"
            }
        }

        // Handle last entry if no trailing newline
        if let path = currentPath {
            let worktree = Worktree(
                path: path,
                branch: currentBranch,
                commitHash: currentCommit,
                isMainWorktree: isMain,
                isLocked: isLocked,
                isPrunable: isPrunable
            )
            worktrees.append(worktree)
        }

        return worktrees
    }

    private func parseLocalBranches(_ output: String) -> [Branch] {
        output.components(separatedBy: .newlines)
            .filter { !$0.isEmpty }
            .map { line in
                let isHead = line.hasSuffix("*")
                let name = isHead ? String(line.dropLast()) : line
                return Branch(name: name, isRemote: false, isHead: isHead)
            }
    }

    private func parseRemoteBranches(_ output: String) -> [Branch] {
        output.components(separatedBy: .newlines)
            .filter { !$0.isEmpty && !$0.contains("HEAD") }
            .map { line in
                let parts = line.split(separator: "/", maxSplits: 1)
                let remoteName = parts.first.map(String.init)
                return Branch(name: line, isRemote: true, remoteName: remoteName)
            }
    }
}
