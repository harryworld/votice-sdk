//
//  CreateSuggestionViewModel.swift
//  Votice
//
//  Created by Arturo Carretero Calvo on 29/6/25.
//  Copyright © 2025 ArtCC. All rights reserved.
//

import Foundation

@MainActor
final class CreateSuggestionViewModel: ObservableObject {
    // MARK: - Properties

    @Published var isSubmitting = false
    @Published var title = ""
    @Published var description = ""
    @Published var nickname = ""
    @Published var currentAlert: VoticeAlertEntity?
    @Published var isShowingAlert = false
    @Published var isIssue = false {
        didSet {
            if !isIssue {
                issueImageData = nil
            }
        }
    }
    @Published var issueImageData: Data?

    private let suggestionUseCase: SuggestionUseCaseProtocol
    private let nicknameManager: NicknameManagerProtocol

    var liquidGlassEnabled: Bool {
        ConfigurationManager.shared.shouldUseLiquidGlass
    }
    var isFormValid: Bool {
        !title.isEmpty
    }

    // MARK: - Init

    init(
        suggestionUseCase: SuggestionUseCaseProtocol = SuggestionUseCase(),
        nicknameManager: NicknameManagerProtocol = NicknameManager()
    ) {
        self.suggestionUseCase = suggestionUseCase
        self.nicknameManager = nicknameManager
        nickname = nicknameManager.loadNickname()
    }

    // MARK: - Functions

    func createSuggestion(title: String, description: String?, nickname: String?) async throws -> SuggestionEntity {
        guard !isSubmitting else {
            throw VoticeError.invalidInput("Already submitting")
        }

        isSubmitting = true

        defer {
            isSubmitting = false
        }

        do {
            let user: UserEntity = ConfigurationManager.shared.user

            var urlImage: String?

            if isIssue, let issueImageData {
                let base64String = issueImageData.base64EncodedString()
                let uploadImageRequest: UploadImageRequest = .init(
                    imageData: "data:image/jpeg;base64,\(base64String)",
                    fileName: UUID().uuidString + ".jpg",
                    mimeType: "image/jpeg"
                )
                let uploadImageResponse = try await suggestionUseCase.uploadImage(request: uploadImageRequest)

                urlImage = uploadImageResponse.imageUrl
            }

            let request: CreateSuggestionRequest = .init(
                title: title,
                description: description,
                nickname: nickname,
                userIsPremium: user.isPremium,
                issue: isIssue,
                urlImage: urlImage
            )
            let response = try await suggestionUseCase.createSuggestion(request: request)

            persistNicknameIfNeeded(nickname)

            return response.suggestion
        } catch {
            LogManager.shared.devLog(.error, "CreateSuggestionViewModel: failed to create suggestion: \(error)")

            showError()

            throw error
        }
    }

    func setIssueImage(_ data: Data) {
        issueImageData = data

        LogManager.shared.devLog(.info, "CreateSuggestionViewModel: received image data (\(data.count) bytes)")
    }

    func submitSuggestion(onSuccess: @escaping (SuggestionEntity) -> Void) async {
        do {
            let normalizedNickname = normalizedNickname(from: nickname)
            let suggestion = try await createSuggestion(
                title: title,
                description: description,
                nickname: normalizedNickname
            )

            onSuccess(suggestion)
        } catch {
            LogManager.shared.devLog(.error, "CreateSuggestionViewModel: failed to submit suggestion: \(error)")
        }
    }

    func resetForm() {
        title = ""
        description = ""
        nickname = nicknameManager.loadNickname()
        isIssue = false
        issueImageData = nil
    }
}

// MARK: - Private

private extension CreateSuggestionViewModel {
    func normalizedNickname(from nickname: String) -> String? {
        let trimmedNickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedNickname.isEmpty else {
            return nil
        }

        return trimmedNickname
    }

    func persistNicknameIfNeeded(_ nickname: String?) {
        guard let nickname else {
            return
        }

        do {
            try nicknameManager.saveNickname(nickname)
            self.nickname = nickname
        } catch {
            LogManager.shared.devLog(.error, "CreateSuggestionViewModel: failed to persist nickname: \(error)")
        }
    }

    func showAlert(_ alert: VoticeAlertEntity) {
        currentAlert = alert

        isShowingAlert = true
    }

    func showError() {
        showAlert(VoticeAlertEntity.error(message: TextManager.shared.texts.genericError))
    }
}
