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
        store["config"] = ["sort": "completed", "tagDisplayLimit": 0]
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
                description: $0["description"] as? String ?? "",
                tags: $0["tags"] as? [String] ?? []
            )
            task.completed = $0["completed"] as? Bool ?? false
            // If no createdDate, use current time so it sorts correctly
            task.createdDate = $0["createdDate"] as? Double ?? Date().timeIntervalSince1970
            task.completedDate = $0["completedDate"] as? Double
            task.updatedDate = $0["updatedDate"] as? Double
            return task
        }

        return sortTasks(taskInstances, by: sortField)
    }

    func track(title: String, description: String, tags: [String] = []) -> Task {
        var store = loadStore()
        var tasks = store["tasks"] as? [[String: Any]] ?? []

        let nextId = tasks.isEmpty ? 1 : tasks.map { $0["id"] as? Int ?? 0 }.max()! + 1
        var task = Task(id: nextId, title: title, description: description, tags: tags)
        let now = Date().timeIntervalSince1970
        task.completed = true
        task.completedDate = now

        var taskDict: [String: Any] = [
            "id": task.id,
            "title": task.title,
            "description": task.description,
            "completed": true,
            "createdDate": now,
            "completedDate": now
        ]
        if !task.tags.isEmpty {
            taskDict["tags"] = task.tags
        }
        tasks.append(taskDict)

        store["tasks"] = tasks
        saveStore(store)

        return task
    }

    func add(title: String, description: String, tags: [String] = []) -> Task {
        var store = loadStore()
        var tasks = store["tasks"] as? [[String: Any]] ?? []

        let nextId = tasks.isEmpty ? 1 : tasks.map { $0["id"] as? Int ?? 0 }.max()! + 1
        let task = Task(id: nextId, title: title, description: description, tags: tags)
        var taskDict: [String: Any] = [
            "id": task.id,
            "title": task.title,
            "description": task.description,
            "completed": task.completed,
            "createdDate": task.createdDate
        ]
        if !task.tags.isEmpty {
            taskDict["tags"] = task.tags
        }
        tasks.append(taskDict)

        store["tasks"] = tasks
        saveStore(store)

        return task
    }

    func update(id: Int, title: String?, description: String?, tags: [String]? = nil) -> Bool {
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
        if let tags = tags {
            var currentTags = tasks[index]["tags"] as? [String] ?? []
            for tag in tags {
                if currentTags.contains(tag) {
                    currentTags.removeAll { $0 == tag }
                } else {
                    currentTags.append(tag)
                }
            }
            if !currentTags.isEmpty {
                tasks[index]["tags"] = currentTags
            } else {
                tasks[index].removeValue(forKey: "tags")
            }
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

    func getConfig() -> [String: Any] {
        let store = loadStore()
        return store["config"] as? [String: Any] ?? [:]
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

    func getTagDisplayLimit() -> Int {
        let store = loadStore()
        let config = store["config"] as? [String: Any] ?? ["sort": "completed"]
        return config["tagDisplayLimit"] as? Int ?? 0
    }

    func getPinTags() -> [String] {
        let store = loadStore()
        let config = store["config"] as? [String: Any] ?? ["sort": "completed"]
        let pinTagsStr = config["pinTags"] as? String ?? ""
        if pinTagsStr.isEmpty { return [] }

        return parseTags(pinTagsStr)
    }

    func getBacklogTags() -> [String] {
        let store = loadStore()
        let config = store["config"] as? [String: Any] ?? ["sort": "completed"]
        let backlogTagsStr = config["backlogTags"] as? String ?? ""
        if backlogTagsStr.isEmpty { return [] }

        return parseTags(backlogTagsStr)
    }

    func getShowBacklog() -> Bool {
        let store = loadStore()
        let config = store["config"] as? [String: Any] ?? ["sort": "completed"]
        if let showBacklog = config["showBacklog"] as? Bool {
            return showBacklog
        }
        if let showBacklogStr = config["showBacklog"] as? String {
            return showBacklogStr == "true"
        }
        return false
    }

    func getShowCompleted() -> Bool {
        let store = loadStore()
        let config = store["config"] as? [String: Any] ?? ["sort": "completed"]
        if let showCompleted = config["showCompleted"] as? Bool {
            return showCompleted
        }
        if let showCompletedStr = config["showCompleted"] as? String {
            return showCompletedStr == "true"
        }
        return true
    }

    private func parseTags(_ tagsStr: String) -> [String] {
        return tagsStr
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .map { tag in
                if tag.hasPrefix("#") {
                    return tag
                }
                return "#" + tag
            }
            .filter { !$0.isEmpty }
    }

    func readyTask(id: Int) -> Bool {
        var store = loadStore()
        var tasks = store["tasks"] as? [[String: Any]] ?? []
        let index = tasks.firstIndex { $0["id"] as? Int == id }

        guard let index = index else { return false }

        let backlogTags = getBacklogTags()
        guard !backlogTags.isEmpty else { return false }

        var tags = tasks[index]["tags"] as? [String] ?? []
        let hadBacklogTag = tags.contains(where: { backlogTags.contains($0) })
        tags = tags.filter { !backlogTags.contains($0) }

        if tags.isEmpty {
            tasks[index].removeValue(forKey: "tags")
        } else {
            tasks[index]["tags"] = tags
        }
        tasks[index]["updatedDate"] = Date().timeIntervalSince1970

        store["tasks"] = tasks
        saveStore(store)
        return hadBacklogTag
    }

    func pinTask(id: Int) -> Bool {
        var store = loadStore()
        var tasks = store["tasks"] as? [[String: Any]] ?? []
        let index = tasks.firstIndex { $0["id"] as? Int == id }

        guard let index = index else { return false }

        let pinTags = getPinTags()
        guard !pinTags.isEmpty else {
            print("Error: no pinTags configured. Set with 'task config pinTags #tag'")
            return false
        }

        var tags = tasks[index]["tags"] as? [String] ?? []

        // Check if task has any pin tags
        let hasPinTag = tags.contains(where: { pinTags.contains($0) })

        if hasPinTag {
            // Remove all pin tags
            tags = tags.filter { !pinTags.contains($0) }
        } else {
            // Add first pin tag
            tags.append(pinTags[0])
        }

        if tags.isEmpty {
            tasks[index].removeValue(forKey: "tags")
        } else {
            tasks[index]["tags"] = tags
        }
        tasks[index]["updatedDate"] = Date().timeIntervalSince1970

        store["tasks"] = tasks
        saveStore(store)
        return true
    }

    func getTask(id: Int) -> Task? {
        let store = loadStore()
        let tasks = store["tasks"] as? [[String: Any]] ?? []

        let taskDict = tasks.first { $0["id"] as? Int == id }
        guard let taskDict = taskDict else { return nil }

        var task = Task(
            id: taskDict["id"] as? Int ?? 0,
            title: taskDict["title"] as? String ?? "",
            description: taskDict["description"] as? String ?? "",
            tags: taskDict["tags"] as? [String] ?? []
        )
        task.completed = taskDict["completed"] as? Bool ?? false
        task.createdDate = taskDict["createdDate"] as? Double ?? task.createdDate
        task.completedDate = taskDict["completedDate"] as? Double
        task.updatedDate = taskDict["updatedDate"] as? Double
        return task
    }

    private func sortUncompleted(_ tasks: [Task]) -> [Task] {
        return tasks.sorted { taskA, taskB in
            if taskA.createdDate == 0.0 && taskB.createdDate == 0.0 {
                return taskA.id < taskB.id
            }
            if taskA.createdDate == 0.0 {
                return false
            }
            if taskB.createdDate == 0.0 {
                return true
            }
            return taskA.createdDate < taskB.createdDate
        }
    }

    private func sortCompleted(_ tasks: [Task]) -> [Task] {
        return tasks.sorted { taskA, taskB in
            if taskA.completedDate == nil && taskB.completedDate == nil {
                return taskA.id < taskB.id
            }
            if taskA.completedDate == nil {
                return false
            }
            if taskB.completedDate == nil {
                return true
            }
            return taskA.completedDate! > taskB.completedDate!
        }
    }

    private func sortTasks(_ tasks: [Task], by field: String) -> [Task] {
        switch field {
        case "completed":
            let uncompleted = sortUncompleted(tasks.filter { !$0.completed })
            let completed = sortCompleted(tasks.filter { $0.completed })
            return uncompleted + completed
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
