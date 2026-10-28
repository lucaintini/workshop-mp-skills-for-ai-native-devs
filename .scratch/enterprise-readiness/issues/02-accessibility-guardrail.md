# 02: Guard the catalog interaction for accessibility

**What to build:** Frontend maintainers receive an automated WCAG A/AA signal for the core catalog-card interaction without mistaking automation for full conformance.

**Blocked by:** None (can start immediately).

**Status:** resolved

- [x] The rendered catalog card is scanned with axe-core in the frontend suite.
- [x] The check uses WCAG A/AA tags and passes in CI-compatible jsdom.
- [x] Documentation states the limits of automated accessibility evidence.
