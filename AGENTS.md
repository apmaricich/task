# Task Manager - Agent Guide

## Build

```bash
swift build
```

Build in release mode:
```bash
swift build -c release
```

## Test

Run the full test suite:
```bash
swift test
```

Run specific test files:
```bash
swift test --filter Tests/taskTests
```

### Test Coverage

Ensure tests are added for all new features and modifications. The project should maintain comprehensive test coverage for:
- Core task CRUD operations
- Sorting and filtering behavior
- Configuration options
- Edge cases and error conditions

## Linting

Run SwiftLint:
```bash
swiftlint
```

### Linter Best Practices

- Fix linter warnings and errors rather than suppressing them
- Avoid adding `// swiftlint:disable` comments unless absolutely necessary
- Ensure code follows Swift conventions for naming, formatting, and style

## Development Workflow

1. Write code
2. Run `swift build` to verify compilation
3. Run `swift test` to ensure all tests pass
4. Run `swiftlint` to check code quality
5. Commit changes with clear, descriptive messages