import { test } from "node:test";
import assert from "node:assert/strict";
import { formatLongDate, trimEmptyWeeks, toIsoDate, buildMonthGrid } from "../js/dateUtils.js";

test("toIsoDate formats single-digit month/day with zero padding", () => {
  assert.equal(toIsoDate(new Date(2026, 0, 5)), "2026-01-05");
});

test("toIsoDate formats double-digit month/day without extra padding", () => {
  assert.equal(toIsoDate(new Date(2026, 10, 25)), "2026-11-25");
});

test("buildMonthGrid returns exactly 42 cells", () => {
  const cells = buildMonthGrid(2026, 10); // November 2026
  assert.equal(cells.length, 42);
});

test("buildMonthGrid places November 1 2026 (a Sunday) at index 0 with no leading blanks", () => {
  const cells = buildMonthGrid(2026, 10);
  assert.equal(cells[0].day, 1);
  assert.equal(cells[0].iso, "2026-11-01");
});

test("buildMonthGrid pads leading blanks for a month not starting on Sunday", () => {
  // December 2026 starts on a Tuesday -> 2 leading blanks (Sun, Mon)
  const cells = buildMonthGrid(2026, 11);
  assert.equal(cells[0], null);
  assert.equal(cells[1], null);
  assert.equal(cells[2].day, 1);
});

test("buildMonthGrid includes the correct last day of the month", () => {
  const cells = buildMonthGrid(2026, 10); // November has 30 days
  const novemberCells = cells.filter((c) => c !== null);
  assert.equal(novemberCells.length, 30);
  assert.equal(novemberCells[29].day, 30);
  assert.equal(novemberCells[29].iso, "2026-11-30");
});

test("buildMonthGrid handles February in a leap year", () => {
  const cells = buildMonthGrid(2028, 1); // Feb 2028, leap year -> 29 days
  const febCells = cells.filter((c) => c !== null);
  assert.equal(febCells.length, 29);
});

test("formatLongDate turns an ISO date into day, month name and year", () => {
  assert.equal(formatLongDate("2026-11-26"), "26 November 2026");
  assert.equal(formatLongDate("2027-01-05"), "5 January 2027");
});

test("trimEmptyWeeks drops trailing all-blank weeks only", () => {
  const november = trimEmptyWeeks(buildMonthGrid(2026, 10)); // starts Sunday, 5 weeks
  assert.equal(november.length, 35);
  assert.equal(november[29].day, 30);

  const august = trimEmptyWeeks(buildMonthGrid(2026, 7)); // starts Saturday, needs all 6 weeks
  assert.equal(august.length, 42);
});
