# Native project and CI

Project/workspace/shared scheme restored from `7cfb432^`, retaining the actual
QRReader app/unit/UI target IDs and synchronized folders. Current filenames and
resources belong to those folders. Team is `5Q94QJ7G98`, bundle
`jp.qleap.qrreader`, minimum iOS 16, marketing version 1.0.3.

```sh
bundle exec ruby build-support/reconcile-project.rb
bundle exec ruby build-support/project-contract.rb
ruby fastlane/test/run_all.rb
```

The shared scheme explicitly includes unit and UI testables. Direct imports have
linked SPM products; direct package requirements match exact lock versions.
`Release Policy` is the only required release check. PR checks need no protected
App credential and do not resolve the private QuantumLeap package. Existing
TestFlight/Fastlane code remains responsible for trusted resolve/archive/upload.
Legacy hosted checks and AI review were removed; the retained CommitLint check
uses a minimal secret-free Ruby conventional-header policy, not a phantom JS app.

Firebase configuration remains ignored and is supplied exclusively by the trusted
release engine into its temporary source copy as `TESTFLIGHT_FIREBASE_CONFIG`.
It is not read or printed by project generation or checks.

The project and build-support locks now contain the complete native Xcode 27
resolver result. The unsigned simulator build passed. QuantumLeap uses the
immutable published 0.0.8 revision. Marketing version 1.0.3 matches the latest
App Store Connect TestFlight version.

Signing, simulator UI execution and TestFlight upload have not been run locally.
Uploads remain restricted to authorized merge CI.
