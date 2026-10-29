# Task Manager

A simple command-line task manager built with Swift and Swift Package Manager.

## Features

- Add, update, delete, and complete tasks
- Multiple sorting options (by completion status, title, description, ID)
- Display limits with pagination indicators
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

Add a task:

```bash
./task add "Task title" --description "Task details"
# Or simply: ./task add "Task title"
```

List tasks:

```bash
./task list
# Or: ./task ls
```

With display limit:

```bash
./task config displayLimit 5
./task ls
```

Update a task:

```bash
./task update <ID> --title "New title" --description "New description"
```

Delete a task:

```bash
./task delete <ID>
```

Mark a task as completed:

```bash
./task done <ID>
# Or: ./task complete <ID>
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