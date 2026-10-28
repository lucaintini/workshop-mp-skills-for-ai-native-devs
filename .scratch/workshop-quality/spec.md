# Verifiable workshop contribution

**Status:** ready-for-agent

## Problem Statement

A workshop participant can complete substantial application work without an easy, trustworthy way to prove that the whole Windows setup, quality loop, running shop, workflow evidence, and architectural explanation are complete. Installed tools may be absent from a stale shell PATH, a running frontend can lock native modules during a clean install, a port can belong to unrelated software, and installation metadata can claim a skill exists even when a fresh Codex process cannot invoke it.

## Solution

Provide one Windows verification command and a durable evidence set. The command discovers the participant's installed tools, protects unrelated processes, runs every backend and frontend quality gate, restores or starts the workshop services, and exercises the running shop through its public HTTP interfaces. The repository records the complete skill loop and explains the application with layered Mermaid views. The PR surfaces these improvements and their evidence directly.

## User Stories

1. As a workshop participant, I want one verification command, so that I can prove the complete checkout without remembering every command.
2. As a workshop participant with a stale PATH, I want installed WinGet and workshop-local tools discovered, so that a valid installation is not misreported as missing.
3. As a workshop participant, I want exact tool paths printed, so that failures are diagnosable.
4. As a workshop participant running Vite, I want clean installation to handle its Windows file lock safely, so that `npm ci` remains trustworthy.
5. As a PC owner, I want unrelated port owners protected, so that verification never terminates other software.
6. As a workshop participant with stopped services, I want verification to launch the shop, so that runtime checks do not depend on manual preparation.
7. As a workshop participant with running services, I want them reused when safe, so that verification remains fast and predictable.
8. As a workshop participant, I want backend tests run from the locked environment, so that dependency drift cannot disguise failures.
9. As a workshop participant, I want frontend tests, production build, and dependency audit run after a clean install, so that the shipped interface is credible.
10. As a workshop participant, I want frontend-proxy health checked, so that two independently running processes are not mistaken for an integrated shop.
11. As a workshop participant, I want every catalog page and image checked, so that partial catalog success is not reported as complete.
12. As a workshop participant, I want demo login checked through the public API, so that authentication readiness is evidenced.
13. As a workshop participant, I want the browser-facing Favourites route checked, so that the feature entry point is reachable.
14. As a workshop participant, I want the exact Matt Pocock plugin version and setup skill checked, so that a stale cache is not accepted accidentally.
15. As a workshop participant, I want an optional fresh-Codex invocation probe, so that plugin discoverability can be distinguished from installation.
16. As a reviewer, I want a complete skill-loop receipt, so that I can see how decisions, implementation, review, PR, and retro connect.
17. As a reviewer, I want layered architecture diagrams, so that I can understand the Shopper journey before implementation detail.
18. As a contributor, I want the PR body to link the evidence, so that my improvements are visible upstream.
19. As a maintainer, I want local and remote guardrails to agree, so that passing locally predicts passing CI.
20. As a maintainer, I want every failure to stop with a non-zero exit code, so that automation cannot silently continue.

## Implementation Decisions

- Use one PowerShell entry point designed for PowerShell 7 on Windows.
- Resolve tools from the active PATH, the workshop tool directory, WinGet package locations, the Codex app binary directory, and the participant's local binary directory.
- Treat the command's exit code and console evidence as the primary test seam.
- Use locked backend synchronization and a frontend clean install before running quality gates.
- Identify service ownership from listening ports and process command lines. Reuse or restart only processes attributable to this repository.
- Start missing workshop services in hidden processes and wait for their public health interfaces.
- Verify all catalog pages and images, not a sample.
- Match the setup skill to the installed Matt Pocock plugin version. Keep fresh-process invocation as a strict diagnostic mode because Codex/plugin discovery is external to the application.
- Keep architecture explanations in one linked document, ordered from participant journey to implementation data flow.
- Keep the workflow receipt beside local specs and tickets and link it from the PR.

## Testing Decisions

- Primary seam: execute the PowerShell command and observe its exit code and output. This catches tool discovery, dependency commands, process ownership, service lifecycle, and HTTP checks together.
- Existing backend FastAPI and frontend Vitest suites remain the application behaviour seams.
- GitHub Actions remains the clean-room remote seam for locked installation, tests, build, and audit.
- The strict skill-invocation mode is expected to fail while the current Codex/plugin loader does not expose the installed skill; that failure is diagnostic evidence, not suppressed output.
- Mermaid documents are reviewed for GitHub-compatible syntax and rendered through the PR/document view.

## Out of Scope

- Fixing the Codex desktop or CLI plugin loader itself.
- Supporting non-Windows service orchestration in the PowerShell verifier.
- Replacing the application's existing test suites.
- Hosting or deploying the shop to public infrastructure.
- Turning architecture documentation into generated source-of-truth diagrams.

## Further Notes

No ADR is needed. The verifier, evidence layout, and Mermaid views are additive and inexpensive to reverse. No eShop glossary term is introduced because workshop verification is an operator concern rather than a Shopper-domain concept.
