//
//  RepositorySettingsSheet.swift
//  Arborist
//
//  Created by Isaac Shea on 2/4/2026.
//

import SwiftUI

/// Sheet for configuring repository-specific preset settings
struct RepositorySettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PresetManager.self) private var presetManager

    let repository: Repository

    @State private var isShowingPresetEditor = false
    @State private var editingPreset: OpenPreset?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Preset Settings")
                    .font(.headline)
                Spacer()
                Text(repository.name)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(.bar)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Override Section
                    overrideSection

                    Divider()

                    // Repository-Specific Presets Section
                    repositoryPresetsSection
                }
                .padding()
            }

            Divider()

            // Footer
            HStack {
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.return, modifiers: [])
            }
            .padding()
            .background(.bar)
        }
        .frame(width: 500, height: 500)
        .sheet(isPresented: $isShowingPresetEditor) {
            PresetEditorSheet(existingPreset: editingPreset) { preset in
                if editingPreset != nil {
                    presetManager.updateRepositoryPreset(preset, for: repository.id)
                } else {
                    presetManager.createRepositoryPreset(preset, for: repository.id)
                }
            }
        }
    }

    @ViewBuilder
    private var overrideSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("App Preset Overrides")
                .font(.headline)

            Text("Override the visibility of app-level presets for this repository.")
                .font(.callout)
                .foregroundStyle(.secondary)

            List {
                ForEach(presetManager.allPresets) { preset in
                    OverrideRow(
                        preset: preset,
                        overrideState: presetManager.getOverrideState(preset.id, for: repository),
                        appEnabled: presetManager.appConfigurations[preset.id]?.isEnabled ?? true,
                        onStateChange: { newState in
                            presetManager.setRepositoryOverride(
                                repositoryId: repository.id,
                                presetId: preset.id,
                                enabled: newState
                            )
                        }
                    )
                }
            }
            .listStyle(.bordered)
            .frame(minHeight: 150)
        }
    }

    @ViewBuilder
    private var repositoryPresetsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Repository Presets")
                    .font(.headline)
                Spacer()
                Button {
                    editingPreset = nil
                    isShowingPresetEditor = true
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)
            }

            Text("Custom presets that only appear for this repository.")
                .font(.callout)
                .foregroundStyle(.secondary)

            let repoPresets = presetManager.getRepositoryCustomPresets(for: repository.id)

            if repoPresets.isEmpty {
                Text("No repository-specific presets. Click + to add one.")
                    .font(.callout)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                List {
                    ForEach(repoPresets) { preset in
                        HStack {
                            Image(systemName: preset.icon)
                                .frame(width: 24)

                            VStack(alignment: .leading) {
                                Text(preset.name)
                                Text(preset.command.displayDescription)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }

                            Spacer()

                            Button {
                                editingPreset = preset
                                isShowingPresetEditor = true
                            } label: {
                                Image(systemName: "pencil")
                            }
                            .buttonStyle(.borderless)

                            Button(role: .destructive) {
                                presetManager.deleteRepositoryPreset(preset.id, for: repository.id)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
                .listStyle(.bordered)
            }
        }
    }
}

struct OverrideRow: View {
    let preset: OpenPreset
    let overrideState: Bool?
    let appEnabled: Bool
    let onStateChange: (Bool?) -> Void

    private var effectiveEnabled: Bool {
        overrideState ?? appEnabled
    }

    private var stateDescription: String {
        if let override = overrideState {
            return override ? "Enabled" : "Disabled"
        }
        return appEnabled ? "Default (Enabled)" : "Default (Disabled)"
    }

    var body: some View {
        HStack {
            Image(systemName: preset.icon)
                .frame(width: 24)
                .foregroundStyle(effectiveEnabled ? .primary : .secondary)

            Text(preset.name)
                .foregroundStyle(effectiveEnabled ? .primary : .secondary)

            Spacer()

            Menu {
                Button {
                    onStateChange(nil)
                } label: {
                    HStack {
                        Text(appEnabled ? "Use Default (Enabled)" : "Use Default (Disabled)")
                        if overrideState == nil {
                            Image(systemName: "checkmark")
                        }
                    }
                }

                Divider()

                Button {
                    onStateChange(true)
                } label: {
                    HStack {
                        Text("Always Enabled")
                        if overrideState == true {
                            Image(systemName: "checkmark")
                        }
                    }
                }

                Button {
                    onStateChange(false)
                } label: {
                    HStack {
                        Text("Always Disabled")
                        if overrideState == false {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(stateDescription)
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .menuStyle(.borderlessButton)
        }
        .padding(4)
    }
}

#Preview {
    RepositorySettingsSheet(
        repository: Repository(
            name: "Test Repo",
            path: URL(filePath: "/Users/test/repo")
        )
    )
    .environment(PresetManager())
}
