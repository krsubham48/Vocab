import { loadDecks } from "./deckLoader.js";
import { loadState, saveState } from "./storage.js";
import { wordsEveryday } from "./words-everyday.js";
import { wordsAdvanced } from "./words-advanced.js";
import { createLearnView } from "./ui-learn.js";
import { createReviseView } from "./ui-revise.js";
import { createRevisitView } from "./ui-revisit.js";
import { createCalendarView } from "./ui-calendar.js";

function boot() {
  const { everyday, advanced, allWords } = loadDecks(wordsEveryday, wordsAdvanced);

  if (everyday.loadFailed || advanced.loadFailed || everyday.droppedCount || advanced.droppedCount) {
    console.warn("Deck load issues:", {
      everydayFailed: everyday.loadFailed,
      advancedFailed: advanced.loadFailed,
      everydayDropped: everyday.droppedCount,
      advancedDropped: advanced.droppedCount,
    });
  }

  let state = loadState(window.localStorage);

  function getState() {
    return state;
  }

  function setState(nextState) {
    state = nextState;
  }

  const views = {
    learn: createLearnView({
      container: document.getElementById("view-learn"),
      allWords,
      getState,
      setState,
      storage: window.localStorage,
    }),
    revise: createReviseView({
      container: document.getElementById("view-revise"),
      allWords,
      getState,
    }),
    revisit: createRevisitView({
      container: document.getElementById("view-revisit"),
      allWords,
      getState,
    }),
    calendar: createCalendarView({
      container: document.getElementById("view-calendar"),
      allWords,
      getState,
    }),
  };

  for (const key of Object.keys(views)) {
    views[key].render();
  }

  const tabButtons = document.querySelectorAll(".tab-button");
  const viewSections = document.querySelectorAll(".view");

  tabButtons.forEach((btn) => {
    btn.addEventListener("click", () => {
      const target = btn.dataset.tab;

      tabButtons.forEach((b) => b.removeAttribute("aria-current"));
      btn.setAttribute("aria-current", "page");

      viewSections.forEach((section) => {
        section.hidden = section.dataset.view !== target;
      });

      views[target].render();
    });
  });

  if ("serviceWorker" in navigator) {
    navigator.serviceWorker.register("sw.js").catch((err) => {
      console.warn("Service worker registration failed:", err);
    });
  }

  window.addEventListener("beforeunload", () => {
    saveState(state, window.localStorage);
  });
}

boot();
