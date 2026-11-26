// Calendar/date utilities for the Calendar tab.
// Deliberately uses local date components (not UTC) throughout, since
// "today" and "learnt on this day" must match the user's actual day boundary
// on their device, not UTC midnight.

export function toIsoDate(date) {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, "0");
  const day = String(date.getDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}

export function todayIso(now = new Date()) {
  return toIsoDate(now);
}

// Returns a flat array of 42 cells (6 weeks x 7 days) for the given
// year/monthIndex (0-based, like Date's getMonth()). Cells outside the
// target month are null so the grid can render leading/trailing blanks.
export function buildMonthGrid(year, monthIndex) {
  const firstOfMonth = new Date(year, monthIndex, 1);
  const daysInMonth = new Date(year, monthIndex + 1, 0).getDate();
  const startWeekday = firstOfMonth.getDay(); // 0 = Sunday

  const cells = [];
  for (let i = 0; i < startWeekday; i++) {
    cells.push(null);
  }
  for (let day = 1; day <= daysInMonth; day++) {
    const iso = toIsoDate(new Date(year, monthIndex, day));
    cells.push({ day, iso });
  }
  while (cells.length < 42) {
    cells.push(null);
  }
  return cells;
}
