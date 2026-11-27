# Before the first App Store upload

1. **Proofread the words.** Both iOS decks are original to Vocab: Everyday (294
   words) and Advanced (1,018 words). They were written by Claude and checked by
   script, not by a person, so read through them before release. The web app
   still uses its older Advanced list, which appears to be SparkNotes'; that list
   is not in the iOS app and should not be added to it.
2. **Apple Developer Program.** Enrol with your Apple ID (US$99 a year).
3. **Signing.** In Xcode: Vocab target, Signing & Capabilities, choose your team.
4. **Bundle identifier.** `io.github.krsubham48.vocab`. Change it now if you want
   another; it cannot change after the first upload.
5. **App name.** Store names must be unique and "Vocab" is likely taken. Choose
   one in App Store Connect; the name under the icon stays "Vocab".
6. **App record.** Create it in App Store Connect: category Education, then price
   and countries.
7. **Privacy.** Answer "Data Not Collected". A privacy policy web address is
   required: add your contact email to [PRIVACY.md](PRIVACY.md) and publish it.
8. **Age rating.** The word lists have no alcohol, gambling, drug, weapon or
   sexual content; some sentences touch on news themes such as law and conflict.
9. **Screenshots.** App Store Connect asks for a large iPhone and a 13-inch iPad
   set. Run the UI tests on "iPhone 17 Pro Max" and "iPad Pro 13-inch (M5)" with
   `-resultBundlePath`, then export them with
   `xcrun xcresulttool export attachments`.
10. **Upload.** Choose "Any iOS Device", Product > Archive, Distribute App.
    Try it through TestFlight before submitting for review.
11. **Later uploads.** Raise the build number each time (`CURRENT_PROJECT_VERSION`),
    and the version (`MARKETING_VERSION`) for a new release.
