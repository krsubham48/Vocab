# Before the first App Store upload

Ready: the words, app icon, privacy manifest, listing text and screenshots. The
privacy policy and help pages are published with the web app. The steps below
need you.

1. **Read through the words.** Claude wrote and checked both decks; no person has
   proofread them. The web app still uses its older Advanced list, which appears
   to be SparkNotes'; do not add that list to the iOS app.
2. **Apple Developer Program.** Enrol with your Apple ID (US$99 a year). As an
   individual, your legal name is shown on the store as the seller.
3. **Signing.** In Xcode: Vocab target, Signing & Capabilities, choose your team.
4. **Bundle identifier.** `io.github.krsubham48.vocab`. Change it now if you want
   another; it cannot change after the first upload.
5. **App record.** Create it in App Store Connect and fill it from
   [AppStore/listing.md](AppStore/listing.md). Choose countries; for the EU you are
   also asked whether you are a "trader", whose contact details are shown publicly.
6. **Screenshots.** Upload the sets in `AppStore/screenshots/`.
7. **Upload.** Choose "Any iOS Device", Product > Archive, Distribute App. Uploads
   need Xcode 26 or later. Try it through TestFlight before submitting for review.
8. **Later uploads.** Raise the build number each time (`CURRENT_PROJECT_VERSION`),
    and the version (`MARKETING_VERSION`) for a new release.
