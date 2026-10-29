# Task Manager

A simple command-line task manager built with Swift and Swift Package Manager.

## Features

- Add, update, delete, and complete tasks
- Multiple sorting options (by completion status, title, description, ID)
- Display limits with pagination indicators
- Tags for organizing tasks
- Pin tasks to the top of the list
- Backlog support with configurable tags
- Persistent storage using JSON files
- Comprehensive unit test coverage

## Installation

Clone the repository and build:

```bash
git clone <repository-url>
cd task
swift build
```

## Usage

Initialize a new task store:

```bash
./task init
```

### Listing Tasks

```bash
./task list
# Or simply run with no arguments:
./task
```

With display limit:

```bash
./task config displayLimit 5
./task ls
```

### Quick Task Detail

View a specific task by providing its ID directly:

```bash
./task 8
```

### Adding Tasks

```bash
./task add "Task title"
./task add "Task title" --description "Task details"
```

Add tags to tasks:

```bash
./task add "Task title" --tag "#important"
./task add "Task title" --tag "#important" --tag "#work"
```

Tags must be prefixed with `#`.

### Updating Tasks

```bash
./task update <ID> --title "New title"
./task update <ID> --description "New description"
./task update <ID> --tag "#newtag"
```

### Deleting and Completing Tasks

```bash
./task delete <ID>
./task done <ID>
# Or:
./task complete <ID>
```

## Configuration

### Sorting

Configure how tasks are sorted when listing:

```bash
./task config sort completed  # Default
./task config sort title
./task config sort description
./task config sort id
```

When sorting by `completed`, uncompleted tasks appear first (sorted by creation date), followed by completed tasks (sorted by completion date, newest first).

### Display Limit

Limit the number of tasks shown:

```bash
./task config displayLimit 5  # Show max 5 tasks
./task config displayLimit 0  # Show all tasks (default)
```

When sorting by `completed`, the limit applies separately to completed and uncompleted tasks.

### Tag Display Limit

Limit the number of tags shown per task:

```bash
./task config tagDisplayLimit 2  # Show max 2 tags per task
./task config tagDisplayLimit 0  # Show all tags (default)
```

### Pin Tags

Pin specific tasks to the top of the list by configuring tag(s) that indicate pinned tasks:

```bash
./task config pinTags "#important"
./task config pinTags "#important,#urgent"  # Multiple tags
```

Tasks with any of the configured pin tags will appear in a separate pinned section at the top of the list, marked with a red asterisk.

### Pinning Tasks

Pin or unpin a task by ID. If the task has no pin tags, the first pin tag from the configured list is applied. If it already has a pin tag, all pin tags are removed:

```bash
./task pin <ID>
```

### Backlog Tags

Hide tasks in the regular list by configuring backlog tags:

```bash
./task config backlogTags "#backlog"
./task config backlogTags "#backlog,#someday"
```

Tasks with backlog tags are hidden by default. Show them in the regular list with:

```bash
./task config showBacklog true
```

View only backlog tasks:

```bash
./task backlog
```

## Help

```bash
./task --help
```

## Testing

Run the test suite:

```bash
swift test
```

## Development

This project uses SwiftLint for code quality. Run linting with:

```bash
swiftlint
```

## License

MIT License