//
//  SetupAutomationProgressView.swift
//  Arborist
//
//  Created by Isaac Shea on 2/7/2026.
//

import SwiftUI

struct SetupAutomationProgressView: View {
  @Environment(RepositoryManager.self) private var repositoryManager

  let runner: SetupAutomationRunner
  let worktree: Worktree
  let repository: Repository
  let onDismiss: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      header

      statusView

      outputTrail

      actionButtons
    }
    .padding(24)
  }

  // MARK: - Header

  private var header: some View {
    HStack(spacing: 12) {
      if case .running = runner.status {
        ProgressView()
          .controlSize(.small)
      }

      VStack(alignment: .leading, spacing: 4) {
        Text("Setting Up Worktree")
          .font(.title2)
          .fontWeight(.semibold)

        Text(worktree.branch)
          .font(.callout)
          .foregroundStyle(.secondary)
      }

      Spacer()

      Button {
        Task {
          await OpenService.shared.revealInFinder(path: worktree.path)
        }
      } label: {
        Label("Open in Finder", systemImage: "folder")
      }
    }
  }

  // MARK: - Status

  @ViewBuilder
  private var statusView: some View {
    switch runner.status {
    case .idle:
      EmptyView()
    case .running(let index, let total):
      Text("Running command \(index + 1) of \(total)...")
        .font(.callout)
        .foregroundStyle(.secondary)
    case .completed:
      Label("Setup complete", systemImage: "checkmark.circle.fill")
        .foregroundStyle(.green)
    case .failed(let index, _):
      Label("Failed at command \(index + 1)", systemImage: "xmark.circle.fill")
        .foregroundStyle(.red)
    }
  }

  // MARK: - Output Trail

  private var outputTrail: some View {
    ScrollViewReader { proxy in
      ScrollView {
        LazyVStack(alignment: .leading, spacing: 2) {
          ForEach(runner.outputLines) { line in
            Text(line.text)
              .font(.system(.caption, design: .monospaced))
              .foregroundStyle(colorForStream(line.stream))
              .textSelection(.enabled)
              .frame(maxWidth: .infinity, alignment: .leading)
              .id(line.id)
          }
        }
        .padding()
      }
      .background(Color(.textBackgroundColor))
      .clipShape(RoundedRectangle(cornerRadius: 8))
      .onChange(of: runner.outputLines.count) { _, _ in
        if let lastLine = runner.outputLines.last {
          withAnimation {
            proxy.scrollTo(lastLine.id, anchor: .bottom)
          }
        }
      }
    }
  }

  private func colorForStream(_ stream: SetupOutputLine.OutputStream) -> Color {
    switch stream {
    case .command: return .accentColor
    case .stdout: return .primary
    case .stderr: return .red
    }
  }

  // MARK: - Action Buttons

  @ViewBuilder
  private var actionButtons: some View {
    HStack {
      Spacer()

      switch runner.status {
      case .completed:
        Button("Done") {
          onDismiss()
        }
        .buttonStyle(.borderedProminent)

      case .failed:
        Button("Skip") {
          onDismiss()
        }
        .buttonStyle(.bordered)

        Button("Retry") {
          repositoryManager.dismissSetupRunner(for: worktree)
          repositoryManager.startSetupAutomation(for: worktree, in: repository)
        }
        .buttonStyle(.borderedProminent)

      case .running:
        Button("Cancel") {
          runner.cancel()
          onDismiss()
        }
        .buttonStyle(.bordered)

      case .idle:
        EmptyView()
      }
    }
  }
}
