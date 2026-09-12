# Release notes

## 1.1.1 — unpublished candidate

Initial public source candidate, retaining the existing local version 1.1.1.

- Inspect USBGuard devices and rules in an Omarchy panel or standalone window.
- Confirm policy changes and authenticate each write through a scoped helper.
- Revalidate device/rule identity before dispatch and refuse direct mutations
  from the unprivileged command runner.
- Use content-addressed QML generations in the optional custom installer.
- Keep Omarchy module symlinks outside the Git plugin source.
- Supply portable CI and fixture tests for parsing, helper boundaries,
  packaging, and isolated installation/update/removal.

Prepared against Omarchy 4.0.0.alpha, Quickshell 0.3.1, and USBGuard 1.1.4.
Final source identity, live lifecycle evidence, and remote CI are pending.
No real peripheral mutation is part of automated release testing.
