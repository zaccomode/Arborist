//
//  AlertInfo.swift
//  Arborist
//
//  Created by Isaac Shea on 3/2/2026.
//

import Foundation

struct AlertInfo: Identifiable {
  let id = UUID()
  let title: String
  let message: String
}
