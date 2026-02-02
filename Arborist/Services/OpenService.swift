//
//  OpenService.swift
//  Arborist
//
//  Created by Isaac Shea on 2/2/2026.
//

import AppKit
import Foundation

/// Errors that can occur when opening worktrees
enum OpenError: LocalizedError {
    case applicationNotFound(bundleIdentifier: String)
    case failedToOpen(message: String)

    var errorDescription: String? {
        switch self {
        case .applicationNotFound(let bundleId):
            return "Application not found: \(bundleId)"
        case .failedToOpen(let message):
            return "Failed to open: \(message)"
        }
    }
}

/// Service for opening worktrees in external applications
actor OpenService {
    static nonisolated let shared = OpenService()

    private let shell: ShellExecutor

    private init() {
        self.shell = ShellExecutor.shared
    }

    /// Open a worktree with a preset
    func open(worktree: Worktree, with preset: OpenPreset) async {
        switch preset.command {
        case .application(let bundleIdentifier):
            await openWithApplication(path: worktree.path, bundleIdentifier: bundleIdentifier)
        case .bash(let script):
            await openWithBashScript(path: worktree.path, script: script)
        }
    }

    /// Open path with a specific application
    private func openWithApplication(path: URL, bundleIdentifier: String) async {
        await MainActor.run {
            let configuration = NSWorkspace.OpenConfiguration()
            configuration.activates = true

            if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) {
                NSWorkspace.shared.open(
                    [path],
                    withApplicationAt: appURL,
                    configuration: configuration
                )
            } else {
                // Fallback: try to open with default app
                NSWorkspace.shared.open(path)
            }
        }
    }

    /// Open path by executing a bash script
    private func openWithBashScript(path: URL, script: String) async {
        // Replace {{path}} placeholder with actual path
        let expandedScript = script.replacingOccurrences(
            of: "{{path}}",
            with: path.path(percentEncoded: false)
        )

        do {
            _ = try await shell.execute(
                command: "/bin/bash",
                arguments: ["-c", expandedScript],
                workingDirectory: path,
                environment: nil
            )
        } catch {
            print("Failed to execute bash script: \(error)")
        }
    }

    /// Reveal path in Finder
    func revealInFinder(path: URL) async {
        await MainActor.run {
            NSWorkspace.shared.activateFileViewerSelecting([path])
        }
    }
}
