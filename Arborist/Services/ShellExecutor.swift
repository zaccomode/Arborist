//
//  ShellExecutor.swift
//  Arborist
//
//  Created by Isaac Shea on 2/2/2026.
//

import Foundation

/// Result of a shell command execution
struct ShellResult: Sendable {
    let exitCode: Int32
    let stdout: String
    let stderr: String

    nonisolated var succeeded: Bool { exitCode == 0 }

    /// Combined output (stdout + stderr)
    nonisolated var combinedOutput: String {
        [stdout, stderr].filter { !$0.isEmpty }.joined(separator: "\n")
    }
}

/// Errors that can occur during shell execution
enum ShellError: LocalizedError {
    case executionFailed(command: String, exitCode: Int32, stderr: String)
    case commandNotFound(command: String)
    case timeout

    var errorDescription: String? {
        switch self {
        case .executionFailed(let command, let exitCode, let stderr):
            return "Command '\(command)' failed with exit code \(exitCode): \(stderr)"
        case .commandNotFound(let command):
            return "Command not found: \(command)"
        case .timeout:
            return "Command timed out"
        }
    }
}

/// Protocol for shell command execution
protocol ShellExecutorProtocol: Sendable {
    func execute(
        command: String,
        arguments: [String],
        workingDirectory: URL?,
        environment: [String: String]?
    ) async throws -> ShellResult
}

extension ShellExecutorProtocol {
    func execute(
        command: String,
        arguments: [String] = [],
        workingDirectory: URL? = nil
    ) async throws -> ShellResult {
        try await execute(
            command: command,
            arguments: arguments,
            workingDirectory: workingDirectory,
            environment: nil
        )
    }
}

/// Executes shell commands using Process
actor ShellExecutor: ShellExecutorProtocol {
    static nonisolated let shared = ShellExecutor()

    private init() {}

    func execute(
        command: String,
        arguments: [String],
        workingDirectory: URL?,
        environment: [String: String]?
    ) async throws -> ShellResult {
        let process = Process()
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()

        process.executableURL = URL(filePath: command)
        process.arguments = arguments
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        if let workingDirectory {
            process.currentDirectoryURL = workingDirectory
        }

        if let environment {
            var env = ProcessInfo.processInfo.environment
            env.merge(environment) { _, new in new }
            process.environment = env
        }

        // Debug logging
        print("[ShellExecutor] Running: \(command) \(arguments.joined(separator: " "))")

        return try await withCheckedThrowingContinuation { continuation in
            do {
                try process.run()

                process.waitUntilExit()

                let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()

                let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
                let stderr = String(data: stderrData, encoding: .utf8) ?? ""

                let result = ShellResult(
                    exitCode: process.terminationStatus,
                    stdout: stdout.trimmingCharacters(in: .whitespacesAndNewlines),
                    stderr: stderr.trimmingCharacters(in: .whitespacesAndNewlines)
                )

                print("[ShellExecutor] Exit code: \(result.exitCode), stdout: \(result.stdout), stderr: \(result.stderr)")

                continuation.resume(returning: result)
            } catch let error {
                print("[ShellExecutor] Error: \(error)")
                continuation.resume(throwing: ShellError.commandNotFound(command: command))
            }
        }
    }

    /// Execute a command and throw if it fails
    func executeOrThrow(
        command: String,
        arguments: [String],
        workingDirectory: URL? = nil
    ) async throws -> String {
        let result = try await execute(
            command: command,
            arguments: arguments,
            workingDirectory: workingDirectory,
            environment: nil
        )

        guard result.succeeded else {
            throw ShellError.executionFailed(
                command: command,
                exitCode: result.exitCode,
                stderr: result.stderr
            )
        }

        return result.stdout
    }
}
