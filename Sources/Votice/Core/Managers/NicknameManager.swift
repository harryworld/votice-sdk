//
//  NicknameManager.swift
//  Votice
//
//  Created by OpenAI Codex on 15/4/26.
//

import Foundation

protocol NicknameManagerProtocol: Sendable {
    func loadNickname() -> String
    func saveNickname(_ nickname: String) throws
}

struct NicknameManager: NicknameManagerProtocol {
    // MARK: - Properties

    private let storageManager: StorageManagerProtocol

    // MARK: - Init

    init(storageManager: StorageManagerProtocol = StorageManager()) {
        self.storageManager = storageManager
    }

    // MARK: - NicknameManagerProtocol

    func loadNickname() -> String {
        do {
            guard let nickname = try storageManager.load(forKey: StorageKey.nickname.rawValue, as: String.self) else {
                return ""
            }

            return normalizedNickname(from: nickname) ?? ""
        } catch {
            LogManager.shared.devLog(.error, "NicknameManager: failed to load nickname: \(error)")
            return ""
        }
    }

    func saveNickname(_ nickname: String) throws {
        guard let normalizedNickname = normalizedNickname(from: nickname) else {
            return
        }

        try storageManager.save(normalizedNickname, forKey: StorageKey.nickname.rawValue)
    }
}

// MARK: - Private

private extension NicknameManager {
    func normalizedNickname(from nickname: String) -> String? {
        let trimmedNickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedNickname.isEmpty else {
            return nil
        }

        return trimmedNickname
    }
}
