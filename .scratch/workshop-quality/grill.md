# Workshop quality loop: grilling record

The user authorised the agent to answer each question with its recommended answer and continue the loop.

## Round 1: purpose and boundaries

### Q1: Who is the capability for?

**Recommended and accepted:** Treat the workshop participant as the operator. The verifier should prove their Windows checkout, tools, application, and evidence are ready without requiring knowledge of where WinGet installed each executable.

### Q2: What is the public testing seam?

**Recommended and accepted:** Use the PowerShell command as the primary seam. A zero exit code plus explicit evidence is success; any missing tool, failed quality gate, foreign port owner, broken runtime route, or missing plugin is a non-zero failure.

### Q3: May verification stop processes?

**Recommended and accepted:** It may stop and restore only a Vite process whose command line points into this repository. Any other owner of ports 4321 or 8765 is a hard stop with the PID reported.

### Q4: What should happen when services are absent?

**Recommended and accepted:** Start the workshop backend and frontend in hidden local processes, wait for readiness, and leave them running for the participant. Existing verified workshop processes are reused, except Vite is restarted around `npm ci` to release Windows native-module locks.

## Round 2: evidence depth

### Q5: How much runtime data should be checked?

**Recommended and accepted:** Check proxy health, every catalog page, every catalog-item image, demo login, and the browser-facing Favourites route. Checking only the first catalog page is incomplete evidence.

### Q6: How should plugin availability be proved?

**Recommended and accepted:** Always verify the exact installed plugin version and exact setup-skill file. Offer a strict fresh-process invocation probe that fails honestly while the current Codex/plugin loader does not expose the skill. Do not turn an external loader defect into a false application failure during ordinary verification.

### Q7: What documentation is required?

**Recommended and accepted:** Maintain five Mermaid views: complete Shopper journey, high-level software, low-level Favourites, Windows runtime/hardware, and Favourite data flow. Link them from the README and PR body.

## Round 3: completion

### Q8: What closes the loop?

**Recommended and accepted:** The spec and tickets are published, all tickets are resolved, the verifier passes locally, standards and spec reviews report zero findings, fork CI is green, the PR body links the evidence, and the selected retro improvements are committed and pushed.

The frontier is empty; no design question remains silently assumed.
