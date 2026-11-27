import Foundation

struct YearMonth: Comparable, Hashable {
    let year: Int
    /// 1 to 12.
    let month: Int

    static func < (lhs: YearMonth, rhs: YearMonth) -> Bool {
        (lhs.year, lhs.month) < (rhs.year, rhs.month)
    }
}

/// Date work for the Calendar. Uses the device's own day (its time zone), and
/// always the Gregorian calendar so dates read the same everywhere.
enum CalendarMath {
    static let monthNames = [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December",
    ]

    static var gregorian: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar
    }

    static func month(of date: Date) -> YearMonth {
        let parts = gregorian.dateComponents([.year, .month], from: date)
        return YearMonth(year: parts.year!, month: parts.month!)
    }

    static func shift(_ month: YearMonth, by delta: Int) -> YearMonth {
        let index = month.year * 12 + (month.month - 1) + delta
        return YearMonth(year: index / 12, month: index % 12 + 1)
    }

    /// Day numbers laid out in whole weeks, with nil for the blanks either side.
    /// `firstWeekday` is 1 for Sunday, 2 for Monday, and so on.
    static func cells(for month: YearMonth, firstWeekday: Int) -> [Int?] {
        let first = gregorian.date(from: DateComponents(year: month.year, month: month.month, day: 1))!
        let days = gregorian.range(of: .day, in: .month, for: first)!.count
        let leading = (gregorian.component(.weekday, from: first) - firstWeekday + 7) % 7
        var cells = [Int?](repeating: nil, count: leading) + (1...days).map { Optional($0) }
        cells += [Int?](repeating: nil, count: (7 - cells.count % 7) % 7)
        return cells
    }

    static func weekdayLetters(firstWeekday: Int) -> [String] {
        let fromSunday = ["S", "M", "T", "W", "T", "F", "S"]
        return (0..<7).map { fromSunday[(firstWeekday - 1 + $0) % 7] }
    }

    static func isoDate(year: Int, month: Int, day: Int) -> String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }

    static func isoDate(_ date: Date) -> String {
        let parts = gregorian.dateComponents([.year, .month, .day], from: date)
        return isoDate(year: parts.year!, month: parts.month!, day: parts.day!)
    }

    static func isoPrefix(_ month: YearMonth) -> String {
        String(format: "%04d-%02d", month.year, month.month)
    }

    /// "2026-11-27" becomes "27 November 2026".
    static func longDate(_ iso: String) -> String {
        let parts = iso.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3, (1...12).contains(parts[1]) else { return iso }
        return "\(parts[2]) \(monthNames[parts[1] - 1]) \(parts[0])"
    }

    static func title(_ month: YearMonth) -> String {
        "\(monthNames[month.month - 1]) \(month.year)"
    }
}
