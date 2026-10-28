# Workshop quality workflow receipt

## Grill

- Eight design questions were answered with the agent's recommendations under the user's standing authorisation.
- The settled tree is recorded in `grill.md`; no unresolved frontier remains.

## Spec and tickets

- `spec.md` defines the Windows verifier, evidence, architecture, and PR visibility capability.
- Tickets 01 and 02 are resolved. Ticket 03 closes when the final two-axis review, PR update, and remote CI complete.

## Implement and review

- Primary seam: the PowerShell command's exit code and evidence.
- A true cold run discovered missing services, launched both, and checked 12 catalog images, login, proxy health, and the Favourites route.
- First review reported 3 Standards findings and 1 Spec finding.
- Resolved the Standards findings by extracting pure helpers, adding deterministic PowerShell tests to Windows CI, and deduplicating frontend startup.
- Resolved the Spec finding by creating this receipt and linking it from the PR evidence.

## PR and retro

- The PR body uses Mermaid and links the architecture, receipts, and enterprise-readiness evidence.
- Retro actions implemented: deterministic helper tests, CI wiring, cohesive module extraction, process-ancestry validation, cold-service startup, and all-page image verification.

## Completion bound

Zero final Standards findings, zero final Spec findings, green local verification, green fork CI, updated PR evidence, and a clean pushed branch.
