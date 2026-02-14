# Arborist - Claude Code Guidelines

## Project Overview

Arborist is a native macOS app (Swift/SwiftUI) for managing git worktrees. It uses SwiftData for persistence.

## SwiftData Schema Migration Rules

**Any change to a `@Model` class MUST include a schema migration.** Failing to do so will cause SwiftData to silently destroy and recreate the database, wiping all user data.

### What counts as a schema change

- Adding, removing, or renaming a property on any `@Model` class
- Changing a property's type (e.g. `String` to `String?`, `Int` to `Double`)
- Adding or removing a `@Relationship`
- Changing a relationship's delete rule
- Adding or removing an `@Attribute` modifier (e.g. `.unique`)
- Adding a new `@Model` class to the schema
- Removing a `@Model` class from the schema

### How to add a migration

All schema versioning lives in `Arborist/Models/ArboristSchemaVersioning.swift`.

1. **Create a new versioned schema enum** (e.g. `SchemaV2`) conforming to `VersionedSchema`:
   ```swift
   enum SchemaV2: VersionedSchema {
     static var versionIdentifier = Schema.Version(2, 0, 0)
     static var models: [any PersistentModel.Type] {
       [/* list ALL current @Model classes */]
     }
   }
   ```

2. **Add a migration stage** to `ArboristMigrationPlan.stages`:
   - Use `.lightweight(fromVersion: SchemaV1.self, toVersion: SchemaV2.self)` for additive changes (new optional properties, new models)
   - Use `.custom(fromVersion:toVersion:willMigrate:didMigrate:)` for destructive changes (renames, type changes, data transforms)

3. **Update `ArboristMigrationPlan`**:
   - Add the new schema to the `schemas` array
   - Update `currentVersion` to point to the new version

4. **Update `ArboristApp.init()`** if you changed which model types are in the schema — the `Schema(SchemaV1.models)` call should reference the latest version's models.

### Important: API placement

The `migrationPlan:` parameter belongs on `ModelContainer(for:migrationPlan:configurations:)`, **not** on `ModelConfiguration`. `ModelConfiguration` only takes `schema:` and `url:`.

### Store location

The SwiftData store lives at `~/Library/Application Support/Arborist/Arborist.store`. This is configured explicitly in `ArboristApp.swift` — do not remove the explicit `url:` parameter from `ModelConfiguration`.

## Architecture Notes

- **RepositoryManager** and **PresetManager** are `@Observable` `@MainActor` classes that own in-memory state and handle persistence through `ModelContext`.
- **GitService** is an actor that shells out to `/usr/bin/git` via `ShellExecutor`.
- Domain models (`Repository`, `OpenPreset`, etc.) are plain value types. Their `Persisted*` counterparts are `@Model` classes for SwiftData.
- Worktree data is NOT persisted — it's refreshed from git on every app launch.

## Build & Run

- Requires Xcode 15.2+, macOS deployment target is 26.2.
- No external dependencies — pure Swift/SwiftUI/SwiftData.
- Not sandboxed (`com.apple.security.app-sandbox` is `false`).
