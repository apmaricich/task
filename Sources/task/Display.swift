import Foundation

// MARK: - Display Formatting

func printAsciiTable(rows: [[String]], headers: [String]) {
    guard !rows.isEmpty && !headers.isEmpty else { return }

    // Calculate column widths
    var columnWidths = headers.map { $0.count }
    for row in rows {
        for (index, cell) in row.enumerated() where index < columnWidths.count {
            columnWidths[index] = max(columnWidths[index], cell.count)
        }
    }

    // Print header
    printTableBorder(columnWidths: columnWidths)
    printTableRow(headers, columnWidths: columnWidths, isHeader: true)
    printTableBorder(columnWidths: columnWidths)

    // Print rows
    for row in rows {
        printTableRow(row, columnWidths: columnWidths, isHeader: false)
    }

    // Print footer
    printTableBorder(columnWidths: columnWidths)
}

private func printTableBorder(columnWidths: [Int]) {
    let border = "+" + columnWidths.map { String(repeating: "-", count: $0 + 2) }.joined(separator: "+") + "+"
    print(border)
}

private func printTableRow(_ row: [String], columnWidths: [Int], isHeader: Bool) {
    var cells = row
    // Pad row with empty cells if necessary
    while cells.count < columnWidths.count {
        cells.append("")
    }

    let formatted = cells.enumerated().map { (index, cell) in
        let width = columnWidths[index]
        let padding = " ".padding(toLength: width - cell.count, withPad: " ", startingAt: 0)
        return " \(cell)\(padding) "
    }

    print("|" + formatted.joined(separator: "|") + "|")
}
