//
//  SettingsView.swift
//  Arborist
//
//  Created by Isaac Shea on 2/2/2026.
//

import SwiftUI

struct SettingsView: View {
  var body: some View {
    TabView {
      GeneralSettingsView()
        .tabItem {
          Label("General", systemImage: "gear")
        }
      
      OpenPresetsSettingsView()
        .tabItem {
          Label("Open Presets", systemImage: "arrow.up.forward.app")
        }
    }
    .frame(width: 550, height: 450)
  }
}

struct GeneralSettingsView: View {
  @AppStorage("autoRefreshOnLaunch") private var autoRefreshOnLaunch = true
  @AppStorage("showStaleWorktreeWarnings") private var showStaleWorktreeWarnings = true
  
  var body: some View {
    Form {
      Toggle("Refresh repositories on launch", isOn: $autoRefreshOnLaunch)
      
      Toggle("Show warnings for stale worktrees", isOn: $showStaleWorktreeWarnings)
    }
    .formStyle(.grouped)
    .padding()
  }
}

struct OpenPresetsSettingsView: View {
  @Environment(PresetManager.self) private var presetManager
  
  @State private var isShowingPresetEditor = false
  @State private var editingPreset: OpenPreset?
  
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      // Built-in Presets Section
      Section {
        Text("Built-in Presets")
          .font(.headline)
        
        List {
          ForEach(OpenPreset.defaultPresets) { preset in
            PresetRow(
              preset: preset,
              isEnabled: presetManager.appConfigurations[preset.id]?.isEnabled ?? true,
              onToggle: { enabled in
                presetManager.setPresetEnabled(preset.id, enabled: enabled)
              },
              onEdit: nil,
              onDelete: nil
            )
          }
        }
        .listStyle(.bordered)
        .frame(minHeight: 120)
      }
      
      // Custom Presets Section
      Section {
        HStack {
          Text("Custom Presets")
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
        
        if presetManager.customPresets.isEmpty {
          Text("No custom presets. Click + to add one.")
            .font(.callout)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 20)
        } else {
          List {
            ForEach(presetManager.customPresets) { preset in
              PresetRow(
                preset: preset,
                isEnabled: presetManager.appConfigurations[preset.id]?.isEnabled ?? true,
                onToggle: { enabled in
                  presetManager.setPresetEnabled(preset.id, enabled: enabled)
                },
                onEdit: {
                  editingPreset = preset
                  isShowingPresetEditor = true
                },
                onDelete: {
                  presetManager.deletePreset(preset.id)
                }
              )
            }
          }
          .listStyle(.bordered)
        }
      }
      
      Spacer()
    }
    .padding()
    .sheet(isPresented: $isShowingPresetEditor) {
      PresetEditorSheet(existingPreset: editingPreset) { preset in
        if editingPreset != nil {
          presetManager.updatePreset(preset)
        } else {
          presetManager.createPreset(preset)
        }
      }
    }
  }
}

struct PresetRow: View {
  let preset: OpenPreset
  let isEnabled: Bool
  let onToggle: (Bool) -> Void
  let onEdit: (() -> Void)?
  let onDelete: (() -> Void)?
  
  var body: some View {
    HStack {
      
      Image(systemName: preset.icon)
        .frame(width: 24)
        .foregroundStyle(isEnabled ? .primary : .secondary)
      
      VStack(alignment: .leading) {
        Text(preset.name)
          .foregroundStyle(isEnabled ? .primary : .secondary)
        Text(preset.command.displayDescription)
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(1)
          .monospaced()
      }
      
      Spacer()
      
      if !preset.isBuiltIn {
        HStack(spacing: 8) {
          if let onEdit {
            Button {
              onEdit()
            } label: {
              Image(systemName: "pencil")
            }
            .buttonStyle(.borderless)
            .padding(4)
            .containerShape(Rectangle())
          }
          
          if let onDelete {
            Button(role: .destructive) {
              onDelete()
            } label: {
              Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .padding(4)
            .containerShape(Rectangle())
          }
        }
      }
      
      
      Toggle(isOn: Binding(
        get: { isEnabled },
        set: { onToggle($0) }
      )) {
        EmptyView()
      }
      .toggleStyle(.checkbox)
      .labelsHidden()
    }
    .padding(4)
  }
}

#Preview {
  SettingsView()
}
