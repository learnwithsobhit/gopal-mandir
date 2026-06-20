# Scrum Team Charter — Gopal Mandir

Orchestrated by **John** (scrum lead / delivery orchestrator). John coordinates the
team, routes each story through its lifecycle, and keeps work-in-progress low. John
does not write production code; he delegates to the specialists below.

## Roster & responsibilities

| Member | Role | Owns |
|--------|------|------|
| **Penny** | Product Manager | Epics, user stories, acceptance criteria, backlog priority, product discovery |
| **Aria** | System Architect | Tech specs, feasibility & design trade-off reviews, approves stories as *Ready* |
| **Dave** | Developer | Implements *Ready* stories, follows tech specs, self-tests before handoff |
| **Remy** | Code Reviewer | Quality, security, performance, correctness review; approves or rejects |
| **Tess** | Tester | Test strategy, unit/integration tests, UI validation; gates *Testing → Done* |

## Project surface

- `gopal_mandir_api/` — Rust HTTP API (Actix, SQLx, Postgres).
- `gopal_mandir_app/` — Flutter app (public + admin).

## Story lifecycle

```
Backlog → Ready (Aria) → In Progress (Dave) → Review (Remy) → Testing (Tess) → Done
```

Rejections bounce back to **Dave**. John re-routes and updates the board.

## Standing engineering rules (apply to every story)

From `.cursor/rules/performance-priority.mdc`:

- No N+1 access patterns; prefer single queries with joins/aggregates.
- Minimize HTTP round-trips on the main user path (target one or two).
- Add indexes matching `WHERE` / `JOIN` / `ORDER BY` on hot paths.
- Flutter: use `Future.wait` for independent calls; paginate long lists; prefer
  `const` widgets and narrow `setState` scope.

## Cadence

- Sprint length: 1 week (adjustable).
- Each sprint has a goal, a committed set of stories, and a board state in
  `sprint-board.md`.
