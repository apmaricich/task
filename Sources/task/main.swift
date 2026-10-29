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

    // Print top separator
    print(String(repeating: "-", count: maxWidth))

    // Determine completion status
    let status = task.completed ? "[x]" : "[ ]"

    // Format title line with ID
    let titleLine = "\(status) \(task.title)"
    let idWidth = String(task.id).count
    let titleWidth = titleLine.count + 2
    let idOffset = maxWidth - idWidth
    let separator = String(repeating: " ", count: max(0, idOffset - titleWidth))
    print("\(titleLine)\(separator)#\(task.id)")

    // Print separator line
    print(String(repeating: "-", count: maxWidth))

    // Format dates
    let createdFormatted = formatDate(task.createdDate)
    let updatedFormatted = task.updatedDate != nil ? formatDate(task.updatedDate!) : "N/A"
    let completedFormatted = task.completedDate != nil ? formatDate(task.completedDate!) : "N/A"

    print("C: \(createdFormatted)\tU: \(updatedFormatted)\tD: \(completedFormatted)")

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
} else if let command = args["command"] {
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
            let sortField = store.getSortField()
            let displayLimit = store.getDisplayLimit()

            if sortField == "completed" && displayLimit > 0 {
                // Split into completed and uncompleted, apply limit to each
                let uncompleted = tasks.filter { !$0.completed }
                let completed = tasks.filter { $0.completed }

                let displayedUncompleted = Array(uncompleted.prefix(displayLimit))
                let displayedCompleted = Array(completed.prefix(displayLimit))

                // Display uncompleted tasks
                for task in displayedUncompleted {
                    if showDescription {
                        print("[ ] #\(task.id) \(task.title) - \(task.description)")
                    } else {
                        print("[ ] #\(task.id) \(task.title)")
                    }
                }
                if uncompleted.count > displayedUncompleted.count {
                    print("...")
                }

                // Separator
                if !displayedUncompleted.isEmpty && !displayedCompleted.isEmpty {
                    print("")
                }

                // Display completed tasks
                for task in displayedCompleted {
                    if showDescription {
                        print("[x] #\(task.id) \(task.title) - \(task.description)")
                    } else {
                        print("[x] #\(task.id) \(task.title)")
                    }
                }
                if completed.count > displayedCompleted.count {
                    print("...")
                }
            } else {
                // Normal display with limit
                var displayedTasks = tasks
                if displayLimit > 0 {
                    displayedTasks = Array(tasks.prefix(displayLimit))
                }

                for task in displayedTasks {
                    let status = task.completed ? "[x]" : "[ ]"
                    if showDescription {
                        print("\(status) #\(task.id) \(task.title) - \(task.description)")
                    } else {
                        print("\(status) #\(task.id) \(task.title)")
                    }
                }

                if displayLimit > 0 && tasks.count > displayedTasks.count {
                    print("...")
                }
            }
        }
        }

    case "add":
        let titleProvided = args["--title"] != nil
        let title = args["--title"] ?? prompt("Title: ")

        if titleProvided {
            // Title provided, don't prompt for description
            let description = args["--description"] ?? ""
            let task = store.add(title: title, description: description)
            print("Added task #\(task.id): \(task.title)")
        } else {
            // No title provided, prompt for both
            let description = prompt("Description: ")
            let task = store.add(title: title, description: description)
            print("Added task #\(task.id): \(task.title)")
        }

    case "update":
        guard let idStr = args["id"], let id = Int(idStr) else {
            print("Error: task ID is required")
            exit(1)
        }
        let title = args["--title"]
        let description = args["--description"]

        if title == nil && description == nil {
            print("Error: at least one field (title or description) is required")
            exit(1)
        }

        if store.update(id: id, title: title, description: description) {
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
                for (key, value) in config.sorted(by: { $0.key < $1.key }) {
                    print("\(key)\t\t\(value)")
                }
            }
        }

    default:
        print("Error: unknown command '\(command)'")
        exit(1)
    }
} else {
    showHelp()
}
