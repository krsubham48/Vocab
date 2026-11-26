import { getRevisePool, unmarkLearnt, displayPronunciation } from "./wordState.js";
import { saveState } from "./storage.js";
import { searchWords } from "./wordSearch.js";

function element(tag, className, text) {
  const el = document.createElement(tag);
  el.className = className;
  if (text !== undefined) el.textContent = text;
  return el;
}

// A native <details> row: collapsed it shows just the word, expanded the full card.
function wordRow(word, openIds, onRemove) {
  const row = element("details", "revisit-item");
  row.open = openIds.has(word.id);
  row.addEventListener("toggle", () => {
    if (row.open) openIds.add(word.id);
    else openIds.delete(word.id);
  });

  const summary = element("summary", "revisit-summary");
  summary.append(
    element("span", "revisit-word", word.word),
    element("span", "revisit-deck", word.deck === "everyday" ? "Everyday" : "Advanced")
  );
  row.appendChild(summary);

  const body = element("div", "revisit-body");
  const pronunciation = displayPronunciation(word);
  if (pronunciation) body.appendChild(element("div", "revisit-pronunciation", pronunciation));
  for (const meaning of word.meanings) {
    const block = element("div", "meaning-block");
    block.appendChild(element("div", "meaning-pos", meaning.partOfSpeech));
    block.appendChild(element("div", "meaning-definition", meaning.definition));
    block.appendChild(element("div", "meaning-example", `“${meaning.example}”`));
    body.appendChild(block);
  }
  const remove = element("button", "revisit-remove", "Remove");
  remove.setAttribute("aria-label", `Remove ${word.word} from learnt words`);
  remove.addEventListener("click", () => onRemove(word));
  body.appendChild(remove);
  row.appendChild(body);
  return row;
}

// The search box is created once so the query survives tab switches and typing
// never loses focus; only the results below it are redrawn.
export function createRevisitView({ container, allWords, getState, setState, storage }) {
  let pool = [];
  // which rows are expanded, kept across redraws (search, tab switch, removal)
  const openIds = new Set();

  const search = element("input", "revisit-search");
  search.type = "search";
  search.placeholder = "Search words or meanings";
  search.setAttribute("aria-label", "Search learnt words");
  search.autocapitalize = "none";
  search.autocomplete = "off";
  search.spellcheck = false;
  search.enterKeyHint = "search";

  const header = element("div", "revisit-header");
  const count = element("div", "progress-label revisit-count");
  header.append(search, count);

  const list = element("div", "revisit-list");

  search.addEventListener("input", drawResults);
  search.addEventListener("keydown", (event) => {
    if (event.key === "Enter") search.blur();
  });

  function drawResults() {
    const results = searchWords(pool, search.value);
    count.textContent = search.value.trim()
      ? `${results.length} of ${pool.length} words`
      : `${pool.length} learnt ${pool.length === 1 ? "word" : "words"}`;
    list.replaceChildren(...results.map((word) => wordRow(word, openIds, removeWord)));
    if (results.length === 0) {
      list.appendChild(element("div", "word-card empty-state", "No matching words."));
    }
  }

  function removeWord(word) {
    if (!window.confirm(`Remove “${word.word}” from your learnt words?`)) return;
    const state = getState();
    const nextState = { ...state, words: unmarkLearnt(word.id, state.words) };
    openIds.delete(word.id);
    setState(nextState);
    saveState(nextState, storage);
    render();
  }

  function render() {
    pool = getRevisePool(allWords, getState().words);
    if (pool.length === 0) {
      container.replaceChildren(element("div", "word-card empty-state", "Learn and mark some words first!"));
      return;
    }
    if (!list.isConnected) container.replaceChildren(header, list);
    drawResults();
  }

  return { render };
}
