const STORAGE_KEY = "vocab-app-state";

export function defaultState() {
  return { words: {}, lastShownWordId: null, activeDeck: "everyday" };
}

export function loadState(storage) {
  try {
    const raw = storage.getItem(STORAGE_KEY);
    if (!raw) return defaultState();
    const parsed = JSON.parse(raw);
    if (!parsed || typeof parsed !== "object" || !parsed.words) return defaultState();
    return parsed;
  } catch {
    return defaultState();
  }
}

export function saveState(state, storage) {
  try {
    storage.setItem(STORAGE_KEY, JSON.stringify(state));
    return { ok: true };
  } catch (err) {
    return { ok: false, error: String(err) };
  }
}
