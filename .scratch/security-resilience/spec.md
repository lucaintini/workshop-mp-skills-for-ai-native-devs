# Security and operational resilience specification

## Acceptance criteria

- Production configuration rejects the tutorial JWT secret and signing secrets shorter than 32 bytes.
- Authentication performs a password-hash check for known and unknown accounts and always returns the same invalid-credentials response.
- Issued tokens contain issuer, audience, issued-at, expiry, and unique ID claims; protected endpoints reject incorrect issuer or audience.
- API responses include correlation, anti-sniffing, frame denial, restrictive frame ancestors, referrer, and permissions headers. Sensitive or authenticated responses use `no-store`; public product images use an explicit public cache policy.
- `/api/health` reports process liveness; `/api/health/ready` returns 200 only when the database answers a probe and otherwise returns 503.
- Verification restores a previously running frontend even when a gate fails and starts missing services before waiting on them.
- Weekly CI detects ecosystem drift. Dependabot opens npm, uv, and Actions pull requests; updates never bypass tests or review.
- Documentation states the SQLite scaling boundary and the production path for supervised restarts, multi-instance data, canaries, and rollback.

## Explicit non-goals

- No claim of full OWASP ASVS conformance, penetration testing, DDoS resistance, zero downtime, or autonomous production remediation.
- No blind dependency auto-merge or code that rewrites itself.
- No pretend horizontal scaling while SQLite remains local state.
