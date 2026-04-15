import Foundation
import Testing
@testable import VoticeSDK

@Test("NicknameManager saves and reloads trimmed nicknames")
func testNicknameManagerSavesTrimmedNickname() throws {
    let suiteName = UUID().uuidString
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defer {
        defaults.removePersistentDomain(forName: suiteName)
    }

    let storageManager = StorageManager(userDefaults: defaults)
    let nicknameManager = NicknameManager(storageManager: storageManager)

    try nicknameManager.saveNickname("  Harry  ")

    #expect(nicknameManager.loadNickname() == "Harry")
    #expect(try storageManager.load(forKey: StorageKey.nickname.rawValue, as: String.self) == "Harry")
}

@Test("NicknameManager ignores blank nicknames")
func testNicknameManagerIgnoresBlankNickname() throws {
    let suiteName = UUID().uuidString
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defer {
        defaults.removePersistentDomain(forName: suiteName)
    }

    let storageManager = StorageManager(userDefaults: defaults)
    let nicknameManager = NicknameManager(storageManager: storageManager)

    try nicknameManager.saveNickname("   ")

    #expect(nicknameManager.loadNickname().isEmpty)
    #expect(try storageManager.load(forKey: StorageKey.nickname.rawValue, as: String.self) == nil)
}
