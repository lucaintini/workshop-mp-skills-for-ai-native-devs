# Favourites workflow receipt

## 1. Grill with docs

- Agreed on a private, persistent, account-owned Favourites collection.
- Chose authenticated Shopper ownership, idempotent add/remove, newest-first ordering, optimistic UI with rollback, and no coupling to Basket or Orders.
- Updated the shared domain vocabulary in `GLOSSARY.md`; no ADR was needed because the design follows the existing architecture and is inexpensive to reverse.

## 2. Spec

- Published `.scratch/favourites/spec.md` with 17 user stories, implementation decisions, testing seams, and explicit exclusions.
- Status: `ready-for-agent`.

## 3. Tickets

- `01-favourite-api.md`: resolved.
- `02-favourites-ui.md`: resolved.
- `03-favourites-resilience.md`: resolved.
- Blocking edges formed a verified linear frontier: 01 → 02 → 03.

## 4. Implement and review

- Implemented account-isolated persistence, authenticated API routes, catalog heart toggles, protected navigation, the Favourites page, rollback errors, and authentication recovery.
- Added backend and frontend behavioural coverage before final implementation closure.
- Repeated standards and specification reviews until both reported zero findings.
- Final local evidence: 46 backend tests and 12 frontend tests passed; production build passed; dependency audit reported 0 vulnerabilities; browser route returned HTTP 200.

## 5. PR

- PR body: `.scratch/favourites/pr.md`.
- Pull request: https://github.com/perth-ai/workshop-mp-skills-for-ai-native-devs/pull/15
- Fork CI run: https://github.com/lucaintini/workshop-mp-skills-for-ai-native-devs/actions/runs/40680517159
- Remote Windows backend and frontend quality-gate jobs passed.

## 6. Retro

- Finding: the repository had no automated guardrail. Added `.github/workflows/ci.yml` for backend tests plus frontend clean install, tests, build, and audit.
- Finding: PATH/tool discovery was brittle, clean installs conflicted with the running Vite process, skill availability was inferred, and workflow evidence was scattered. Added `scripts/Verify-Workshop.ps1` and this receipt.
- Strict fresh-process skill invocation currently detects a Codex/plugin discoverability failure even though plugin 1.3.1 is installed and enabled. The verifier reports this explicitly instead of treating installation metadata as proof of invocation.

## Completion bound

The loop is complete when all tickets are resolved, review findings are zero, local verification passes, fork CI passes, the PR is open, and every retro action selected for this run is committed and pushed.
