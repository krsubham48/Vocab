# Vocab — Design Spec

Date: 2026-11-25

## Purpose

A vocabulary-building app for an Indian English speaker with intermediate English knowledge. It teaches words commonly encountered in newspapers, magazines, TV series, and everyday conversation — explicitly not the rarest/most obscure words. It must run locally on an iPhone, with a simple and visually appealing UI.

## Platform Decision

**Progressive Web App (PWA)**, not a native Swift/SwiftUI app.

The development machine has Xcode Command Line Tools but not the full Xcode.app installed. Building a native iOS app would require installing Xcode (7-12GB, 30-60+ min) and would prevent Claude from independently building, running, or testing the app — the user would have to do all compiling/verification in Xcode/Simulator. Free Apple ID sideloads also expire after 7 days without a paid Apple Developer account.

A PWA avoids all of this:
- Built with vanilla HTML/CSS/JS — no framework, no build step, no Node toolchain dependency.
- Installed via Safari's "Add to Home Screen" — runs full-screen like a native app, works fully offline, no App Store or Apple ID required, no expiry.
- Claude can run and test it locally in a browser (via Python's built-in `http.server`) before the user ever installs it on-device.

## Architecture

Pure client-side, no backend, no network calls at runtime.

- **HTML/CSS/JS**, vanilla — no framework, no build step.
- **Word data**: two bundled JS data files (`words-everyday.js`, `words-advanced.js`) — no API, no internet needed after install.
- **Persistence**: `localStorage` on-device, storing per-word state and per-day learnt history for the calendar.
- **Install mechanism**: PWA manifest (`manifest.json`) + service worker (`sw.js`) so Safari's "Add to Home Screen" produces a full-screen, offline-capable home screen app.
- **Dev/test loop**: a local static file server (Python's `http.server`) for Claude and the user to view and click through the app in a browser before installing on iPhone.

All files live in `App/`:
```
App/
  index.html
  styles.css
  app.js
  words-everyday.js
  words-advanced.js
  manifest.json
  sw.js
  icons/
    (generated app icon assets, multiple sizes)
```

## Visual Design

Decided via visual brainstorming with the user (mockups in `.superpowers/brainstorm/`):

- **Palette**: lavender gradient (light lavender background gradient; buttons use a purple gradient from `#a177f0` to `#6b2fb3`).
- **Typography**: Helvetica / Helvetica Neue throughout.
- **Style**: warm, rounded, friendly — rounded cards (14-20px radius), soft shadows, generous padding. Not the stark minimal/editorial alternatives that were also considered.
- **Navigation**: bottom tab bar with 3 tabs — Learn (open book icon), Revise (card stack icon 🗂️), Calendar (📅 icon). Active tab shown with the purple gradient icon background.
- **App icon**: "Vocab" wordmark in bold Helvetica, white text on the lavender/purple gradient background, with a small white underline accent beneath the text.

## Content & Word Bank

Two decks, sharing one data shape:

```js
{
  id: "abundant",             // unique key, derived from the word
  word: "Abundant",
  pronunciation: "uh-BUN-dant",  // simple phonetic spelling, not IPA
  deck: "everyday" | "advanced",
  meanings: [
    { partOfSpeech: "adjective", definition: "Existing or available in large quantities; plentiful.", example: "The region has abundant rainfall." }
    // 1-2 meanings per word, each with its own part of speech + one example sentence.
    // partOfSpeech lives per-meaning (not at the word level) because some words carry a
    // different part of speech across meanings, e.g. "annex" (v. to incorporate territory;
    // n. a room attached to a larger space) or "attribute" (v. to credit; n. a trait).
  ]
}
```

**Everyday deck** (~300 words): hand-curated by Claude for common newspaper/magazine/TV/conversational usage. This is the default, primary deck — it directly serves the app's core purpose of building practical everyday vocabulary for an intermediate English speaker.

**Advanced deck** (1000 words): sourced from the user-provided SAT vocabulary list (`sat.vocab.pdf`). This list skews significantly more advanced/rare than the app's core goal (e.g., "legerdemain", "pulchritude", "sycophant"), so it is kept as an explicitly separate, opt-in deck rather than merged into the everyday word pool. Content (word, part of speech, definition, example) is parsed from the existing PDF text. Pronunciation is generated programmatically from the CMU Pronouncing Dictionary (a free, standard pronunciation data source) mapped to simple phonetic spelling, for consistency across 1000 entries; if that data source is unavailable in this environment, pronunciations are authored manually in batches instead.

The source PDF's example sentences include a small number of entries with mature references (e.g., innuendo, drinking/gambling, dark humor) mixed in with its characteristic joke-y tone. Since this is a personal app for an adult user, most entries are kept as-is to preserve that tone; only the handful of entries with overtly explicit/inappropriate content get a lightly rewritten example sentence (same word, definition, and difficulty — just a cleaner example). This is a judgment call made during content generation, not a structural feature.

Both decks are bundled into the app at build time — no internet required at runtime.

## Screens & Navigation

Bottom tab bar with three tabs. Tab state (scroll position, in-progress revise session, etc.) is preserved when switching tabs.

### 1. Learn (home tab)
- Deck toggle at the top: **Everyday** / **Advanced** segmented control. Switching decks changes which pool "New Word" draws from; it does not affect Revise or Calendar (see Data Flow).
- Word card: word, pronunciation, and one or more meanings, each showing its own part of speech, definition, and example sentence.
- Progress indicator, e.g. "12 / 300 learnt" for the active deck.
- **New Word** button: shows the next word from the active deck (see selection rule below).
- **Mark as Learnt** button: marks the currently displayed word as learnt for today. Disables / changes to a confirmed state ("✓ Learnt") until a new word is drawn.

### 2. Revise
- Flashcard self-check over all words with status `learnt`, pooled across **both** decks (each card shows which deck the word came from).
- Shows the word; user mentally recalls the meaning, taps to reveal the definition/example; then self-marks **Got it** or **Still learning** (see Data Flow for effect — currently: no status change, purely a self-assessment signal for the user's own benefit).
- Empty state if there are no learnt words yet: "Learn and mark some words first!"

### 3. Calendar
- Month grid view. Days with at least one word marked learnt show a dot/highlight.
- Tapping a date shows the list of words marked learnt on that date (word + which deck it belongs to).

## Data Flow & State

All state lives in `localStorage`, keyed by word id:

```js
{
  words: {
    "abundant": { deck: "everyday", status: "unseen" | "seen" | "learnt", learntDate: "2026-11-25" | null }
    // ... one entry per word across both decks
  },
  lastShownWordId: "abundant",      // so reopening the app shows the same card, not a fresh pick
  activeDeck: "everyday"             // remembers the last-selected deck toggle position
}
```

**New Word press:**
1. Filter the active deck's words to `status != "learnt"` (i.e., `unseen` or `seen` are both eligible — a word stays in rotation until explicitly marked learnt).
2. Pick one at random from that filtered set.
3. If the set is empty, show a completion state ("You've learnt every word in this deck!") instead of a word card.
4. If the picked word's status was `unseen`, update it to `seen`.
5. Update `lastShownWordId`.

**Mark as Learnt press:**
1. Set the current word's `status = "learnt"` and `learntDate` = today's date (local device date).
2. Update the button to a confirmed/disabled state until the next "New Word" press.

**Revise:**
1. Collect every word across both decks where `status == "learnt"`.
2. Present as a flashcard loop (word → reveal → self-mark Got it / Still learning).
3. Self-marks do not change word status (confirmed with user) — Revise is a non-destructive self-check layer on top of the Learn tab's progress tracking.

**Calendar:**
1. Group all `learnt` words by `learntDate`.
2. Render a dot/highlight on any date with ≥1 entry.
3. Tapping a date filters the word list to that date's entries.

**App reopen:** the Learn tab shows `lastShownWordId`'s card rather than drawing a new word, so closing and reopening Safari (or relaunching the home-screen app) doesn't silently burn through words.

## Error Handling

Scoped to what's actually possible in a fully offline, no-backend app:

- **`localStorage` write failure** (e.g., storage full — very unlikely at this data scale, a few hundred KB max for ~1300 words of state): caught and surfaced as a non-blocking toast rather than crashing the app.
- **Malformed/missing word data on load**: defensive parsing when loading each deck at startup. If one deck fails to load, the app shows an error state for that deck only — the other deck and the rest of the app (Revise, Calendar) continue to function normally.
- No network/offline-retry handling is needed since the app makes no network calls at runtime.

## Testing Approach

Manual testing, appropriate for a small, build-step-free, backend-free personal app:

1. Claude runs a local static server (Python's `http.server`) and exercises the app in a desktop browser to verify layout, interactions, and logic.
2. Claude uses Chrome DevTools' iPhone device emulation to sanity-check mobile layout before real-device testing.
3. The user performs the authoritative test on their actual iPhone via Safari — both as a regular browser tab and after "Add to Home Screen" — since standalone display mode, home screen icon rendering, and on-device `localStorage` persistence can only be fully confirmed on real hardware.
4. A manual test checklist covers: pressing New Word repeatedly (including deck exhaustion), marking words learnt, switching between Everyday/Advanced decks, using Revise (including the empty state), checking the Calendar (including tapping dates with and without entries), and closing/reopening the app to confirm state persists correctly.

No automated test suite — not warranted for a UI-driven, no-backend, personal-use app at this scope.

## Installation (end-user instructions, to be finalized after implementation)

**Hosting decision:** iOS only allows a web app to fully cache itself for true offline use (launchable without any server, any WiFi network, or the development Mac being on) when served over real HTTPS from a public host. A local Wi-Fi server on the user's Mac would only let the app open while that Mac is awake, the server is running, and the iPhone is on the same network — unacceptable for a daily-use app. So the app will be published to a free static host (e.g., GitHub Pages) instead.

Note: this publishes the `App/` folder's code and bundled word-list files publicly. The user's personal learning progress (word states, learnt dates) lives only in the iPhone's on-device `localStorage` and is never uploaded anywhere — only the static app code and word content are hosted.

Once built, verified locally, and published, the user will:
1. Open the app's public URL in Safari on the iPhone.
2. Tap the Share icon → "Add to Home Screen".
3. Launch "Vocab" from the home screen like any other app — from then on it works fully offline, without WiFi or any server being active.

Exact publishing steps (e.g., GitHub account/repo setup) will be provided as a follow-up instructions document once the app is implemented and locally verified.
