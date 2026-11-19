# Camera Design Implementation Plan

> **For agentic workers:** Execute this plan with Claude Code for bounded file changes and Codex for native macOS commands, integration, screenshots, and evidence. No Git commits or publishing are part of this request.

**Goal:** Apply the user-approved Camera mock to the real QRReader app, including the larger icons.

**Architecture:** Use one shared history store, pure Foundation parsing/persistence/session rules, and SwiftUI screens. Keep CodeScanner for actual capture and QuantumLeap for support, policy, version, and first-launch storage. Native sheets and safe-area layout adapt to real devices; the HTML phone frame is not app code.

**Tech Stack:** Swift, SwiftUI, AVFoundation, CodeScanner, QuantumLeap, FirebaseCore/AppCheck, Swift Testing, XCTest, XcodeGen.

**Spec:** `design/mockups/qrreader-ui-v2.html`, Camera variant, approved by the user on 2026-10-14.

## Global Constraints

- Preserve the `QR_HISTORY` JSON array schema: UUID `id`, string `value`, Foundation Codable `date`.
- Preserve `IS_FIRST_LAUNCH` and QuantumLeap's environment provider; intro completion and camera permission are separate states.
- Explicit HTTP/HTTPS opening only; preserve the complete original payload for display/copy/share.
- Action symbols 24pt, tab symbols 28pt, at least 44pt control targets. Use an accessible SwiftUI bottom bar to honor the specified symbol sizing; keep the system status bar and home indicator.
- Existing project metadata is absent. The user authorized creating it. Pin compatible dependencies and use iOS 16 (QuantumLeap 0.0.8's verified floor), without adopting the newer iOS-17-only package.
- Real camera behavior on devices. DEBUG fixtures and isolated defaults only for UI tests; never seed a user's history or launch fixture behavior in Release.
- Never edit or stop another project's simulator/resources. Register cleanup before creating this run's device; shut down/delete only owned UDIDs.

## Review Focus

- Duplicate scanner callbacks while a result is presented; foreground/tab/modal transitions must pause and resume correctly.
- Malformed/non-web URLs and long payloads must remain readable and copyable without implicit external navigation.
- Same-date duplicate history values must delete by UUID, not sorted offsets.
- Existing and corrupt persisted history must not be overwritten by an automatic fallback to an empty list.
- Permission denial, restricted hardware, first-run timing, large text, and light/dark appearances must have usable paths.

## Tasks

### 1. Pure behavior and persistence tests

**Files:** `Package.swift`, `QRReader/Models/{QRContent,HistoryRepository,ScanSessionState}.swift`, `QRReader/Codable/HistoryItem.swift`, `QRReaderTests/QRReaderCoreTests.swift`.

**Interfaces:** `QRContent(value:)` with `webURL`, `title`, `isWebURL`; `HistoryRepository(defaults:key:)` with `items`, `sortedItems`, `hasLoadError`, `append(value:date:)`, `remove(ids:)`, `clear()`; `ScanSessionState.canScan` derived from the seven visibility/permission/presentation/error flags.

- [x] Write behavioral tests and minimal deliberately failing stubs.
- [x] Codex runs `swift test` on studio and retains the expected red output (18 tests, 34 expected issues).
- [x] Implement the pure behavior; run the entire package suite to green.
- [x] Verify existing UUID/date/value records round-trip, stable same-date ordering and deletion, and corrupt-data non-overwrite.

### 2. Camera design and real flows

**Files:** `ContentView.swift`, the five existing screens, shared theme/tab bar, authorization/configuration/history-store services, `Main.swift`, localization, and relevant colorsets.

- [x] Full camera preview with a legible overlay, viewfinder, settings entry, and fixed two-destination bottom bar.
- [x] Gate scanner mounting on authorization and completed intro; derive paused state from tab/scene/modal/result/error flags. Guard duplicate callbacks before saving.
- [x] Present URL/text results in the same native medium/large sheet. Pin actions, scroll text, report copy, share through the system sheet, and resume after dismissal/return.
- [x] Render newest-first history, empty/error states, UUID deletion confirmation and clear confirmation; share the same result presentation and settings.
- [x] One-page intro with explicit permission request and persisted completion; no OS camera request behind the intro.
- [x] Remove the unused scanner implementation and unused imports if confirmed unreferenced.
- [x] Add DEBUG-only launch fixtures and isolated test storage, then meaningful UI tests for result/close/copy/clear cancel/settings/first-run.

### 3. Build configuration and native verification

**Files:** `project.yml`, native validation script, README build instructions.

- [x] Generate `QRReader.xcodeproj` with app/unit/UI test targets, localized camera purpose, assets, and actual package dependencies. Keep generated project ignored; commit no credentials.
- [x] Native simulator build and tests on a uniquely owned device, without signing or publishing.
- [x] Inspect actual app screenshots for scan, result, history, and intro; include light/dark, long text and enlarged text where relevant.
- [x] Independent Claude Code review of the actual diff; fix material findings and verify fixes.
- [x] Verify cleanup and report evidence plus any physical-camera or configuration limitations.

## Rulings and Evidence

- Work in the current checkout: the only initial local changes are this chat's mock files; the user wants the actual app updated here. No worktree or commit operation is necessary.
- Both independent plan reviews completed before implementation. Primary risks are session gating and stable-ID deletion.
- Source history always includes UUIDs. Do not invent an unproven missing-ID migration; preserve malformed raw storage and refuse automatic append until explicitly cleared instead.
- Cached primary sources verify QuantumLeap 0.0.8 supports iOS 16 and uses `IS_FIRST_LAUNCH`; CodeScanner 2.5.2 exposes `isPaused`, continuous mode, and simulated data.
- Pin QuantumLeap's verified 0.0.8 source revision `e68cb0aed9394348b54969e018e14d640b4126e2`: the native resolver reported a cached tag revision mismatch. The upstream tag was checked directly, and revision resolution succeeded. Record all transitive pins in `Config/Xcode-Package.resolved`.
- Code edits execute in Claude's verified Linux mount; Swift/Xcode compilation executes on studio because the worker has no Swift toolchain.
- The user explicitly authorized creating the missing Xcode project.

## Final Native Evidence

- Full final run: 18 SwiftPM core tests, 28 iOS unit tests, 15 UI tests passed.
- Additional screenshots/operation checks: iPhone SE iOS 17.5 at maximum accessibility font and iPad Air iOS 26.5 dark, five tests each. Codex inspected the images.
- Unsigned Release arm64 iOS build passed; generated version values and exclusion of DEBUG fixture markers checked.
- All nine owned disposable devices are absent from the current device set, the validation lock is gone, and the pre-existing Simulator PID is preserved.
- Static review findings and native visual findings were resolved or verified. CI/deployment remain outside this request; their generation/configuration prerequisites are documented.
- See docs/validation/2026-10-14-camera-ui.md. Physical-camera behavior still requires a device check.
