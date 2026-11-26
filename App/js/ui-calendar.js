import { groupLearntByDate } from "./wordState.js";
import { buildMonthGrid, trimEmptyWeeks, formatLongDate, shiftMonth, toIsoDate, MONTH_NAMES } from "./dateUtils.js";

const WEEKDAY_LABELS = ["S", "M", "T", "W", "T", "F", "S"];

export function createCalendarView({ container, allWords, getState }) {
  // null means "the current month", so an app left open follows into a new month
  let pinned = null;
  let selectedIso = null;

  // read the date each time, never once at startup
  function currentMonth() {
    const now = new Date();
    return { year: now.getFullYear(), month: now.getMonth() };
  }

  const isBefore = (a, b) => a.year < b.year || (a.year === b.year && a.month < b.month);

  function showMonth(target) {
    pinned = isBefore(target, currentMonth()) ? target : null;
    selectedIso = null;
    render();
  }

  function navButton(direction, label, onClick) {
    const button = document.createElement("button");
    button.className = `calendar-nav ${direction}`;
    button.setAttribute("aria-label", label);
    button.addEventListener("click", onClick);
    return button;
  }

  function buildHeader(view) {
    const header = document.createElement("div");
    header.className = "calendar-header";

    const label = document.createElement("div");
    label.className = "calendar-month-label";
    label.textContent = `${MONTH_NAMES[view.month]} ${view.year}`;

    const previous = navButton("previous", "Previous month", () => showMonth(shiftMonth(view.year, view.month, -1)));
    const next = navButton("next", "Next month", () => showMonth(shiftMonth(view.year, view.month, 1)));
    // nothing can have been learnt in a future month
    next.disabled = !isBefore(view, currentMonth());

    header.append(previous, label, next);
    return header;
  }

  function render() {
    const state = getState();
    const grouped = groupLearntByDate(allWords, state.words);
    const view = pinned ?? currentMonth();
    container.innerHTML = "";
    container.appendChild(buildHeader(view));

    const grid = document.createElement("div");
    grid.className = "calendar-grid";

    for (const wd of WEEKDAY_LABELS) {
      const wdEl = document.createElement("div");
      wdEl.className = "calendar-weekday";
      wdEl.textContent = wd;
      grid.appendChild(wdEl);
    }

    const cells = trimEmptyWeeks(buildMonthGrid(view.year, view.month));
    for (const cell of cells) {
      const cellEl = document.createElement("button");
      cellEl.className = "calendar-day";
      if (!cell) {
        cellEl.style.visibility = "hidden";
        grid.appendChild(cellEl);
        continue;
      }
      const entries = grouped[cell.iso] || [];
      if (entries.length > 0) {
        cellEl.classList.add("has-entries");
      }
      cellEl.textContent = String(cell.day);
      if (cell.iso === selectedIso) {
        cellEl.classList.add("selected");
        cellEl.setAttribute("aria-pressed", "true");
      }
      if (entries.length > 0) {
        const dot = document.createElement("div");
        dot.className = "calendar-day-dot";
        cellEl.appendChild(dot);
      }
      cellEl.addEventListener("click", () => {
        selectedIso = cell.iso;
        render();
      });
      grid.appendChild(cellEl);
    }

    container.appendChild(grid);

    // "2026-11": a selection left over from another month shows nothing
    const monthPrefix = toIsoDate(new Date(view.year, view.month, 1)).slice(0, 7);
    if (selectedIso?.startsWith(monthPrefix)) {
      renderDayDetail(grouped[selectedIso] || []);
    }
  }

  function renderDayDetail(entries) {
    const existing = container.querySelector(".calendar-day-detail");
    if (existing) existing.remove();

    const detail = document.createElement("div");
    detail.className = "calendar-day-detail word-card";

    if (entries.length === 0) {
      detail.classList.add("empty-state");
      detail.textContent = "No words learnt on this day.";
    } else {
      const heading = document.createElement("div");
      heading.className = "word-label";
      heading.textContent = `Learnt on ${formatLongDate(selectedIso)}`;
      detail.appendChild(heading);

      for (const word of entries) {
        const row = document.createElement("div");
        row.className = "calendar-word";
        const name = document.createElement("span");
        name.className = "calendar-word-name";
        name.textContent = word.word;
        const deck = document.createElement("span");
        deck.className = "deck-tag";
        deck.textContent = word.deck === "everyday" ? "Everyday" : "Advanced";
        row.append(name, deck);
        detail.appendChild(row);
      }
    }

    container.appendChild(detail);
  }

  return { render };
}
