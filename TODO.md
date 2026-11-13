# TODO

## Repository review (2026-11-13)

- [x] **P1 — Refresh image pins and harden action inputs (medium).**
  The builder now uses Rust 1.100.0, Alpine 3.24.4, and `tonistiigi/xx` 1.10.0. The sample workflow runs the local action and uses current `actions/checkout`; `app-name` and `output-file-name` are passed through environment variables and validated before shell or path use.

- [x] **P1 — Add a hosted Linux smoke test for the action artifact (small).**
  `.github/workflows/ci.yml` runs the action with `test_app`, checks the reported archive path, loads the saved image, and runs the container.
- [ ] **P1 — Validate the action artifact on Linux (medium).**
  Keep this open until the hosted smoke workflow passes. Docker Desktop's Linux daemon is unavailable locally, so archive and container behavior remain unverified here; the first hosted result will be available after this change is pushed.
