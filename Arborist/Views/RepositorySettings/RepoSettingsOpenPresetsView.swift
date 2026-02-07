//
//  RepoSettingsOpenPresetsView.swift
//  Arborist
//
//  Created by Isaac Shea on 7/2/2026.
//

import SwiftUI

struct RepoSettingsOpenPresetsView: View {
  @Environment(PresetManager.self) private var presetManager
  
  let repository: Repository
  
  @State private var isShowingPresetEditor = false
  @State private var editingPreset: OpenPreset?
  
  var body: some View {
    Form {
      // Override Section
      overrideSection
      
      // Repository-Specific Presets Section
      repositoryPresetsSection
    }
    .formStyle(.grouped)
    .navigationTitle("Open Presets")
    .navigationSubtitle(repository.name)
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
    Section {
      ForEach(presetManager.allPresets) { preset in
        OverrideRow(
          preset: preset,
          overrideState: presetManager.getOverrideState(preset.id, for: repository),
          appEnabled: presetManager.appConfigurations[preset.id]?.isEnabled ?? preset.defaultEnabled,
          onStateChange: { newState in
            presetManager.setRepositoryOverride(
              repositoryId: repository.id,
              presetId: preset.id,
              enabled: newState
            )
          }
        )
      }
      
    } header: {
      Text("App Preset Overrides")
        .font(.headline)
      
      Text("Override the visibility of app-level presets for this repository.")
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
  }
  
  @ViewBuilder
  private var repositoryPresetsSection: some View {
    Section {
      let repoPresets = presetManager.getRepositoryCustomPresets(for: repository.id)
      
      if repoPresets.isEmpty {
        Text("No repository-specific presets. Click + to add one.")
          .font(.callout)
          .foregroundStyle(.tertiary)
          .frame(maxWidth: .infinity, alignment: .center)
          .padding(.vertical, 20)
      } else {
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
                .monospaced()
            }
            
            Spacer()
            
            Button {
              editingPreset = preset
              isShowingPresetEditor = true
            } label: {
              Image(systemName: "pencil")
            }
            .buttonStyle(.borderless)
            .padding(4)
            .contentShape(Rectangle())
            
            Button(role: .destructive) {
              presetManager.deleteRepositoryPreset(preset.id, for: repository.id)
            } label: {
              Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .padding(4)
            .contentShape(Rectangle())
          }
        }
      }
    } header: {
      HStack {
        VStack(alignment: .leading) {
          Text("Repository Presets")
            .font(.headline)
          
          Text("Custom presets that only appear for this repository.")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        Spacer()
        Button {
          editingPreset = nil
          isShowingPresetEditor = true
        } label: {
          Image(systemName: "plus")
        }
        .buttonStyle(.borderless)
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
