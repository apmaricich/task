import Foundation

// MARK: - Git Operations

/// Checks if the current directory is a git repository by looking for the .git directory
func isGitRepository() -> Bool {
    let gitDir = FileManager.default.currentDirectoryPath + "/.git"
    return FileManager.default.fileExists(atPath: gitDir)
}

/// Checks if a git branch exists
func doesBranchExist(_ branchName: String) -> Bool {
    let process = Process()
    process.launchPath = "/bin/bash"
    process.arguments = ["-c", "git rev-parse --verify refs/heads/\(branchName) > /dev/null 2>&1"]
    process.currentDirectoryPath = FileManager.default.currentDirectoryPath
    process.launch()
    process.waitUntilExit()
    return process.terminationStatus == 0
}

/// Checks out an existing git branch
func checkoutBranch(_ branchName: String) {
    let process = Process()
    process.launchPath = "/bin/bash"
    process.arguments = ["-c", "git checkout \(branchName)"]
    process.currentDirectoryPath = FileManager.default.currentDirectoryPath
    process.launch()
    process.waitUntilExit()
}

/// Creates and checks out a new git branch
func createAndCheckoutBranch(_ branchName: String) {
    let process = Process()
    process.launchPath = "/bin/bash"
    process.arguments = ["-c", "git checkout -b \(branchName)"]
    process.currentDirectoryPath = FileManager.default.currentDirectoryPath
    process.launch()
    process.waitUntilExit()
}

/// Merges a branch into the current branch
func mergeBranch(_ branchName: String) {
    let process = Process()
    process.launchPath = "/bin/bash"
    process.arguments = ["-c", "git merge \(branchName)"]
    process.currentDirectoryPath = FileManager.default.currentDirectoryPath
    process.launch()
    process.waitUntilExit()
}

/// Adds tasks.json to .gitattributes with the -diff attribute to prevent it from
/// showing changes in diff output
func addTasksGitattributesEntry() {
    let gitattributesPath = FileManager.default.currentDirectoryPath + "/.gitattributes"
    let entry = "tasks.json -diff\n"

    // Check if .gitattributes exists
    if FileManager.default.fileExists(atPath: gitattributesPath) {
        // Read existing content
        if let content = try? String(contentsOfFile: gitattributesPath, encoding: .utf8) {
            // Check if entry already exists
            if content.contains("tasks.json") {
                return
            }
            // Append entry
            if let file = try? FileHandle(forWritingTo: URL(fileURLWithPath: gitattributesPath)) {
                _ = try? file.seekToEnd()
                if let data = entry.data(using: .utf8) {
                    file.write(data)
                }
                try? file.close()
            }
        }
    } else {
        // Create .gitattributes with the entry
        try? entry.write(toFile: gitattributesPath, atomically: true, encoding: .utf8)
    }
}
