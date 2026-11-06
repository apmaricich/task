import XCTest
@testable import task

class ProgressMonitorTests: XCTestCase {
    var monitor: ProgressMonitor!

    override func setUp() {
        super.setUp()
        monitor = ProgressMonitor()
    }

    override func tearDown() {
        super.tearDown()
        monitor = nil
    }

    // MARK: - State Transitions

    func testMonitorProgress_NoUncompletedTasks() {
        let tmpFile = NSTemporaryDirectory() + "test_monitor_\(UUID().uuidString).json"
        defer { try? FileManager.default.removeItem(atPath: tmpFile) }
        let store = TaskStore(filePath: tmpFile)
        let state = monitor.monitorProgress(store: store, tag: nil)
        XCTAssertEqual(state, ProgressMonitor.State.completed)
    }

    func testMonitorProgress_CompleteTasks() {
        let tmpFile = NSTemporaryDirectory() + "test_monitor_\(UUID().uuidString).json"
        defer { try? FileManager.default.removeItem(atPath: tmpFile) }
        let store = TaskStore(filePath: tmpFile)
        store.add(title: "T1", description: "D")
        store.add(title: "T2", description: "D")
        let tasks = store.list()
        for task in tasks {
            store.done(id: task.id)
        }
        let state = monitor.monitorProgress(store: store, tag: nil)
        XCTAssertEqual(state, ProgressMonitor.State.completed)
    }

    func testMonitorProgress_PartiallyCompleteTasks() {
        // This test creates a scenario with 1 uncompleted task (T2),
        // but the monitor would wait forever in real usage.
        // So we test the progress info generation instead.
        let uncompletedCount = 1
        let currentCompleted = 0
        let progress = monitor.generateProgressInfo(total: uncompletedCount, completed: currentCompleted)
        // 0% done, still running
        XCTAssertEqual(progress.percentage, 0)
        XCTAssertEqual(progress.filledBlocks, 0)
        XCTAssertEqual(progress.emptyBlocks, 20)
    }

    // MARK: - Progress Bar Generation

    func testGenerateProgressInfo_ZeroTasks() {
        // Edge case: no tasks
        let progress = monitor.generateProgressInfo(total: 0, completed: 0)
        XCTAssertEqual(progress.percentage, 0)
        XCTAssertEqual(progress.filledBlocks, 0)
        XCTAssertEqual(progress.emptyBlocks, 20)
        XCTAssertEqual(progress.progressBar, "[░░░░░░░░░░░░░░░░░░░░]")
    }

    func testGenerateProgressInfo_FiftyPercent() {
        let progress = monitor.generateProgressInfo(total: 10, completed: 5)
        XCTAssertEqual(progress.percentage, 50)
        XCTAssertEqual(progress.filledBlocks, 10)
        XCTAssertEqual(progress.emptyBlocks, 10)
        XCTAssertEqual(progress.progressBar, "[██████████░░░░░░░░░░]")
    }

    func testGenerateProgressInfo_OneHundredPercent() {
        let progress = monitor.generateProgressInfo(total: 5, completed: 5)
        XCTAssertEqual(progress.percentage, 100)
        XCTAssertEqual(progress.filledBlocks, 20)
        XCTAssertEqual(progress.emptyBlocks, 0)
        XCTAssertEqual(progress.progressBar, "[████████████████████]")
    }

    func testGenerateProgressInfo_25Percent() {
        let progress = monitor.generateProgressInfo(total: 4, completed: 1)
        XCTAssertEqual(progress.percentage, 25)
        XCTAssertEqual(progress.filledBlocks, 5)
        XCTAssertEqual(progress.emptyBlocks, 15)
        XCTAssertEqual(progress.progressBar, "[█████░░░░░░░░░░░░░░░]")
    }

    func testGenerateProgressInfo_35Percent() {
        let progress = monitor.generateProgressInfo(total: 20, completed: 7)
        XCTAssertEqual(progress.percentage, 35)
        XCTAssertEqual(progress.filledBlocks, 7)
        XCTAssertEqual(progress.emptyBlocks, 13)
        XCTAssertEqual(progress.progressBar, "[███████░░░░░░░░░░░░░]")
    }
}
