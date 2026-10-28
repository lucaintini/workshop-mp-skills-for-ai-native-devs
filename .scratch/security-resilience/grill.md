# Security and resilience grill

## Decisions answered

- **What is protected?** Shopper credentials, signed identity, per-shopper baskets and favourites, order data, and service availability.
- **What trust boundaries matter?** Browser to Vite proxy, proxy to API, API to SQLite, CI to package registries, and update PR to protected branch.
- **What failure should restart?** A dead process may be restarted by its supervisor. A live but database-unready process must receive no traffic. Repeated failure needs bounded backoff and operator evidence, not a restart storm.
- **Should updates install themselves?** No. Dependabot proposes locked changes; CI, review, canary health, and rollback gate delivery.
- **What can scale now?** Static frontend delivery can scale independently. The API remains single-instance while SQLite is authoritative; horizontal API scale requires shared durable state first.
- **What OWASP claim is made?** Targeted controls informed by ASVS 5.0 and OWASP authentication/REST guidance, not blanket ASVS certification or a penetration-test claim.

## Threats selected for this tracer bullet

1. A production deployment accidentally uses the tutorial signing secret.
2. Login leaks whether an account exists through a skipped password-hash operation.
3. Tokens from a different issuer or audience are accepted.
4. Sensitive API responses are cached or embedded by another origin.
5. A database failure leaves a live instance receiving traffic.
6. Dependency drift accumulates unnoticed or updates bypass verification.
