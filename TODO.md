<!-- TODO Reviewed ??-??-2026. -->

# TODO

## Repository review (2026-11-13)

- [ ] **P1 — Validate the action artifact on Linux (medium).**
  Keep this open until the hosted smoke workflow passes. Docker Desktop's Linux daemon is unavailable locally, so archive and container behavior remain unverified here. <!-- Partial (2026-11-17): hosted Linux run [#44033512154](https://github.com/john-cd/rust_github_action/actions/runs/44033512154) reached the action and failed because the Docker context was the repository root, which lacks `Cargo.toml`; the sample project is under `test_app/`. Commit `6b9bf54` adds a defaulted `project-path`, confines it to the checkout, checks for `Cargo.toml`, and makes the smoke workflow cover the nested project and an escaping path. Actionlint and commit hooks passed. Docker is unavailable locally; rerun the hosted smoke workflow after publishing the fix. -->
