//
//  AddRepositorySheet.swift
//  Arborist
//
//  Created by Isaac Shea on 2/2/2026.
//

import SwiftUI
import UniformTypeIdentifiers

struct AddRepositorySheet: View {
  let onAddRepository: (_ repository: Repository) -> Void
  
  @Environment(\.dismiss) private var dismiss
  @Environment(RepositoryManager.self) private var repositoryManager
  
  @State private var selectedURL: URL?
  @State private var isValidating = false
  @State private var validationError: String?
  @State private var isShowingFilePicker = false
  
  var body: some View {
    VStack(spacing: 20) {
      // Header
      VStack(spacing: 8) {
        Image(systemName: "folder.badge.plus")
          .font(.system(size: 48))
          .foregroundStyle(.blue)
        
        Text("Add Repository")
          .font(.title2)
          .fontWeight(.semibold)
        
        Text("Select a git repository folder to start managing its worktrees.")
          .font(.callout)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
      }
      
      // Selected path display
      if let url = selectedURL {
        HStack {
          Image(systemName: "folder.fill")
            .foregroundStyle(.blue)
          
          Text(url.path(percentEncoded: false))
            .lineLimit(1)
            .truncationMode(.middle)
          
          Spacer()
          
          Button {
            selectedURL = nil
            validationError = nil
          } label: {
            Image(systemName: "xmark.circle.fill")
              .foregroundStyle(.secondary)
          }
          .buttonStyle(.plain)
        }
        .padding()
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
      }
      
      // Error message
      if let error = validationError {
        HStack {
          Image(systemName: "exclamationmark.triangle.fill")
            .foregroundStyle(.orange)
          
          Text(error)
            .font(.callout)
            .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
      }
      
      Spacer()
      
      // Actions
      HStack {
        Button("Cancel") {
          dismiss()
        }
        .keyboardShortcut(.cancelAction)
        
        Spacer()
        
        if selectedURL == nil {
          Button("Choose Folder...") {
            isShowingFilePicker = true
          }
          .buttonStyle(.borderedProminent)
        } else {
          Button {
            addRepository()
          } label: {
            if isValidating {
              ProgressView()
                .controlSize(.small)
            } else {
              Text("Add Repository")
            }
          }
          .buttonStyle(.borderedProminent)
          .disabled(isValidating)
          .keyboardShortcut(.defaultAction)
        }
      }
    }
    .padding(24)
    .frame(width: 420, height: 320)
    .fileImporter(
      isPresented: $isShowingFilePicker,
      allowedContentTypes: [.folder]
    ) { result in
      switch result {
      case .success(let url):
        selectedURL = url
        validationError = nil
      case .failure(let error):
        validationError = error.localizedDescription
      }
    }
  }
  
  private func addRepository() {
    guard let url = selectedURL else { return }
    
    isValidating = true
    validationError = nil
    
    Task {
      do {
        // Start accessing security-scoped resource (may be needed even without sandbox)
        let didStartAccess = url.startAccessingSecurityScopedResource()
        defer {
          if didStartAccess {
            url.stopAccessingSecurityScopedResource()
          }
        }
        
        let repository = try await repositoryManager.addRepository(at: url)
        if let repository {
          onAddRepository(repository)
        }
        dismiss()
      } catch let error as GitError {
        validationError = error.localizedDescription
      } catch {
        validationError = error.localizedDescription
      }
      
      isValidating = false
    }
  }
}

#Preview {
  AddRepositorySheet(onAddRepository: { _ in})
    .environment(RepositoryManager())
}
