import Foundation

// MARK: - Display Formatting

func printHeader(_ title: String, separatorSize: Int = 13) {
    print(title)
    print(String(repeating: "-", count: separatorSize))
}

func printAsciiTable(rows: [[String]], headers: [String]) {
    guard !rows.isEmpty && !headers.isEmpty else { return }

    // Calculate column widths
    var columnWidths = headers.map { $0.count }
    for row in rows {
        for (index, cell) in row.enumerated() where index < columnWidths.count {
            columnWidths[index] = max(columnWidths[index], cell.count)
        }
    }

    // Print header
    printTableBorder(columnWidths: columnWidths)
    printTableRow(headers, columnWidths: columnWidths, isHeader: true)
    printTableBorder(columnWidths: columnWidths)

    // Print rows
    for row in rows {
        printTableRow(row, columnWidths: columnWidths, isHeader: false)
    }

    // Print footer
    printTableBorder(columnWidths: columnWidths)
}

private func printTableBorder(columnWidths: [Int]) {
    let border = "+" + columnWidths.map { String(repeating: "-", count: $0 + 2) }.joined(separator: "+") + "+"
    print(border)
}

private func printTableRow(_ row: [String], columnWidths: [Int], isHeader: Bool) {
    var cells = row
    // Pad row with empty cells if necessary
    while cells.count < columnWidths.count {
        cells.append("")
    }

    let formatted = cells.enumerated().map { (index, cell) in
        let width = columnWidths[index]
        let padding = " ".padding(toLength: width - cell.count, withPad: " ", startingAt: 0)
        return " \(cell)\(padding) "
    }

    print("|" + formatted.joined(separator: "|") + "|")
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

// MARK: - List Display

struct TaskDisplayOptions {
    let sortField: String
    let displayLimit: Int
    let tagDisplayLimit: Int
    let pinTags: [String]
    let showDescription: Bool
}

func formatTaskTags(tags: [String], tagDisplayLimit: Int) -> String {
    if tags.isEmpty { return "" }
    let cyan = "\u{1b}[36m"
    let reset = "\u{1b}[0m"
    var displayTags = tags
    if tagDisplayLimit > 0 && tags.count > tagDisplayLimit {
        displayTags = Array(tags.prefix(tagDisplayLimit))
        return " \(cyan)" + displayTags.joined(separator: " ") + " ...\(reset)"
    }
    return " \(cyan)" + displayTags.joined(separator: " ") + "\(reset)"
}

func displayTaskLine(task: Task, pinStr: String, options: TaskDisplayOptions) {
    let status = task.completed ? "[x]" : "[ ]"
    let tagStr = formatTaskTags(tags: task.tags, tagDisplayLimit: options.tagDisplayLimit)
    if options.showDescription {
        print("  \(pinStr)\(status) #\(task.id) \(task.title)\(tagStr) - \(task.description)")
    } else {
        print("  \(pinStr)\(status) #\(task.id) \(task.title)\(tagStr)")
    }
}

func displayTasksSection(_ tasksToShow: [Task], showPin: Bool, options: TaskDisplayOptions) {
    let red = "\u{1b}[31m"
    let reset = "\u{1b}[0m"
    let pinStr = showPin ? "\(red)* \(reset)" : ""

    if options.sortField == "completed" {
        let uncompleted = tasksToShow.filter { !$0.completed }
        let completed = tasksToShow.filter { $0.completed }

        var displayedUncompleted = uncompleted
        var displayedCompleted = completed
        if options.displayLimit > 0 {
            displayedUncompleted = Array(uncompleted.prefix(options.displayLimit))
            displayedCompleted = Array(completed.prefix(options.displayLimit))
        }

        for task in displayedUncompleted {
            displayTaskLine(task: task, pinStr: pinStr, options: options)
        }
        if uncompleted.count > displayedUncompleted.count {
            print("  ...")
        }

        if !displayedUncompleted.isEmpty && !displayedCompleted.isEmpty {
            print("")
        }

        for task in displayedCompleted {
            displayTaskLine(task: task, pinStr: pinStr, options: options)
        }
        if completed.count > displayedCompleted.count {
            print("  ...")
        }
    } else {
        var displayedTasks = tasksToShow
        if options.displayLimit > 0 {
            displayedTasks = Array(tasksToShow.prefix(options.displayLimit))
        }

        for task in displayedTasks {
            displayTaskLine(task: task, pinStr: pinStr, options: options)
        }

        if options.displayLimit > 0 && tasksToShow.count > displayedTasks.count {
            print("  ...")
        }
    }
}

func displayTaskList(tasks: [Task], options: TaskDisplayOptions) {
    // Separate pinned tasks from the rest
    let pinnedTasks = tasks.filter { task in
        !options.pinTags.isEmpty && task.tags.contains(where: { options.pinTags.contains($0) })
    }
    let unpinnedTasks = tasks.filter { task in
        pinnedTasks.contains(where: { $0.id == task.id }) == false
    }

    if !pinnedTasks.isEmpty {
        displayTasksSection(pinnedTasks, showPin: true, options: options)
        print("")
    }

    if !unpinnedTasks.isEmpty {
        displayTasksSection(unpinnedTasks, showPin: false, options: options)
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
    print("  view <tag>              View tasks by tag")
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
