import { pickNewWord, markLearnt, computeProgress, displayPronunciation } from "./wordState.js";
import { saveState } from "./storage.js";
import { todayIso } from "./dateUtils.js";

export function createLearnView({ container, allWords, getState, setState, storage }) {
  function render() {
    const state = getState();
    container.innerHTML = "";

    const deckToggle = document.createElement("div");
    deckToggle.className = "deck-toggle";
    for (const deck of ["everyday", "advanced"]) {
      const btn = document.createElement("button");
      btn.textContent = deck === "everyday" ? "Everyday" : "Advanced";
      btn.className = state.activeDeck === deck ? "active" : "";
      btn.addEventListener("click", () => {
        const nextState = { ...state, activeDeck: deck };
        setState(nextState);
        saveState(nextState, storage);
        render();
      });
      deckToggle.appendChild(btn);
    }
    container.appendChild(deckToggle);

    const progress = computeProgress(allWords, state.words, state.activeDeck);
    const progressLabel = document.createElement("div");
    progressLabel.className = "progress-label";
    progressLabel.textContent = `${progress.learnt} / ${progress.total} learnt`;
    container.appendChild(progressLabel);

    const currentWord = allWords.find((w) => w.id === state.lastShownWordId && w.deck === state.activeDeck);

    if (!currentWord) {
      renderNoCurrentWord(container, state);
    } else {
      renderWordCard(container, currentWord, state);
    }
  }

  function renderNoCurrentWord(container, state) {
    const card = document.createElement("div");
    card.className = "word-card empty-state";
    card.textContent = "Press “New Word” to start learning.";
    container.appendChild(card);
    container.appendChild(buildButtonRow(state, null));
  }

  function renderWordCard(container, word, state) {
    const isLearnt = state.words[word.id]?.status === "learnt";

    const card = document.createElement("div");
    card.className = "word-card";

    const label = document.createElement("div");
    label.className = "word-label";
    label.textContent = "✦ Current word";
    card.appendChild(label);

    const title = document.createElement("div");
    title.className = "word-title";
    title.textContent = word.word;
    card.appendChild(title);

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

    container.appendChild(card);
    container.appendChild(buildButtonRow(state, word, isLearnt));
  }

  function buildButtonRow(state, word, isLearnt) {
    const row = document.createElement("div");
    row.className = "button-row";

    const newWordBtn = document.createElement("button");
    newWordBtn.className = "btn-primary";
    newWordBtn.textContent = "New Word";
    newWordBtn.addEventListener("click", () => {
      const { word: nextWord, nextStateMap } = pickNewWord(allWords, state.words, state.activeDeck);
      const nextState = {
        ...state,
        words: nextStateMap,
        lastShownWordId: nextWord ? nextWord.id : null,
      };
      setState(nextState);
      saveState(nextState, storage);
      render();
    });
    row.appendChild(newWordBtn);

    const learntBtn = document.createElement("button");
    learntBtn.className = "btn-secondary" + (isLearnt ? " confirmed" : "");
    learntBtn.textContent = isLearnt ? "✓ Learnt" : "Mark as Learnt";
    learntBtn.disabled = !word || isLearnt;
    learntBtn.addEventListener("click", () => {
      if (!word) return;
      const nextWords = markLearnt(word.id, word.deck, state.words, todayIso());
      const nextState = { ...state, words: nextWords };
      setState(nextState);
      saveState(nextState, storage);
      render();
    });
    row.appendChild(learntBtn);

    return row;
  }

  return { render };
}
