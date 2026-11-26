import { getRevisePool, displayPronunciation } from "./wordState.js";

// `render()` is called every time the user switches to this tab (see app.js),
// so index/revealed/pool must survive across render() calls — they're declared
// outside render() and only reset when the pool's membership actually changes
// (not on every tab-switch re-render), per the spec's "preserve tab state" rule.
export function createReviseView({ container, allWords, getState }) {
  let pool = [];
  let index = 0;
  let revealed = false;

  function render() {
    const state = getState();
    const freshPool = getRevisePool(allWords, state.words);

    const poolChanged =
      freshPool.length !== pool.length ||
      !freshPool.every((w, i) => w.id === pool[i]?.id);
    pool = freshPool;
    if (poolChanged) {
      index = 0;
      revealed = false;
    }

    container.innerHTML = "";

    if (pool.length === 0) {
      const empty = document.createElement("div");
      empty.className = "word-card empty-state";
      empty.textContent = "Learn and mark some words first!";
      container.appendChild(empty);
      return;
    }

    index = Math.min(index, pool.length - 1);
    renderCard();
  }

  function renderCard() {
    container.innerHTML = "";
    const word = pool[index];

    const card = document.createElement("div");
    card.className = "flashcard";

    const deckTag = document.createElement("div");
    deckTag.className = "flashcard-deck-tag";
    deckTag.textContent = word.deck === "everyday" ? "Everyday" : "Advanced";
    card.appendChild(deckTag);

    const wordEl = document.createElement("div");
    wordEl.className = "flashcard-word";
    wordEl.textContent = word.word;
    card.appendChild(wordEl);

    if (revealed) {
      const pronunciation = displayPronunciation(word);
      if (pronunciation) {
        const pron = document.createElement("div");
        pron.className = "word-pronunciation";
        pron.textContent = pronunciation;
        card.appendChild(pron);
      }

      for (const meaning of word.meanings) {
        const block = document.createElement("div");
        block.className = "meaning-block";

        const pos = document.createElement("div");
        pos.className = "meaning-pos";
        pos.textContent = meaning.partOfSpeech;
        block.appendChild(pos);

        const def = document.createElement("div");
        def.className = "meaning-definition";
        def.textContent = meaning.definition;
        block.appendChild(def);

        const ex = document.createElement("div");
        ex.className = "meaning-example";
        ex.textContent = `“${meaning.example}”`;
        block.appendChild(ex);

        card.appendChild(block);
      }
    } else {
      const hint = document.createElement("div");
      hint.className = "flashcard-reveal-hint";
      hint.textContent = "Tap to reveal the meaning";
      card.appendChild(hint);
    }

    card.addEventListener("click", () => {
      if (!revealed) {
        revealed = true;
        renderCard();
      }
    });

    container.appendChild(card);

    if (revealed) {
      const row = document.createElement("div");
      row.className = "button-row";

      const gotIt = document.createElement("button");
      gotIt.className = "btn-primary";
      gotIt.textContent = "Got it";
      gotIt.addEventListener("click", () => advance());
      row.appendChild(gotIt);

      const stillLearning = document.createElement("button");
      stillLearning.className = "btn-secondary";
      stillLearning.textContent = "Still learning";
      stillLearning.addEventListener("click", () => advance());
      row.appendChild(stillLearning);

      container.appendChild(row);
    }
  }

  function advance() {
    index = (index + 1) % pool.length;
    revealed = false;
    renderCard();
  }

  return { render };
}
