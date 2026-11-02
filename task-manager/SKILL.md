# Task Manager CLI Skill

A terminal task manager with tagging, sorting, and configuration.

## Workflow

**Always verify before completing:** Never mark a task as done without showing the results to the user first. Build, test, and demonstrate that the fix works, then present the changes for approval before running `task done`.

**Never commit without permission:** Always present changes to the user for review before committing. Show the commit message and files, wait for explicit approval, then commit.

**Always run task adds sequentially:** If adding more than one task, run them as a single command separated by `&&` — never split into multiple concurrent runs. The ID generation logic requires serial execution:

```bash
task add -t "Task 1" -d "Description" && task add -t "Task 2" -d "Description"
```

## Quick Commands

**Add a task:**
```bash
task add -t "Fix login bug" -d "User gets 401 after password reset"
```

**Add with tag:**
```bash
task add -t "Update docs" -d "Add API reference" -T "#documentation"
```

**List all tasks:**
```bash
task list
```

**View task details:**
```bash
task list 1
```

## Tags

Tags must be prefixed with `#`. Common tags:
- `#bug` — Bug fixes
- `#feature` — New features
- `#documentation` — Documentation work
- `#backlog` — Future/low priority work

View tasks by tag: `task view #bug`

## Common Operations

| Operation | Command |
|-----------|---------|
| Mark complete | `task done 1` |
| Update task | `task update 1 -t "New title" -d "New description"` |
| Delete task | `task delete 1` |
| List all tags | `task tags` |
| Set config | `task config sort title` |

## Configuration

```bash
task config sort completed          # Sort: completed last
task config sort title               # Sort: alphabetically
task config displayLimit 10          # Show max 10 tasks
task config showCompleted true       # Include completed in list
task config showBacklog false        # Hide backlog tasks
task config backlogTags "#backlog"   # Tags that mark backlog
```

## Output Format

Task list shows:
- `[ ]` — Incomplete task
- `[x]` — Completed task
- Task ID, title, tags
- Counts: (total, completed)