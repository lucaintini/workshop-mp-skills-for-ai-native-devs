# eShop: new features with Matt Pocock's skills

This branch, `mash/part-2-new-features`, is the starting point for Part 2 of the Perth AI workshop on Matt Pocock's skills for AI coding agents. Part 1 runs from `main`.

**Setup guide:** https://perth-ai.github.io/workshop-mp-skills-for-ai-native-devs/ · [skills cheat sheet](https://perth-ai.github.io/workshop-mp-skills-for-ai-native-devs/skills.html) · [slides](https://perth-ai.github.io/workshop-mp-skills-for-ai-native-devs/slides.html)

## The story

In Part 1 you were handed a buggy, vibe-coded online store and triaged it. Those bugs are now fixed, with tests. The client is happy, and now they want new features. Your job is to build one properly: grill the idea, write a spec, break it into tickets, implement it test-first, and get it reviewed and merged.

See [`docs/architecture.md`](docs/architecture.md) for the complete Shopper journey plus high-level software, low-level Favourites, runtime/hardware, and data-flow diagrams.

See [`docs/enterprise-readiness.md`](docs/enterprise-readiness.md) for implemented platform controls, their limits, and the ranked standards-backed roadmap toward a production enterprise system.

## Get your own copy

1. Click **Use this template** → **Create a new repository** at the top of this page, and tick **Include all branches**.
2. Clone your new repo and switch to Part 2. Already have a copy from Part 1? Run `git stash -u` and `git fetch` first.

   ```bash
   git switch mash/part-2-new-features
   ```

3. Run `/setup-matt-pocock-skills` in your coding agent. Choose GitHub issues if you're signed in to `gh`, or local files if not.

Your copy has its own issues, and pull requests go into your own `mash/part-2-new-features`.

## Run the app

The full guide is in [`python-eshop/README.md`](python-eshop/README.md). In short, in two terminals:

```bash
cd python-eshop/backend && uv sync && uv run python run.py
cd python-eshop/frontend && npm install && npm run dev
```

Open http://127.0.0.1:4321 and sign in with `demouser@perthai.com.au` / `Pass@word1`.

## Run the tests

```bash
cd python-eshop/backend && uv run pytest
```

On Windows, run the complete workshop guardrail from the repository root:

```powershell
pwsh -File .\scripts\Verify-Workshop.ps1
```

It discovers WinGet and workshop-local tools even when the current shell's PATH is stale, verifies the Matt Pocock plugin and setup-skill installation, runs every backend and frontend quality gate, audits both Python dependency manifests plus npm, and checks the running shop through its API and frontend proxy. Runtime checks include database readiness, browser anti-framing headers, every catalog page and product image, login, and the Favourites route. If the workshop Vite server owns port 4321, the script restores it even after a failed gate; it refuses to stop unrelated processes.

Use `-CheckSkillInvocation` to launch a fresh read-only Codex process and prove that `$setup-matt-pocock-skills` is actually callable, rather than merely installed. This stricter diagnostic fails when Codex's plugin loader does not expose the skill.

GitHub Actions repeats the same tests on Windows and Ubuntu for pushes, pull requests, manual runs, and a weekly drift check. Dependabot proposes weekly npm, uv, and Actions updates. Updates remain pull requests: review and green gates are required rather than blind auto-merge or self-modifying production.

## What's here for the review step

- [`AGENTS.md`](AGENTS.md): project context your agent loads every session (Codex, Cursor, Copilot and others read it; `CLAUDE.md` points Claude Code at it).
- [`REVIEW.md`](REVIEW.md): what a reviewer, human or `/code-review`, should care about in this repo.
- [`.github/pull_request_template.md`](.github/pull_request_template.md): every PR says how it was tested, how risky it is and how to revert it.

## Credits

The app comes from Part 1 of this workshop, on `main`, by Rafael Avigad and Raj Saddi. Released under CC0, like the original.
