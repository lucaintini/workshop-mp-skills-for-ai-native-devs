# 01: Save and list private Favourites

**What to build:** A signed-in Shopper can save, list, and remove private Favourites through the shop interface, with persistence and complete catalog-card data.

**Blocked by:** None (can start immediately).

**Status:** resolved

- [x] Authenticated list, add, and remove operations work through the HTTP interface.
- [x] Add and remove are idempotent, ordered newest-first, and reject missing catalog items.
- [x] One Shopper cannot read or change another Shopper's Favourites.
- [x] Existing backend tests remain green.
