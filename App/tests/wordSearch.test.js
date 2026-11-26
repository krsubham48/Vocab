import { test } from "node:test";
import assert from "node:assert/strict";
import { searchWords } from "../js/wordSearch.js";

const words = [
  { word: "Timorous", meanings: [{ definition: "timid, fearful", example: "Tallulah broke into tears." }] },
  { word: "abundant", meanings: [{ definition: "more than enough", example: "Food was abundant." }] },
  { word: "Candid", meanings: [{ definition: "frank", example: "a candid reply" }, { definition: "unposed", example: "a photo" }] },
];
const found = (query) => searchWords(words, query).map((w) => w.word);

test("an empty query returns every word in alphabetical order, ignoring case", () => {
  assert.deepEqual(found("   "), ["abundant", "Candid", "Timorous"]);
  assert.equal(words[0].word, "Timorous");
});

test("matches part of the word, ignoring case and surrounding spaces", () => {
  assert.deepEqual(found("  IMOR "), ["Timorous"]);
});

test("matches any meaning's definition", () => {
  assert.deepEqual(found("fearful"), ["Timorous"]);
  assert.deepEqual(found("unposed"), ["Candid"]);
});

test("lists words matching by name before words matching by definition", () => {
  assert.deepEqual(found("an"), ["abundant", "Candid"]);
  assert.deepEqual(found("ti"), ["Timorous"]);
  const mixed = [{ word: "alpha", meanings: [{ definition: "beta" }] }, { word: "beta", meanings: [{ definition: "x" }] }];
  assert.deepEqual(searchWords(mixed, "beta").map((w) => w.word), ["beta", "alpha"]);
});

test("returns nothing when there is no match, and ignores example sentences", () => {
  assert.deepEqual(found("tallulah"), []);
});
