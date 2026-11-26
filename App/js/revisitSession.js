// Pure logic for one round of the Revisit tab. A round ends when every card
// has been answered "got it"; "still learning" cards go to the back of the queue.

export function shuffle(items, random = Math.random) {
  const result = [...items];
  for (let i = result.length - 1; i > 0; i--) {
    const j = Math.floor(random() * (i + 1));
    [result[i], result[j]] = [result[j], result[i]];
  }
  return result;
}

export function createSession(words, random = Math.random) {
  return { queue: shuffle(words, random), total: words.length, missedIds: [] };
}

export function answerCard(session, gotIt) {
  if (session.queue.length === 0) return session;
  const [current, ...rest] = session.queue;
  if (gotIt) return { ...session, queue: rest };

  const missedIds = session.missedIds.includes(current.id)
    ? session.missedIds
    : [...session.missedIds, current.id];
  return { ...session, queue: [...rest, current], missedIds };
}
