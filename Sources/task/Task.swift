import Foundation

// MARK: - Task Model

struct Task {
    let id: Int
    var title: String
    var description: String
    var completed: Bool
    var createdDate: Double
    var completedDate: Double?
    var updatedDate: Double?
    var tags: [String]

    init(id: Int, title: String, description: String, tags: [String] = []) {
        self.id = id
        self.title = title
        self.description = description
        self.completed = false
        self.createdDate = Date().timeIntervalSince1970
        self.tags = tags
    }

    func createdDateFormatted() -> String {
        let date = Date(timeIntervalSince1970: createdDate)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
}
