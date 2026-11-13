# TODO

## Repository review (2026-11-12)

- [x] **P1 — Refresh image pins and harden action inputs (medium).**
  The builder now uses Rust 1.100.0, Alpine 3.24.4, and `tonistiigi/xx` 1.10.0. The sample workflow runs the local action and uses current `actions/checkout`; `app-name` and `output-file-name` are passed through environment variables and validated before shell or path use.

- [ ] **P1 — Validate the action artifact on Linux (medium).**
  Run the locked Docker build, start the final container, and verify that the action reports an existing `<output-file-name>.tar.zip` in the workspace. Docker Desktop's Linux daemon is unavailable in this environment; `docker info` cannot connect to `npipe:////./pipe/dockerDesktopLinuxEngine`, so container and archive behavior remain unverified.
