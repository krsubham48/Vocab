import { test } from "node:test";
import assert from "node:assert/strict";
import { loadState, saveState, defaultState } from "../js/storage.js";

function makeFakeStorage(initial = {}) {
  const map = new Map(Object.entries(initial));
  return {
    getItem: (k) => (map.has(k) ? map.get(k) : null),
    setItem: (k, v) => map.set(k, v),
  };
}

test("loadState returns default state when storage is empty", () => {
  const storage = makeFakeStorage();
  assert.deepEqual(loadState(storage), defaultState());
});

test("saveState then loadState round-trips correctly", () => {
  const storage = makeFakeStorage();
  const state = {
    words: { abundant: { deck: "everyday", status: "learnt", learntDate: "2026-11-25" } },
    lastShownWordId: "abundant",
    activeDeck: "everyday",
  };
  const result = saveState(state, storage);
  assert.equal(result.ok, true);
  assert.deepEqual(loadState(storage), state);
});

test("loadState falls back to default on corrupted JSON", () => {
  const storage = makeFakeStorage({ "vocab-app-state": "{not valid json" });
  assert.deepEqual(loadState(storage), defaultState());
});

test("saveState reports failure without throwing when storage.setItem throws", () => {
  const storage = {
    getItem: () => null,
    setItem: () => { throw new Error("QuotaExceededError"); },
  };
  const result = saveState({ words: {} }, storage);
  assert.equal(result.ok, false);
  assert.match(result.error, /QuotaExceededError/);
});
