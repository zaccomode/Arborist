//
//  SetupAutomationRunner.swift
//  Arborist
//
//  Created by Isaac Shea on 2/7/2026.
//

import Foundation

/// A single line of output from a running setup automation
struct SetupOutputLine: Identifiable {
  let id = UUID()
  let text: String
  let stream: OutputStream
  let timestamp: Date

  enum OutputStream {
    case stdout
    case stderr
    case command
  }
}

/// The overall status of a setup automation run
enum SetupAutomationStatus: Equatable {
  case idle
  case running(commandIndex: Int, totalCommands: Int)
  case completed
  case failed(commandIndex: Int, error: String)
}

/// Manages execution of setup automation scripts for a worktree
@Observable
@MainActor
final class SetupAutomationRunner {
  private(set) var status: SetupAutomationStatus = .idle
  private(set) var outputLines: [SetupOutputLine] = []

  private var currentProcess: Process?

  /// Parse a script into executable commands, stripping blank lines and comments
  static func parseCommands(from script: String) -> [String] {
    script.components(separatedBy: .newlines)
      .map { $0.trimmingCharacters(in: .whitespaces) }
      .filter { !$0.isEmpty && !$0.hasPrefix("#") }
  }

  /// Run the setup automation for a worktree
  func run(
    script: String,
    worktree: Worktree,
    repository: Repository
  ) async {
    let commands = Self.parseCommands(from: script)
    guard !commands.isEmpty else {
      status = .completed
      return
    }

    outputLines = []

    for (index, rawCommand) in commands.enumerated() {
      status = .running(commandIndex: index, totalCommands: commands.count)

      let command = SubstitutableString.substituteAll(
        in: rawCommand,
        worktree: worktree,
        repository: repository
      )

      appendOutput("$ \(command)", stream: .command)

      let success = await executeWithStreaming(
        command: command,
        workingDirectory: worktree.path
      )

      if !success {
        status = .failed(commandIndex: index, error: "Command failed: \(command)")
        return
      }
    }

    status = .completed
  }

  /// Cancel the current run
  func cancel() {
    currentProcess?.terminate()
    currentProcess = nil
    status = .idle
  }

  /// Reset to allow restarting after failure
  func reset() {
    currentProcess = nil
    status = .idle
    outputLines = []
  }

  // MARK: - Streaming execution

  private func executeWithStreaming(
    command: String,
    workingDirectory: URL
  ) async -> Bool {
    let process = Process()
    let stdoutPipe = Pipe()
    let stderrPipe = Pipe()

    process.executableURL = URL(filePath: "/bin/bash")
    process.arguments = ["-l", "-c", command]
    process.currentDirectoryURL = workingDirectory
    process.standardOutput = stdoutPipe
    process.standardError = stderrPipe

    currentProcess = process

    // Set up streaming handlers that capture output as it arrives
    let stdoutHandler = StreamHandler(stream: .stdout) { [weak self] text in
      Task { @MainActor in
        self?.appendOutput(text, stream: .stdout)
      }
    }
    let stderrHandler = StreamHandler(stream: .stderr) { [weak self] text in
      Task { @MainActor in
        self?.appendOutput(text, stream: .stderr)
      }
    }

    stdoutPipe.fileHandleForReading.readabilityHandler = { handle in
      let data = handle.availableData
      guard !data.isEmpty else { return }
      if let text = String(data: data, encoding: .utf8) {
        stdoutHandler.onData(text)
      }
    }

    stderrPipe.fileHandleForReading.readabilityHandler = { handle in
      let data = handle.availableData
      guard !data.isEmpty else { return }
      if let text = String(data: data, encoding: .utf8) {
        stderrHandler.onData(text)
      }
    }

    do {
      try process.run()
    } catch {
      appendOutput("Failed to start command: \(error.localizedDescription)", stream: .stderr)
      currentProcess = nil
      return false
    }

    // Wait for process to exit using terminationHandler to avoid deadlocks
    let exitCode: Int32 = await withCheckedContinuation { continuation in
      process.terminationHandler = { proc in
        continuation.resume(returning: proc.terminationStatus)
      }
    }

    // Clean up handlers
    stdoutPipe.fileHandleForReading.readabilityHandler = nil
    stderrPipe.fileHandleForReading.readabilityHandler = nil

    // Read any remaining data
    let remainingStdout = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
    let remainingStderr = stderrPipe.fileHandleForReading.readDataToEndOfFile()

    if !remainingStdout.isEmpty, let text = String(data: remainingStdout, encoding: .utf8) {
      appendOutput(text, stream: .stdout)
    }
    if !remainingStderr.isEmpty, let text = String(data: remainingStderr, encoding: .utf8) {
      appendOutput(text, stream: .stderr)
    }

    currentProcess = nil
    return exitCode == 0
  }

  private func appendOutput(_ text: String, stream: SetupOutputLine.OutputStream) {
    let lines = text.components(separatedBy: .newlines)
      .filter { !$0.isEmpty }
    for line in lines {
      outputLines.append(
        SetupOutputLine(text: line, stream: stream, timestamp: Date())
      )
    }
  }
}

// MARK: - Stream Handler

/// Helper to receive streaming data callbacks
private final class StreamHandler: @unchecked Sendable {
  let stream: SetupOutputLine.OutputStream
  let onData: @Sendable (String) -> Void

  init(stream: SetupOutputLine.OutputStream, onData: @escaping @Sendable (String) -> Void) {
    self.stream = stream
    self.onData = onData
  }
}
