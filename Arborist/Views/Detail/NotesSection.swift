//
//  NotesSection.swift
//  Arborist
//
//  Created by Isaac Shea on 2/4/2026.
//

import SwiftUI

struct NotesSection: View {
  @Binding var notes: String
  let onSave: (String) -> Void

  @State private var isEditing = false
  @State private var editingText = ""
  @FocusState private var isFocused: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("Notes")
          .font(.headline)

        Spacer()

        if !notes.isEmpty && !isEditing {
          Button("Edit") {
            startEditing()
          }
          .buttonStyle(.borderless)
        }
      }

      if isEditing {
        editingView
      } else if notes.isEmpty {
        emptyStateView
      } else {
        displayView
      }
    }
  }

  private var emptyStateView: some View {
    Text("No notes")
      .foregroundStyle(.tertiary)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding()
      .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
      .contentShape(Rectangle())
      .onTapGesture {
        startEditing()
      }
  }

  private var displayView: some View {
    Text(notes)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding()
      .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
      .contentShape(Rectangle())
      .onTapGesture {
        startEditing()
      }
  }

  private var editingView: some View {
    VStack(alignment: .trailing, spacing: 8) {
      TextEditor(text: $editingText)
        .font(.body)
        .frame(minHeight: 80)
        .scrollContentBackground(.hidden)
        .padding(8)
        .background(.quaternary.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .focused($isFocused)

      HStack(spacing: 8) {
        Button("Cancel") {
          cancelEditing()
        }
        .buttonStyle(.borderless)

        Button("Save") {
          saveNotes()
        }
        .buttonStyle(.borderedProminent)
      }
    }
  }

  private func startEditing() {
    editingText = notes
    isEditing = true
    isFocused = true
  }

  private func cancelEditing() {
    isEditing = false
    editingText = ""
  }

  private func saveNotes() {
    notes = editingText
    onSave(editingText)
    isEditing = false
    editingText = ""
  }
}

#Preview("Empty") {
  NotesSection(
    notes: .constant(""),
    onSave: { _ in }
  )
  .padding()
}

#Preview("With Notes") {
  NotesSection(
    notes: .constant("This is a sample note that spans multiple lines.\n\nIt can contain various information about the repository or worktree."),
    onSave: { _ in }
  )
  .padding()
}
