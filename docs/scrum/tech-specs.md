# Tech Specs — Epic E1 (Play Store release)

Authored by **Aria**. One section per P0 story. Each spec lists the approach,
exact files to change (current → target), commands, risks/trade-offs, and a
per-story Definition-of-Ready (DoR) checklist mapped to
`definition-of-ready-and-done.md`. Dave implements against these; Tess verifies
against the acceptance criteria in `backlog.md`.

> Source of truth for the *what/why* is `backlog.md`. This file is the *how*.
> Discovery line numbers are cited from the repo as inspected on 2026-06-20.

## Conventions

- App module: `gopal_mandir_app/` (Flutter). API: `gopal_mandir_api/` (Rust/Actix).
- Performance rule (`.cursor/rules/performance-priority.mdc`) is respected in
  every spec; the only new API surface (E1-S4) is a static, zero-query route.

## Recommended implementation order (Dave)

1. **E1-S13** Disable payments — biggest risk reducer, unblocks an honest Data
   safety form; no dependency.
2. **E1-S1** App identity & versioning — must be locked before any signed upload.
3. **E1-S2** Release signing — depends on S1 (applicationId final).
4. **E1-S4** Privacy `/privacy` route — independent; deploy to Railway early so
   the URL is live and stable for Play.
5. **E1-S7** Build & verify `.aab` — depends on S2 (and ideally S13 already in).
6. **E1-S3** Permissions/Data-safety mapping — analysis; finalize alongside S13
   so it reflects "no payment data in v1".
7. **E1-S9** Play Console — owner-blocked (account + $25); sequence only.

---

## E1-S1 — Finalize app identity & versioning

**Status target:** Ready · **Owner:** Dave · **Depends on:** none (owner decisions locked)

### Approach
Two concrete identity edits (applicationId, label) plus a documented version
convention. The version wiring already works — `build.gradle` reads
`flutter.versionCode`/`flutter.versionName` from `pubspec.yaml` (`version: 1.0.0+1`),
so **no gradle version edit is needed**; we only formalize the convention and
remove the generated placeholders.

> SDK-level pinning (`targetSdk`/`minSdk`) is owned by **E1-S6** (hardening).
> Recommended values are noted there so S1 stays a pure identity change.

### Files to change

`gopal_mandir_app/android/app/build.gradle`
- L23 — remove placeholder comment `// TODO: Specify your own unique Application ID …`.
- L24 — `applicationId = "com.gopalmandir.gopal_mandir_app"` → `applicationId = "com.gopalmandir.app"`.
- L9 (`namespace = "com.gopalmandir.gopal_mandir_app"`) — **leave as-is.** `namespace`
  is the Kotlin/R-class package and is *not* the published id; changing it forces
  package-path churn for `MainActivity` with zero Play benefit. Only `applicationId`
  is immutable on Play. (Decision below.)

`gopal_mandir_app/android/app/src/main/AndroidManifest.xml`
- L4 — `android:label="gopal_mandir_app"` → `android:label="Shri Gopal Mandir"`.

`gopal_mandir_app/pubspec.yaml`
- L4 — keep `version: 1.0.0+1` for the first upload. Document the convention (below).

### Version convention (document in PR description / E1-S12)
- `pubspec.yaml` `version: <versionName>+<versionCode>` → e.g. `1.0.0+1`.
- `versionName` = semver (user-visible). `versionCode` = strictly monotonic
  integer; **+1 every upload** even for re-uploads (Play rejects duplicates).

### Commands (verify only)
```bash
cd gopal_mandir_app
flutter pub get
dart analyze
```

### Risks / trade-offs
- **`applicationId` is immutable after first publish.** `com.gopalmandir.app` is
  owner-approved and final — do not upload before this lands.
- Keeping `namespace` ≠ `applicationId` is fully supported by AGP and avoids a
  needless refactor of the `com/gopalmandir/gopal_mandir_app/MainActivity` path.
- Long label "Shri Gopal Mandir" may truncate under the launcher icon on small
  launchers — acceptable; verify on device.

### DoR checklist
- [x] Clear user story + testable AC (Penny, `backlog.md` E1-S1).
- [x] Tech approach attached & approved (this section).
- [x] Affected files identified (build.gradle L23–24, manifest L4, pubspec L4).
- [x] Performance impact: none (build-config only).
- [x] Small enough for one sprint.

---

## E1-S2 — Set up release signing (upload keystore)

**Status target:** Ready · **Owner:** Dave · **Depends on:** E1-S1

### Approach
Generate a local upload keystore (never committed), create a git-ignored
`android/key.properties`, and wire a real `signingConfigs.release` into
`build.gradle` so the `release` build type stops signing with the debug key.
Enroll in **Play App Signing** (Google manages the app-signing key; our keystore
becomes the *upload* key — recoverable if lost).

> Good news from discovery: `gopal_mandir_app/android/.gitignore` (L11–13)
> **already** ignores `key.properties`, `**/*.keystore`, and `**/*.jks`. No
> .gitignore edit is required — Dave must only confirm the files land under
> `android/` and verify `git status` shows them untracked.

### Generate the upload keystore (run once; store securely, back up)
```bash
keytool -genkey -v \
  -keystore "$HOME/keystores/gopalmandir-upload.jks" \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias gopalmandir-upload
```

### New file: `gopal_mandir_app/android/key.properties` (git-ignored; template)
```properties
storePassword=<store-password>
keyPassword=<key-password>
keyAlias=gopalmandir-upload
storeFile=/absolute/path/to/gopalmandir-upload.jks
```

### Files to change

`gopal_mandir_app/android/app/build.gradle`
- **Before the `android {` block (after the `plugins { … }` block, ~L7)** add the
  key.properties loader:
```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
```
  (`rootProject.file("key.properties")` resolves to `android/key.properties`.)
- **Inside `android { }`, add a `signingConfigs` block** (above `buildTypes`):
```gradle
signingConfigs {
    release {
        keyAlias keystoreProperties['keyAlias']
        keyPassword keystoreProperties['keyPassword']
        storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
        storePassword keystoreProperties['storePassword']
    }
}
```
- **L33–38 `buildTypes.release`** — current → target:
  - current: `signingConfig = signingConfigs.debug` + `// TODO: Add your own signing config…`
  - target: `signingConfig = signingConfigs.release` (remove both TODO comment lines).

### Commands (verify)
```bash
cd gopal_mandir_app
flutter build appbundle --release
# Confirm the signer is the upload key, not the debug key:
keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab
```

### Risks / trade-offs
- **Lost keystore = cannot ship updates** unless on Play App Signing (recommended,
  allows upload-key reset). Record store/key passwords + `.jks` location in the
  owner's secret store; document custody in E1-S12.
- `key.properties` or `*.jks` must never reach git — already covered by
  `android/.gitignore`; still verify `git status` before committing S2.
- If `key.properties` is absent on a build machine, `storeFile` is null and the
  release build fails fast (acceptable — surfaces missing secrets early).

### DoR checklist
- [x] Clear user story + testable AC (Penny).
- [x] Tech approach attached & approved.
- [x] Affected files identified (build.gradle signing wiring; new key.properties).
- [x] Performance impact: none.
- [x] Small enough for one sprint.

---

## E1-S3 — Permissions audit & Data safety mapping

**Status target:** Ready (analysis deliverable) · **Owner:** Penny + Aria · **Depends on:** none (finalize with E1-S13)

### Approach
This is an analysis/documentation story, not code (manifest stays minimal). Produce
the data-collection table for the Play Data safety form. The v1 mapping must
reflect **payments disabled (E1-S13)** → *no payment data collected in v1*.

### Manifest permissions (current)
`AndroidManifest.xml` L2: only `android.permission.INTERNET` — justified (all API
calls to `https://gopal-mandir-production.up.railway.app`). No cleartext
(`usesCleartextTraffic` absent → defaults false). **No permission additions
needed.** The `<queries>` PROCESS_TEXT block (L40–45) is Flutter-engine default —
keep.

### Plugin-implied behavior (pubspec.yaml L13–25)
| Plugin | Permission/SDK reality | Data-safety note |
|--------|------------------------|------------------|
| `http` | uses INTERNET | network only |
| `flutter_secure_storage` | Android Keystore | on-device; not "collected" |
| `shared_preferences` | local prefs | on-device; not collected |
| `file_picker` 8.x | Photo Picker / SAF, **no storage permission** on modern API | no broad media permission declared — keep it that way |
| `just_audio` / `video_player` | stream over network | no mic/camera |
| `cached_network_image` | network + cache | on-device cache |
| `syncfusion_flutter_pdfviewer` | renders network/asset PDFs | no extra permission |
| `razorpay_flutter` | **payment SDK** | **DISABLED in v1 (E1-S13)** → exclude from v1 data-safety; declare when re-enabled |

### Data-collection table (v1 — payments off)
| Data type | Collected? | Where | Purpose | Shared w/ 3rd party |
|-----------|-----------|-------|---------|---------------------|
| Phone number | Yes | Membership/admin OTP login | Account/auth | No (server-side OTP) |
| Name + contact | Yes | Volunteer / learn registration, feedback | Service delivery | No |
| Payment info | **No (v1)** | — (Razorpay gated off) | — | — |
| Approx/precise location | No | — | — | — |
| Device identifiers/analytics | No (none found) | — | — | — |

### Risks / trade-offs
- If E1-S13 slips and any checkout remains reachable, this form becomes
  inaccurate → Play policy risk. **S3 sign-off is gated on S13 being merged.**
- Re-enabling payments later requires a Data safety update (payment info +
  Razorpay as a third-party processor) before that release ships.

### DoR checklist
- [x] Clear story + testable AC (Penny).
- [x] Approach approved; mapping table produced above.
- [x] Affected surface identified (manifest stays as-is; doc artifact).
- [x] Performance impact: none.
- [x] Small enough for one sprint.

---

## E1-S4 — Privacy policy: hosted route on the Rust API

**Status target:** Ready · **Owner:** Dave (hosting) + Penny (content) · **Depends on:** E1-S3 (content accuracy)

### Approach
Add a **public, unauthenticated GET `/privacy`** route to the existing Actix API
returning a static HTML page (EN + HI sections in one document — Play needs a
single stable URL). Dependency-free and lean: serve a compile-time string via
`include_str!` (zero DB, zero runtime I/O, no new crates), mirroring the existing
`root_health`/`health` handler style in `routes.rs` (L23–45).

Final URL: `https://gopal-mandir-production.up.railway.app/privacy`.

### Files to change

New file: `gopal_mandir_api/static/privacy.html`
- Self-contained HTML (inline `<style>`, `<meta name="viewport">`, `lang`
  attributes). Two sections: English, then हिन्दी. Content (Penny) must match
  E1-S3: data collected = phone (OTP), name/contact (registration/feedback);
  **no payment data in v1**; controller/contact = temple email/phone; retention;
  user rights; last-updated date. Note Razorpay only as a future processor or
  omit until re-enabled.

`gopal_mandir_api/src/routes.rs` — add a handler next to the health handlers (~L46):
```rust
#[get("/privacy")]
pub async fn privacy_policy() -> HttpResponse {
    HttpResponse::Ok()
        .content_type("text/html; charset=utf-8")
        .body(include_str!("../static/privacy.html"))
}
```

`gopal_mandir_api/src/main.rs` — register it with the other public routes
(alongside L75–77 health services):
```rust
.service(routes::privacy_policy)
```

### Commands (verify)
```bash
cd gopal_mandir_api
cargo check
cargo run   # then:
curl -i http://localhost:8080/privacy   # expect 200 + text/html, no auth
```
After Railway deploy: `curl -I https://gopal-mandir-production.up.railway.app/privacy`.

### Risks / trade-offs
- **`include_str!` is compile-time** — editing the policy requires a rebuild/redeploy.
  Acceptable for a rarely-changed legal page and keeps the route allocation-free
  and DB-free (performance rule satisfied). Alternative (read file at runtime)
  rejected: adds I/O per request for no benefit.
- CORS already `allow_any_origin` (main.rs L64–68) so the page is broadly
  reachable; it's public by design — no secrets.
- Must stay live post-launch (Play re-checks). It rides the same Railway service
  as the API, so uptime is coupled to the backend (already required for the app).

### DoR checklist
- [x] Clear story + testable AC (Penny).
- [x] Approach approved (static route, EN+HI single page).
- [x] Affected files identified (routes.rs, main.rs, new static/privacy.html).
- [x] Performance impact: static body, no query/round-trip — compliant.
- [x] Small enough for one sprint.

---

## E1-S7 — Build & verify release `.aab`

**Status target:** Ready · **Owner:** Dave · **Depends on:** E1-S2 (signing), E1-S13 (payments off), E1-S1 (identity)

### Approach
Produce the signed App Bundle from a clean tree and verify it installs and reaches
production. No source edits — this is the build/verify gate that consumes S1/S2/S13.

### Commands
```bash
cd gopal_mandir_app
flutter clean && flutter pub get
dart analyze                         # must be clean (DoD)
flutter build appbundle --release    # -> build/app/outputs/bundle/release/app-release.aab
keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab   # upload key, not debug
# Install-from-bundle smoke test (local, before Play):
# bundletool build-apks --bundle=app-release.aab --output=gm.apks --mode=universal
# bundletool install-apks --apks=gm.apks
```

### Verify on device
- App launches; label shows "Shri Gopal Mandir"; reaches production API (browse,
  OTP login, daily upasana, gallery, live, events).
- Confirm **no payment entry point** is reachable (More has no "My Bookings"/"Pooja
  Appointment", Events has no "Donate") — cross-check E1-S13.

### Risks / trade-offs
- versionCode collisions on re-upload → bump per E1-S1 convention.
- Bundle-size warnings are non-blocking for internal track; R8/shrink is E1-S6.
- If S6 lands first, rebuild here to inherit shrink settings.

### DoR checklist
- [x] Clear story + testable AC (Penny).
- [x] Approach approved (build + verify steps).
- [x] Affected surface identified (artifact only; depends on S1/S2/S13).
- [x] Performance impact: n/a (build).
- [x] Small enough for one sprint.

---

## E1-S9 — Play Console setup & internal testing track  (BLOCKED — owner account)

**Status target:** Drafted / Blocked · **Owner:** John + product owner · **Depends on:** E1-S3, E1-S4, E1-S7

### Why it cannot be Ready
Requires an active Google Play developer account ($25 paid) — **not yet created**.
No code for Dave. Spec'd here as a sequence so it's executable the moment the
account exists.

### Prerequisites (must all be true before starting)
1. Google Play developer account active ($25 registration complete). Confirm
   **account type** — a personal account triggers the **12-tester / 14-day closed
   testing** gate before production access.
2. E1-S7 artifact (`app-release.aab`) available, signed with the upload key.
3. E1-S4 privacy URL live: `…/privacy` (reachable without login).
4. E1-S3 data-safety mapping finalized (payments excluded for v1).

### Sequence (owner + John)
1. Create app → default language, "Shri Gopal Mandir", app (not game), free.
2. Enroll in **Play App Signing** (let Google manage the signing key).
3. Complete **Data safety** form from E1-S3 table; paste privacy URL (E1-S4).
4. Content rating questionnaire (devotional/utility).
5. Create **Internal testing** track; add tester emails; upload the `.aab`.
6. Share opt-in link; confirm a non-team device installs and reaches the API.

### Risks / trade-offs
- Personal-account closed-testing rule can add ~2 weeks before production —
  surface to owner now so timeline expectations are set.
- App-signing enrollment decision is permanent per app — choose Play-managed.

### DoR checklist (blocked)
- [x] Clear story + testable AC (Penny).
- [x] Approach/sequence approved.
- [ ] **External prerequisite unmet:** dev account + $25 (owner). → stays Drafted/Blocked.
- [x] Performance impact: n/a.
- [x] Small enough for one sprint once unblocked.

---

## E1-S13 — Disable payment flows for v1 launch

**Status target:** Ready · **Owner:** Dave · **Depends on:** none

### Approach — single flag, two layers (fully reversible)
Introduce **one** compile-time flag and gate payments at two levels so no normal
user can trigger Razorpay, while every screen/code path stays intact for a later
re-enable.

**New file:** `gopal_mandir_app/lib/config/feature_flags.dart`
```dart
/// Master switch for monetary flows (donation, seva, prasad, pooja).
/// v1 launches with payments OFF (owner decision, backlog E1-S13).
/// Flip to `true` (and update Play Data safety) to re-enable.
const bool kPaymentsEnabled = false;
```

**Layer 1 — hide the reachable entry points** (only these three are still
reachable; home + bottom nav were already stripped, and
`SevaOfferingsScreen`/`SevaScreen`/`PrasadScreen`/`DonateScreen` are already
orphaned/unreferenced):

| File | Lines | Change |
|------|-------|--------|
| `lib/screens/more_screen.dart` | L234–247 (My Bookings tile) | wrap in `if (kPaymentsEnabled) … ` |
| `lib/screens/more_screen.dart` | L248–261 (Pooja Appointment tile) | wrap in `if (kPaymentsEnabled) … ` |
| `lib/screens/events_screen.dart` | L241–261 (Donate `ElevatedButton`) | render only `if (kPaymentsEnabled)`; keep the **Join** button (L228–239) always |

> Implementation note: `more_screen` builds a column of `_menuItem(...)` widgets;
> use a list with conditional `if (kPaymentsEnabled)` spreads, or a collection-`if`,
> to drop the two tiles without leaving gaps.

**Layer 2 — defense-in-depth at every checkout trigger** (covers orphaned screens
and any deep-link path). At the top of each handler, early-return with a "temporarily
unavailable" SnackBar when `!kPaymentsEnabled`:

| File | Handler | Line |
|------|---------|------|
| `lib/screens/donate_screen.dart` | `_submit()` | L212 |
| `lib/screens/event_donate_screen.dart` | `_submit()` | L189 |
| `lib/screens/seva_booking_screen.dart` | `_confirm()` | L69 |
| `lib/screens/prasad_booking_screen.dart` | `_confirm()` | L74 |
| `lib/screens/bookings_screen.dart` | `_payPoojaOnline()` | L420 |

Each gate (import `../config/feature_flags.dart`):
```dart
if (!kPaymentsEnabled) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(s.paymentsDisabledNotice)), // add EN+HI string
  );
  return;
}
```
(Add `paymentsDisabledNotice` to `lib/l10n/app_language.dart` strings, EN + HI,
to stay consistent with the bilingual app. A literal string is acceptable if the
team prefers to keep S13 tiny — call it in the PR.)

### Why this approach (trade-offs)
- **Compile-time `const bool`** over a remote/build-time flag: the goal is to make
  it impossible to reach Razorpay in the shipped binary, and to tree-shake cleanly.
  A remote flag would leave a live payment path one config-toggle away — wrong risk
  profile for "no live-payment risk at launch." Re-enabling is a one-line change +
  rebuild, which aligns with the "deliberate later update" decision.
- **Two layers**: Layer 1 keeps the UI honest (no dead tiles); Layer 2 guarantees
  the AC ("no checkout can be triggered by a normal user") even via orphaned
  screens or future deep links — without deleting any code.
- **Non-destructive**: no screens/routes/API calls removed; flip the flag to restore.

### Risks / trade-offs
- Ensure no *empty section/heading* remains after hiding tiles in `more_screen`
  (the two tiles sit between the header card and "About Temple" — verify spacing).
- `BookingsScreen` ("My Bookings") is hidden entirely in v1; acceptable because no
  bookings can be created with payments off and this is a first public launch
  (no pre-existing user bookings). Revisit when payments return.
- Keep Razorpay deps in `pubspec.yaml` (do **not** remove) so re-enable is trivial
  and the build is unchanged.

### DoR checklist
- [x] Clear user story + testable AC (Penny).
- [x] Tech approach attached & approved (one flag, two layers).
- [x] Affected files identified (new feature_flags.dart; more_screen, events_screen;
      5 checkout handlers; l10n string).
- [x] Performance impact: positive (dead code tree-shaken; fewer widgets built).
- [x] Small enough for one sprint.
