## What changed

<!-- One or two sentences. Link the issue: Closes #123 -->

## Testing

<!-- How you checked it works. Paste the `uv run pytest` summary, and anything you clicked through. -->

- [ ] Complete local verifier or equivalent focused tests passed
- [ ] Dependency audits passed when manifests or lockfiles changed
- [ ] Liveness/readiness and failure behavior were checked when runtime dependencies changed

## Risk

<!-- Low: docs, copy, additive behind a flag. Medium: ordinary product change. High: auth, baskets, checkout, CI. -->

## How to revert

<!-- Usually "revert this PR". Say so if there is a data change that a revert would not undo. -->

<!-- For delivery/operations changes, describe the unhealthy-release signal and the last-known-good rollback path. -->
