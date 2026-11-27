# Vocab for iPhone and iPad

A native SwiftUI version of the web app in `App/`, with the same features: Learn,
Revise, Revisit, Calendar and About. It works fully offline.

## Open and run

1. Open `ios/Vocab.xcodeproj` in Xcode.
2. Pick an iPhone or iPad simulator and press Run.

To try it on your own iPhone, select the phone as the destination and choose your
team under Signing & Capabilities. A free Apple ID works, but the installed app
expires after 7 days. A paid developer membership removes that limit.

## Tests

```bash
xcodebuild test -project ios/Vocab.xcodeproj -scheme Vocab \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

`VocabTests` covers the word logic, calendar, saving and app state. `VocabUITests`
drives every flow, including very large text and landscape, and keeps screenshots
in the result bundle.

## Words and icon

- **Everyday** comes from the web app's list. After changing it, run
  `node scripts/export_ios_decks.mjs`.
- **Advanced** is an original list for this app, in `scripts/advanced_words/`
  (one word per line). After changing it, run
  `python3 scripts/generate_ios_advanced_deck.py` (needs `pip install cmudict`).
  It rejects duplicates, words already in Everyday and missing pronunciations.
- **Icon:** `python3 scripts/generate_icons.py` (needs Pillow) writes the web and
  iOS icons.

## How it differs from the web app

- The Advanced deck is different: an original list of 1,018 words, none of them
  also in Everyday.
- Progress is separate from the web app; nothing moves across by itself.
- Light appearance only.

Before putting it on the App Store, work through [RELEASE.md](RELEASE.md).
