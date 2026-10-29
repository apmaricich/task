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

// MARK: - Help Display

func showHelp() {
    print("Usage: task [COMMAND] [OPTIONS]")
    print("")
    print("Commands:")
    print("  init                    Initialize the task store")
    print("  list, ls                List all tasks")
    print("  add                     Add a new task")
    print("  update <ID>             Update a task")
    print("  delete <ID>             Delete a task")
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

    case "add":
        guard let title = args["--title"] else {
            print("Error: --title is required")
            exit(1)
        }
        let description = args["--description"] ?? ""
        let task = store.add(title: title, description: description)
        print("Added task #\(task.id): \(task.title)")

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
        guard let key = args["id"] else {
            print("Error: config key is required")
            exit(1)
        }
        guard let value = args["value"] else {
            print("Error: config value is required")
            exit(1)
        }
        store.setConfig(key: key, value: value)

    default:
        print("Error: unknown command '\(command)'")
        exit(1)
    }
} else {
    showHelp()
}