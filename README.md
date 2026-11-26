# Vocab

A simple vocabulary-building app for learning everyday English words commonly used in newspapers, magazines, TV, and conversation — built as an offline-capable web app you install on your iPhone home screen.

## What it does

- **Learn**: press "New Word" to see a word, its pronunciation, and one or more meanings with examples. Press "Mark as Learnt" once you've got it.
- **Revise**: self-check flashcards over every word you've marked learnt.
- **Calendar**: tap any date to see what you learnt that day.
- Two decks: **Everyday** (~300 common words) and **Advanced** (1000 more challenging words), switchable from the Learn tab.
- Fully offline after install — no account, no internet needed day-to-day.

## Installing on your iPhone

This app needs to be hosted somewhere with a real `https://` address before Safari can install it with full offline support (a `file://` link or a plain local-network address won't let iOS cache it for offline use). This repo includes a GitHub Actions workflow that publishes the `App/` folder to **GitHub Pages** automatically — using your own personal GitHub account (github.com — not any company/internal GitHub).

### 1. Push this repo to your personal GitHub account

On a machine where you're logged into your personal GitHub account, create a new empty repository on github.com first (e.g. named `vocab`), then:

```bash
cd vocab-app   # this project folder
git remote add origin https://github.com/<your-username>/vocab.git
git push -u origin main
```

**Note:** this publishes the app's code and the two bundled word lists publicly. Your personal learning progress is never part of this — it lives only in your iPhone's on-device storage and is never uploaded anywhere.

### 2. Enable GitHub Pages (via GitHub Actions)

1. On GitHub, go to your repo's **Settings → Pages**.
2. Under "Build and deployment" → "Source," choose **"GitHub Actions"** (not "Deploy from a branch" — this repo serves the app from the `App/` subfolder, which only the Actions-based method supports).
3. Go to the **Actions** tab. The "Deploy Vocab to GitHub Pages" workflow should run automatically after your push in step 1 (if it doesn't, click it and choose "Run workflow").
4. Once the workflow finishes (green checkmark), go back to **Settings → Pages** — it will show your live URL, something like `https://<your-username>.github.io/vocab/`.
5. Open that URL in a browser to confirm the app loads.

### 3. Install on your iPhone

1. Open the GitHub Pages URL from step 2 in **Safari** on your iPhone (must be Safari, not Chrome or another browser — "Add to Home Screen" with full offline support only works from Safari on iOS).
2. Tap the **Share** button (square with an arrow pointing up).
3. Scroll down and tap **"Add to Home Screen."**
4. Tap **"Add"** in the top-right corner.
5. Find the **Vocab** icon on your home screen and open it — it now runs full-screen like a native app.

From then on, Vocab works fully offline: no WiFi, no server, no laptop needed. If you ever update the word lists or app code and push again, the workflow redeploys automatically, and reopening the app on your phone will pick up the update (the service worker checks for changes).

## Updating the word lists

The word content is generated from scripts in `scripts/`, not hand-edited in `App/js/words-*.js` directly:

- Everyday deck: edit `scripts/everyday_words_raw.py`, then run `python3 scripts/generate_everyday_deck.py`.
- Advanced deck: re-run `python3 scripts/parse_advanced_deck.py` if the source text changes.

Both scripts regenerate the corresponding `App/js/words-*.js` file in place.

## Running locally for development

```bash
cd App
python3 -m http.server 8765
```

Then open `http://localhost:8765/` in a browser. Run the test suite with:

```bash
cd App
node --test "tests/**/*.test.js"
```
