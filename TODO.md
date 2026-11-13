# TODO

## Repository review (2026-11-12)

- [ ] **P1 — Modernize the action's Rust and Alpine images and validate its artifact (medium).**
  `action.yaml` builds with Rust 1.75, the Dockerfile uses Alpine 3.19 and `tonistiigi/xx:1.3.0`, and the sample workflow references a mutable branch. Define the minimum supported Rust version, pin compatible maintained image releases, and validate a locked build, container startup, and the reported zip path on Linux. Treat action inputs as data via environment variables and quote or validate them before use in shell steps.
