// Pure logic for word selection, progress, and revision pooling.
// No DOM, no localStorage — operates entirely on plain objects/arrays so it can
// be unit tested directly with Node's built-in test runner.

export function pickNewWord(allWords, stateMap, activeDeck) {
  const eligible = allWords.filter(
    (w) => w.deck === activeDeck && stateMap[w.id]?.status !== "learnt"
  );
  if (eligible.length === 0) {
    return { word: null, nextStateMap: stateMap };
  }
  const chosen = eligible[Math.floor(Math.random() * eligible.length)];
  const currentStatus = stateMap[chosen.id]?.status ?? "unseen";
  if (currentStatus === "unseen") {
    return {
      word: chosen,
      nextStateMap: {
        ...stateMap,
        [chosen.id]: { ...stateMap[chosen.id], deck: chosen.deck, status: "seen", learntDate: null },
      },
    };
  }
  return { word: chosen, nextStateMap: stateMap };
}

export function markLearnt(wordId, deck, stateMap, todayIso) {
  return {
    ...stateMap,
    [wordId]: { deck, status: "learnt", learntDate: todayIso },
  };
}

export function unmarkLearnt(wordId, stateMap) {
  if (stateMap[wordId]?.status !== "learnt") return stateMap;
  return {
    ...stateMap,
    [wordId]: { ...stateMap[wordId], status: "seen", learntDate: null },
  };
}

export function computeProgress(allWords, stateMap, activeDeck) {
  const deckWords = allWords.filter((w) => w.deck === activeDeck);
  const learntCount = deckWords.filter((w) => stateMap[w.id]?.status === "learnt").length;
  return { learnt: learntCount, total: deckWords.length };
}

export function getRevisePool(allWords, stateMap) {
  return allWords.filter((w) => stateMap[w.id]?.status === "learnt");
}

export function groupLearntByDate(allWords, stateMap) {
  const byDate = {};
  for (const w of allWords) {
    const entry = stateMap[w.id];
    if (entry?.status === "learnt" && entry.learntDate) {
      if (!byDate[entry.learntDate]) byDate[entry.learntDate] = [];
      byDate[entry.learntDate].push(w);
    }
  }
  return byDate;
}
