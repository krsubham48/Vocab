import { getRevisePool } from "./wordState.js";
import { searchWords } from "./wordSearch.js";

function element(tag, className, text) {
  const el = document.createElement(tag);
  el.className = className;
  if (text !== undefined) el.textContent = text;
  return el;
}

function wordCard(word) {
  const card = element("article", "word-card revisit-card");
  card.appendChild(element("div", "flashcard-deck-tag", word.deck === "everyday" ? "Everyday" : "Advanced"));
  card.appendChild(element("div", "word-title", word.word));
  card.appendChild(element("div", "word-pronunciation", word.pronunciation));
  for (const meaning of word.meanings) {
    const block = element("div", "meaning-block");
    block.appendChild(element("div", "meaning-pos", meaning.partOfSpeech));
    block.appendChild(element("div", "meaning-definition", meaning.definition));
    block.appendChild(element("div", "meaning-example", `“${meaning.example}”`));
    card.appendChild(block);
  }
  return card;
}

// The search box is created once so the query survives tab switches and typing
// never loses focus; only the results below it are redrawn.
export function createRevisitView({ container, allWords, getState }) {
  let pool = [];

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
    list.replaceChildren(...results.map(wordCard));
    if (results.length === 0) {
      list.appendChild(element("div", "word-card empty-state", "No matching words."));
    }
  }

  function render() {
    pool = getRevisePool(allWords, getState().words);
    if (pool.length === 0) {
      container.replaceChildren(element("div", "word-card empty-state", "Learn and mark some words first!"));
      return;
    }
    container.replaceChildren(header, list);
    drawResults();
  }

  return { render };
}
