//
//  OpenPreset.swift
//  Arborist
//
//  Created by Isaac Shea on 2/2/2026.
//

import Foundation
import SwiftData

/// The type of command to execute when opening a worktree
enum OpenCommand: Codable, Hashable, Sendable {
    /// Open with a specific application by bundle identifier
    case application(bundleIdentifier: String)
    /// Execute a custom bash script ({{path}} is replaced with worktree path)
    case bash(script: String)

    var displayDescription: String {
        switch self {
        case .application(let bundleId):
            return "Open with \(bundleId)"
        case .bash(let script):
            return script
        }
    }
}

/// Represents a preset for opening worktrees in external applications
struct OpenPreset: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var name: String
    var icon: String
    var command: OpenCommand
    var isBuiltIn: Bool
    var sortOrder: Int

    init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        command: OpenCommand,
        isBuiltIn: Bool = false,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.command = command
        self.isBuiltIn = isBuiltIn
        self.sortOrder = sortOrder
    }

    // MARK: - Built-in Presets

    static let finder = OpenPreset(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        name: "Finder",
        icon: "folder",
        command: .application(bundleIdentifier: "com.apple.Finder"),
        isBuiltIn: true,
        sortOrder: 0
    )

    static let terminal = OpenPreset(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
        name: "Terminal",
        icon: "terminal",
        command: .application(bundleIdentifier: "com.apple.Terminal"),
        isBuiltIn: true,
        sortOrder: 1
    )

    static let warp = OpenPreset(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
        name: "Warp",
        icon: "terminal.fill",
        command: .application(bundleIdentifier: "dev.warp.Warp-Stable"),
        isBuiltIn: true,
        sortOrder: 2
    )

    static let vscode = OpenPreset(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
        name: "VS Code",
        icon: "chevron.left.forwardslash.chevron.right",
        command: .bash(script: "code \"{{path}}\""),
        isBuiltIn: true,
        sortOrder: 3
    )

    static let defaultPresets: [OpenPreset] = [
        .finder,
        .terminal,
        .warp,
        .vscode
    ]
}

// MARK: - SwiftData Persistence Model

@Model
final class PersistedOpenPreset {
    @Attribute(.unique) var id: UUID
    var name: String
    var icon: String
    var commandType: String
    var commandValue: String
    var isBuiltIn: Bool
    var sortOrder: Int

    init(
        id: UUID,
        name: String,
        icon: String,
        commandType: String,
        commandValue: String,
        isBuiltIn: Bool,
        sortOrder: Int
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.commandType = commandType
        self.commandValue = commandValue
        self.isBuiltIn = isBuiltIn
        self.sortOrder = sortOrder
    }

    convenience init(from preset: OpenPreset) {
        let (type, value): (String, String) = {
            switch preset.command {
            case .application(let bundleId):
                return ("application", bundleId)
            case .bash(let script):
                return ("bash", script)
            }
        }()

        self.init(
            id: preset.id,
            name: preset.name,
            icon: preset.icon,
            commandType: type,
            commandValue: value,
            isBuiltIn: preset.isBuiltIn,
            sortOrder: preset.sortOrder
        )
    }

    func toOpenPreset() -> OpenPreset {
        let command: OpenCommand = {
            switch commandType {
            case "application":
                return .application(bundleIdentifier: commandValue)
            case "bash":
                return .bash(script: commandValue)
            default:
                return .bash(script: commandValue)
            }
        }()

        return OpenPreset(
            id: id,
            name: name,
            icon: icon,
            command: command,
            isBuiltIn: isBuiltIn,
            sortOrder: sortOrder
        )
    }
}
