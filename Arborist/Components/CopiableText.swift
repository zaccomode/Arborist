//
//  CopiableText.swift
//  Arborist
//
//  Created by Isaac Shea on 3/2/2026.
//

import SwiftUI

struct CopiableText: View {
  /// The text to display and/or copy.
  let text: String
  /// The text to copy to the clipboard, if provided. If not provided, `text` will be copied instead.
  let copyContent: String? = nil
  
  @State private var copied = false
  
  var body: some View {
    Button {
      NSPasteboard.general.clearContents()
      NSPasteboard.general.setString(
        copyContent ?? text,
        forType: .string
      )
    } label: {
      Text(text)
    }
    .buttonStyle(.plain)
    .help(copied ? "Copied!" : "Click to copy")
  }
}
