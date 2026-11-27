import XCTest
@testable import Vocab

final class CalendarMathTests: XCTestCase {
    private let november = YearMonth(year: 2026, month: 11)

    func testShiftCrossesYearBoundaries() {
        XCTAssertEqual(CalendarMath.shift(november, by: -1), YearMonth(year: 2026, month: 10))
        XCTAssertEqual(CalendarMath.shift(YearMonth(year: 2026, month: 12), by: 1), YearMonth(year: 2027, month: 1))
        XCTAssertEqual(CalendarMath.shift(YearMonth(year: 2027, month: 1), by: -1), YearMonth(year: 2026, month: 12))
    }

    func testMonthsAreOrdered() {
        XCTAssertLessThan(YearMonth(year: 2026, month: 12), YearMonth(year: 2027, month: 1))
        XCTAssertLessThan(YearMonth(year: 2026, month: 10), november)
    }

    func testNovember2026StartingSundayIsFiveWeeks() {
        let cells = CalendarMath.cells(for: november, firstWeekday: 1)
        XCTAssertEqual(cells.count, 35)
        XCTAssertEqual(cells.first ?? nil, 1)
        XCTAssertEqual(cells.compactMap { $0 }, Array(1...30))
    }

    func testAugust2026NeedsSixWeeks() {
        XCTAssertEqual(CalendarMath.cells(for: YearMonth(year: 2026, month: 8), firstWeekday: 1).count, 42)
    }

    func testWeeksStartingMondayShiftTheBlanks() {
        let cells = CalendarMath.cells(for: november, firstWeekday: 2)
        XCTAssertEqual(Array(cells.prefix(7)), [nil, nil, nil, nil, nil, nil, 1])
    }

    func testLeapFebruary() {
        XCTAssertEqual(CalendarMath.cells(for: YearMonth(year: 2028, month: 2), firstWeekday: 1).compactMap { $0 }.count, 29)
    }

    func testWeekdayLettersBeginOnTheFirstWeekday() {
        XCTAssertEqual(CalendarMath.weekdayLetters(firstWeekday: 1), ["S", "M", "T", "W", "T", "F", "S"])
        XCTAssertEqual(CalendarMath.weekdayLetters(firstWeekday: 2), ["M", "T", "W", "T", "F", "S", "S"])
    }

    func testDateStrings() {
        XCTAssertEqual(CalendarMath.isoDate(year: 2026, month: 1, day: 5), "2026-01-05")
        XCTAssertEqual(CalendarMath.isoPrefix(YearMonth(year: 2026, month: 3)), "2026-03")
        XCTAssertEqual(CalendarMath.longDate("2026-11-27"), "27 November 2026")
        XCTAssertEqual(CalendarMath.title(november), "November 2026")
    }

    func testADateBelongsToTheDeviceDay() {
        let justAfterMidnight = makeDate(2026, 12, 1, 0, 3)
        XCTAssertEqual(CalendarMath.isoDate(justAfterMidnight), "2026-12-01")
        XCTAssertEqual(CalendarMath.month(of: justAfterMidnight), YearMonth(year: 2026, month: 12))
    }
}
