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

// MARK: - Task Detail Display

func displayTaskDetail(task: Task) {
    let maxWidth = 80

    // Print top box
    print("+\(String(repeating: "-", count: maxWidth))+")

    // Determine completion status
    let status = task.completed ? "[x]" : "[ ]"

    // Format title line with ID right-aligned
    let titleText = "\(status) \(task.title)"
    let idText = "#\(task.id)"
    let contentLength = titleText.count + idText.count + 1  // +1 for space
    let padding = String(repeating: " ", count: max(0, maxWidth - contentLength - 2))
    print("| \(titleText) \(padding)\(idText) |")

    // Print bottom box
    print("+\(String(repeating: "-", count: maxWidth))+")

    // Format dates
    let createdFormatted = formatDate(task.createdDate)
    let updatedFormatted = task.updatedDate != nil ? formatDate(task.updatedDate!) : "N/A"
    let completedFormatted = task.completedDate != nil ? formatDate(task.completedDate!) : "N/A"

    print("  C: \(createdFormatted)\tU: \(updatedFormatted)\tD: \(completedFormatted)")

    // Print tags
    if !task.tags.isEmpty {
        let cyan = "\u{1b}[36m"
        let reset = "\u{1b}[0m"
        print("  \(cyan)\(task.tags.joined(separator: " "))\(reset)")
    }

    // Print description with word wrapping
    if task.description.isEmpty {
        print("")
        print("  No description provided.")
    } else {
        print("")
        printWrappedText(task.description, maxWidth: maxWidth, indent: "  ")
    }
}

func formatDate(_ timestamp: Double) -> String {
    let date = Date(timeIntervalSince1970: timestamp)
    let formatter = DateFormatter()
    formatter.dateFormat = "MM/dd/yy h:mm a"
    return formatter.string(from: date)
}

func printWrappedText(_ text: String, maxWidth: Int, indent: String) {
    let words = text.split(separator: " ", omittingEmptySubsequences: false)
    var line = ""

    for word in words {
        if line.isEmpty {
            line = word.description
        } else if line.count + 1 + word.count <= maxWidth - indent.count {
            line = line + " " + word.description
        } else {
            print(indent + line)
            line = word.description
        }
    }

    if !line.isEmpty {
        print(indent + line)
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

// MARK: - Help Display

func showHelp() {
    print("Usage: task [COMMAND] [OPTIONS]")
    print("")
    print("Commands:")
    print("  init                    Initialize the task store")
    print("  list, ls                List all tasks")
    print("  list <ID>               Show details for a specific task")
    print("  add                     Add a new task")
    print("  track                   Track time spent (add and complete immediately)")
    print("  update <ID>             Update a task")
    print("  delete <ID>             Delete a task")
    print("  done <ID>               Mark a task as completed")
    print("  complete <ID>           Mark a task as completed")
    print("  pin <ID>                Pin or unpin a task")
    print("  ready <ID>              Remove a task from the backlog")
    print("  backlog                 View backlog tasks")
    print("  config <key> <value>    Update configuration")
    print("")
    print("Options:")
    print("  --title, -t <title>     Task title")
    print("  --description, -d <desc> Task description")
    print("  --tag, -T <tag>         Tag (must be prefixed with #)")
    print("  --help, -h              Show this help message")
    print("")
    print("Configuration Keys:")
    print("  sort                completed|title|description|id")
    print("  displayLimit        Max tasks to show (0 for all)")
    print("  tagDisplayLimit     Max tags to show per task (0 for all)")
    print("  pinTags             Tags that pin tasks to top (comma-separated)")
    print("  backlogTags         Tags that mark tasks as backlog (comma-separated)")
    print("  showBacklog         true|false - show backlog tasks in list")
    print("  showCompleted       true|false - show completed tasks in list")
}

// MARK: - Main

let store = TaskStore()
let args = parseArguments()

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

    case "backlog":
        let backlogTags = store.getBacklogTags()
        let backlogTasks = store.list().filter { task in
            if backlogTags.isEmpty { return false }
            return task.tags.contains(where: { backlogTags.contains($0) })
        }

        let backlogCount = backlogTasks.count
        printHeader("Backlog: (\(backlogCount))")
        if backlogTasks.isEmpty {
            print("  No tasks.")
        } else {

            let sortField = store.getSortField()
            let displayLimit = store.getDisplayLimit()
            let tagDisplayLimit = store.getTagDisplayLimit()
            let pinTags = store.getPinTags()
            let cyan = "\u{1b}[36m"
            let red = "\u{1b}[31m"
            let reset = "\u{1b}[0m"

            // Separate pinned tasks from the rest
            let pinnedTasks = backlogTasks.filter { task in
                !pinTags.isEmpty && task.tags.contains(where: { pinTags.contains($0) })
            }
            let unpinnedTasks = backlogTasks.filter { task in
                pinnedTasks.contains(where: { $0.id == task.id }) == false
            }

            func formatTags(_ tags: [String]) -> String {
                if tags.isEmpty { return "" }
                var displayTags = tags
                if tagDisplayLimit > 0 && tags.count > tagDisplayLimit {
                    displayTags = Array(tags.prefix(tagDisplayLimit))
                    return " \(cyan)" + displayTags.joined(separator: " ") + " ...\(reset)"
                }
                return " \(cyan)" + displayTags.joined(separator: " ") + "\(reset)"
            }

            func displayBacklogTaskLine(_ task: Task, pinStr: String) {
                let status = task.completed ? "[x]" : "[ ]"
                let tagStr = formatTags(task.tags)
                print("  \(pinStr)\(status) #\(task.id) \(task.title)\(tagStr)")
            }

            func displayBacklogTasks(_ tasksToShow: [Task], showPin: Bool) {
                let pinStr = showPin ? "\(red)* \(reset)" : ""

                if sortField == "completed" {
                    let uncompleted = tasksToShow.filter { !$0.completed }
                    let completed = tasksToShow.filter { $0.completed }

                    var displayedUncompleted = uncompleted
                    var displayedCompleted = completed
                    if displayLimit > 0 {
                        displayedUncompleted = Array(uncompleted.prefix(displayLimit))
                        displayedCompleted = Array(completed.prefix(displayLimit))
                    }

                    for task in displayedUncompleted {
                        displayBacklogTaskLine(task, pinStr: pinStr)
                    }
                    if uncompleted.count > displayedUncompleted.count {
                        print("  ...")
                    }

                    if !displayedUncompleted.isEmpty && !displayedCompleted.isEmpty {
                        print("")
                    }

                    for task in displayedCompleted {
                        displayBacklogTaskLine(task, pinStr: pinStr)
                    }
                    if completed.count > displayedCompleted.count {
                        print("  ...")
                    }
                } else {
                    var displayedTasks = tasksToShow
                    if displayLimit > 0 {
                        displayedTasks = Array(tasksToShow.prefix(displayLimit))
                    }

                    for task in displayedTasks {
                        displayBacklogTaskLine(task, pinStr: pinStr)
                    }

                    if displayLimit > 0 && tasksToShow.count > displayedTasks.count {
                        print("  ...")
                    }
                }
            }

            // Display pinned section at the top
            if !pinnedTasks.isEmpty {
                displayBacklogTasks(pinnedTasks, showPin: true)
                print("")
            }

            // Display unpinned tasks
            if !unpinnedTasks.isEmpty {
                displayBacklogTasks(unpinnedTasks, showPin: false)
            }
        }

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
            let cyan = "\u{1b}[36m"
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
            }

            func formatTags(_ tags: [String]) -> String {
                if tags.isEmpty { return "" }
                var displayTags = tags
                if tagDisplayLimit > 0 && tags.count > tagDisplayLimit {
                    displayTags = Array(tags.prefix(tagDisplayLimit))
                    return " \(cyan)" + displayTags.joined(separator: " ") + " ...\(reset)"
                }
                return " \(cyan)" + displayTags.joined(separator: " ") + "\(reset)"
            }

            func displayTaskLine(_ task: Task, pinStr: String) {
                let status = task.completed ? "[x]" : "[ ]"
                let tagStr = formatTags(task.tags)
                if showDescription {
                    print("  \(pinStr)\(status) #\(task.id) \(task.title)\(tagStr) - \(task.description)")
                } else {
                    print("  \(pinStr)\(status) #\(task.id) \(task.title)\(tagStr)")
                }
            }

            func displayTasks(_ tasksToShow: [Task], showPin: Bool) {
                let pinStr = showPin ? "\(red)* \(reset)" : ""

                if sortField == "completed" {
                    let uncompleted = tasksToShow.filter { !$0.completed }
                    let completed = tasksToShow.filter { $0.completed }

                    var displayedUncompleted = uncompleted
                    var displayedCompleted = completed
                    if displayLimit > 0 {
                        displayedUncompleted = Array(uncompleted.prefix(displayLimit))
                        displayedCompleted = Array(completed.prefix(displayLimit))
                    }

                    for task in displayedUncompleted {
                        displayTaskLine(task, pinStr: pinStr)
                    }
                    if uncompleted.count > displayedUncompleted.count {
                        print("  ...")
                    }

                    if !displayedUncompleted.isEmpty && !displayedCompleted.isEmpty {
                        print("")
                    }

                    for task in displayedCompleted {
                        displayTaskLine(task, pinStr: pinStr)
                    }
                    if completed.count > displayedCompleted.count {
                        print("  ...")
                    }
                } else {
                    var displayedTasks = tasksToShow
                    if displayLimit > 0 {
                        displayedTasks = Array(tasksToShow.prefix(displayLimit))
                    }

                    for task in displayedTasks {
                        displayTaskLine(task, pinStr: pinStr)
                    }

                    if displayLimit > 0 && tasksToShow.count > displayedTasks.count {
                        print("  ...")
                    }
                }
            }

        // Display pinned section at the top
        if !pinnedTasks.isEmpty {
            displayTasks(pinnedTasks, showPin: true)
            print("")
        }

        // Display unpinned tasks
        if !unpinnedTasks.isEmpty {
            displayTasks(unpinnedTasks, showPin: false)
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
        if let key = args["id"] {
            guard let value = args["value"] else {
                print("Error: config value is required")
                exit(1)
            }
            store.setConfig(key: key, value: value)
        } else {
            let config = store.getConfig()
            if config.isEmpty {
                print("No configuration set.")
            } else {
                let headers = ["Key", "Value"]
                let rows: [[String]] = config.sorted(by: { $0.key < $1.key }).map { [ $0.key, "\($0.value)" ] }
                printAsciiTable(rows: rows, headers: headers)
            }
        }

    default:
        if let id = Int(command) {
            if let task = store.getTask(id: id) {
                displayTaskDetail(task: task)
            } else {
                print("Error: task #\(id) not found")
                exit(1)
            }
        } else {
            print("Error: unknown command '\(command)'")
            exit(1)
        }
    }
}
