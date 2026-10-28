# REVIEW.md

What matters when reviewing a change to this repo:

- **Baskets and auth:** a failure is "one shopper can see or change another shopper's basket or orders". Check every new route for who can reach it.
- **Checkout:** a failure is "an order and a basket disagree". Order writes and basket changes must stay in one transaction.
- **Tests:** every behaviour change has a test that would fail without it. No test, no merge.
- **Frontend:** errors must be shown, never disguised as an empty state.
- **Identity:** production must reject the tutorial JWT secret; tokens must be bound to issuer, audience, and expiry; login failures must not reveal account existence.
- **Operations:** liveness is not readiness. Database-unready instances receive no traffic, restarts use bounded policy, and updates remain test/review gated.
- **Scale:** SQLite is a single-instance boundary. Reject diagrams or claims that add API replicas without shared durable state, migrations, and recovery evidence.
- **Supply chain:** both Python manifests and npm are audited; lockfiles and CI actions must change together with their source manifests.
- At most 3 nits per review. Skip `uv.lock`, `package-lock.json` and `static/images`.
- Cite `file:line` for every finding. No findings from names alone.
- Start the summary with a count of findings. If nothing needs fixing, say so.
