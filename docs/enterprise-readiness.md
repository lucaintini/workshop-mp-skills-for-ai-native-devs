# Enterprise readiness

This workshop shop is not represented as production-ready. This document separates controls implemented in the branch from the next evidence-based upgrades.

## Implemented baseline

- Every API response carries a UUID request ID, preserving a valid caller-provided ID for cross-system correlation.
- API requests produce structured JSON events containing method, route, status, duration, and request ID without credentials or tokens.
- API responses set `nosniff`, clickjacking, referrer, and browser-permission headers.
- A frontend test uses axe-core rules tagged for WCAG A and AA to catch automatically detectable catalog-card regressions.
- CI performs locked installation, backend and frontend tests, a production build, and dependency audit.
- Windows verification exercises proxy health, all catalog pages and images, login, and the browser-facing Favourites route.

Automated accessibility checks are a guardrail, not a conformance claim. WCAG conformance applies to complete pages and requires criteria that automation cannot fully assess. [W3C recommends WCAG 2.2 for current applicability](https://www.w3.org/TR/WCAG22/), and [Playwright's accessibility guidance](https://playwright.dev/docs/accessibility-testing) likewise recommends combining automation with manual and inclusive testing.

## Ranked next cycles

### 1. Production identity and secrets

- Move signing keys and environment-specific configuration into a managed secret store.
- Add key rotation, token revocation/expiry policy, login throttling, and security-event audit records.
- Select and trace a proportional OWASP ASVS 5.0 Level 1/2 requirement set. ASVS is the current stable framework for designing and verifying modern web application controls: [OWASP ASVS 5.0](https://asvs.owasp.org/).

### 2. Durable data operations

- Replace local SQLite with a managed relational database for multi-instance deployment.
- Adopt versioned migrations, encrypted backups, restore drills, retention policy, and recovery objectives.
- Add concurrency and failure tests around checkout and Favourite writes.

### 3. Full observability

- Export traces, metrics, and logs through OpenTelemetry rather than retaining only local structured events.
- Propagate trace context through the frontend proxy and database calls.
- Define service-level indicators for availability, latency, error rate, login, checkout, and dependency health.

OpenTelemetry provides shared HTTP names for cross-platform traces, metrics, and logs; use its [HTTP semantic conventions](https://opentelemetry.io/docs/specs/semconv/http/) instead of inventing vendor-specific field names.

### 4. Security and accessibility verification

- Add CodeQL, secret scanning, dependency review, API abuse tests, and an ASVS traceability matrix.
- Add real-browser axe scans for complete pages, keyboard-only flows, focus visibility/order, zoom/reflow, screen-reader checks, and inclusive user testing.
- Publish an accessibility statement that distinguishes automated coverage from manual evidence.

GitHub's [dependency review](https://docs.github.com/en/pull-requests/how-tos/review-pull-requests/reviewing-dependency-changes-in-a-pull-request) can reject newly introduced vulnerable dependencies on pull requests.

### 5. Reproducible delivery

- Build immutable deployment artifacts, generate an SBOM, sign releases, and attach provenance.
- Separate development and production topology, add readiness/liveness probes, and practise rollback.
- Define protected environments and required reviews before production deployment.

[SLSA 1.2](https://slsa.dev/spec/v1.2/) provides incremental supply-chain levels; Build L1 starts with provenance describing what built an artifact, how, and from which inputs.

## Completion policy

Each future cycle should select one bounded outcome, grill its decisions, publish a spec and tracer-bullet tickets, implement test-first, reach zero Standards and Spec findings, update the PR/release evidence, and run a retro. “Enterprise-ready” is never a one-time unchecked label.
