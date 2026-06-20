# Definition of Ready (DoR) & Definition of Done (DoD)

These gates are enforced by John as stories move across the board.

## Definition of Ready — a story may enter *In Progress* only when:

- [ ] User story has a clear "As a … I want … so that …" statement (Penny).
- [ ] Acceptance criteria are explicit and testable (Penny).
- [ ] Tech approach / spec is attached and approved (Aria).
- [ ] Affected files/modules and API or schema changes are identified.
- [ ] Performance impact considered (round-trips, queries, indexes).
- [ ] Story is small enough to finish within a sprint; otherwise split.

## Definition of Done — a story is *Done* only when:

- [ ] Acceptance criteria all met (verified by Tess).
- [ ] Code implemented and self-tested (Dave).
- [ ] Code review approved (Remy): quality, security, performance, correctness.
- [ ] Tests written/updated and passing; for Flutter, `dart analyze` clean.
- [ ] For Rust, `cargo check` (and tests where relevant) pass.
- [ ] No new lint/analyzer errors introduced.
- [ ] DB migrations (if any) noted for staging→prod rollout.
- [ ] Performance rules from the workspace rule respected.
