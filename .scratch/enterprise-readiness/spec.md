# Enterprise-ready platform baseline

**Status:** ready-for-agent

## Problem Statement

The shop demonstrates functional behaviour but lacks several foundations reviewers expect from a modern enterprise product: correlated requests, machine-readable operational evidence, explicit browser hardening, automated accessibility regression detection, and an honest roadmap separating implemented controls from future production work.

## Solution

Add a bounded platform baseline: correlated and hardened API responses with structured HTTP events, an axe-powered accessibility guardrail for the core catalog interaction, and a standards-backed readiness document that prioritises identity, data durability, observability, verification, and supply-chain work.

## User Stories

1. As an operator, I want every request correlated, so that failures can be traced across logs and clients.
2. As an operator, I want machine-readable HTTP events, so that monitoring systems can ingest them.
3. As a security reviewer, I want hardened response defaults, so that common browser behaviours are constrained.
4. As a security reviewer, I want invalid external correlation IDs replaced, so that log structure remains trustworthy.
5. As a frontend maintainer, I want automated accessibility checks, so that common WCAG regressions fail CI.
6. As an accessibility reviewer, I want automation limits stated, so that a passing test is not misrepresented as conformance.
7. As an enterprise architect, I want standards-backed priorities, so that later investment follows explicit risk rather than fashion.
8. As a contributor, I want these controls and evidence visible in the PR, so that the improvement is reviewable.

## Implementation Decisions

- Add one FastAPI middleware boundary for request IDs, security headers, and structured completion events.
- Preserve only syntactically valid UUID request IDs; generate a UUID otherwise.
- Log method, route, status, duration, and request ID without headers, tokens, credentials, or bodies.
- Expose request IDs through CORS for browser diagnostics.
- Run axe-core against the rendered catalog-card interaction using WCAG A/AA tags; document that automation is partial evidence.
- Keep future controls as a ranked roadmap tied to OWASP ASVS 5.0, WCAG 2.2, OpenTelemetry HTTP conventions, GitHub dependency review, and SLSA 1.2.

## Testing Decisions

- Test middleware through the FastAPI TestClient public HTTP seam.
- Test accessibility through the rendered React component seam.
- Run the full application suites, production build, audit, Windows verifier, and fork CI after targeted red/green cycles.

## Out of Scope

- Claiming WCAG or ASVS certification.
- Deploying telemetry collectors, managed identity, a managed database, or release infrastructure.
- Generating SLSA provenance without a release artifact.
- Adding controls that cannot be exercised meaningfully in this workshop topology.

## Further Notes

This is an additive two-way-door baseline. Later enterprise cycles remain independently reviewable.
