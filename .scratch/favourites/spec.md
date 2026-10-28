# Favourites

**Status:** ready-for-agent

## Problem Statement

Shoppers can browse and buy catalog items, but cannot save interesting items for later. Signed-in Shoppers need a private, persistent Favourites collection that is quick to manage from the catalog and easy to revisit.

## Solution

Add an account-owned Favourites capability. A Shopper can toggle a Favourite from any catalog card and browse all saved catalog items on a dedicated Favourites page. The capability persists across sessions, preserves account isolation, reports failures visibly, and keeps basket and order behaviour unchanged.

## User Stories

1. As a signed-in Shopper, I want to save a catalog item as a Favourite, so that I can revisit it later.
2. As a signed-in Shopper, I want to remove a Favourite, so that my collection stays relevant.
3. As a signed-in Shopper, I want a saved heart state on catalog cards, so that I can see which items are already Favourites.
4. As a signed-in Shopper, I want Favourite changes to appear immediately, so that the interaction feels responsive.
5. As a signed-in Shopper, I want a failed Favourite change to roll back and show an error, so that the screen never lies about saved state.
6. As a signed-in Shopper, I want my Favourites to survive logout, login, and application restarts, so that they remain useful over time.
7. As a signed-in Shopper, I want a Favourites link in the header, so that my collection is easy to find.
8. As a signed-in Shopper, I want a dedicated Favourites page, so that I can browse saved catalog items together.
9. As a signed-in Shopper, I want newest-saved Favourites first, so that recent interests are easiest to find.
10. As a signed-in Shopper, I want Favourite cards to retain Add to basket, so that saving and buying remain separate capabilities.
11. As a signed-in Shopper with no Favourites, I want a clear empty state linking to the catalog, so that I know how to begin.
12. As a signed-out Shopper, I want the heart affordance to lead me through login, so that I understand the capability and can use it.
13. As a Shopper whose session expires, I want the existing login recovery flow to handle Favourite requests, so that authentication behaviour stays consistent.
14. As a Shopper, I want repeated save or remove requests to be harmless, so that retries do not create duplicates or errors.
15. As a Shopper, I want a deleted or nonexistent catalog item excluded from Favourites, so that the collection contains only current catalog items.
16. As a Shopper, I want my Favourites isolated from every other account, so that another Shopper can never read or change them.
17. As a Shopper, I want Favourite changes not to alter my Basket or Orders, so that saving is independent from purchasing.

## Implementation Decisions

- Favourites belong only to an authenticated Shopper identified by the existing authentication interface; anonymous basket identifiers never participate.
- Persist Favourites with a unique Shopper/catalog-item relationship and an aware UTC saved timestamp.
- Enforce catalog-item existence and cascade removal when a catalog item is deleted.
- Expose authenticated list, add, and remove operations. Add and remove are idempotent.
- List responses contain the complete catalog-card representation and are ordered newest-saved first.
- Place rules in a favourites service and all SQL in the existing database client, preserving Router → Service → Database client layering.
- Add a heart toggle to catalog cards, a protected Favourites route, and an authenticated header link.
- Signed-out heart selection routes through login with a safe return destination.
- Use optimistic UI only with rollback and a visible error on failure.
- Do not introduce a Favourite limit, pagination, a new state library, or coupling to Basket/Order state.

## Testing Decisions

- Primary seam: FastAPI HTTP endpoints through the existing TestClient and throwaway SQLite database. This catches routing, authentication, service rules, SQL, serialization, and account isolation together.
- Cover authentication requirement, per-Shopper isolation, persistence, idempotent add/remove, nonexistent catalog items, newest-first ordering, and full catalog-card data.
- Keep expected values independent and verify observable HTTP behaviour rather than internal calls or database rows.
- Focused frontend behaviour uses Vitest and Testing Library at the component/router seam, supplemented by the production Vite build and browser interaction.
- Run the full backend suite after each vertical slice and the full build/browser checks at completion.

## Out of Scope

- Sharing Favourites, public wishlists, notifications, recommendations, notes, folders, ranking, limits, bulk operations, and anonymous Favourites.
- Changes to checkout, Basket ownership, Orders, catalog administration, or product inventory.

## Further Notes

The feature is intentionally called Favourites throughout the UI and domain documentation. No ADR is needed because the selected design follows existing architecture and remains inexpensive to reverse.
