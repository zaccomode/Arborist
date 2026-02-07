//
//  RepoSettingsSetupAutomationView.swift
//  Arborist
//
//  Created by Isaac Shea on 2/7/2026.
//

import SwiftUI

struct RepoSettingsSetupAutomationView: View {
  @Environment(RepositoryManager.self) private var repositoryManager

  let repository: Repository

  @State private var script: String = ""
  @State private var hasLoaded = false
  @FocusState private var isEditorFocused: Bool

  var body: some View {
    Form {
      Section {
        Text("Automatically execute setup commands (e.g. npm install) when creating a new worktree.")
          .font(.callout)
          .foregroundStyle(.secondary)

        TextEditor(text: $script)
          .font(.system(.body, design: .monospaced))
          .frame(minHeight: 200)
          .border(Color.secondary.opacity(0.3))
          .focused($isEditorFocused)
          .onChange(of: isEditorFocused) { _, isFocused in
            if !isFocused {
              repositoryManager.saveSetupAutomation(repository, script: script)
            }
          }
          .onDisappear {
            repositoryManager.saveSetupAutomation(repository, script: script)
          }
        
        TemplateTextHelpView()
      } header: {
        Text("Setup Script")
          .font(.headline)
      }

      Section {
        let commands = SetupAutomationRunner.parseCommands(from: script)
        if commands.isEmpty {
          Text("No commands configured. Add bash commands above, one per line.")
            .font(.callout)
            .foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 20)
        } else {
          ForEach(Array(commands.enumerated()), id: \.offset) { index, command in
            HStack(alignment: .top) {
              Text("\(index + 1).")
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .frame(width: 24, alignment: .trailing)
              Text(command)
                .font(.system(.body, design: .monospaced))
                .lineLimit(2)
            }
          }
        }
      } header: {
        VStack(alignment: .leading) {
          Text("Command Preview")
            .font(.headline)

          Text("Comments and blank lines are excluded.")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
      }
    }
    .formStyle(.grouped)
    .navigationTitle("Setup Automations")
    .navigationSubtitle(repository.name)
    .onAppear {
      if !hasLoaded {
        script = repositoryManager.getSetupAutomation(repository) ?? ""
        hasLoaded = true
      }
    }
  }
}

#Preview {
  RepoSettingsSetupAutomationView(
    repository: Repository(
      name: "Test Repo",
      path: URL(filePath: "/Users/test/repo")
    )
  )
  .environment(RepositoryManager())
}
