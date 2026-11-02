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
