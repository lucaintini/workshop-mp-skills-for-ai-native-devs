## Summary

```mermaid
flowchart LR
    Shopper([Shopper]) --> Catalog[Catalog product]
    Catalog --> Favourite[Save Favourite]
    Favourite --> Revisit[Favourites page]
    Catalog --> Basket[Add to Basket]
    Revisit --> Basket
    Favourite --> API[Authenticated API]
    API --> DB[(Account-owned SQLite relationship)]
    CI[CI guardrail] --> Tests[Backend and frontend tests]
    CI --> Build[Build and audit]
```

Adds private, persistent Favourites for authenticated Shoppers, including optimistic heart toggles with visible rollback errors, a protected Favourites page, account isolation, and resilient authentication transitions. Adds CI quality gates, a tested one-command Windows verifier, multi-level Mermaid architecture documentation, correlated and hardened API responses, automated accessibility checks, and a standards-backed enterprise-readiness roadmap.

See the [architecture diagrams](https://github.com/lucaintini/workshop-mp-skills-for-ai-native-devs/blob/mash/part-2-new-features/docs/architecture.md), [workshop-quality receipt](https://github.com/lucaintini/workshop-mp-skills-for-ai-native-devs/blob/mash/part-2-new-features/.scratch/workshop-quality/loop.md), [enterprise baseline receipt](https://github.com/lucaintini/workshop-mp-skills-for-ai-native-devs/blob/mash/part-2-new-features/.scratch/enterprise-readiness/loop.md), and [ranked enterprise roadmap](https://github.com/lucaintini/workshop-mp-skills-for-ai-native-devs/blob/mash/part-2-new-features/docs/enterprise-readiness.md).

## Evidence

- **Before:** Shoppers had no way to save catalog items, and the repository had no CI workflow enforcing its existing checks.
  **After:** 49 backend tests and 13 frontend tests pass; PowerShell helper tests, the Vite production build, axe accessibility audit, and `npm audit` pass; browser verification reaches `/favourites` and checks all 12 catalog images. The Windows verifier finds stale-PATH tools, protects unrelated processes, starts or restores the local app, and can detect when an installed plugin is not actually invocable.

## Merge Danger

**Door:** two-way

The feature and CI workflow can be reverted without destructive data migration. The new table is additive.

**Blast Radius:** shop

Touches catalog cards, authenticated navigation, SQLite schema initialization, and account-scoped API routes. Basket, checkout, and Orders behaviour remain unchanged and covered by the full backend suite.
