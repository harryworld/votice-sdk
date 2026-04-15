import Foundation
import Testing
@testable import VoticeSDK

@MainActor
@Test("CreateSuggestionViewModel prepopulates the saved nickname")
func testCreateSuggestionViewModelPrepopulatesSavedNickname() {
    let nicknameManager = MockNicknameManager(loadedNickname: "Harry")
    let viewModel = CreateSuggestionViewModel(nicknameManager: nicknameManager)

    #expect(viewModel.nickname == "Harry")
}

@MainActor
@Test("SuggestionDetailViewModel prepopulates the saved nickname")
func testSuggestionDetailViewModelPrepopulatesSavedNickname() {
    let nicknameManager = MockNicknameManager(loadedNickname: "Harry")
    let viewModel = SuggestionDetailViewModel(nicknameManager: nicknameManager)

    #expect(viewModel.commentNickname == "Harry")
}

@MainActor
@Test("CreateSuggestionViewModel saves the nickname after a successful submission")
func testCreateSuggestionViewModelSavesNicknameOnSuccessfulSubmission() async {
    let nicknameManager = MockNicknameManager()
    let suggestionUseCase = MockSuggestionUseCase()
    let viewModel = CreateSuggestionViewModel(
        suggestionUseCase: suggestionUseCase,
        nicknameManager: nicknameManager
    )
    viewModel.title = "Saved name"
    viewModel.nickname = "  Harry  "

    await viewModel.submitSuggestion { _ in }

    #expect(nicknameManager.savedNicknames == ["Harry"])
    #expect(viewModel.nickname == "Harry")
}

@MainActor
@Test("SuggestionDetailViewModel saves the nickname after a successful comment")
func testSuggestionDetailViewModelSavesNicknameOnSuccessfulComment() async {
    let nicknameManager = MockNicknameManager()
    let commentUseCase = MockCommentUseCase()
    let viewModel = SuggestionDetailViewModel(
        commentUseCase: commentUseCase,
        suggestionUseCase: MockSuggestionUseCase(),
        nicknameManager: nicknameManager
    )
    viewModel.newComment = "Looks good"
    viewModel.commentNickname = "  Harry  "

    await viewModel.submitComment(for: "suggestion-id") {}

    #expect(nicknameManager.savedNicknames == ["Harry"])
    #expect(viewModel.commentNickname == "Harry")
    #expect(viewModel.newComment.isEmpty)
}

private final class MockNicknameManager: NicknameManagerProtocol, @unchecked Sendable {
    var loadedNickname: String
    var savedNicknames: [String] = []

    init(loadedNickname: String = "") {
        self.loadedNickname = loadedNickname
    }

    func loadNickname() -> String {
        loadedNickname
    }

    func saveNickname(_ nickname: String) throws {
        savedNicknames.append(nickname)
        loadedNickname = nickname
    }
}

private struct MockSuggestionUseCase: SuggestionUseCaseProtocol {
    func fetchFilterApplied() throws -> SuggestionStatusEntity? {
        nil
    }

    func setFilterApplied(_ status: SuggestionStatusEntity?) throws {}

    func clearFilterApplied() throws {}

    func fetchSuggestions(
        status: SuggestionStatusEntity?,
        excludeCompleted: Bool,
        pagination: PaginationRequest
    ) async throws -> SuggestionsResponse {
        SuggestionsResponse(suggestions: [], count: 0, nextPageToken: nil)
    }

    func createSuggestion(request: CreateSuggestionRequest) async throws -> CreateSuggestionResponse {
        CreateSuggestionResponse(
            message: "ok",
            suggestion: SuggestionEntity(id: "suggestion-id", title: request.title, nickname: request.nickname)
        )
    }

    func deleteSuggestion(suggestionId: String) async throws -> DeleteSuggestionResponse {
        DeleteSuggestionResponse(
            message: "ok",
            deleted: DeletedSuggestionResponse(suggestion: 0, votes: 0, comments: 0)
        )
    }

    func fetchVoteStatus(suggestionId: String) async throws -> VoteStatusEntity {
        VoteStatusEntity(hasVoted: false, voteCount: 0, suggestionId: suggestionId, deviceId: "device-id")
    }

    func vote(suggestionId: String, voteType: VoteType) async throws -> VoteSuggestionResponse {
        VoteSuggestionResponse(message: "ok", vote: nil, suggestion: nil)
    }

    func uploadImage(request: UploadImageRequest) async throws -> UploadImageResponse {
        UploadImageResponse(message: "ok", imageUrl: "", fileName: "")
    }
}

private struct MockCommentUseCase: CommentUseCaseProtocol {
    func fetchComments(suggestionId: String, pagination: PaginationRequest) async throws -> CommentsResponse {
        CommentsResponse(comments: [], count: 0, nextPageToken: nil, nextPageTokenString: nil)
    }

    func createComment(suggestionId: String, text: String, nickname: String?) async throws -> CreateCommentResponse {
        CreateCommentResponse(
            message: "ok",
            comment: CommentEntity(
                id: "comment-id",
                suggestionId: suggestionId,
                appId: "app-id",
                text: text,
                createdAt: nil,
                updatedAt: nil,
                createdBy: nil,
                deviceId: nil,
                nickname: nickname,
                source: "sdk"
            )
        )
    }

    func deleteComment(commentId: String) async throws {}
}
