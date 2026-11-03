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
        
        return monitorProgressInternal(tasks: tasks, initialUncompletedCount: uncompletedCount)
    }
    
    // Internal loop that monitors tasks until all are complete
    func monitorProgressInternal(tasks: [Task], initialUncompletedCount: Int) -> State {
        var completedCount: Int = 0
        
        loop: while completedCount < initialUncompletedCount {
            // Recalculate remaining uncompleted tasks
            let uncompleted = tasks.filter { !$0.completed }
            let remaining = uncompleted.count
            completedCount = initialUncompletedCount - remaining
            
            let progressInfo = generateProgressInfo(
                total: initialUncompletedCount,
                completed: completedCount
            )
            
            print("Progress: \(progressInfo.percentage)% \(progressInfo.progressBar)  \(completedCount)/\(initialUncompletedCount)")
            
            // Exit when all tasks are complete
            if remaining == 0 {
                break
            }
            
            // Sleep 5 seconds before next poll
            sleep(5)
        }
        
        print("All tasks completed!")
        return .completed
    }
    
    // Generate progress info snapshot from current completion status
    func generateProgressInfo(total: Int, completed: Int) -> ProgressInfo {
        guard total > 0 else {
            return ProgressInfo(
                current: completed,
                total: total,
                percentage: 0,
                filledBlocks: 0,
                emptyBlocks: 20,
                progressBar: "[░░░░░░░░░░░░░░░░░░░░]"
            )
        }
        
        let percentage = completed * 100 / total
        let filledBlocks = Int(percentage / 5)  // 20 blocks, 5% each
        let emptyBlocks = 20 - filledBlocks
        let progressBar = String(repeating: "█", count: filledBlocks) +
                         String(repeating: "░", count: emptyBlocks)
        
        return ProgressInfo(
            current: completed,
            total: total,
            percentage: percentage,
            filledBlocks: filledBlocks,
            emptyBlocks: emptyBlocks,
            progressBar: "[\(progressBar)]"
        )
    }
}