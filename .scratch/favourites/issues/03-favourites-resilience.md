# 03: Make Favourites resilient

**What to build:** Favourites remain trustworthy during authentication transitions and request failures.

**Blocked by:** 02: Browse and toggle Favourites.

**Status:** ready-for-agent

- [ ] Signed-out heart selection routes through login and returns safely to the catalog.
- [ ] Expired sessions use the existing authentication recovery flow.
- [ ] Failed optimistic changes roll back and display an error rather than an empty state.
- [ ] Full tests, build, API checks, and browser verification pass.
