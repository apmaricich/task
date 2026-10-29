import Foundation

// MARK: - Task Store

class TaskStore {
    private let filePath: String

    init(filePath: String = "tasks.json") {
        self.filePath = filePath
    }

    private func loadStore() -> [String: Any] {
        guard FileManager.default.fileExists(atPath: filePath) else {
            return ["tasks": [], "config": ["sort": "completed"]]
        }

        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
            let decoded = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            return decoded ?? ["tasks": [], "config": ["sort": "completed"]]
        } catch {
            return ["tasks": [], "config": ["sort": "completed"]]
        }
    }

    private func saveStore(_ store: [String: Any]) {
        do {
            let data = try JSONSerialization.data(withJSONObject: store, options: [.prettyPrinted])
            try data.write(to: URL(fileURLWithPath: filePath), options: [.atomic])
        } catch {
            print("Error saving tasks: \(error)")
        }
    }

    func initStore() {
        var store = loadStore()
        store["config"] = ["sort": "completed"]
        saveStore(store)
        print("Task store initialized at \(filePath)")
    }

    func list() -> [Task] {
        let store = loadStore()
        let tasks = store["tasks"] as? [[String: Any]] ?? []
        let config = store["config"] as? [String: Any] ?? ["sort": "completed"]
        let sortField = config["sort"] as? String ?? "completed"

        let taskInstances: [Task] = tasks.compactMap {
            var task = Task(
                id: $0["id"] as? Int ?? 0,
                title: $0["title"] as? String ?? "",
                description: $0["description"] as? String ?? ""
            )
            task.completed = $0["completed"] as? Bool ?? false
            task.createdDate = $0["createdDate"] as? Double ?? task.createdDate
            task.completedDate = $0["completedDate"] as? Double
            task.updatedDate = $0["updatedDate"] as? Double
            return task
        }

        return sortTasks(taskInstances, by: sortField)
    }

    func add(title: String, description: String) -> Task {
        var store = loadStore()
        var tasks = store["tasks"] as? [[String: Any]] ?? []

        let nextId = tasks.isEmpty ? 1 : tasks.map { $0["id"] as? Int ?? 0 }.max()! + 1
        let task = Task(id: nextId, title: title, description: description)
        let taskDict: [String: Any] = [
            "id": task.id,
            "title": task.title,
            "description": task.description,
            "completed": task.completed,
            "createdDate": task.createdDate
        ]
        tasks.append(taskDict)

        store["tasks"] = tasks
        saveStore(store)

        return task
    }

    func update(id: Int, title: String?, description: String?) -> Bool {
        var store = loadStore()
        var tasks = store["tasks"] as? [[String: Any]] ?? []
        let index = tasks.firstIndex { $0["id"] as? Int == id }

        guard let index = index else { return false }

        if let title = title {
            tasks[index]["title"] = title
        }
        if let description = description {
            tasks[index]["description"] = description
        }
        tasks[index]["updatedDate"] = Date().timeIntervalSince1970

        store["tasks"] = tasks
        saveStore(store)
        return true
    }

    func done(id: Int) -> Bool {
        var store = loadStore()
        var tasks = store["tasks"] as? [[String: Any]] ?? []
        let index = tasks.firstIndex { $0["id"] as? Int == id }

        guard let index = index else { return false }

        tasks[index]["completed"] = true
        tasks[index]["completedDate"] = Date().timeIntervalSince1970
        store["tasks"] = tasks
        saveStore(store)
        return true
    }

    func delete(id: Int) -> Bool {
        var store = loadStore()
        var tasks = store["tasks"] as? [[String: Any]] ?? []
        let index = tasks.firstIndex { $0["id"] as? Int == id }

        guard let index = index else { return false }

        tasks.remove(at: index)
        store["tasks"] = tasks
        saveStore(store)
        return true
    }

    func setConfig(key: String, value: String) {
        var store = loadStore()
        var config = store["config"] as? [String: Any] ?? [:]

        // Try to parse as integer
        if let intValue = Int(value) {
            config[key] = intValue
        } else {
            config[key] = value
        }

        store["config"] = config
        saveStore(store)
        print("Updated config: \(key) = \(value)")
    }

    func getSortField() -> String {
        let store = loadStore()
        let config = store["config"] as? [String: Any] ?? ["sort": "completed"]
        return config["sort"] as? String ?? "completed"
    }

    func getDisplayLimit() -> Int {
        let store = loadStore()
        let config = store["config"] as? [String: Any] ?? ["sort": "completed"]
        return config["displayLimit"] as? Int ?? 0
    }

    private func sortTasks(_ tasks: [Task], by field: String) -> [Task] {
        switch field {
        case "completed":
            // Primary: uncompleted first, then completed
            // Uncompleted: oldest createdDate first (ascending)
            // Completed: most recent completedDate first (descending)
            return tasks.sorted { a, b in
                if a.completed != b.completed {
                    return !a.completed && b.completed
                }
                if a.completed && b.completed {
                    // Both completed - sort by completedDate (newest first)
                    if let aDate = a.completedDate, let bDate = b.completedDate {
                        return aDate > bDate
                    }
                    if a.completedDate != nil && b.completedDate == nil {
                        return true
                    }
                    return false
                }
                // Both uncompleted - sort by createdDate (oldest first)
                return a.createdDate < b.createdDate
            }
        case "title":
            return tasks.sorted { $0.title < $1.title }
        case "description":
            return tasks.sorted { $0.description < $1.description }
        case "id":
            return tasks.sorted { $0.id < $1.id }
        default:
            return tasks
        }
    }
}