import Foundation

// MARK: - Argument Parsing

func parseArguments() -> [String: String] {
    var args = CommandLine.arguments
    args.removeFirst() // Remove executable name

    var result: [String: String] = [:]

    while !args.isEmpty {
        let arg = args.removeFirst()

        if arg == "--title" || arg == "-t" {
            if !args.isEmpty {
                result["--title"] = args.removeFirst()
            }
        } else if arg == "--description" || arg == "-d" {
            if result["command"] == "list" || args.isEmpty {
                result[arg] = ""
            } else {
                result["--description"] = args.removeFirst()
            }
        } else if arg == "--tag" || arg == "-T" {
            if !args.isEmpty {
                let tagValue = args.removeFirst()
                if result["--tag"] == nil {
                    result["--tag"] = tagValue
                } else {
                    result["--tag"] = result["--tag"]! + "," + tagValue
                }
            }
        } else if arg == "--help" || arg == "-h" {
            result["--help"] = ""
        } else if result["command"] == nil {
            result["command"] = arg
        } else if result["command"] == "add" && result["--title"] == nil {
            result["--title"] = arg
        } else if result["command"] == "config" && result["id"] == nil {
            result["id"] = arg
        } else if result["command"] == "config" && result["id"] != nil && result["value"] == nil {
            result["value"] = arg
        } else if result["command"] == "command" && result["id"] == nil {
            result["id"] = arg
        } else {
            result["id"] = arg
        }
    }

    return result
}

// MARK: - Input Prompting

func prompt(_ message: String) -> String {
    print(message, terminator: "")
    let input = readLine() ?? ""
    return input
}

// MARK: - Tag Parsing

func parseTags(_ tagsStr: String) -> [String] {
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

// MARK: - Config Command

func handleConfig(store: TaskStore, args: [String: String]) {
    if let key = args["id"] {
        if let value = args["value"] {
            let config = store.getConfig()
            let listKeys = config["lists"] as? [String] ?? []

            if let currentValue = config[key] as? [String] {
                // Current value is a list - toggle
                if currentValue.contains(value) {
                    var newList = currentValue
                    newList.removeAll(where: { $0 == value })
                    store.setConfig(key: key, value: newList)
                } else {
                    var newList = currentValue
                    newList.append(value)
                    store.setConfig(key: key, value: newList)
                }
            } else if listKeys.contains(key) {
                // Key is in the lists config but doesn't exist yet - create list
                store.setConfig(key: key, value: [value])
            } else {
                // Key doesn't exist or current value is not a list - set directly
                store.setConfig(key: key, value: value)
            }
        } else {
            print("Error: value is required for '\(key)'")
            exit(1)
        }
    } else {
        let config = store.getConfig()
        if config.isEmpty {
            print("No configuration set.")
        } else {
            let headers = ["Key", "Value"]
            let rows: [[String]] = config.sorted(by: { $0.key < $1.key }).map { key, value in
                let valueStr: String
                if let arr = value as? [String] {
                    valueStr = arr.joined(separator: ", ")
                } else if let int = value as? Int {
                    valueStr = "\(int)"
                } else if let bool = value as? Bool {
                    valueStr = "\(bool)"
                } else {
                    valueStr = "\(value)"
                }
                return [key, valueStr]
            }
            printAsciiTable(rows: rows, headers: headers)
        }
    }
}

// MARK: - View Command

func handleView(store: TaskStore, args: [String: String]) {
    guard let tagName = args["id"] else {
        print("Error: tag name is required")
        exit(1)
    }

    let tag = tagName.hasPrefix("#") ? tagName : "#" + tagName
    let viewTasks = store.list().filter { task in
        task.tags.contains(tag)
    }

    let capitalizedTag = tagName.capitalized
    let viewCount = viewTasks.count
    printHeader("\(capitalizedTag): (\(viewCount))")

    if viewTasks.isEmpty {
        print("  No tasks.")
    } else {
        let sortField = store.getSortField()
        let displayLimit = store.getDisplayLimit()
        let tagDisplayLimit = store.getTagDisplayLimit()
        let pinTags = store.getPinTags()
        let viewOptions = TaskDisplayOptions(
            sortField: sortField,
            displayLimit: displayLimit,
            tagDisplayLimit: tagDisplayLimit,
            pinTags: pinTags,
            showDescription: false
        )
        displayTaskList(tasks: viewTasks, options: viewOptions)
    }
}

// MARK: - Add Task with Prompt

func addTaskWithPrompt(_ store: TaskStore, args: [String: String]) {
    let titleProvided = args["--title"] != nil
    let title = args["--title"] ?? prompt("Title: ")

    var tags: [String] = []
    if let tagStr = args["--tag"] {
        tags = store.parseTags(tagStr)
    }

    if titleProvided {
        let description = args["--description"] ?? ""
        let task = store.add(title: title, description: description, tags: tags)
        print("Added task #\(task.id): \(task.title)")
    } else {
        let description = prompt("Description: ")

        if tags.isEmpty {
            let tagInput = prompt("Tags (comma-separated, prefix with #): ")
            if !tagInput.isEmpty {
                tags = store.parseTags(tagInput)
            }
        }

        let task = store.add(title: title, description: description, tags: tags)
        print("Added task #\(task.id): \(task.title)")
    }
}

// MARK: - Main

let store = TaskStore()
let args = parseArguments()

// Get configured commands
let commands = store.getCommands()

if args["--help"] != nil {
    showHelp()
} else {
    let command = args["command"] ?? "list"
    switch command {
    case "init":
        store.initStore()

    case "ready":
        guard let idStr = args["id"], let id = Int(idStr) else {
            print("Error: task ID is required")
            exit(1)
        }

        if store.readyTask(id: id) {
            print("Task #\(id) has been removed from the backlog")
        } else {
            print("Error: task #\(id) not found")
            exit(1)
        }

    case "pin":
        guard let idStr = args["id"], let id = Int(idStr) else {
            print("Error: task ID is required")
            exit(1)
        }

        if store.pinTask(id: id) {
            print("Task #\(id) toggled pin status")
        } else {
            print("Error: task #\(id) not found")
            exit(1)
        }

    case "view":
        handleView(store: store, args: args)

    case "list", "ls":
        if let idStr = args["id"], let id = Int(idStr) {
            // Show detailed info for a specific task
            if let task = store.getTask(id: id) {
                displayTaskDetail(task: task)
            } else {
                print("Error: task #\(id) not found")
                exit(1)
            }
        } else {
            let showDescription = args["--description"] != nil || args["-d"] != nil
            let tasks = store.list()
            let yellow = "\u{1b}[33m"
            let green = "\u{1b}[32m"
            let red = "\u{1b}[31m"
            let reset = "\u{1b}[0m"

            let sortField = store.getSortField()
            let displayLimit = store.getDisplayLimit()
            let tagDisplayLimit = store.getTagDisplayLimit()
            let pinTags = store.getPinTags()
            let backlogTags = store.getBacklogTags()
            let showBacklog = store.getShowBacklog()
            let showCompleted = store.getShowCompleted()

            // Filter out backlog tasks unless showBacklog is true
            let nonBacklogTasks = tasks.filter { task in
                if backlogTags.isEmpty {
                    return true
                }
                let hasBacklogTag = task.tags.contains(where: { backlogTags.contains($0) })
                return !hasBacklogTag || showBacklog
            }

            let nonBacklogUncompleted = nonBacklogTasks.filter { !$0.completed }.count
            let nonBacklogCompleted = nonBacklogTasks.filter { $0.completed }.count
            let backlogCount = tasks.count - nonBacklogTasks.count

            // Filter out completed tasks if showCompleted is false
            var tasksToShow = nonBacklogTasks
            if !showCompleted {
                tasksToShow = tasksToShow.filter { !$0.completed }
            }

            // Separate pinned tasks from the rest
            let pinnedTasks = tasksToShow.filter { task in
                !pinTags.isEmpty && task.tags.contains(where: { pinTags.contains($0) })
            }
            let unpinnedTasks = tasksToShow.filter { task in
                pinnedTasks.contains(where: { $0.id == task.id }) == false
            }

            // Print header with pin count and backlog count
            let pinCount = pinnedTasks.count
            let headerTitle = "Tasks: (\(yellow)\(nonBacklogUncompleted)\(reset), \(green)\(nonBacklogCompleted)\(reset))"
            let backlogSuffix = backlogCount > 0 ? " \(red)b\(backlogCount)\(reset)" : ""
            if pinCount > 0 {
                printHeader(headerTitle + " \(red)*\(pinCount)\(reset)\(backlogSuffix)")
            } else {
                printHeader(headerTitle + backlogSuffix)
            }

            if tasksToShow.isEmpty {
                print("  No tasks.")
            } else {
                let listOptions = TaskDisplayOptions(
                    sortField: sortField,
                    displayLimit: displayLimit,
                    tagDisplayLimit: tagDisplayLimit,
                    pinTags: pinTags,
                    showDescription: showDescription
                )
                displayTaskList(tasks: tasksToShow, options: listOptions)
            }
        }

    case "track":
        let titleProvided = args["--title"] != nil
        let title = args["--title"] ?? prompt("Title: ")

        // Parse tags
        var tags: [String] = []
        if let tagStr = args["--tag"] {
            tags = store.parseTags(tagStr)
        }

        if titleProvided {
            let description = args["--description"] ?? ""
            let task = store.track(title: title, description: description, tags: tags)
            print("Tracked #\(task.id): \(task.title)")
        } else {
            let description = prompt("Description: ")
            let task = store.track(title: title, description: description, tags: tags)
            print("Tracked #\(task.id): \(task.title)")
        }

    case "add":
        addTaskWithPrompt(store, args: args)

    case "idea":
        addTaskWithPrompt(store, args: args)
        let backlogTags = store.getConfigTags("backlogTags")
        if backlogTags.isEmpty {
            print("Error: no backlogTags configured. Set with 'task config backlogTags #tag'")
            exit(1)
        }
        let allTasks = store.list()
        guard let newestTask = allTasks.max(by: { $0.id < $1.id }) else {
            exit(1)
        }
        // Add backlog tag while preserving any user-provided tags
        let updatedTags = Array(Set(newestTask.tags + [backlogTags[0]]))
        store.update(id: newestTask.id, title: newestTask.title, description: newestTask.description, tags: updatedTags)

    case "update":
        guard let idStr = args["id"], let id = Int(idStr) else {
            print("Error: task ID is required")
            exit(1)
        }
        let title = args["--title"]
        let description = args["--description"]

        // Parse tags
        var updateTags: [String]?
        if let tagStr = args["--tag"] {
            updateTags = store.parseTags(tagStr)
        }

        if title == nil && description == nil && updateTags == nil {
            print("Error: at least one field (title, description, or tag) is required")
            exit(1)
        }

        if store.update(id: id, title: title, description: description, tags: updateTags) {
            print("Updated task #\(id)")
        } else {
            print("Error: task #\(id) not found")
            exit(1)
        }

    case "delete":
        guard let idStr = args["id"], let id = Int(idStr) else {
            print("Error: task ID is required")
            exit(1)
        }

        if store.delete(id: id) {
            print("Deleted task #\(id)")
        } else {
            print("Error: task #\(id) not found")
            exit(1)
        }

    case "done", "complete":
        guard let idStr = args["id"], let id = Int(idStr) else {
            print("Error: task ID is required")
            exit(1)
        }

        if store.done(id: id) {
            print("Completed task #\(id)")
        } else {
            print("Error: task #\(id) not found")
            exit(1)
        }

    case "config":
        handleConfig(store: store, args: args)

    case "doctor":
        let filePath = "tasks.json"
        if !FileManager.default.fileExists(atPath: filePath) {
            print("❌ File not found: \(filePath)")
            exit(1)
        }

        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
            let parsed = try JSONSerialization.jsonObject(with: data, options: [])

            if let obj = parsed as? [String: Any] {
                print("✅ Valid JSON")

                if let tasks = obj["tasks"] as? [[String: Any]] {
                    print("✅ Tasks array: \(tasks.count) task(s)")
                } else if let tasks = obj["tasks"] {
                    print("⚠️ 'tasks' exists but is not an array: \(type(of: tasks))")
                } else {
                    print("⚠️ Missing 'tasks' field")
                }

                if let config = obj["config"] as? [String: Any] {
                    print("✅ Config object found")

                    if let sort = config["sort"] as? String {
                        print("✅ sort: \(sort)")
                    } else if config["sort"] != nil {
                        print("⚠️ 'sort' is not a string: \(type(of: config["sort"]!))")
                    } else {
                        print("⚠️ Missing 'sort' config")
                    }

                    // Validate pinTags and backlogTags are arrays
                    for key in ["pinTags", "backlogTags"] {
                        if let value = config[key] {
                            if let tags = value as? [String] {
                                print("✅ \(key): \(tags.count) tag(s)")
                            } else {
                                print("⚠️ '\(key)' is not an array: \(type(of: value))")
                            }
                        }
                    }
                } else if let config = obj["config"] {
                    print("⚠️ 'config' exists but is not an object: \(type(of: config))")
                } else {
                    print("⚠️ Missing 'config' field")
                }
            } else {
                print("⚠️ JSON is not an object")
            }
        } catch {
            print("❌ Invalid JSON: \(error)")
            exit(1)
        }

    default:
        if let id = Int(command) {
            if let task = store.getTask(id: id) {
                displayTaskDetail(task: task)
            } else {
                print("Error: task #\(id) not found")
                exit(1)
            }
        } else if commands.contains(command) {
            addTaskWithPrompt(store, args: args)
            let allTasks = store.list()
            let maxId = allTasks.map { $0.id }.max()!
            let task = allTasks.first { $0.id == maxId }!
            let tagToApply = "#" + command
            let updatedTags = task.tags + [tagToApply]
            store.update(id: task.id, title: task.title, description: task.description, tags: updatedTags)
        } else {
            print("Error: unknown command '\(command)'")
            exit(1)
        }
    }
}
