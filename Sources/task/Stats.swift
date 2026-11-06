import Foundation

// MARK: - Stats Command

func handleStats(store: TaskStore) {
    let tasks = store.list()

    // Counters
    let total = tasks.count
    let completed = tasks.filter { $0.completed }.count
    let pending = total - completed

    // Tasks completed today
    let now = Date()
    let startOfToday = Calendar.current.startOfDay(for: now)
    let tasksCompletedToday = tasks.filter { task in
        guard let completedDate = task.completedDate else { return false }
        let date = Date(timeIntervalSince1970: completedDate)
        return date >= startOfToday
    }.count

    // Tasks completed this week
    let startOfWeek = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: startOfToday) ?? startOfToday
    let tasksCompletedThisWeek = tasks.filter { task in
        guard let completedDate = task.completedDate else { return false }
        let date = Date(timeIntervalSince1970: completedDate)
        return date >= startOfWeek
    }.count

    // Average completion time
    let avgCompletionTime = calculateAverageCompletionTime(tasks: tasks)

    // Tag distribution
    let tagDistribution = calculateTagDistribution(tasks: tasks)

    // Display stats
    printHeader("Task Statistics")

    // Overview
    print("")
    print("  Overview")
    let completionPct = total > 0 ? (Double(completed) / Double(total)) * 100.0 : 0.0
    print("    Total tasks:     \(total)")
    print("    Completed:       \(completed) (\(Int(completionPct))%)")
    print("    Pending:         \(pending) (\(Int(100.0 - completionPct))%)")

    // Velocity
    print("")
    print("  Velocity")
    print("    Completed today:   \(tasksCompletedToday)")
    print("    Completed this week: \(tasksCompletedThisWeek)")
    if let avg = avgCompletionTime {
        print("    Avg completion time: \(formatDuration(avg))")
    } else {
        print("    Avg completion time: N/A")
    }

    // Tag Distribution (top 5)
    if !tagDistribution.isEmpty {
        print("")
        print("  Top Tags")
        let sortedTags = tagDistribution.sorted { $0.value > $1.value }.prefix(5)
        for (tag, count) in sortedTags {
            print("    \(tag): \(count)")
        }
    }
}

private func calculateAverageCompletionTime(tasks: [Task]) -> TimeInterval? {
    let completedTasks = tasks.filter { task in
        task.completed && task.completedDate != nil
    }

    guard !completedTasks.isEmpty else { return nil }

    var totalDuration: TimeInterval = 0
    let count = completedTasks.count

    for task in completedTasks {
        let duration = task.completedDate! - task.createdDate
        totalDuration += duration
    }

    return totalDuration / Double(count)
}

private func calculateTagDistribution(tasks: [Task]) -> [String: Int] {
    var distribution: [String: Int] = [:]

    for task in tasks {
        for tag in task.tags {
            if let count = distribution[tag] {
                distribution[tag] = count + 1
            } else {
                distribution[tag] = 1
            }
        }
    }

    return distribution
}

private func formatDuration(_ seconds: TimeInterval) -> String {
    let minutes = Int(seconds) / 60
    let hours = minutes / 60
    let days = hours / 24

    if days > 0 {
        return "\(days)d \(hours % 24)h"
    } else if hours > 0 {
        return "\(hours)h \(minutes % 60)m"
    } else if minutes > 0 {
        return "\(minutes)m"
    } else {
        return "\(Int(seconds))s"
    }
}
