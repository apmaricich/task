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
    func monitorProgress(store: TaskStore, uncompletedCount: Int) -> State {
        guard uncompletedCount > 0 else {
            return .completed
        }
        
        return monitorProgressInternal(store: store, initialUncompletedCount: uncompletedCount)
    }
    
    // Internal loop that monitors tasks until all are complete
    func monitorProgressInternal(store: TaskStore, initialUncompletedCount: Int) -> State {
        var completedCount: Int = 0
        
        loop: while completedCount < initialUncompletedCount {
            // Re-read tasks from store to get latest state
            let tasks = store.list()
            
            // Count uncompleted tasks
            let uncompletedTasks = tasks.filter { !$0.completed }
            let currentUncompletedCount = uncompletedTasks.count
            
            // Calculate completed tasks: initial - current uncompleted
            completedCount = initialUncompletedCount - currentUncompletedCount
            
            // Clamp to avoid negative values
            if completedCount < 0 {
                completedCount = 0
            }
            
            let progressInfo = generateProgressInfo(
                total: initialUncompletedCount,
                completed: completedCount
            )
            
            // Update in place - overwrite previous line
            print("\rProgress: \(progressInfo.percentage)% \(progressInfo.progressBar)  \(completedCount)/\(initialUncompletedCount)", terminator: "")
            fflush(stdout)
            
            // Exit when all initial uncompleted tasks are complete
            if completedCount >= initialUncompletedCount {
                print()
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
        // Clamp percentage to 0-100 range to handle over-completion
        let clampedPercentage = max(0, min(100, percentage))
        let filledBlocks = Int(clampedPercentage / 5)
        let emptyBlocks = 20 - filledBlocks
        let progressBar = String(repeating: "█", count: filledBlocks) +
                         String(repeating: "░", count: emptyBlocks)
        
        return ProgressInfo(
            current: completed,
            total: total,
            percentage: clampedPercentage,
            filledBlocks: filledBlocks,
            emptyBlocks: emptyBlocks,
            progressBar: "[\(progressBar)]"
        )
    }
}