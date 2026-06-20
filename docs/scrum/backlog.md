# Product Backlog — Gopal Mandir

Owned and prioritized by **Penny**. Stories flow from here into a sprint once Aria
marks them *Ready*. IDs are stable; status mirrors `sprint-board.md`.

## Epic E1 — Deploy Android app to Google Play Store

**Product owner goal:** "Deploy the Android app to the Google Play Store so anyone
can download and install it on their device."

**Why:** The app and its production backend already exist (`ApiService.baseUrl`
points at `https://gopal-mandir-production.up.railway.app`), but there is no
distribution channel. Devotees currently have no way to install the app. Shipping a
public, signed, policy-compliant release on Play is the single step that turns the
finished app into something real users can get on their phones.

**Definition of success:** A signed Android App Bundle is published on a Play
production track (or staged rollout), passes Play review, and a non-team device can
search, install, open the app, and reach the production API.

### Discovery findings (current Android state vs. gaps)

Inspected on this iteration — concrete values cited by file:

| Area | Current state | Gap for Play release |
|------|---------------|----------------------|
| Application ID | `com.gopalmandir.gopal_mandir_app` (`android/app/build.gradle` L9, L24) — still the Flutter-generated id, with the default `// TODO: Specify your own unique Application ID` comment | Confirm/finalize package id **before first publish** (immutable afterward). Decide whether `_app` suffix stays. |
| App display name | `android:label="gopal_mandir_app"` (`android/app/src/main/AndroidManifest.xml` L4) — raw project slug, not human-readable | Set a proper label, e.g. "Shri Gopal Mandir" (pubspec description already uses that name). |
| Versioning | `version: 1.0.0+1` (`pubspec.yaml` L4); gradle reads `flutter.versionCode` / `flutter.versionName` (`build.gradle` L29–30) | Define a versionCode/versionName scheme for the first upload and future updates. |
| SDK levels | `compileSdk`, `minSdk`, `targetSdk` all delegate to `flutter.*` defaults (`build.gradle` L10, L27–28) — no explicit values | Pin `targetSdk` to meet the current Play target-API requirement; confirm `minSdk` satisfies plugins (razorpay, syncfusion pdf viewer). |
| Release signing | `release { signingConfig = signingConfigs.debug }` (`build.gradle` L33–38) with `// TODO: Add your own signing config` | **BLOCKER.** Debug-signed bundles are rejected by Play. Need real upload keystore + signingConfig. |
| Keystore / key.properties | **None present** (no `*.jks`, no `key.properties` under `android/`) | Must be generated and wired in; stored securely, never committed. |
| Launcher icon | Default Flutter `ic_launcher.png` in `mipmap-mdpi…xxxhdpi` only; **no `mipmap-anydpi-v26` adaptive icon**, no `flutter_launcher_icons` dep (`pubspec.yaml`) | Replace with Gopal Mandir branded icon + adaptive (foreground/background) for modern Android. |
| Splash | No `flutter_native_splash` config in `pubspec.yaml`; manifest uses default `LaunchTheme` | Optional polish — branded splash. |
| Permissions | Only `android.permission.INTERNET` (`AndroidManifest.xml` L2) | Audit against actual plugin needs (file_picker, razorpay, just_audio, video_player). Keep minimal; map for Data safety. |
| Cleartext / network security | No `usesCleartextTraffic`; all API calls use `https://…railway.app` (`lib/services/api_service.dart` L12) | Good — no cleartext needed. Confirm no http endpoints sneak in. |
| Deep links | None declared (only standard MAIN/LAUNCHER intent-filter) | None required for v1 unless owner wants them. |
| Privacy policy | **None found anywhere in repo** | **BLOCKER for Data safety form** — app collects phone/name (OTP login) and processes payments via Razorpay. Need a hosted policy URL. |
| Data collection surface | OTP membership + admin login (phone numbers), volunteer/learn registration (name/contact), donations & seva/prasad/pooja payments via `razorpay_flutter` | Must be declared accurately in the Play Data safety section. |

### Stories

| ID | Title | Type | Priority | Status |
|----|-------|------|----------|--------|
| E1-S1 | Finalize app identity & versioning | Story | P0 | **Ready** |
| E1-S2 | Set up release signing (upload keystore) | Story | P0 | **Ready** |
| E1-S3 | Permissions audit & Data safety mapping | Story | P0 | **Ready** |
| E1-S4 | Privacy policy: content + hosting | Story | P0 | **Ready** |
| E1-S5 | Branded launcher + adaptive icon (+ splash) | Story | P1 | Drafted |
| E1-S6 | Release build hardening (R8/shrink, ProGuard, bundle) | Story | P1 | Drafted |
| E1-S7 | Build & verify release `.aab` | Story | P0 | **Ready** |
| E1-S8 | Store listing assets (EN/HI) + content rating | Story | P1 | Drafted |
| E1-S9 | Play Console setup & internal testing track | Story | P0 | Drafted / Blocked (owner account) |
| E1-S10 | Pre-launch validation on internal track | Story | P1 | Drafted |
| E1-S11 | Production rollout (staged) & country targeting | Story | P1 | Drafted |
| E1-S12 | Post-release update & versioning process | Story | P2 | Drafted |
| E1-S13 | Disable payment flows for v1 launch | Story | P0 | **Ready** |

> **Aria (2026-06-20):** Tech specs for all P0 stories are in
> [`tech-specs.md`](./tech-specs.md). E1-S1/S2/S3/S4/S7/S13 are **Ready** (specs
> approved, DoR met). E1-S9 stays **Drafted/Blocked** — sequence is spec'd but it
> needs the owner's Google Play account ($25) before it can start.

**Critical path (sequencing):**
`E1-S1 → E1-S2 → E1-S7 → E1-S9 → E1-S10 → E1-S11`, with `E1-S3 + E1-S4` required
before `E1-S9` (Data safety form), and `E1-S8` required before `E1-S11` (store
listing must be complete to publish). `E1-S5`, `E1-S6`, `E1-S12` are parallelizable.

---

#### E1-S1 — Finalize app identity & versioning
- **Priority:** P0 · **Owner:** Dave (spec: Aria) · **Depends on:** none
- **As a** product owner, **I want** a final, human-readable app name and a stable
  package id with a clear version scheme, **so that** the Play listing is
  professional and future updates increment cleanly.
- **Acceptance criteria:**
  - [ ] `applicationId` set to **`com.gopalmandir.app`** (owner-approved) and the
        placeholder `// TODO` comment removed in `android/app/build.gradle`.
  - [ ] `android:label` shows **"Shri Gopal Mandir"**, not `gopal_mandir_app`.
  - [ ] `pubspec.yaml` `version` set to the agreed first-release value with a
        documented versionCode/versionName convention.
  - [ ] App name renders correctly on the launcher and in app switcher on a device.
- **Decision (owner):** package id `com.gopalmandir.app` (drops the `_app` suffix);
  name "Shri Gopal Mandir". Immutable after first publish.
- **Edge cases:** package id is immutable after first publish — must be confirmed by
  owner before any upload; long names truncating under the launcher icon.
- **Tech spec (Aria → `tech-specs.md` §E1-S1):** edit `build.gradle` L24
  `applicationId` (remove L23 TODO), `AndroidManifest.xml` L4 `android:label`; keep
  `namespace` (L9) and `pubspec.yaml` `version: 1.0.0+1` (gradle already reads
  `flutter.versionCode/Name`). SDK pinning deferred to E1-S6. **Status: Ready.**

#### E1-S2 — Set up release signing (upload keystore)
- **Priority:** P0 · **Owner:** Dave (spec: Aria) · **Depends on:** E1-S1
- **As a** developer, **I want** a real upload keystore wired into a release
  `signingConfig`, **so that** Play accepts the bundle and updates stay verifiable.
- **Acceptance criteria:**
  - [ ] An upload keystore (`*.jks`) is generated and stored securely (not committed;
        path/secrets recorded for the owner).
  - [ ] `android/key.properties` exists locally and is git-ignored.
  - [ ] `build.gradle` `release` block uses a real `signingConfig` (not
        `signingConfigs.debug`); the `// TODO: Add your own signing config` is gone.
  - [ ] `flutter build appbundle --release` produces a bundle signed with the upload
        key (verified via `keytool`/bundletool).
  - [ ] Play App Signing enrollment decision recorded (recommended: let Google
        manage the app signing key).
- **Edge cases:** lost keystore = permanently unable to update (unless Play App
  Signing with key reset); ensure secure backup. `key.properties` must never reach git.
- **Tech spec (Aria → `tech-specs.md` §E1-S2):** `keytool` upload keystore +
  git-ignored `android/key.properties` (note: `android/.gitignore` L11–13 already
  ignores `key.properties`/`*.jks`/`*.keystore`); add key-loader + `signingConfigs.release`
  to `build.gradle` and switch `buildTypes.release` (L33–38) off `signingConfigs.debug`.
  Enroll in Play App Signing. **Status: Ready.**

#### E1-S3 — Permissions audit & Data safety mapping
- **Priority:** P0 · **Owner:** Penny + Aria · **Depends on:** none
- **As a** product owner, **I want** the app's actual data collection and
  permissions documented and minimized, **so that** the Play Data safety form is
  accurate and we don't over-request.
- **Acceptance criteria:**
  - [ ] Each manifest permission is justified; unnecessary ones removed (currently
        only `INTERNET`).
  - [ ] Plugin-implied permissions/SDKs identified (razorpay, file_picker,
        just_audio, video_player, syncfusion pdf viewer, flutter_secure_storage).
  - [ ] A data-collection table is produced: phone number, name, payment info, and
        purpose/sharing for each — mapped to Play Data safety categories.
  - [ ] Confirmed whether Razorpay SDK shares data with third parties (declared if so).
- **Edge cases:** payment data handling; OTP phone numbers count as personal data;
  any analytics SDKs (none found yet — confirm).
- **Tech spec (Aria → `tech-specs.md` §E1-S3):** manifest stays minimal (only
  `INTERNET`, L2 — no additions). Data-collection table produced: phone (OTP),
  name/contact (registration/feedback); **payment data = No in v1** (gated by
  E1-S13); no analytics/location/device IDs found. Sign-off gated on E1-S13 merge.
  **Status: Ready (analysis).**

#### E1-S4 — Privacy policy: content + hosting
- **Priority:** P0 · **Owner:** Penny (content) + Dave (hosting) · **Depends on:** E1-S3
- **As a** user, **I want** to read how my data is used, **so that** I can trust the
  app; **and** Play requires a public privacy policy URL for the Data safety form.
- **Acceptance criteria:**
  - [ ] Privacy policy drafted covering: data collected (phone, name, payment),
        purpose, third parties (Razorpay), retention, contact, and user rights.
  - [ ] Policy is published at a stable public HTTPS URL (e.g. a page on the temple
        site or a route served by the existing API/host).
  - [ ] URL is reachable without login and ready to paste into Play Console.
- **Edge cases:** must stay reachable after launch (Play re-checks); EN (and HI if
  store listing is bilingual) versions consistent.
- **Tech spec (Aria → `tech-specs.md` §E1-S4):** add public `#[get("/privacy")]`
  handler in `routes.rs` (next to `health`, L46) serving `include_str!("../static/privacy.html")`
  as `text/html`; register in `main.rs` (`.service(routes::privacy_policy)`). Static,
  dependency-free, zero DB/round-trip. Single EN+HI page; content (Penny) excludes
  payment data per v1. **Status: Ready.**

#### E1-S5 — Branded launcher + adaptive icon (+ optional splash)
- **Priority:** P1 · **Owner:** Dave · **Depends on:** E1-S1
- **As a** user, **I want** a recognizable Gopal Mandir icon, **so that** the app
  looks trustworthy and on-brand on my home screen.
- **Acceptance criteria:**
  - [ ] Branded launcher icon replaces the default Flutter icon across all densities.
  - [ ] Adaptive icon (foreground + background, `mipmap-anydpi-v26`) renders
        correctly on Android 8+ (round/squircle masks).
  - [ ] (Optional) Branded splash configured; no white-flash regression on cold start.
  - [ ] 512×512 high-res icon prepared for the Play listing.
- **Edge cases:** safe-zone cropping on adaptive masks; icon legibility at small size.

#### E1-S6 — Release build hardening (R8/shrink, ProGuard, bundle)
- **Priority:** P1 · **Owner:** Dave (spec: Aria) · **Depends on:** E1-S2
- **As a** developer, **I want** an optimized, correctly-configured release build,
  **so that** download size is small and no runtime crashes from stripped code.
- **Acceptance criteria:**
  - [ ] `targetSdk` pinned to meet the current Play target-API requirement.
  - [ ] Decision recorded on minify/resource shrink (R8); if enabled, keep rules
        added for razorpay & syncfusion to avoid stripping needed classes.
  - [ ] App Bundle (per-ABI/density splits via Play) confirmed as the artifact.
  - [ ] Release build runs on a physical device without obfuscation-related crashes
        (payments, PDF view, audio/video all functional).
- **Edge cases:** R8 stripping reflection-based SDK code (Razorpay); 16 KB page-size
  / native lib alignment if flagged by Play.

#### E1-S7 — Build & verify release `.aab`
- **Priority:** P0 · **Owner:** Dave · **Depends on:** E1-S2 (and E1-S6 if hardening lands first)
- **As a** developer, **I want** a reproducible release App Bundle, **so that** we
  have the exact artifact to upload to Play.
- **Acceptance criteria:**
  - [ ] `flutter build appbundle --release` succeeds; `dart analyze` is clean.
  - [ ] Output `app-release.aab` is signed with the upload key.
  - [ ] Installed from the bundle (via internal track or bundletool) the app launches
        and reaches the production API.
- **Edge cases:** version code collisions on re-upload; bundle size warnings.
- **Tech spec (Aria → `tech-specs.md` §E1-S7):** `flutter clean && pub get`,
  `dart analyze` clean, `flutter build appbundle --release`; verify signer via
  `keytool -printcert -jarfile …app-release.aab` (upload key, not debug); smoke-test
  install + confirm no payment entry points reachable. Consumes S1/S2/S13.
  **Status: Ready.**

#### E1-S8 — Store listing assets (EN/HI) + content rating
- **Priority:** P1 · **Owner:** Penny · **Depends on:** E1-S5 (icon)
- **As a** product owner, **I want** complete, bilingual store-listing content,
  **so that** users discover and understand the app, and the listing passes review.
- **Acceptance criteria:**
  - [ ] App title, short description, full description in **EN and HI**.
  - [ ] Feature graphic (1024×500) and phone screenshots (≥2, multiple sizes incl.
        tablet if supported) from real screens.
  - [ ] App category, tags, and contact details set.
  - [ ] Content rating questionnaire answers prepared (devotional/utility app).
- **Edge cases:** screenshots must reflect current UI; payment screens — avoid
  exposing test data; HI translations reviewed for accuracy.

#### E1-S9 — Play Console setup & internal testing track
- **Priority:** P0 · **Owner:** John + product owner (account) · **Depends on:** E1-S3, E1-S4, E1-S7
- **As a** product owner, **I want** the app created in Play Console with an internal
  testing track, **so that** we can validate the real artifact before public release.
- **Acceptance criteria:**
  - [ ] Google Play developer account active ($25 one-time registration done).
  - [ ] App created; Data safety form completed using E1-S3 mapping; privacy URL
        (E1-S4) entered.
  - [ ] First `.aab` uploaded to the **internal testing** track with tester emails.
  - [ ] Internal testers can install via the opt-in link.
- **Edge cases:** new personal developer accounts may require the 12-tester / 14-day
  closed-testing rule before production access — confirm account type.
- **Tech spec (Aria → `tech-specs.md` §E1-S9):** prerequisites + Console sequence
  spec'd (create app → Play App Signing → Data safety from S3 → privacy URL from S4
  → internal track upload of S7 `.aab`). No code for Dave. **BLOCKED:** owner must
  create + pay the $25 Google Play account. **Status: Drafted/Blocked.**

#### E1-S10 — Pre-launch validation on internal track
- **Priority:** P1 · **Owner:** Tess · **Depends on:** E1-S9
- **As a** tester, **I want** to validate the installed release build end-to-end,
  **so that** we catch crashes/policy issues before public rollout.
- **Acceptance criteria:**
  - [ ] Core flows pass on a physical device from the store install: browse,
        OTP login, donations/seva/prasad/pooja payment, PDF/audio/video, gallery.
  - [ ] Play **pre-launch report** reviewed; crashes/ANRs triaged.
  - [ ] API connectivity to the production backend confirmed on mobile data + Wi-Fi.
- **Edge cases:** payment in Play sandbox vs. live Razorpay; permission prompts on
  Android 13+; offline/error states.

#### E1-S11 — Production rollout (staged) & country targeting
- **Priority:** P1 · **Owner:** John + product owner · **Depends on:** E1-S8, E1-S10
- **As a** product owner, **I want** a controlled production release, **so that** we
  limit blast radius if something breaks.
- **Acceptance criteria:**
  - [ ] Target countries selected (default: India; confirm with owner).
  - [ ] Production release created with **staged rollout** (e.g. start 10–20%).
  - [ ] App passes Play review and is live; installable by the public.
  - [ ] Rollback/halt plan noted.
- **Edge cases:** review rejection handling; rollout halt criteria (crash-rate threshold).

#### E1-S12 — Post-release update & versioning process
- **Priority:** P2 · **Owner:** Aria + Penny · **Depends on:** E1-S11
- **As a** team, **I want** a documented update process, **so that** future releases
  are fast, safe, and consistent.
- **Acceptance criteria:**
  - [ ] versionCode/versionName bump procedure documented.
  - [ ] Keystore backup & access documented (who holds it, where).
  - [ ] Staged-rollout + release-notes checklist captured for future updates.
- **Edge cases:** team handoff if keystore holder is unavailable.

#### E1-S13 — Disable payment flows for v1 launch
- **Priority:** P0 · **Owner:** Dave (spec: Aria) · **Depends on:** none
- **As a** product owner, **I want** Razorpay-backed payment actions hidden/disabled
  for the first public release, **so that** we launch without live-payment risk and
  enable monetary flows in a later, deliberate update.
- **Acceptance criteria:**
  - [ ] Donation / seva / prasad / pooja payment entry points are hidden or disabled
        in the UI for v1 (non-destructive, behind a single toggle/flag so they can be
        re-enabled later).
  - [ ] No `razorpay_flutter` checkout can be triggered by a normal user in v1.
  - [ ] Remaining flows (browse, OTP login, learn/volunteer registration, daily
        upasana, gallery, live, events) are unaffected.
  - [ ] Data safety form (E1-S3) reflects that payment data is not collected in v1.
- **Edge cases:** ensure no orphaned screens/nav after hiding; keep code paths intact
  for the later re-enable; avoid breaking deep links to those screens.
- **Decision (owner):** payments disabled for v1; re-enable in a later update.
- **Tech spec (Aria → `tech-specs.md` §E1-S13):** one compile-time flag
  `kPaymentsEnabled = false` in new `lib/config/feature_flags.dart`, two layers —
  **(1)** hide the 3 reachable entry points (`more_screen.dart` My Bookings L234–247
  + Pooja Appointment L248–261; `events_screen.dart` Donate button L241–261), and
  **(2)** early-return guards in the 5 checkout handlers (`donate_screen._submit`
  L212, `event_donate_screen._submit` L189, `seva_booking_screen._confirm` L69,
  `prasad_booking_screen._confirm` L74, `bookings_screen._payPoojaOnline` L420).
  Home + bottom nav already stripped; Seva/Offerings/Donate/Prasad screens already
  orphaned. Non-destructive; keep Razorpay deps. **Status: Ready.**

### Resolved decisions (product owner — 2026-06-20)

1. **Developer account:** None yet — must create a Google Play developer account and
   pay the $25 registration (gates E1-S9). Account type TBD; if personal, the
   12-tester / 14-day closed-testing requirement applies before production.
2. **App identity:** Name **"Shri Gopal Mandir"**, package **`com.gopalmandir.app`**
   (drops `_app`). Locked into E1-S1. Immutable after first publish.
3. **Privacy policy:** Write one and host it as a **route on the Railway API** (e.g.
   `/privacy` or `/privacy-policy`) served as public HTTPS. Locked into E1-S4.
4. **Languages & countries:** Store listing **EN + HI**, launch **India-only**.
   Locked into E1-S8 / E1-S11.
5. **Payments at launch:** **Disabled for v1** — see new story E1-S13; re-enable in a
   later update.

### Still open (non-blocking for P0 start)

- **Minimum Android version:** accept Flutter default `minSdk` unless owner specifies
  one (subject to plugin requirements — to be confirmed in E1-S6).
- **Branding assets:** is there final app icon / feature-graphic source art, or does
  design need to produce it? (Affects E1-S5 / E1-S8.)

## How to add work

1. Penny drafts the epic and breaks it into stories with acceptance criteria here.
2. Aria attaches a tech spec and marks the story *Ready*.
3. John pulls *Ready* stories into the active sprint board.
