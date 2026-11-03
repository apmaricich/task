import Foundation

// Monitor task completion progress and display a visual progress bar
class ProgressMonitor {
    // State machine: running → completed | interrupted
    enum State {
        case running, completed, interrupted
    }
    
    // Snapshot of progress at any given moment
    struct ProgressInfo {
        let current: Int
        let total: Int
        let percentage: Int
        let filledBlocks: Int
        let emptyBlocks: Int
        let progressBar: String
    }
    
    // Protocol for side effects (printing, sleeping, exiting)
    enum TerminalAction {
        case printLine(String)
        case sleep(seconds: Double)
        case exit(exitCode: Int)
        case interrupt
    }
    
    // Errors that can occur during monitoring
    enum ProgressMonitorError: Error {
        case noUncompletedTasks
        case invalidCount
    }
    
    init() {}
    
    // Main entry point: monitor progress and return final state
    func monitorProgress(tasks: [Task]) -> State {
        let uncompletedCount = tasks.filter { !$0.completed }.count
        
        guard uncompletedCount > 0 else {
            return .completed
        }
        
        return monitorProgressInternal(tasks: tasks, uncompletedCount: uncompletedCount)
    }
    
    // Internal loop that monitors tasks until all are complete
    func monitorProgressInternal(tasks: [Task], uncompletedCount: Int) -> State {
        var currentCompleted: Int = 0
        
        loop: while currentCompleted < uncompletedCount {
            let uncompleted = tasks.filter { !$0.completed }
            currentCompleted = uncompleted.count
            
            let progressInfo = generateProgressInfo(
                uncompletedCount: uncompletedCount,
                currentCompleted: currentCompleted
            )
            
            print("Progress: \(progressInfo.percentage)% \(progressInfo.progressBar)  \(currentCompleted)/\(uncompletedCount)")
            
            // Sleep 5 seconds before next poll
            sleep(5)
        }
        
        print("All tasks completed!")
        return .completed
    }
    
    // Generate progress info snapshot from current completion status
    func generateProgressInfo(uncompletedCount: Int, currentCompleted: Int) -> ProgressInfo {
        let percentage = currentCompleted * 100 / uncompletedCount
        let filledBlocks = Int(percentage / 5)  // 20 blocks, 5% each
        let emptyBlocks = 20 - filledBlocks
        let progressBar = String(repeating: "█", count: filledBlocks) +
                         String(repeating: "░", count: emptyBlocks)
        
        return ProgressInfo(
            current: currentCompleted,
            total: uncompletedCount,
            percentage: percentage,
            filledBlocks: filledBlocks,
            emptyBlocks: emptyBlocks,
            progressBar: "[\(progressBar)]"
        )
    }
}