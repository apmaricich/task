import XCTest
@testable import task

final class TaskStoreTests: XCTestCase {
    var store: TaskStore!
    var testFilePath: String!

    override func setUp() {
        super.setUp()
        testFilePath = NSTemporaryDirectory() + "test_tasks_\(UUID().uuidString).json"
        store = TaskStore(filePath: testFilePath)
    }

    override func tearDown() {
        super.tearDown()
        if FileManager.default.fileExists(atPath: testFilePath) {
            try? FileManager.default.removeItem(atPath: testFilePath)
        }
    }

    func testInitStore() {
        store.initStore()
        XCTAssertTrue(FileManager.default.fileExists(atPath: testFilePath))
    }

    func testAddTask() {
        let task = store.add(title: "Test Task", description: "Test description")
        XCTAssertEqual(task.id, 1)
        XCTAssertEqual(task.title, "Test Task")
        XCTAssertEqual(task.description, "Test description")
        XCTAssertFalse(task.completed)
        XCTAssertGreaterThan(task.createdDate, 0)
    }

    func testAddMultipleTasks() {
        let task1 = store.add(title: "Task 1", description: "Description 1")
        let task2 = store.add(title: "Task 2", description: "Description 2")

        XCTAssertEqual(task1.id, 1)
        XCTAssertEqual(task2.id, 2)
    }

    func testListTasks() {
        store.add(title: "Task 1", description: "Description 1")
        store.add(title: "Task 2", description: "Description 2")

        let tasks = store.list()
        XCTAssertEqual(tasks.count, 2)
        XCTAssertEqual(tasks[0].id, 1)
        XCTAssertEqual(tasks[1].id, 2)
    }

    func testUpdateTaskTitle() {
        let task = store.add(title: "Old Title", description: "Description")
        store.update(id: task.id, title: "New Title", description: nil)

        let updated = store.list().first { $0.id == task.id }
        XCTAssertEqual(updated?.title, "New Title")
        XCTAssertEqual(updated?.description, "Description")
        XCTAssertNotNil(updated?.updatedDate)
    }

    func testUpdateTaskDescription() {
        let task = store.add(title: "Title", description: "Old Description")
        store.update(id: task.id, title: nil, description: "New Description")

        let updated = store.list().first { $0.id == task.id }
        XCTAssertEqual(updated?.title, "Title")
        XCTAssertEqual(updated?.description, "New Description")
    }

    func testDeleteTask() {
        let task = store.add(title: "Delete me", description: "Description")
        let deleted = store.delete(id: task.id)

        XCTAssertTrue(deleted)
        let tasks = store.list()
        XCTAssertEqual(tasks.count, 0)
    }

    func testDeleteNonExistentTask() {
        let deleted = store.delete(id: 999)
        XCTAssertFalse(deleted)
    }

    func testUpdateNonExistentTask() {
        let updated = store.update(id: 999, title: "New Title", description: "Description")
        XCTAssertFalse(updated)
    }

    func testDoneTask() {
        let task = store.add(title: "To complete", description: "Description")
        let done = store.done(id: task.id)

        XCTAssertTrue(done)
        let completed = store.list().first { $0.id == task.id }
        XCTAssertTrue(completed?.completed ?? false)
        XCTAssertNotNil(completed?.completedDate)
    }

    func testDoneNonExistentTask() {
        let done = store.done(id: 999)
        XCTAssertFalse(done)
    }

    func testSortByCompleted() {
        store.add(title: "Uncompleted 1", description: "")
        store.add(title: "Completed 1", description: "")
        store.add(title: "Uncompleted 2", description: "")

        let task2 = store.list().first { $0.title == "Completed 1" }!
        store.done(id: task2.id)

        store.setConfig(key: "sort", value: "completed")

        let tasks = store.list()
        // Uncompleted should come first
        XCTAssertFalse(tasks[0].completed)
        XCTAssertFalse(tasks[1].completed)
        XCTAssertTrue(tasks[2].completed)
    }

    func testSortByTitle() {
        store.add(title: "C Task", description: "")
        store.add(title: "A Task", description: "")
        store.add(title: "B Task", description: "")

        store.setConfig(key: "sort", value: "title")

        let tasks = store.list()
        XCTAssertEqual(tasks[0].title, "A Task")
        XCTAssertEqual(tasks[1].title, "B Task")
        XCTAssertEqual(tasks[2].title, "C Task")
    }

    func testSortByDescription() {
        store.add(title: "Task 1", description: "C Desc")
        store.add(title: "Task 2", description: "A Desc")
        store.add(title: "Task 3", description: "B Desc")

        store.setConfig(key: "sort", value: "description")

        let tasks = store.list()
        XCTAssertEqual(tasks[0].description, "A Desc")
        XCTAssertEqual(tasks[1].description, "B Desc")
        XCTAssertEqual(tasks[2].description, "C Desc")
    }

    func testSortById() {
        store.add(title: "Task 3", description: "")
        store.add(title: "Task 1", description: "")
        store.add(title: "Task 2", description: "")

        store.setConfig(key: "sort", value: "id")

        let tasks = store.list()
        XCTAssertEqual(tasks[0].id, 1)
        XCTAssertEqual(tasks[1].id, 2)
        XCTAssertEqual(tasks[2].id, 3)
    }

    func testCompletedSortSecondaryOrder() {
        // Create tasks with different completion times
        store.add(title: "Completed Last", description: "")
        store.add(title: "Completed First", description: "")
        store.add(title: "Uncompleted Old", description: "")
        store.add(title: "Uncompleted New", description: "")

        let completed1 = store.list().first { $0.title == "Completed First" }!
        store.done(id: completed1.id)

        // Small delay to ensure different timestamps
        Thread.sleep(forTimeInterval: 0.1)

        let completed2 = store.list().first { $0.title == "Completed Last" }!
        store.done(id: completed2.id)

        store.setConfig(key: "sort", value: "completed")

        let tasks = store.list()
        // Uncompleted should be sorted by oldest createdDate first
        XCTAssertEqual(tasks[0].title, "Uncompleted Old")
        XCTAssertEqual(tasks[1].title, "Uncompleted New")
        // Completed should be sorted by most recent completedDate first
        XCTAssertEqual(tasks[2].title, "Completed Last")
        XCTAssertEqual(tasks[3].title, "Completed First")
    }

    func testGetSortField() {
        XCTAssertEqual(store.getSortField(), "completed")

        store.setConfig(key: "sort", value: "title")
        XCTAssertEqual(store.getSortField(), "title")
    }

    func testGetDisplayLimit() {
        XCTAssertEqual(store.getDisplayLimit(), 0)

        store.setConfig(key: "displayLimit", value: "5")
        XCTAssertEqual(store.getDisplayLimit(), 5)
    }

    func testSetConfigString() {
        store.setConfig(key: "sort", value: "title")
        XCTAssertEqual(store.getSortField(), "title")
    }

    func testSetConfigInteger() {
        store.setConfig(key: "displayLimit", value: "10")
        XCTAssertEqual(store.getDisplayLimit(), 10)
    }

    func testTaskCreatedDateFormatted() {
        let task = store.add(title: "Test", description: "")
        let formatted = task.createdDateFormatted()
        // Should match format yyyy-MM-dd HH:mm:ss
        XCTAssertGreaterThan(formatted.count, 0)
    }

    func testPersistence() {
        // Create store, add tasks, then recreate store
        store.add(title: "Persistent Task", description: "Description")

        let newStore = TaskStore(filePath: testFilePath)
        let tasks = newStore.list()

        XCTAssertEqual(tasks.count, 1)
        XCTAssertEqual(tasks[0].title, "Persistent Task")
    }

    func testUpdateSetsUpdatedDate() {
        let task = store.add(title: "Original", description: "")
        XCTAssertEqual(task.updatedDate, nil)

        store.update(id: task.id, title: "Updated", description: nil)
        let updated = store.list().first { $0.id == task.id }!
        XCTAssertNotNil(updated.updatedDate)
    }

    func testGetTask() {
        let task = store.add(title: "Get Test", description: "Test description")
        let retrieved = store.getTask(id: task.id)

        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.title, "Get Test")
        XCTAssertEqual(retrieved?.description, "Test description")
        XCTAssertEqual(retrieved?.id, task.id)
    }

    func testGetTaskNonExistent() {
        let retrieved = store.getTask(id: 999)
        XCTAssertNil(retrieved)
    }

    func testPrompt() {
        // Test that prompt returns empty string when no input is provided
        let result = prompt("Test: ")
        // We can't easily test interactive input in unit tests, so just verify
        // the function can be called without crashing
        XCTAssert(result is String)
    }

    func testGetConfig() {
        store.setConfig(key: "sort", value: "title")
        store.setConfig(key: "displayLimit", value: "10")

        let config = store.getConfig()
        XCTAssertEqual(config["sort"] as? String, "title")
        XCTAssertEqual(config["displayLimit"] as? Int, 10)
    }

    func testGetConfigEmpty() {
        let config = store.getConfig()
        // Default config should have sort field
        XCTAssertEqual(config["sort"] as? String, "completed")
    }

    // MARK: - Task Counting Tests (for list header)

    func testCountUncompletedTasks() {
        store.add(title: "Uncompleted 1", description: "")
        store.add(title: "Completed 1", description: "")
        let completedTask = store.list().first { $0.title == "Completed 1" }!
        store.done(id: completedTask.id)
        store.add(title: "Uncompleted 2", description: "")

        let tasks = store.list()
        let uncompletedCount = tasks.filter { !$0.completed }.count
        XCTAssertEqual(uncompletedCount, 2)
    }

    func testCountCompletedTasks() {
        store.add(title: "Task 1", description: "")
        store.add(title: "Task 2", description: "")
        store.add(title: "Task 3", description: "")

        let tasks = store.list()
        for task in tasks.prefix(2) {
            store.done(id: task.id)
        }

        let completedCount = store.list().filter { $0.completed }.count
        XCTAssertEqual(completedCount, 2)
    }

    func testCountsWithNoTasks() {
        let tasks = store.list()
        let uncompletedCount = tasks.filter { !$0.completed }.count
        let completedCount = tasks.filter { $0.completed }.count
        XCTAssertEqual(uncompletedCount, 0)
        XCTAssertEqual(completedCount, 0)
    }

    func testCountsAfterMixedOperations() {
        // Add 4 tasks, complete 1, delete 1
        store.add(title: "A", description: "")
        store.add(title: "B", description: "")
        store.add(title: "C", description: "")
        store.add(title: "D", description: "")

        let taskB = store.list().first { $0.title == "B" }!
        store.done(id: taskB.id)

        let taskC = store.list().first { $0.title == "C" }!
        store.delete(id: taskC.id)

        let tasks = store.list()
        let uncompletedCount = tasks.filter { !$0.completed }.count
        let completedCount = tasks.filter { $0.completed }.count

        XCTAssertEqual(tasks.count, 3)
        XCTAssertEqual(uncompletedCount, 2)
        XCTAssertEqual(completedCount, 1)
    }

    func testBacklogTasksExcludedFromCounts() {
        store.add(title: "Regular uncompleted", description: "")
        store.add(title: "Regular completed", description: "")
        let completed = store.list().first { $0.title == "Regular completed" }!
        store.done(id: completed.id)

        store.add(title: "Backlog uncompleted", description: "", tags: ["#backlog"])
        store.add(title: "Backlog completed", description: "", tags: ["#backlog"])
        let backlogCompleted = store.list().first { $0.title == "Backlog completed" }!
        store.done(id: backlogCompleted.id)

        store.setConfig(key: "backlogTags", value: "#backlog")

        let tasks = store.list()
        let nonBacklogTasks = tasks.filter { task in
            let backlogTags = store.getBacklogTags()
            if backlogTags.isEmpty { return true }
            return !task.tags.contains(where: { backlogTags.contains($0) })
        }

        // Non-backlog tasks should be 2 (1 uncompleted, 1 completed)
        XCTAssertEqual(nonBacklogTasks.count, 2)
        XCTAssertEqual(nonBacklogTasks.filter { !$0.completed }.count, 1)
        XCTAssertEqual(nonBacklogTasks.filter { $0.completed }.count, 1)

        // Total tasks should be 4
        XCTAssertEqual(tasks.count, 4)

        // Backlog count
        let backlogCount = tasks.count - nonBacklogTasks.count
        XCTAssertEqual(backlogCount, 2)
    }

    func testBacklogCountWithNoBacklogTasks() {
        store.add(title: "Regular task", description: "")
        store.setConfig(key: "backlogTags", value: "#backlog")

        let tasks = store.list()
        let nonBacklogTasks = tasks.filter { task in
            let backlogTags = store.getBacklogTags()
            if backlogTags.isEmpty { return true }
            return !task.tags.contains(where: { backlogTags.contains($0) })
        }

        XCTAssertEqual(tasks.count, 1)
        XCTAssertEqual(nonBacklogTasks.count, 1)
        XCTAssertEqual(tasks.count - nonBacklogTasks.count, 0)
    }

    // MARK: - Track Task Tests

    func testTrackTaskCreatesAndCompletes() {
        let task = store.track(title: "Tracked Task", description: "Description")
        XCTAssertTrue(task.completed)
        XCTAssertNotNil(task.completedDate)
        XCTAssertEqual(task.id, 1)
    }

    func testTrackTaskWithTags() {
        let task = store.track(title: "Tracked", description: "", tags: ["#tag"])
        let retrieved = store.getTask(id: task.id)
        XCTAssertTrue(retrieved?.completed ?? false)
        XCTAssertEqual(retrieved?.tags, ["#tag"])
    }

    // MARK: - Ready Task Tests

    func testReadyTaskRemovesBacklogTag() {
        let task = store.add(title: "Test", description: "", tags: ["#backlog"])
        store.setConfig(key: "backlogTags", value: "#backlog,#someday")

        let result = store.readyTask(id: task.id)
        XCTAssertTrue(result)

        let retrieved = store.getTask(id: task.id)
        XCTAssertTrue(retrieved?.tags.isEmpty ?? true)
    }

    func testReadyTaskKeepsNonBacklogTags() {
        let task = store.add(title: "Test", description: "", tags: ["#backlog", "#important"])
        store.setConfig(key: "backlogTags", value: "#backlog")

        let result = store.readyTask(id: task.id)
        XCTAssertTrue(result)

        let retrieved = store.getTask(id: task.id)
        XCTAssertEqual(retrieved?.tags, ["#important"])
    }

    func testReadyTaskNonExistent() {
        store.setConfig(key: "backlogTags", value: "#backlog")
        let result = store.readyTask(id: 999)
        XCTAssertFalse(result)
    }

    // MARK: - Pin Task Tests

    func testGetPinTagsEmpty() {
        let pinTags = store.getPinTags()
        XCTAssertTrue(pinTags.isEmpty)
    }

    func testGetPinTagsConfigured() {
        store.setConfig(key: "pinTags", value: "#important,#urgent")
        let pinTags = store.getPinTags()
        XCTAssertEqual(pinTags.count, 2)
        XCTAssertTrue(pinTags.contains("#important"))
        XCTAssertTrue(pinTags.contains("#urgent"))
    }

    func testPinTaskAddsTag() {
        let task = store.add(title: "Test", description: "")
        store.setConfig(key: "pinTags", value: "#important")

        let result = store.pinTask(id: task.id)
        XCTAssertTrue(result)

        let retrieved = store.getTask(id: task.id)
        XCTAssertEqual(retrieved?.tags, ["#important"])
    }

    func testUnpinTaskRemovesTag() {
        let task = store.add(title: "Test", description: "", tags: ["#important"])
        store.setConfig(key: "pinTags", value: "#important,#urgent")

        let result = store.pinTask(id: task.id)
        XCTAssertTrue(result)

        let retrieved = store.getTask(id: task.id)
        XCTAssertTrue(retrieved?.tags.isEmpty ?? true)
    }

    func testPinTaskNonExistent() {
        store.setConfig(key: "pinTags", value: "#important")
        let result = store.pinTask(id: 999)
        XCTAssertFalse(result)
    }

    func testPinTaskNoPinTagsConfigured() {
        let task = store.add(title: "Test", description: "")
        let result = store.pinTask(id: task.id)
        XCTAssertFalse(result)
    }

    func testPinTaskRemovesAllPinTags() {
        let task = store.add(title: "Test", description: "", tags: ["#important", "#urgent", "#other"])
        store.setConfig(key: "pinTags", value: "#important,#urgent")

        let result = store.pinTask(id: task.id)
        XCTAssertTrue(result)

        let retrieved = store.getTask(id: task.id)
        XCTAssertEqual(retrieved?.tags, ["#other"])
    }

    // MARK: - Backlog Tag Tests

    func testGetBacklogTagsEmpty() {
        let backlogTags = store.getBacklogTags()
        XCTAssertTrue(backlogTags.isEmpty)
    }

    func testGetBacklogTagsConfigured() {
        store.setConfig(key: "backlogTags", value: "#backlog,#someday")
        let backlogTags = store.getBacklogTags()
        XCTAssertEqual(backlogTags.count, 2)
        XCTAssertTrue(backlogTags.contains("#backlog"))
        XCTAssertTrue(backlogTags.contains("#someday"))
    }

    func testGetShowBacklogDefault() {
        let showBacklog = store.getShowBacklog()
        XCTAssertFalse(showBacklog)
    }

    func testGetShowBacklogEnabled() {
        store.setConfig(key: "showBacklog", value: "true")
        let showBacklog = store.getShowBacklog()
        XCTAssertTrue(showBacklog)
    }
}
