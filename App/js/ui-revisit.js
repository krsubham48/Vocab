import { getRevisePool } from "./wordState.js";
import { createSession, answerCard } from "./revisitSession.js";

function element(tag, className, text) {
  const el = document.createElement(tag);
  el.className = className;
  if (text !== undefined) el.textContent = text;
  return el;
}

// The round survives tab switches; it restarts only when the set of learnt
// words changes.
export function createRevisitView({ container, allWords, getState }) {
  let pool = [];
  let poolKey = null;
  let session = null;
  let revealed = false;

  function render() {
    pool = getRevisePool(allWords, getState().words);
    const key = pool.map((w) => w.id).join("|");
    if (key !== poolKey) {
      poolKey = key;
      restart();
    }
    draw();
  }

  function restart() {
    session = createSession(pool);
    revealed = false;
  }

  function draw() {
    container.innerHTML = "";

    if (session.total === 0) {
      container.appendChild(element("div", "word-card empty-state", "Learn and mark some words first!"));
    } else if (session.queue.length === 0) {
      drawSummary();
    } else {
      drawCard();
    }
  }

  function drawCard() {
    const word = session.queue[0];
    const done = session.total - session.queue.length;
    container.appendChild(element("div", "progress-label", `Got ${done} of ${session.total}`));

    const card = element("div", "flashcard");
    card.appendChild(element("div", "flashcard-deck-tag", word.deck === "everyday" ? "Everyday" : "Advanced"));
    card.appendChild(element("div", "flashcard-word", word.word));

    if (revealed) {
      card.appendChild(element("div", "word-pronunciation", word.pronunciation));
      for (const meaning of word.meanings) {
        const block = element("div", "meaning-block flashcard-meaning");
        block.appendChild(element("div", "meaning-pos", meaning.partOfSpeech));
        block.appendChild(element("div", "meaning-definition", meaning.definition));
        block.appendChild(element("div", "meaning-example", `“${meaning.example}”`));
        card.appendChild(block);
      }
    } else {
      card.appendChild(element("div", "flashcard-reveal-hint", "Tap to reveal the meaning"));
      card.addEventListener("click", () => {
        revealed = true;
        draw();
      });
    }
    container.appendChild(card);

    if (revealed) {
      const row = element("div", "button-row");
      row.appendChild(answerButton("btn-primary", "Got it", true));
      row.appendChild(answerButton("btn-secondary", "Still learning", false));
      container.appendChild(row);
    }
  }

  function answerButton(className, text, gotIt) {
    const button = element("button", className, text);
    button.addEventListener("click", () => {
      session = answerCard(session, gotIt);
      revealed = false;
      draw();
    });
    return button;
  }

  function drawSummary() {
    const missed = session.missedIds.length;
    const card = element("div", "word-card empty-state");
    card.appendChild(element("div", "flashcard-word", "Round complete"));
    card.appendChild(element(
      "div",
      "flashcard-reveal-hint",
      `${session.total - missed} of ${session.total} right first time` +
        (missed ? `, ${missed} needed another go.` : ".")
    ));
    container.appendChild(card);

    const row = element("div", "button-row");
    const again = element("button", "btn-primary", "Start again");
    again.addEventListener("click", () => {
      restart();
      draw();
    });
    row.appendChild(again);
    container.appendChild(row);
  }

  return { render };
}
