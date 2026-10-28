# 01: Correlate and harden API responses

**What to build:** Operators and security reviewers receive trustworthy request correlation, structured completion events, and hardened browser response defaults on every API request.

**Blocked by:** None (can start immediately).

**Status:** resolved

- [x] Valid request IDs are preserved and invalid or missing IDs are replaced with UUIDs.
- [x] Structured events contain no request bodies, credentials, tokens, or headers.
- [x] Security and correlation headers are covered through the HTTP seam.
