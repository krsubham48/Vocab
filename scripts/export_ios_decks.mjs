// Exports the web app's Everyday list to JSON for the iOS app.
// Run after changing it: node scripts/export_ios_decks.mjs
//
// The iOS Advanced deck is a separate, original list: see
// scripts/generate_ios_advanced_deck.py. This script must not overwrite it.
import { mkdir, writeFile } from "node:fs/promises";
import { wordsEveryday } from "../App/js/words-everyday.js";

const folder = new URL("../ios/Vocab/Resources/", import.meta.url);
await mkdir(folder, { recursive: true });
await writeFile(new URL("words-everyday.json", folder), JSON.stringify(wordsEveryday, null, 1) + "\n");
console.log(`words-everyday.json: ${wordsEveryday.length} words`);
