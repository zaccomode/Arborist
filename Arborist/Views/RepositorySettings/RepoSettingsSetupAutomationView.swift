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
  @State private var isSaved = true

  var body: some View {
    Form {
      Section {
        Text("Commands that run automatically when a new worktree is created for this repository. Commands execute sequentially — if any command fails, execution stops.")
          .font(.callout)
          .foregroundStyle(.secondary)

        TextEditor(text: $script)
          .font(.system(.body, design: .monospaced))
          .frame(minHeight: 200)
          .border(Color.secondary.opacity(0.3))
          .onChange(of: script) { _, _ in
            isSaved = false
          }

        TemplateTextHelpView()
      } header: {
        HStack {
          VStack(alignment: .leading) {
            Text("Setup Script")
              .font(.headline)

            Text("Bash commands to run after creating a worktree.")
              .font(.subheadline)
              .foregroundStyle(.secondary)
          }

          Spacer()

          Button("Save") {
            repositoryManager.saveSetupAutomation(repository, script: script)
            isSaved = true
          }
          .buttonStyle(.borderedProminent)
          .disabled(isSaved)
        }
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
        isSaved = true
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
