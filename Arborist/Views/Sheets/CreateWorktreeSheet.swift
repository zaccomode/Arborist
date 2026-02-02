//
//  CreateWorktreeSheet.swift
//  Arborist
//
//  Created by Isaac Shea on 2/2/2026.
//

import SwiftUI
import UniformTypeIdentifiers

struct CreateWorktreeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(RepositoryManager.self) private var repositoryManager

    let repository: Repository

    @State private var branchInput = ""
    @State private var parsedBranch = ""
    @State private var useCustomLocation = false
    @State private var customLocation: URL?
    @State private var isCheckingBranch = false
    @State private var branchExists: Bool?
    @State private var isCreating = false
    @State private var errorMessage: String?
    @State private var isShowingFolderPicker = false

    private var defaultWorktreePath: URL {
        let folderName = BranchNameParser.sanitizeForFolder(parsedBranch)
        return repository.path.deletingLastPathComponent().appending(path: folderName)
    }

    private var worktreePath: URL {
        if useCustomLocation, let customLocation {
            return customLocation
        }
        return defaultWorktreePath
    }

    private var canCreate: Bool {
        !parsedBranch.isEmpty &&
        BranchNameParser.isValidBranchName(parsedBranch) &&
        !isCreating &&
        !isCheckingBranch
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "plus.rectangle.on.folder")
                    .font(.system(size: 40))
                    .foregroundStyle(.blue)

                Text("New Worktree")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            .padding(.top, 24)
            .padding(.bottom, 20)

            // Form
            Form {
                Section {
                    TextField("Branch name or git command", text: $branchInput)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: branchInput) { _, newValue in
                            parsedBranch = BranchNameParser.parse(newValue)
                            branchExists = nil
                            checkBranchExists()
                        }

                    if !parsedBranch.isEmpty && parsedBranch != branchInput {
                        HStack {
                            Text("Detected branch:")
                                .foregroundStyle(.secondary)
                            Text(parsedBranch)
                                .fontWeight(.medium)
                        }
                        .font(.callout)
                    }

                    if !parsedBranch.isEmpty {
                        HStack {
                            if isCheckingBranch {
                                ProgressView()
                                    .controlSize(.small)
                                Text("Checking branch...")
                                    .foregroundStyle(.secondary)
                            } else if let exists = branchExists {
                                if exists {
                                    Label("Branch exists", systemImage: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                } else {
                                    Label("New branch will be created", systemImage: "plus.circle.fill")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        .font(.callout)
                    }
                } header: {
                    Text("Branch")
                }

                Section {
                    Toggle("Use custom location", isOn: $useCustomLocation)

                    if useCustomLocation {
                        HStack {
                            if let customLocation {
                                Text(customLocation.path(percentEncoded: false))
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("No location selected")
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button("Choose...") {
                                isShowingFolderPicker = true
                            }
                        }
                    } else if !parsedBranch.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Worktree location:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(defaultWorktreePath.path(percentEncoded: false))
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Location")
                }
            }
            .formStyle(.grouped)

            // Error
            if let error = errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text(error)
                        .font(.callout)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal)
            }

            // Actions
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button {
                    createWorktree()
                } label: {
                    if isCreating {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text("Create Worktree")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canCreate)
                .keyboardShortcut(.defaultAction)
            }
            .padding(24)
        }
        .frame(width: 480, height: 420)
        .fileImporter(
            isPresented: $isShowingFolderPicker,
            allowedContentTypes: [.folder]
        ) { result in
            switch result {
            case .success(let url):
                customLocation = url
            case .failure:
                break
            }
        }
    }

    private func checkBranchExists() {
        guard !parsedBranch.isEmpty else {
            branchExists = nil
            return
        }

        isCheckingBranch = true

        Task {
            do {
                branchExists = try await GitService.shared.branchExists(
                    in: repository.path,
                    name: parsedBranch
                )
            } catch {
                branchExists = nil
            }
            isCheckingBranch = false
        }
    }

    private func createWorktree() {
        isCreating = true
        errorMessage = nil

        Task {
            do {
                try await repositoryManager.createWorktree(
                    in: repository,
                    branch: parsedBranch,
                    customPath: useCustomLocation ? customLocation : nil
                )
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isCreating = false
        }
    }
}

#Preview {
    CreateWorktreeSheet(
        repository: Repository(
            name: "my-project",
            path: URL(filePath: "/Users/test/my-project")
        )
    )
    .environment(RepositoryManager())
}
