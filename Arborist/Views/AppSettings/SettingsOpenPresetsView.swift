//
//  SettingsOpenPresetsView.swift
//  Arborist
//
//  Created by Isaac Shea on 7/2/2026.
//

import SwiftUI

struct SettingsOpenPresetsView: View {
  @Environment(PresetManager.self) private var presetManager
  
  @State private var isShowingPresetEditor = false
  @State private var editingPreset: OpenPreset?
  
  var body: some View {
    Form {
      // Built-in Presets Section
      Section {
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
      } header: {
        Text("Built-in Presets")
          .font(.headline)
      }
      
      
      // Custom Presets Section
      Section {
        if presetManager.customPresets.isEmpty {
          Text("No custom presets. Click + to add one.")
            .font(.callout)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 20)
        } else {
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
      } header: {
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
      }
    }
    .navigationTitle("Open Presets")
    .formStyle(.grouped)
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
      .padding(.trailing, 4)
    }
  }
}
