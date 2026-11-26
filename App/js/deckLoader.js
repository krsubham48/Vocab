// Defensive validation for bundled deck data (spec: "Malformed/missing word data on load").
// A deck is an array of word entries; validateDeck filters out malformed entries
// individually rather than rejecting the whole deck, and reports what it dropped.

function isValidMeaning(m) {
  return (
    m &&
    typeof m.partOfSpeech === "string" &&
    m.partOfSpeech.length > 0 &&
    typeof m.definition === "string" &&
    m.definition.length > 0 &&
    typeof m.example === "string" &&
    m.example.length > 0
  );
}

function isValidWordEntry(entry, expectedDeck) {
  return (
    entry &&
    typeof entry.id === "string" &&
    entry.id.length > 0 &&
    typeof entry.word === "string" &&
    entry.word.length > 0 &&
    typeof entry.pronunciation === "string" &&
    entry.pronunciation.length > 0 &&
    entry.deck === expectedDeck &&
    Array.isArray(entry.meanings) &&
    entry.meanings.length > 0 &&
    entry.meanings.every(isValidMeaning)
  );
}

export function validateDeck(rawDeckArray, expectedDeck) {
  if (!Array.isArray(rawDeckArray)) {
    return { words: [], droppedCount: 0, loadFailed: true };
  }
  const words = [];
  let droppedCount = 0;
  for (const entry of rawDeckArray) {
    if (isValidWordEntry(entry, expectedDeck)) {
      words.push(entry);
    } else {
      droppedCount++;
    }
  }
  return { words, droppedCount, loadFailed: false };
}

export function loadDecks(everydayRaw, advancedRaw) {
  const everyday = validateDeck(everydayRaw, "everyday");
  const advanced = validateDeck(advancedRaw, "advanced");
  return {
    everyday,
    advanced,
    allWords: [...everyday.words, ...advanced.words],
  };
}
