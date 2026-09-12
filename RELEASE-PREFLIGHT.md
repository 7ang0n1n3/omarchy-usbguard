# Release preparation — 2026-09-12

Status: MIT-licensed local source candidate prepared; remote CI, tag, and
release assets remain pending. The manifest version is 1.1.1.

## Candidate identity

- Repository: https://github.com/7ang0n1n3/omarchy-usbguard
- Remote state when inspected: empty repository with no default-branch HEAD.
- Local candidate: `omarchy-usbguard-release`, cloned from that remote and
  populated from the previously validated working source. Use
  `git rev-parse HEAD` for its full immutable identity after committing.
- Target host observed: Omarchy 4.0.0.alpha, Quickshell 0.3.1, USBGuard 1.1.4,
  one 1920×1200 untransformed display.

## Current evidence

- Official `omarchy plugin validate`: passed against the symlink-free source.
- Portable release validator passes. Declared process, privilege, installer,
  package, and service capabilities require the documented manual review; its
  advisory static scan is not a security audit.
- `./tests/run`: passed 11 parser/safety tests, seven privileged-helper tests,
  one immutable-packaging test, one isolated user install/update/removal and
  collision test, plus Bash syntax checks.
- `bash tests/run-service.sh`: passed the Quickshell fake-CLI state suite,
  including six intended authenticated mutations, cancellation/denial,
  dependency/daemon failures, recovery, and stale-ID refusal.
- QML files parsed with the installed Qt 6 `qmlformat`; `qmllint` was exercised
  with the installed Omarchy imports. Dynamic host tokens continue to produce
  the limitations recorded in VALIDATION.md.
- `./demo/run`: generated `preview.png` at 920×780 from committed fictional
  fixture data on an empty temporary workspace and restored workspace 1.
  Demo preflight passes.
- `.github/workflows/tests.yml` is prepared for the portable suite. It has not
  run remotely because the repository is still empty.

## Source changes made for release

- Excluded the development-only `Commons` and `Ui` symlinks. The optional
  standalone installer now creates its own runtime copy and module links outside
  the Git plugin source; isolated install, repeat update, removal, idempotent
  removal, and destination-collision behavior are tested.
- Added standard `omarchy plugin add`, update, and removal documentation,
  version-matched draft release notes, dependency/system-access documentation,
  support/security routes, portable CI, and deterministic preview tooling.

## Remaining release boundary

1. Push the default branch and require green CI.
2. Exercise fresh installation from the pushed Git repository, live-shell
   discovery/enable/open/reload/disable/removal, and a fast-forward update.
   Record the exact final plugin SHA and Omarchy source identity.
3. Re-run the preflight, write final release notes, and prepare source/release
   manifests, an SPDX 2.3 SBOM, artifacts, and complete SHA-256 checksums bound
   to the final commit.
4. Create and push an immutable annotated `v1.1.1` tag only after explicit owner
   authorization. Verify the remote tag object and downloaded draft assets with
   tagged preflight before publishing a GitHub release.

No real USB device or policy was changed during release preparation. No Git
push, tag, or release was published. Existing system helper files were
not changed. This evidence is scoped to the commands and environment above.
