import { groupLearntByDate } from "./wordState.js";
import { buildMonthGrid } from "./dateUtils.js";

const WEEKDAY_LABELS = ["S", "M", "T", "W", "T", "F", "S"];
const MONTH_NAMES = [
  "January", "February", "March", "April", "May", "June",
  "July", "August", "September", "October", "November", "December",
];

export function createCalendarView({ container, allWords, getState }) {
  const today = new Date();
  let viewYear = today.getFullYear();
  let viewMonth = today.getMonth();
  let selectedIso = null;

  function render() {
    const state = getState();
    const grouped = groupLearntByDate(allWords, state.words);
    container.innerHTML = "";

    const label = document.createElement("div");
    label.className = "calendar-month-label";
    label.textContent = `${MONTH_NAMES[viewMonth]} ${viewYear}`;
    container.appendChild(label);

    const grid = document.createElement("div");
    grid.className = "calendar-grid";

    for (const wd of WEEKDAY_LABELS) {
      const wdEl = document.createElement("div");
      wdEl.className = "calendar-weekday";
      wdEl.textContent = wd;
      grid.appendChild(wdEl);
    }

    const cells = buildMonthGrid(viewYear, viewMonth);
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
      if (entries.length > 0) {
        const dot = document.createElement("div");
        dot.className = "calendar-day-dot";
        cellEl.appendChild(dot);
      }
      cellEl.addEventListener("click", () => {
        selectedIso = cell.iso;
        render();
        renderDayDetail(grouped[selectedIso] || []);
      });
      grid.appendChild(cellEl);
    }

    container.appendChild(grid);

    if (selectedIso) {
      renderDayDetail(grouped[selectedIso] || []);
    }
  }

  function renderDayDetail(entries) {
    const existing = container.querySelector(".calendar-day-detail");
    if (existing) existing.remove();

    const detail = document.createElement("div");
    detail.className = "calendar-day-detail word-card";
    detail.style.marginTop = "16px";

    if (entries.length === 0) {
      detail.textContent = "No words learnt on this day.";
    } else {
      const heading = document.createElement("div");
      heading.className = "word-label";
      heading.textContent = `Learnt on ${selectedIso}`;
      detail.appendChild(heading);

      for (const word of entries) {
        const row = document.createElement("div");
        row.className = "meaning-block";
        row.textContent = `${word.word} (${word.deck === "everyday" ? "Everyday" : "Advanced"})`;
        detail.appendChild(row);
      }
    }

    container.appendChild(detail);
  }

  return { render };
}
