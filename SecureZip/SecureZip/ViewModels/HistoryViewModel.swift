import Foundation
import Observation

@Observable
final class HistoryViewModel {

    var items: [HistoryItem] = []
    var searchText: String = ""
    var isLoading: Bool = false
    var errorMessage: String?

    private let historyService: HistoryServiceProtocol

    init(historyService: HistoryServiceProtocol = HistoryService()) {
        self.historyService = historyService
    }

    var filteredItems: [HistoryItem] {
        guard !searchText.isEmpty else { return items }
        return items.filter {
            $0.recipientEmail.localizedCaseInsensitiveContains(searchText)
            || $0.fileName.localizedCaseInsensitiveContains(searchText)
        }
    }

    func loadHistory() async {
        isLoading = true
        do {
            items = try await historyService.fetchAll()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func deleteItem(id: UUID) async {
        do {
            try await historyService.delete(id: id)
            items.removeAll { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
