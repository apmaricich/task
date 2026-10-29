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

// MARK: - Help Display

func showHelp() {
    print("Usage: task [COMMAND] [OPTIONS]")
    print("")
    print("Commands:")
    print("  init                    Initialize the task store")
    print("  list, ls                List all tasks")
    print("  list <ID>               Show details for a specific task")
    print("  add                     Add a new task")
    print("  update <ID>             Update a task")
    print("  delete <ID>             Delete a task")
    print("  detail <ID>             Show task details")
    print("  done <ID>               Mark a task as completed")
    print("  complete <ID>           Mark a task as completed")
    print("  config <key> <value>    Update configuration")
    print("")
    print("Options:")
    print("  --title, -t <title>     Task title")
    print("  --description, -d <desc> Task description")
    print("  --help, -h              Show this help message")
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
            if tasks.isEmpty {
                print("No tasks found.")
            } else {
            let uncompletedCount = tasks.filter { !$0.completed }.count
            let completedCount = tasks.filter { $0.completed }.count
            let yellow = "\u{1b}[33m"
            let green = "\u{1b}[32m"
            let cyan = "\u{1b}[36m"
            let reset = "\u{1b}[0m"
            print("Tasks: (\(yellow)\(uncompletedCount)\(reset), \(green)\(completedCount)\(reset))")
            print(String(repeating: "-", count: 13))

            let sortField = store.getSortField()
            let displayLimit = store.getDisplayLimit()
            let tagDisplayLimit = store.getTagDisplayLimit()

            func formatTags(_ tags: [String]) -> String {
                if tags.isEmpty { return "" }
                var displayTags = tags
                if tagDisplayLimit > 0 && tags.count > tagDisplayLimit {
                    displayTags = Array(tags.prefix(tagDisplayLimit))
                    return " \(cyan)" + displayTags.joined(separator: " ") + " ...\(reset)"
                }
                return " \(cyan)" + displayTags.joined(separator: " ") + "\(reset)"
            }

            if sortField == "completed" {
                // Split into completed and uncompleted, apply limit to each
                let uncompleted = tasks.filter { !$0.completed }
                let completed = tasks.filter { $0.completed }

                var displayedUncompleted = uncompleted
                var displayedCompleted = completed
                if displayLimit > 0 {
                    displayedUncompleted = Array(uncompleted.prefix(displayLimit))
                    displayedCompleted = Array(completed.prefix(displayLimit))
                }

                // Display uncompleted tasks
                for task in displayedUncompleted {
                    let tagStr = formatTags(task.tags)
                    if showDescription {
                        print("  [ ] #\(task.id) \(task.title)\(tagStr) - \(task.description)")
                    } else {
                        print("  [ ] #\(task.id) \(task.title)\(tagStr)")
                    }
                }
                if uncompleted.count > displayedUncompleted.count {
                    print("  ...")
                }

                // Separator
                if !displayedUncompleted.isEmpty && !displayedCompleted.isEmpty {
                    print("")
                }

                // Display completed tasks
                for task in displayedCompleted {
                    let tagStr = formatTags(task.tags)
                    if showDescription {
                        print("  [x] #\(task.id) \(task.title)\(tagStr) - \(task.description)")
                    } else {
                        print("  [x] #\(task.id) \(task.title)\(tagStr)")
                    }
                }
                if completed.count > displayedCompleted.count {
                    print("  ...")
                }
            } else {
                // Normal display with limit
                var displayedTasks = tasks
                if displayLimit > 0 {
                    displayedTasks = Array(tasks.prefix(displayLimit))
                }

                for task in displayedTasks {
                    let status = task.completed ? "[x]" : "[ ]"
                    let tagStr = formatTags(task.tags)
                    if showDescription {
                        print("  \(status) #\(task.id) \(task.title)\(tagStr) - \(task.description)")
                    } else {
                        print("  \(status) #\(task.id) \(task.title)\(tagStr)")
                    }
                }

                if displayLimit > 0 && tasks.count > displayedTasks.count {
                    print("  ...")
                }
            }
        }
        }

    case "add":
        let titleProvided = args["--title"] != nil
        let title = args["--title"] ?? prompt("Title: ")

        // Parse tags
        var tags: [String] = []
        if let tagStr = args["--tag"] {
            tags = tagStr.split(separator: ",").map {
                let tag = $0.trimmingCharacters(in: .whitespaces)
                if !tag.hasPrefix("#") {
                    print("Error: tag '\(tag)' must be prefixed with '#'")
                    exit(1)
                }
                return tag
            }
        }

        if titleProvided {
            // Title provided, don't prompt for description
            let description = args["--description"] ?? ""
            let task = store.add(title: title, description: description, tags: tags)
            print("Added task #\(task.id): \(task.title)")
        } else {
            // No title provided, prompt for both
            let description = prompt("Description: ")
            let task = store.add(title: title, description: description, tags: tags)
            print("Added task #\(task.id): \(task.title)")
        }

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
            updateTags = tagStr.split(separator: ",").map {
                let tag = $0.trimmingCharacters(in: .whitespaces)
                if !tag.hasPrefix("#") {
                    print("Error: tag '\(tag)' must be prefixed with '#'")
                    exit(1)
                }
                return tag
            }
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
