// Search over word names and definitions. Name matches are listed first, and
// each group is alphabetical.
export function searchWords(words, query) {
  const needle = query.trim().toLowerCase();
  const sorted = [...words].sort((a, b) => a.word.localeCompare(b.word, "en", { sensitivity: "base" }));
  if (!needle) return sorted;

  const nameMatches = sorted.filter((w) => w.word.toLowerCase().includes(needle));
  const definitionMatches = sorted.filter(
    (w) => !nameMatches.includes(w) && w.meanings.some((m) => m.definition.toLowerCase().includes(needle))
  );
  return [...nameMatches, ...definitionMatches];
}
