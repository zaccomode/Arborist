//
//  ArboristSchemaVersioning.swift
//  Arborist
//
//  Created by Isaac Shea on 2/14/2026.
//

import Foundation
import SwiftData

// MARK: - Schema Versions

/// The current (and initial tracked) schema version for Arborist's SwiftData models.
///
/// When modifying any @Model class, you MUST:
/// 1. Create a new `enum SchemaVN` (e.g. `SchemaV2`) conforming to `VersionedSchema`
/// 2. Copy ALL @Model classes into it with the updated shape
/// 3. Add a migration stage to `ArboristMigrationPlan.stages`
/// 4. Update `ArboristMigrationPlan.currentVersion` to point to the new version
/// 5. Update `ArboristApp.init()` if the schema list changed
///
/// See CLAUDE.md at the project root for full details.
enum SchemaV1: VersionedSchema {
  static var versionIdentifier: Schema.Version = Schema.Version(1, 0, 0)

  static var models: [any PersistentModel.Type] {
    [
      PersistedRepository.self,
      PersistedOpenPreset.self,
      PersistedPresetConfiguration.self,
      PersistedRepositoryPresetOverride.self,
      PersistedRepositoryCustomPreset.self,
      PersistedWorktreeNote.self,
    ]
  }
}

// MARK: - Migration Plan

enum ArboristMigrationPlan: SchemaMigrationPlan {
  /// Update this to the latest schema version whenever a new version is added.
  static var currentVersion: any VersionedSchema.Type { SchemaV1.self }

  static var schemas: [any VersionedSchema.Type] {
    [SchemaV1.self]
  }

  static var stages: [MigrationStage] {
    // No migration stages yet — this is the initial tracked version.
    // When adding SchemaV2, add a migration stage here, e.g.:
    //   .lightweight(fromVersion: SchemaV1.self, toVersion: SchemaV2.self)
    []
  }
}
