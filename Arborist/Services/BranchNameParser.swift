//
//  BranchNameParser.swift
//  Arborist
//
//  Created by Isaac Shea on 2/2/2026.
//

import Foundation

/// Parses and sanitizes branch names from various input formats
enum BranchNameParser {
    /// Common git command prefixes to strip
    private static let gitPrefixes = [
        "git checkout -b ",
        "git checkout ",
        "git switch -c ",
        "git switch --create ",
        "git switch ",
        "git branch ",
        "git co -b ",
        "git co ",
    ]

    /// Extracts a branch name from various input formats
    /// - Parameter input: Raw input string (could be a git command, URL, or plain branch name)
    /// - Returns: Cleaned branch name
    ///
    /// Examples:
    /// - "git checkout feature/ABC-123" -> "feature/ABC-123"
    /// - "git switch -c bugfix/DEF-456" -> "bugfix/DEF-456"
    /// - "feature/GHI-789" -> "feature/GHI-789"
    /// - "  feature/JKL-012  " -> "feature/JKL-012"
    static func parse(_ input: String) -> String {
        var result = input.trimmingCharacters(in: .whitespacesAndNewlines)

        // Try to strip common git command prefixes
        for prefix in gitPrefixes {
            if result.lowercased().hasPrefix(prefix.lowercased()) {
                result = String(result.dropFirst(prefix.count))
                break
            }
        }

        // Handle origin/ prefix (sometimes copied from remote branch names)
        if result.hasPrefix("origin/") {
            result = String(result.dropFirst(7))
        }

        // Remove any remaining leading/trailing whitespace
        result = result.trimmingCharacters(in: .whitespacesAndNewlines)

        // If there are multiple words, take just the first one (the branch name)
        // This handles cases like "git checkout feature/ABC-123 -- file.txt"
        if let firstWord = result.split(separator: " ").first {
            result = String(firstWord)
        }

        return result
    }

    /// Sanitizes a branch name for use as a folder name
    /// - Parameter branch: The branch name
    /// - Returns: A sanitized folder name
    ///
    /// Examples:
    /// - "feature/ABC-123" -> "feature-ABC-123"
    /// - "bugfix/issue#456" -> "bugfix-issue-456"
    static func sanitizeForFolder(_ branch: String) -> String {
        var result = branch

        // Replace forward slashes with hyphens
        result = result.replacingOccurrences(of: "/", with: "-")

        // Remove or replace invalid filesystem characters
        let invalidCharacters = CharacterSet(charactersIn: "\\:*?\"<>|#")
        result = result.components(separatedBy: invalidCharacters).joined(separator: "-")

        // Remove leading/trailing hyphens and dots
        result = result.trimmingCharacters(in: CharacterSet(charactersIn: "-."))

        // Collapse multiple hyphens
        while result.contains("--") {
            result = result.replacingOccurrences(of: "--", with: "-")
        }

        return result
    }

    /// Validates if a string is a valid git branch name
    /// - Parameter name: The branch name to validate
    /// - Returns: Whether the name is valid
    static func isValidBranchName(_ name: String) -> Bool {
        guard !name.isEmpty else { return false }

        // Git branch name restrictions
        let invalidPatterns = [
            "..",           // Cannot contain consecutive dots
            "//",           // Cannot contain consecutive slashes
            "@{",           // Cannot contain @{
            "\\",           // Cannot contain backslash
        ]

        for pattern in invalidPatterns {
            if name.contains(pattern) {
                return false
            }
        }

        // Cannot start or end with certain characters
        if name.hasPrefix("/") || name.hasSuffix("/") ||
           name.hasPrefix(".") || name.hasSuffix(".") ||
           name.hasSuffix(".lock") {
            return false
        }

        // Cannot contain control characters or spaces
        let invalidCharSet = CharacterSet.controlCharacters.union(CharacterSet(charactersIn: " ~^:?*["))
        if name.rangeOfCharacter(from: invalidCharSet) != nil {
            return false
        }

        return true
    }
}
