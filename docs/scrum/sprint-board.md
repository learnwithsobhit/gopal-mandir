# Sprint Board

**Sprint:** 1 (proposed) — *Play Store release foundations*
**Goal:** Get a signed, policy-compliant release `.aab` built and uploaded to a Play
internal testing track — the unblocking foundation for public launch (Epic E1).

> Status: **proposed**. Aria's tech specs are attached (`tech-specs.md`) and the
> codeable P0 stories are signed off as **Ready** per the Definition of Ready.
> E1-S9 stays in Backlog, **blocked** on the owner's Play account. Owner decisions
> are resolved (see `backlog.md` → Resolved decisions).

| Backlog | Ready | In Progress | Review | Testing | Done |
|---------|-------|-------------|--------|---------|------|
| E1-S5, E1-S6, E1-S8, E1-S10, E1-S11, E1-S12, E1-S9 *(blocked: owner account)* | E1-S1, E1-S2, E1-S3, E1-S4, E1-S7, E1-S13 | — | — | — | Team charter, DoR/DoD, backlog, board scaffolding |

## Proposed Sprint 1 commitment (P0 critical path)

1. **E1-S1** Finalize app identity & versioning — `com.gopalmandir.app` / "Shri Gopal Mandir"
2. **E1-S2** Set up release signing (upload keystore)
3. **E1-S3** Permissions audit & Data safety mapping (payments excluded per v1 decision)
4. **E1-S4** Privacy policy: content + host as route on Railway API
5. **E1-S13** Disable payment flows for v1 launch
6. **E1-S7** Build & verify release `.aab`
7. **E1-S9** Play Console setup & internal testing track *(blocked: owner must create dev account + pay $25)*

P1/P2 stories (E1-S5, S6, S8, S10, S11, S12) sit in backlog for Sprint 1 stretch or
Sprint 2 once the foundation lands.

## Notes

- First product epic received: **E1 — Deploy Android app to Google Play Store**.
- Discovery done by Penny; concrete Android-readiness findings recorded in `backlog.md`.
- **Aria tech specs (2026-06-20):** `tech-specs.md` covers all P0 stories. Ready:
  E1-S1, E1-S2, E1-S3, E1-S4, E1-S7, E1-S13. Recommended dev order: **S13 → S1 →
  S2 → S4 → S7**, with S3 finalized alongside S13. E1-S9 spec'd but blocked on the
  Google Play account ($25).
- **Owner decisions (2026-06-20):** no dev account yet (must create + pay $25);
  name "Shri Gopal Mandir" / package `com.gopalmandir.app`; privacy policy hosted as
  a Railway API route; EN+HI listing, India-only; payments disabled for v1 (E1-S13).
- **Hard blockers:** release build is debug-signed (`build.gradle`), no
  keystore/`key.properties`, and no privacy policy yet — all on the Sprint 1 P0 path.
- **External blocker:** E1-S9 cannot start until the Google Play developer account is
  created and paid; if it's a personal account, expect the 12-tester / 14-day
  closed-testing gate before production.
- Next: Aria attaches tech specs to the P0 stories and marks them *Ready*.
