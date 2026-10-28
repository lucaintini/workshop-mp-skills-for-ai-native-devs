## Summary

```text
Shopper
  Catalog card heart
    authenticated Favourites API
      account-owned SQLite relationship
  Favourites page
    newest-saved catalog cards
    Add to basket remains independent

CI
  Windows backend tests
  Frontend tests → production build → dependency audit
```

Adds private, persistent Favourites for authenticated Shoppers, including optimistic heart toggles with visible rollback errors, a protected Favourites page, account isolation, and resilient authentication transitions. Adds CI quality gates for the backend and frontend.

## Evidence

- **Before:** Shoppers had no way to save catalog items, and the repository had no CI workflow enforcing its existing checks.
  **After:** 46 backend tests and 12 frontend tests pass; the Vite production build succeeds; `npm audit` reports 0 vulnerabilities; browser verification reaches `/favourites` successfully.

## Merge Danger

**Door:** two-way

The feature and CI workflow can be reverted without destructive data migration. The new table is additive.

**Blast Radius:** shop

Touches catalog cards, authenticated navigation, SQLite schema initialization, and account-scoped API routes. Basket, checkout, and Orders behaviour remain unchanged and covered by the full backend suite.
