//
//  PresetManager.swift
//  Arborist
//
//  Created by Isaac Shea on 2/4/2026.
//

import Foundation
import SwiftData

/// Manages open presets at both app and repository levels
@Observable
@MainActor
final class PresetManager {
    // MARK: - Properties

    /// Custom presets created by the user (app-level)
    private(set) var customPresets: [OpenPreset] = []

    /// App-level configurations for preset visibility and ordering
    private(set) var appConfigurations: [UUID: PresetConfiguration] = [:]

    /// Repository-specific overrides, keyed by repository ID
    private(set) var repositoryOverrides: [UUID: [UUID: RepositoryPresetOverride]] = [:]

    /// Repository-specific custom presets, keyed by repository ID
    private(set) var repositoryCustomPresets: [UUID: [OpenPreset]] = [:]

    private let modelContainer: ModelContainer?

    // MARK: - Initialization

    nonisolated init(modelContainer: ModelContainer? = nil) {
        self.modelContainer = modelContainer
    }

    // MARK: - Computed Properties

    /// All presets in order (built-in + custom app-level presets)
    var allPresets: [OpenPreset] {
        let builtIn = OpenPreset.defaultPresets
        let combined = builtIn + customPresets
        return combined.sorted { preset1, preset2 in
            let order1 = appConfigurations[preset1.id]?.sortOrder ?? preset1.sortOrder
            let order2 = appConfigurations[preset2.id]?.sortOrder ?? preset2.sortOrder
            return order1 < order2
        }
    }

    /// Enabled presets at the app level
    var enabledPresets: [OpenPreset] {
        allPresets.filter { preset in
            appConfigurations[preset.id]?.isEnabled ?? preset.defaultEnabled
        }
    }

    // MARK: - Repository-Specific Presets

    /// Returns the effective presets for a specific repository
    /// This includes app-level presets (with overrides applied) + repository-specific custom presets
    func presetsForRepository(_ repository: Repository) -> [OpenPreset] {
        let repoOverrides = repositoryOverrides[repository.id] ?? [:]
        let repoCustom = repositoryCustomPresets[repository.id] ?? []

        // Filter app-level presets based on overrides
        let appPresets = allPresets.filter { preset in
            if let override = repoOverrides[preset.id] {
                // Repository has an explicit override
                return override.isEnabled ?? (appConfigurations[preset.id]?.isEnabled ?? preset.defaultEnabled)
            }
            // Use app-level configuration, falling back to preset's default
            return appConfigurations[preset.id]?.isEnabled ?? preset.defaultEnabled
        }

        // Combine app presets with repository-specific custom presets
        return appPresets + repoCustom.sorted { $0.sortOrder < $1.sortOrder }
    }

    /// Check if a preset is enabled for a specific repository
    func isPresetEnabled(_ presetId: UUID, for repository: Repository) -> Bool {
        let preset = allPresets.first { $0.id == presetId }
        let defaultEnabled = preset?.defaultEnabled ?? true

        if let override = repositoryOverrides[repository.id]?[presetId] {
            return override.isEnabled ?? (appConfigurations[presetId]?.isEnabled ?? defaultEnabled)
        }
        return appConfigurations[presetId]?.isEnabled ?? defaultEnabled
    }

    /// Get the override state for a preset in a repository (nil = use default)
    func getOverrideState(_ presetId: UUID, for repository: Repository) -> Bool? {
        repositoryOverrides[repository.id]?[presetId]?.isEnabled
    }

    // MARK: - App-Level Configuration

    /// Set whether a preset is enabled at the app level
    func setPresetEnabled(_ presetId: UUID, enabled: Bool) {
        if var config = appConfigurations[presetId] {
            config.isEnabled = enabled
            appConfigurations[presetId] = config
        } else {
            let sortOrder = allPresets.firstIndex(where: { $0.id == presetId }) ?? 0
            appConfigurations[presetId] = PresetConfiguration(
                presetId: presetId,
                isEnabled: enabled,
                sortOrder: sortOrder
            )
        }
        saveAppConfigurations()
    }

    /// Update the sort order for presets
    func updateSortOrder(_ presetIds: [UUID]) {
        for (index, presetId) in presetIds.enumerated() {
            if var config = appConfigurations[presetId] {
                config.sortOrder = index
                appConfigurations[presetId] = config
            } else {
                appConfigurations[presetId] = PresetConfiguration(
                    presetId: presetId,
                    isEnabled: true,
                    sortOrder: index
                )
            }
        }
        saveAppConfigurations()
    }

    // MARK: - Repository Override Management

    /// Set a repository-specific override for a preset
    /// Pass nil for `enabled` to remove the override and use app default
    func setRepositoryOverride(repositoryId: UUID, presetId: UUID, enabled: Bool?) {
        if repositoryOverrides[repositoryId] == nil {
            repositoryOverrides[repositoryId] = [:]
        }

        if let enabled {
            repositoryOverrides[repositoryId]?[presetId] = RepositoryPresetOverride(
                presetId: presetId,
                isEnabled: enabled
            )
        } else {
            repositoryOverrides[repositoryId]?.removeValue(forKey: presetId)
        }
        saveRepositoryOverrides(for: repositoryId)
    }

    /// Remove all overrides for a repository
    func clearRepositoryOverrides(repositoryId: UUID) {
        repositoryOverrides.removeValue(forKey: repositoryId)
        saveRepositoryOverrides(for: repositoryId)
    }

    // MARK: - Custom Preset CRUD (App-Level)

    /// Create a new custom preset at the app level
    func createPreset(_ preset: OpenPreset) {
        var newPreset = preset
        newPreset.sortOrder = allPresets.count
        customPresets.append(newPreset)
        appConfigurations[newPreset.id] = PresetConfiguration(
            presetId: newPreset.id,
            isEnabled: true,
            sortOrder: newPreset.sortOrder
        )
        saveCustomPresets()
        saveAppConfigurations()
    }

    /// Update an existing custom preset
    func updatePreset(_ preset: OpenPreset) {
        if let index = customPresets.firstIndex(where: { $0.id == preset.id }) {
            customPresets[index] = preset
            saveCustomPresets()
        }
    }

    /// Delete a custom preset
    func deletePreset(_ presetId: UUID) {
        customPresets.removeAll { $0.id == presetId }
        appConfigurations.removeValue(forKey: presetId)

        // Also remove any repository overrides for this preset
        for repoId in repositoryOverrides.keys {
            repositoryOverrides[repoId]?.removeValue(forKey: presetId)
        }

        saveCustomPresets()
        saveAppConfigurations()
    }

    // MARK: - Repository Custom Preset CRUD

    /// Create a repository-specific custom preset
    func createRepositoryPreset(_ preset: OpenPreset, for repositoryId: UUID) {
        if repositoryCustomPresets[repositoryId] == nil {
            repositoryCustomPresets[repositoryId] = []
        }
        var newPreset = preset
        newPreset.sortOrder = repositoryCustomPresets[repositoryId]?.count ?? 0
        repositoryCustomPresets[repositoryId]?.append(newPreset)
        saveRepositoryCustomPresets(for: repositoryId)
    }

    /// Update a repository-specific custom preset
    func updateRepositoryPreset(_ preset: OpenPreset, for repositoryId: UUID) {
        if let index = repositoryCustomPresets[repositoryId]?.firstIndex(where: { $0.id == preset.id }) {
            repositoryCustomPresets[repositoryId]?[index] = preset
            saveRepositoryCustomPresets(for: repositoryId)
        }
    }

    /// Delete a repository-specific custom preset
    func deleteRepositoryPreset(_ presetId: UUID, for repositoryId: UUID) {
        repositoryCustomPresets[repositoryId]?.removeAll { $0.id == presetId }
        saveRepositoryCustomPresets(for: repositoryId)
    }

    /// Get all repository-specific custom presets for a repository
    func getRepositoryCustomPresets(for repositoryId: UUID) -> [OpenPreset] {
        repositoryCustomPresets[repositoryId] ?? []
    }

    // MARK: - Persistence

    /// Load all preset data from SwiftData
    func loadPresets() async {
        guard let container = modelContainer else { return }

        do {
            let context = ModelContext(container)

            // Load custom presets
            let presetDescriptor = FetchDescriptor<PersistedOpenPreset>(
                predicate: #Predicate { !$0.isBuiltIn },
                sortBy: [SortDescriptor(\.sortOrder)]
            )
            let persistedPresets = try context.fetch(presetDescriptor)
            customPresets = persistedPresets.map { $0.toOpenPreset() }

            // Load app configurations
            let configDescriptor = FetchDescriptor<PersistedPresetConfiguration>()
            let persistedConfigs = try context.fetch(configDescriptor)
            appConfigurations = Dictionary(
                uniqueKeysWithValues: persistedConfigs.map { ($0.presetId, $0.toPresetConfiguration()) }
            )

            // Load repository overrides
            let repoDescriptor = FetchDescriptor<PersistedRepository>()
            let persistedRepos = try context.fetch(repoDescriptor)

            for repo in persistedRepos {
                // Load overrides
                let overrides = repo.presetOverrides.map { $0.toRepositoryPresetOverride() }
                if !overrides.isEmpty {
                    repositoryOverrides[repo.id] = Dictionary(
                        uniqueKeysWithValues: overrides.map { ($0.presetId, $0) }
                    )
                }

                // Load repository custom presets
                let customPresets = repo.customPresets.map { $0.toOpenPreset() }
                if !customPresets.isEmpty {
                    repositoryCustomPresets[repo.id] = customPresets
                }
            }
        } catch {
            print("Failed to load presets: \(error)")
        }
    }

    private func saveCustomPresets() {
        guard let container = modelContainer else { return }

        do {
            let context = ModelContext(container)

            // Delete existing custom presets
            let existingDescriptor = FetchDescriptor<PersistedOpenPreset>(
                predicate: #Predicate { !$0.isBuiltIn }
            )
            let existing = try context.fetch(existingDescriptor)
            for preset in existing {
                context.delete(preset)
            }

            // Insert new custom presets
            for preset in customPresets {
                let persisted = PersistedOpenPreset(from: preset)
                context.insert(persisted)
            }

            try context.save()
        } catch {
            print("Failed to save custom presets: \(error)")
        }
    }

    private func saveAppConfigurations() {
        guard let container = modelContainer else { return }

        do {
            let context = ModelContext(container)

            // Delete existing configurations
            let existingDescriptor = FetchDescriptor<PersistedPresetConfiguration>()
            let existing = try context.fetch(existingDescriptor)
            for config in existing {
                context.delete(config)
            }

            // Insert new configurations
            for (_, config) in appConfigurations {
                let persisted = PersistedPresetConfiguration(from: config)
                context.insert(persisted)
            }

            try context.save()
        } catch {
            print("Failed to save app configurations: \(error)")
        }
    }

    private func saveRepositoryOverrides(for repositoryId: UUID) {
        guard let container = modelContainer else { return }

        do {
            let context = ModelContext(container)

            // Find the repository
            let repoDescriptor = FetchDescriptor<PersistedRepository>(
                predicate: #Predicate { $0.id == repositoryId }
            )
            guard let repo = try context.fetch(repoDescriptor).first else { return }

            // Clear existing overrides
            for override in repo.presetOverrides {
                context.delete(override)
            }
            repo.presetOverrides = []

            // Add new overrides
            if let overrides = repositoryOverrides[repositoryId] {
                for (_, override) in overrides {
                    let persisted = PersistedRepositoryPresetOverride(from: override)
                    persisted.repository = repo
                    repo.presetOverrides.append(persisted)
                }
            }

            try context.save()
        } catch {
            print("Failed to save repository overrides: \(error)")
        }
    }

    private func saveRepositoryCustomPresets(for repositoryId: UUID) {
        guard let container = modelContainer else { return }

        do {
            let context = ModelContext(container)

            // Find the repository
            let repoDescriptor = FetchDescriptor<PersistedRepository>(
                predicate: #Predicate { $0.id == repositoryId }
            )
            guard let repo = try context.fetch(repoDescriptor).first else { return }

            // Clear existing custom presets
            for preset in repo.customPresets {
                context.delete(preset)
            }
            repo.customPresets = []

            // Add new custom presets
            if let presets = repositoryCustomPresets[repositoryId] {
                for preset in presets {
                    let persisted = PersistedRepositoryCustomPreset(from: preset)
                    persisted.repository = repo
                    repo.customPresets.append(persisted)
                }
            }

            try context.save()
        } catch {
            print("Failed to save repository custom presets: \(error)")
        }
    }
}
