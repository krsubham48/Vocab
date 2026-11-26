import { test } from "node:test";
import assert from "node:assert/strict";
import { createSession, answerCard, shuffle } from "../js/revisitSession.js";

const words = [{ id: "a" }, { id: "b" }, { id: "c" }];
const ids = (list) => list.map((w) => w.id);

test("shuffle keeps every item and leaves the input untouched", () => {
  const input = [1, 2, 3, 4, 5];
  const result = shuffle(input, () => 0);
  assert.deepEqual(input, [1, 2, 3, 4, 5]);
  assert.notDeepEqual(result, input);
  assert.deepEqual([...result].sort(), input);
});

test("createSession queues every word with nothing answered yet", () => {
  const session = createSession(words, () => 0.99);
  assert.deepEqual(ids(session.queue), ["a", "b", "c"]);
  assert.equal(session.total, 3);
  assert.deepEqual(session.missedIds, []);
});

test("answering 'got it' removes the card from the round", () => {
  const next = answerCard(createSession(words, () => 0.99), true);
  assert.deepEqual(ids(next.queue), ["b", "c"]);
  assert.equal(next.total, 3);
  assert.deepEqual(next.missedIds, []);
});

test("answering 'still learning' sends the card to the back and records it once", () => {
  let session = answerCard(createSession(words, () => 0.99), false);
  assert.deepEqual(ids(session.queue), ["b", "c", "a"]);
  session = answerCard(answerCard(answerCard(session, true), true), false);
  assert.deepEqual(ids(session.queue), ["a"]);
  assert.deepEqual(session.missedIds, ["a"]);
});

test("the round is over once every card has been got", () => {
  let session = createSession(words, () => 0.99);
  for (let i = 0; i < 3; i++) session = answerCard(session, true);
  assert.equal(session.queue.length, 0);
  assert.equal(answerCard(session, true), session);
});
