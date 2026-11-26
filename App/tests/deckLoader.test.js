import { test } from "node:test";
import assert from "node:assert/strict";
import { validateDeck, loadDecks } from "../js/deckLoader.js";

const goodWord = {
  id: "abundant",
  word: "Abundant",
  pronunciation: "uh-BUN-dant",
  deck: "everyday",
  meanings: [{ partOfSpeech: "adjective", definition: "plentiful", example: "Rain is abundant here." }],
};

test("validateDeck accepts a well-formed entry", () => {
  const result = validateDeck([goodWord], "everyday");
  assert.equal(result.words.length, 1);
  assert.equal(result.droppedCount, 0);
  assert.equal(result.loadFailed, false);
});

test("validateDeck drops an entry missing a required field", () => {
  const badWord = { ...goodWord, pronunciation: "" };
  const result = validateDeck([goodWord, badWord], "everyday");
  assert.equal(result.words.length, 1);
  assert.equal(result.droppedCount, 1);
});

test("validateDeck drops an entry with an empty meanings array", () => {
  const badWord = { ...goodWord, id: "x", meanings: [] };
  const result = validateDeck([goodWord, badWord], "everyday");
  assert.equal(result.words.length, 1);
  assert.equal(result.droppedCount, 1);
});

test("validateDeck drops an entry whose deck tag doesn't match the expected deck", () => {
  const mismatched = { ...goodWord, id: "y", deck: "advanced" };
  const result = validateDeck([goodWord, mismatched], "everyday");
  assert.equal(result.words.length, 1);
  assert.equal(result.droppedCount, 1);
});

test("validateDeck flags loadFailed when given non-array input", () => {
  const result = validateDeck(null, "everyday");
  assert.equal(result.loadFailed, true);
  assert.deepEqual(result.words, []);
});

test("loadDecks keeps advanced deck usable when everyday deck fails to load", () => {
  const advancedWord = { ...goodWord, id: "legerdemain", deck: "advanced" };
  const result = loadDecks(undefined, [advancedWord]);
  assert.equal(result.everyday.loadFailed, true);
  assert.equal(result.advanced.loadFailed, false);
  assert.equal(result.allWords.length, 1);
  assert.equal(result.allWords[0].id, "legerdemain");
});
