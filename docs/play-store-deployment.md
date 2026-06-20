# Google Play Store Deployment — Shri Gopal Mandir

Everything needed to publish the Android app (`gopal_mandir_app`) to the Play
Store with an individual developer account. Work through it top to bottom.

- **App ID:** `com.gopalmandir.gopal_mandir_app`
- **Version:** `1.0.0` (versionCode `1`) — from `pubspec.yaml`
- **Payments:** disabled for v1 via `AppConfig.paymentsEnabled = false`
  (`lib/config/app_config.dart`). No Razorpay required.

> Replace every `CONTACT_EMAIL_HERE` / `ADDRESS_HERE` placeholder (in
> `gopal_mandir_api/static/privacy.html`) before going live.

---

## 1. Create the upload keystore (one-time, do this yourself)

Run this in a terminal. It will prompt for a password and a few identity
fields. **Keep the password and the `.jks` file backed up forever** — losing
them means you can never publish an update to this app.

```bash
keytool -genkey -v \
  -keystore "$HOME/keys/gopal-mandir-upload.jks" \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

Then create `gopal_mandir_app/android/key.properties` (already gitignored)
from the template `key.properties.example`:

```properties
storePassword=<the password you just set>
keyPassword=<same password unless you set a separate key password>
keyAlias=upload
storeFile=/Users/shobhit/keys/gopal-mandir-upload.jks
```

`build.gradle` automatically picks this up and signs release builds with it.
If `key.properties` is absent it falls back to debug signing (so the project
still builds for others), but **Play will reject debug-signed bundles**.

> Recommended: also enable **Play App Signing** when creating the app in the
> console (default). You upload with this key; Google manages the final
> signing key.

---

## 2. Build the release bundle

```bash
cd gopal_mandir_app
flutter clean
flutter pub get
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab` — this is what you
upload. (Use `flutter build apk --release` only for local device testing.)

Test the release build on a real device first:

```bash
flutter install --release      # or: flutter run --release
```

Verify: app name shows as **Shri Gopal Mandir**, branded icon appears, and no
Donate / Pay / Pooja-appointment buttons are visible.

---

## 3. Store listing copy

**App name:** Shri Gopal Mandir

**Short description (≤80 chars):**
> Digital darshan, aarti timings, panchang & temple updates for Shri Gopal Mandir.

**Full description (≤4000 chars):**
> Shri Gopal Mandir brings the temple to your phone. Stay connected to Laddu
> Gopal with live darshan, daily aarti timings, the Hindu panchang, daily
> upasana, shlokas, festival calendar, photo gallery, and temple
> announcements.
>
> Features:
> • Live darshan and daily darshan images
> • Aarti timings and daily upasana
> • Hindu panchang (tithi, nakshatra, festivals)
> • Festival calendar with photos and videos
> • Daily shlok and spiritual learning hub
> • Community Q&A and ask-an-astrologer
> • Temple gallery, announcements, and about/seva info
> • Hindi and English, light and dark themes
>
> Jai Shri Krishna! Radhe Radhe.

**Category:** Lifestyle (alternative: Books & Reference)
**Tags/keywords:** temple, mandir, darshan, aarti, panchang, Krishna, Gopal
**Contact email:** CONTACT_EMAIL_HERE
**Privacy policy URL:** `https://gopal-mandir-production.up.railway.app/privacy`

### Graphics required
- **App icon:** 512×512 PNG (32-bit, with alpha). Use the deity launcher icon.
- **Feature graphic:** 1024×500 PNG/JPG.
- **Phone screenshots:** at least 2 (up to 8), 16:9 or 9:16, min 320px side.
  Suggested: Home, Live Darshan, Panchang, Festival calendar, Gallery.

---

## 4. Data Safety form answers

The app (with payments off) collects only what users submit. Use these answers:

**Does your app collect or share any of the required user data types?** — Yes.

| Data type | Collected | Shared | Purpose | Optional? |
|---|---|---|---|---|
| Phone number | Yes | No | Account management (OTP login), App functionality | Yes |
| Name | Yes | No | App functionality (forms/requests) | Yes |
| Email address | Yes | No | App functionality (forms/requests) | Yes |
| User content (posts, comments, feedback) | Yes | No | App functionality | Yes |
| App info & performance (diagnostics) | No* | No | — | — |

\* No third-party analytics/ads SDKs are used.

Other declarations:
- **Is data encrypted in transit?** Yes (all API calls use HTTPS).
- **Can users request data deletion?** Yes — via the contact email in the
  privacy policy. (Provide that email.)
- **Is all collected data optional?** Yes — only collected when the user uses a
  feature that requires it.

> Important: the Data Safety form must match the privacy policy and actual
> behavior. Because payments are disabled in v1, do **not** declare financial
> info. If you re-enable donations later, update this form to add
> "Payment info" before that release.

---

## 5. Content rating

Complete the IARC questionnaire. This is a reference/lifestyle app with
user-generated content (community Q&A, comments). Answer honestly:
- Contains user-generated content / social features: **Yes** (community posts &
  comments). This typically yields a low rating (Everyone / PEGI 3) but flags
  UGC, so make sure you have basic moderation (admin tools already exist).
- No violence, sexual content, gambling, or alcohol/drugs.

---

## 6. Play Console steps

1. **Create app** → All apps → Create app. Name: *Shri Gopal Mandir*,
   Default language, App (not game), Free.
2. Complete **App content** (left nav → "Policy → App content"):
   - Privacy policy URL (step 3)
   - Data safety (step 4)
   - Content rating (step 5)
   - Target audience, Ads (declare **No ads**), Government app = No, etc.
3. **Set up your store listing** (graphics + descriptions from step 3).
4. **Testing → Internal testing** → Create release → upload the `.aab` → add
   yourself as a tester → roll out → install via the opt-in link and verify.
5. When happy: **Production → Create release** → upload the same/updated
   `.aab` → submit for review.

First reviews typically take a few days. Address any policy feedback and
resubmit as a **new** release (bump `version` in `pubspec.yaml`, e.g.
`1.0.1+2`).

---

## 7. Re-enabling payments later

1. Set `RAZORPAY_KEY_ID` / `RAZORPAY_KEY_SECRET` on the Railway API.
2. Flip `AppConfig.paymentsEnabled = true` in
   `gopal_mandir_app/lib/config/app_config.dart`.
3. Update the Data Safety form to include Payment info, bump the version, and
   ship a new release. Note: genuine charitable donations to a registered
   religious organization are exempt from Google Play Billing, but you must be
   able to show the org's registered status if asked.
