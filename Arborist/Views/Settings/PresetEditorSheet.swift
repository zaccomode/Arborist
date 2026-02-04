//
//  PresetEditorSheet.swift
//  Arborist
//
//  Created by Isaac Shea on 2/4/2026.
//

import SwiftUI

/// Sheet for creating or editing an open preset
struct PresetEditorSheet: View {
    @Environment(\.dismiss) private var dismiss

    let existingPreset: OpenPreset?
    let onSave: (OpenPreset) -> Void

    @State private var name: String = ""
    @State private var icon: String = "app"
    @State private var commandType: CommandType = .application
    @State private var bundleIdentifier: String = ""
    @State private var bashScript: String = ""
    @State private var urlTemplate: String = ""

    enum CommandType: String, CaseIterable {
        case application = "Application"
        case bash = "Bash Script"
        case url = "URL"

        var description: String {
            switch self {
            case .application:
                return "Open with an application by bundle identifier"
            case .bash:
                return "Execute a bash script. Use {{path}} for the worktree path."
            case .url:
                return "Open a URL in the default browser. Use {{path}} for the worktree path."
            }
        }
    }

    private var isValid: Bool {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return false }

        switch commandType {
        case .application:
            return !bundleIdentifier.trimmingCharacters(in: .whitespaces).isEmpty
        case .bash:
            return !bashScript.trimmingCharacters(in: .whitespaces).isEmpty
        case .url:
            return !urlTemplate.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(existingPreset == nil ? "New Preset" : "Edit Preset")
                    .font(.headline)
                Spacer()
            }
            .padding()
            .background(.bar)

            Divider()

            // Form content
            Form {
                Section {
                    TextField("Name", text: $name)
                    iconPicker
                }

                Section {
                    Picker("Command Type", selection: $commandType) {
                        ForEach(CommandType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }

                    Text(commandType.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    commandInput
                }
            }
            .formStyle(.grouped)

            Divider()

            // Footer buttons
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape, modifiers: [])

                Spacer()

                Button("Save") {
                    savePreset()
                }
                .keyboardShortcut(.return, modifiers: [])
                .disabled(!isValid)
            }
            .padding()
            .background(.bar)
        }
        .frame(width: 450, height: 400)
        .onAppear {
            if let preset = existingPreset {
                loadPreset(preset)
            }
        }
    }

    @ViewBuilder
    private var iconPicker: some View {
        HStack {
            Text("Icon")
            Spacer()
            Menu {
                ForEach(availableIcons, id: \.self) { iconName in
                    Button {
                        icon = iconName
                    } label: {
                        Label(iconName, systemImage: iconName)
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .frame(width: 20)
                    Text(icon)
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .menuStyle(.borderlessButton)
        }
    }

    @ViewBuilder
    private var commandInput: some View {
        switch commandType {
        case .application:
            TextField("Bundle Identifier", text: $bundleIdentifier)
                .textFieldStyle(.roundedBorder)
            Text("Example: com.apple.Terminal")
                .font(.caption)
                .foregroundStyle(.tertiary)

        case .bash:
            TextEditor(text: $bashScript)
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 80)
                .border(Color.secondary.opacity(0.3))
            Text("Example: code \"{{path}}\"")
                .font(.caption)
                .foregroundStyle(.tertiary)

        case .url:
            TextField("URL Template", text: $urlTemplate)
                .textFieldStyle(.roundedBorder)
            Text("Example: https://github.com/repo/tree/{{path}}")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    private var availableIcons: [String] {
        [
            "app",
            "terminal",
            "terminal.fill",
            "folder",
            "folder.fill",
            "doc",
            "doc.fill",
            "globe",
            "link",
            "chevron.left.forwardslash.chevron.right",
            "hammer",
            "wrench",
            "gearshape",
            "star",
            "heart",
            "bolt",
            "arrow.up.forward.app",
            "arrow.up.forward.square",
            "square.and.arrow.up",
            "externaldrive",
            "cpu"
        ]
    }

    private func loadPreset(_ preset: OpenPreset) {
        name = preset.name
        icon = preset.icon

        switch preset.command {
        case .application(let bundleId):
            commandType = .application
            bundleIdentifier = bundleId
        case .bash(let script):
            commandType = .bash
            bashScript = script
        case .url(let template):
            commandType = .url
            urlTemplate = template
        }
    }

    private func savePreset() {
        let command: OpenCommand
        switch commandType {
        case .application:
            command = .application(bundleIdentifier: bundleIdentifier.trimmingCharacters(in: .whitespaces))
        case .bash:
            command = .bash(script: bashScript.trimmingCharacters(in: .whitespaces))
        case .url:
            command = .url(template: urlTemplate.trimmingCharacters(in: .whitespaces))
        }

        let preset = OpenPreset(
            id: existingPreset?.id ?? UUID(),
            name: name.trimmingCharacters(in: .whitespaces),
            icon: icon,
            command: command,
            isBuiltIn: false,
            sortOrder: existingPreset?.sortOrder ?? 0
        )

        onSave(preset)
        dismiss()
    }
}

#Preview {
    PresetEditorSheet(existingPreset: nil) { _ in }
}
