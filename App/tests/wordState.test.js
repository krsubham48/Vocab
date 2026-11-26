import { test } from "node:test";
import assert from "node:assert/strict";
import {
  pickNewWord,
  markLearnt,
  computeProgress,
  getRevisePool,
  groupLearntByDate,
} from "../js/wordState.js";

const words = [
  { id: "abundant", deck: "everyday" },
  { id: "candid", deck: "everyday" },
  { id: "legerdemain", deck: "advanced" },
];

test("pickNewWord excludes learnt words and respects active deck", () => {
  const stateMap = { abundant: { deck: "everyday", status: "learnt", learntDate: "2026-11-25" } };
  const { word } = pickNewWord(words, stateMap, "everyday");
  assert.equal(word.id, "candid");
});

test("pickNewWord returns null when deck is fully learnt", () => {
  const stateMap = {
    abundant: { deck: "everyday", status: "learnt", learntDate: "2026-11-25" },
    candid: { deck: "everyday", status: "learnt", learntDate: "2026-11-25" },
  };
  const { word } = pickNewWord(words, stateMap, "everyday");
  assert.equal(word, null);
});

test("pickNewWord marks an unseen word as seen", () => {
  const { word, nextStateMap } = pickNewWord(words, {}, "everyday");
  assert.ok(["abundant", "candid"].includes(word.id));
  assert.equal(nextStateMap[word.id].status, "seen");
});

test("pickNewWord can re-draw a seen-but-not-learnt word without changing its status", () => {
  const stateMap = { abundant: { deck: "everyday", status: "seen", learntDate: null } };
  const narrowedWords = [words[0]];
  const { word, nextStateMap } = pickNewWord(narrowedWords, stateMap, "everyday");
  assert.equal(word.id, "abundant");
  assert.equal(nextStateMap.abundant.status, "seen");
});

test("markLearnt sets status and learntDate", () => {
  const next = markLearnt("abundant", "everyday", {}, "2026-11-25");
  assert.deepEqual(next.abundant, { deck: "everyday", status: "learnt", learntDate: "2026-11-25" });
});

test("computeProgress counts only learnt words in the active deck", () => {
  const stateMap = {
    abundant: { deck: "everyday", status: "learnt", learntDate: "2026-11-25" },
    legerdemain: { deck: "advanced", status: "learnt", learntDate: "2026-11-25" },
  };
  const progress = computeProgress(words, stateMap, "everyday");
  assert.deepEqual(progress, { learnt: 1, total: 2 });
});

test("getRevisePool pools learnt words across both decks", () => {
  const stateMap = {
    abundant: { deck: "everyday", status: "learnt", learntDate: "2026-11-25" },
    legerdemain: { deck: "advanced", status: "learnt", learntDate: "2026-11-25" },
    candid: { deck: "everyday", status: "seen", learntDate: null },
  };
  const pool = getRevisePool(words, stateMap);
  assert.deepEqual(
    pool.map((w) => w.id).sort(),
    ["abundant", "legerdemain"]
  );
});

test("groupLearntByDate groups words learnt on the same day", () => {
  const stateMap = {
    abundant: { deck: "everyday", status: "learnt", learntDate: "2026-11-25" },
    candid: { deck: "everyday", status: "learnt", learntDate: "2026-11-25" },
    legerdemain: { deck: "advanced", status: "learnt", learntDate: "2026-11-24" },
  };
  const grouped = groupLearntByDate(words, stateMap);
  assert.equal(grouped["2026-11-25"].length, 2);
  assert.equal(grouped["2026-11-24"].length, 1);
});
