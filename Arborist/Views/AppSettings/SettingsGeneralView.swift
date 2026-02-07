//
//  SettingsGeneralView.swift
//  Arborist
//
//  Created by Isaac Shea on 7/2/2026.
//

import SwiftUI

struct SettingsGeneralView: View {
  @AppStorage("autoRefreshOnLaunch") private var autoRefreshOnLaunch = true
  @AppStorage("showStaleWorktreeWarnings") private var showStaleWorktreeWarnings = true
  
  var body: some View {
    Form {
      Toggle("Refresh repositories on launch", isOn: $autoRefreshOnLaunch)
      Toggle("Show warnings for stale worktrees", isOn: $showStaleWorktreeWarnings)
    }
    .formStyle(.grouped)
    .navigationTitle("General")
  }
}
