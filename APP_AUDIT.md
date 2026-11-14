# Seniors 2027 — Flutter App Audit

- **Audit date:** 2026-11-05
- **Stabilization batch:** 2026-11-06
- **Repository:** `D:\fluuter_projects\Seniors_27`
- **Branch:** `sallam`
- **Latest commit:** `9335cbc Add refresh support for dynamic app content`
- **Working tree:** Pre-existing modifications remain in `lib/features/dashboard/daily_highlights_book_screen.dart`, `lib/features/dashboard/models/daily_highlight.dart`, and `pubspec.yaml`. Batch 1 additionally modifies the dashboard highlight viewer, token/session cleanup, profile loading/model, and tests, and adds `APP_AUDIT.md` plus regression test files.

## Scope and Method

Audited the Flutter application source, tests, configuration, dependencies, and build outputs. The review covered:

- App startup, splash, session handling, and login/OTP flow.
- Main tab shell, dashboard, daily highlights, announcements, and events.
- Notes and send-note flows.
- Profile, visited profiles, gallery, social links, and favorite song.
- Seniors directory and senior cards.
- Memoryboard and add-memory flow.
- Leaderboard.
- Shared widgets, API client, token storage, current-user cache, and models.
- Existing unit/widget tests and coverage output.

The audit used static source inspection, existing tests, coverage generation, debug builds, and runtime smoke attempts. The original audit made no production changes. A follow-up Batch 1 applied the scoped fixes documented below on 2026-11-06.

## Executive Summary

The project builds successfully for Windows, web, and Android, and the analyzer reports no errors. However, it is **not release-ready**:

- Batch 1 made the test suite green: **70 tests passed**.
- Line coverage improved to **44.79% (2208 / 4930)**.
- `HIGHLIGHTS-01`, `SESSION-01`, `PROFILE-01`, `HIGHLIGHTS-04`, and the ambiguous `OPEN BOOK` widget test were resolved.
- `AUTH-01` remains unresolved: the OTP flow still bypasses the username/gender onboarding screens, and no backend contract was available to justify changing routing.
- Android launch/login smoke testing succeeded using an x86_64 split debug APK. Windows and web runtime smoke testing remain blocked.
- Several P2 consistency issues remain, including error visibility, notes actions, and dead controls.

## Environment

- Flutter `3.44.8`
- Dart `3.12.2`
- Windows PowerShell 5.1
- Windows desktop target available
- Edge web target available
- Android emulator `Pixel_7a` available and booted
- `flutter doctor` reports:
  - Chrome missing
  - Android licenses not accepted
  - Visual Studio Community 2026 Insiders pre-release

## Verification Results

| Check | Command | Result |
|---|---|---|
| Formatting | `dart format` on Batch 1 files | Passed for all changed files |
| Full format check | `dart format --output=none --set-exit-if-changed lib test` | Reports one pre-existing file: `lib/features/dashboard/models/daily_highlight.dart`; not written |
| Static analysis | `flutter analyze` | Passed with 4 infos |
| Targeted regression tests | `flutter test test/daily_highlights_book_screen_test.dart test/token_storage_test.dart test/session_manager_test.dart test/profile_refresh_test.dart` | 22 passed |
| Widget tests | `flutter test test/widget_test.dart` | 10 passed |
| Full test suite | `flutter test --coverage` | **70 passed** |
| Coverage | `flutter test --coverage` | **44.79%** lines, `2208 / 4930` |
| Windows build | `flutter build windows --debug` | Passed |
| Web build | `flutter build web --debug` | Passed |
| Android build | `flutter build apk --debug` | Passed; APK is `191,720,225` bytes |
| Android split build | `flutter build apk --debug --split-per-abi` | Passed; x86_64 APK is `81,280,442` bytes |
| Android runtime smoke | Install x86_64 split APK, launch app, tap `LOGIN` | Passed; login screen and `STEP 1 / 5` email screen rendered; no app fatal log |

### Batch 1 Changes

- `HIGHLIGHTS-01`: final-item deletion now pops outside `setState`, empty lists render an empty state, and out-of-range indexes are clamped.
- `SESSION-01`: `TokenStorage.clearToken()` now clears legacy and in-memory state even when secure deletion fails, then rethrows the secure-delete error; `SessionManager` still clears identity and navigates.
- `PROFILE-01`: social-link and favorite-song saves now force a profile refresh. `ProfileUser.fromJson` now safely accepts string IDs.
- Widget test: `OPEN BOOK` ambiguity removed by targeting the notes section (`LATEST 4 NOTES`) instead of a global label.
- Regression tests added for final deletion, empty/out-of-range highlights, secure-delete failure, session navigation after failure, and profile refresh.

### Resolved Test Detail

The original failure was:

```text
flutter test test/widget_test.dart --plain-name "main shell navigates between yearbook sections"

StateError: Bad state: Too many elements
test/widget_test.dart:306
```

`ProfileScreen` contains multiple `OPEN BOOK` labels: the notes card and the gallery card. Batch 1 now targets the notes section via `LATEST 4 NOTES`, avoids `pumpAndSettle` while the notes screen spinner is active, and verifies `NotesOpenBookScreen` is shown.

### Coverage Change

| Run | Lines | Covered | Coverage |
|---|---:|---:|---:|
| Audit baseline | 4907 | 1887 | 38.46% |
| Batch 1 | 4930 | 2208 | 44.79% |

New tests cover final-highlight deletion, empty/out-of-range highlights, secure-delete failure, session cleanup after failure, and profile refresh after a saved favorite song.

## Findings

Severity definitions:

- **P0:** Release blocker; crash, data loss, security breach, or unusable core flow.
- **P1:** High-risk defect in a core flow or likely crash.
- **P2:** Medium-risk functional, consistency, or UX defect.
- **P3:** Low-risk hardening, cleanup, or edge-case issue.

### P0

No P0 issue was confirmed from the available static and test evidence. Runtime smoke testing was incomplete, so this remains provisional.

### P1

#### AUTH-01 — OTP success bypasses username and gender onboarding

**Status: Unresolved (Batch 1 investigation).** No backend contract or product documentation was found. `LoginUsernameScreen` and `LoginGenderScreen` contain no API calls and are referenced only by tests/manual navigation. Routing was intentionally left unchanged.

**Evidence:**
- `lib/features/auth/login_email_screen.dart:160` opens `LoginOtpScreen`.
- `lib/features/auth/login_otp_screen.dart:103-106` navigates directly to `MainAppShell` after successful OTP verification.
- `lib/features/auth/login_username_screen.dart:52` only links to `LoginGenderScreen`; grep found no production reference to either screen.
- `lib/features/auth/widgets/login_progress.dart:15` displays `STEP $step / 5`, but the active flow only reaches steps 1 and 2.

**Impact:**
New or returning users may never supply a username or gender. Downstream features that assume a complete profile may display incomplete data or behave inconsistently. If the backend intentionally completes the profile during OTP verification, the orphaned screens and 5-step progress indicator are misleading.

**Recommended action:**
Confirm the intended onboarding contract with the product/backend owner. Either restore the username/gender steps in the active flow, or remove the dead screens and correct the progress indicator to match the real flow.

#### HIGHLIGHTS-01 — Deleting the last daily highlight can crash during dismissal

**Status: Resolved in Batch 1 (2026-11-06).** The viewer now clamps indexes, renders an empty state, and dismisses after deletion without mutating state inside `setState`. Regression coverage is in `test/daily_highlights_book_screen_test.dart`.

**Evidence:**
- `lib/features/dashboard/daily_highlights_book_screen.dart:119-127` removes the highlight, and when the list becomes empty calls `Navigator.pop(context)` and `return` from inside `setState`.
- `lib/features/dashboard/daily_highlights_book_screen.dart:151` unconditionally indexes `highlights[_currentIndex]` during build.

**Impact:**
When the final highlight is deleted, the route can rebuild with an empty `_highlights` list before dismissal completes, causing a `RangeError`/build failure. This is a likely crash in a core dashboard flow.

**Recommended action:**
Pop before mutating state, or guard the build path with an empty-list placeholder. Remove the `Navigator.pop` from inside `setState` and add a focused regression test for the one-item deletion case.

### P2

#### AUTH-02 — “RESEND OTP” is non-interactive

**Evidence:** `lib/features/auth/login_otp_screen.dart:240-247` renders `RESEND OTP` as a plain `Text`, not a button.

**Impact:** Users who do not receive or lose the OTP have no in-flow resend path. They must navigate back and restart the email step.

**Recommended action:** Add a cooldown-aware resend action and surface its result/error state.

#### SESSION-01 — Token clear can leave a persisted session behind

**Status: Resolved in Batch 1 (2026-11-06).** `clearToken()` now always clears legacy preferences and the in-memory cache, rethrows secure-delete failures, and `SessionManager` still clears identity and navigates. Regression tests cover both storage and session behavior.

**Evidence:**
- `lib/core/storage/token_storage.dart:120-131` awaits `_secure.delete(_tokenKey)` before clearing the legacy `SharedPreferences` copy and in-memory cache.
- `lib/core/auth/session_manager.dart:52-57` catches token-clear failures and continues with navigation.

**Impact:** If secure deletion fails, the legacy preference or in-memory token may survive while the user is shown the login screen. On a later launch, the app may restore the old session. Logout is not guaranteed to be complete.

**Recommended action:** Clear in-memory and legacy storage in a `finally` block, make secure deletion best-effort with explicit failure handling, and add a test for secure-delete failure.

#### PROFILE-01 — Social links and favorite song can stay stale after saving

**Status: Resolved in Batch 1 (2026-11-06).** Social-link and favorite-song saves now call `_loadProfile(forceRefresh: true)`. The regression test also exposed and fixed string-ID parsing in `ProfileUser.fromJson`.

**Evidence:**
- `lib/features/profile/profile_screen.dart:384` passes `_loadProfile` as `onSaved` for social links.
- `lib/features/profile/profile_screen.dart:398` calls `_loadProfile()` after saving the favorite song.
- `lib/features/profile/profile_screen.dart:98-123` uses `CurrentUserCache.get`; a fresh cache entry returns without calling the `/me` fetcher.
- `FavoriteSongScreen` only pops `true` and does not update `CurrentUserCache`.
- `SocialLinksScreen` saves but does not return the updated list to `ProfileScreen`.

**Impact:** After editing social links or the favorite song, the profile can continue showing the old values until the 60-second cache expires or a forced refresh occurs.

**Recommended action:** Call `_loadProfile(forceRefresh: true)` after these saves, or return the saved values and update local state/cache directly.

#### PROFILE-02 — Profile load failures have no clear top-level error or retry

**Evidence:**
- `lib/features/profile/profile_screen.dart:128-133` catches `/api/Auth/me` failure and only calls `_stopChildLoading()`.
- `lib/features/profile/profile_screen.dart:167-187` catches visited-profile failure and only sets gallery/notes error strings.
- The profile header can remain on default/placeholder data without an explicit “failed to load profile” state.

**Impact:** Users can see an apparently valid but empty profile with no indication that the main profile request failed and no retry action.

**Recommended action:** Add a profile-level error state with retry, and keep child-section errors separate.

#### NOTES-01 — “ADD NOTE” is dead and currently unreachable

**Evidence:**
- `lib/features/notes/notes_open_book_screen.dart:392-395` defines `ADD NOTE` with `onPressed: () {}`.
- `lib/features/app_shell/main_app_shell.dart:212-214` opens Notes with `openedFromProfile: true`.
- `lib/features/notes/notes_open_book_screen.dart:374` hides the add button when `openedFromProfile || readOnly` is true.
- `lib/features/profile/profile_screen.dart:1381-1385` also opens Notes with `openedFromProfile: true` and `readOnly: true`.

**Impact:** The only rendered add-note control is hidden in current navigation, and its callback is empty. Users cannot add a note from this screen even if the button is later exposed.

**Recommended action:** Wire the button to the send-note flow, or remove the dead control. Decide whether note creation belongs in Notes or only in the profile action.

#### HIGHLIGHTS-02 — Generic reaction failure leaves a stuck spinner

**Evidence:** `lib/features/dashboard/daily_highlights_book_screen.dart:64-72` catches generic errors but does not remove the highlight ID from `_reactingIds`. The `ApiException` branch at lines 58-63 does remove it.

**Impact:** A non-API exception leaves the reaction control permanently disabled/spinning for that highlight.

**Recommended action:** Remove the ID in a `finally` block, as the Notes screen does.

#### HIGHLIGHTS-03 — Image decode failure can hang the highlight picker

**Evidence:**
- `lib/features/dashboard/add_highlight_sheet.dart:123-137` resolves `FileImage` into a `Completer<ui.Size>` and only attaches a success listener.
- No error listener completes the future if decoding fails.
- `setState` follows the await at line 138 without a mounted check.
- `_startCaptionEdit` schedules a delayed focus without a mounted check.

**Impact:** A corrupt or unsupported image can leave the picker stuck indefinitely. A fast dismissal can also trigger `setState` after disposal.

**Recommended action:** Add an `onError` listener that completes with an error, handle it in the UI, and guard post-await state updates with `mounted`.

#### NOTES-02 — Notes actions update state after disposal and expose raw errors

**Evidence:**
- `lib/features/notes/notes_open_book_screen.dart:188-193` calls `setState` after `await _api.addReaction(...)` without a mounted check.
- `lib/features/notes/notes_open_book_screen.dart:265-268` calls `setState` after `await _api.deleteNote(...)` without a mounted check.
- `lib/features/notes/notes_open_book_screen.dart:202` and `:282` interpolate raw exception text into snackbars.

**Impact:** Navigating away during a request can produce “setState called after dispose” errors. Raw exception text can expose implementation details and is not user-friendly.

**Recommended action:** Guard post-await state updates with `mounted` and map errors to safe user-facing messages.

### P3

#### DATA-01 — Event images do not resolve relative URLs

**Evidence:** `lib/features/dashboard/widgets/event_card.dart:117` passes `event.photoUrl!` directly to `NetworkImage`. `lib/features/dashboard/widgets/announcement_card.dart:61-68` resolves relative announcement URLs against `ApiConstants.baseUrl`.

**Impact:** If the backend returns relative event image paths, event images fail while announcements work. This is inconsistent and depends on the API contract.

**Recommended action:** Resolve event URLs with the same helper used by announcements, or normalize them in the `Event` model.

#### DATA-02 — Memoryboard accepts only a raw list response

**Evidence:** `lib/features/memoryboard/memoryboard_screen.dart:105-113` parses only `data is List`; any map/paginated response returns an empty list.

**Impact:** If the memoryboard endpoint returns `{items: [...]}` or another envelope, the board appears empty. The backend contract was not available to confirm this.

**Recommended action:** Confirm the response shape and support the known envelope keys, as the profile gallery loader already does.

#### LEADERBOARD-01 — Leaderboard is capped at 100 users with no pagination

**Evidence:** `lib/features/leaderboard/leaderboard_screen.dart:56` requests `pageNumber: 1, pageSize: 100` and does not load further pages.

**Impact:** Rankings can silently truncate once the cohort exceeds 100 seniors.

**Recommended action:** Add pagination or explicitly document/enforce the cohort-size assumption.

#### PROFILE-03 — Own-profile note check can fail when the current user cache is empty

**Evidence:** `lib/features/profile/profile_screen.dart:1360-1365` returns `false` early for non-read-only profiles and compares `_currentUserId` with `widget.userId`. `_currentUserId` is populated from `CurrentUserCache.peek()` in visited-profile loading, but can remain empty.

**Impact:** If the current user ID is unavailable, the “send note to self” guard may not trigger.

**Recommended action:** Fetch or require the current user ID before enabling note actions, and treat unknown identity as not allowed.

#### PROFILE-04 — Read-only profile assumes a non-null user ID

**Evidence:** `lib/features/profile/profile_screen.dart:144` uses `widget.userId!` in `_loadVisitedProfile`.

**Impact:** Constructing `ProfileScreen(readOnly: true)` without a user ID throws instead of showing a validation/error state. Current callers pass an ID, so this is an edge case.

**Recommended action:** Validate `userId` in the constructor or handle null safely.

#### SESSION-02 — Login-navigation flag can remain stuck

**Evidence:** `lib/core/auth/session_manager.dart:78-84` sets `_loginScreenVisible = true` before `pushNamedAndRemoveUntil` and only resets it on successful login.

**Impact:** If navigation throws, future unauthorized handling may skip the login redirect. The route is currently registered, so this is unlikely but still a fragile failure path.

**Recommended action:** Reset the flag in the catch block or derive visibility from the active route.

#### TOKEN-01 — Transient secure-storage read failure is treated as “no token”

**Evidence:** `lib/core/storage/token_storage.dart:113-117` catches persistent-read failures, marks the cache initialized, and returns `null`.

**Impact:** A temporary secure-storage failure can log the user out for the session instead of retrying.

**Recommended action:** Distinguish “no token” from “read failed” and allow a retry or recovery path.

#### ADD-MEMORY-01 — Add-memory flow is gallery-only and exposes raw errors

**Evidence:**
- `lib/shared/widgets/add_memory_sheet.dart:59` always submits `description` as `null`.
- Only `ImageSource.gallery` is offered at line 119.
- `setState` follows the picker await at lines 40-45 without a mounted check.
- Raw `$e` appears in error messages at lines 74 and 77.

**Impact:** Users cannot add a caption or use the camera, and error messages may expose internal details.

**Recommended action:** Add optional description input and camera support if intended, guard post-await state updates, and use safe error messages.

#### RETRO-01 — Disabled buttons lack a clear disabled visual

**Evidence:** `lib/shared/widgets/retro_button.dart:30-72` disables taps when `onPressed` is null, but does not change color, opacity, or shadow styling.

**Impact:** Users can mistake a disabled action for an active one.

**Recommended action:** Add a disabled color/opacity treatment and remove hover/press affordances when disabled.

#### DEAD-01 — Orphaned senior details screen and unused note callback

**Evidence:**
- `lib/features/seniors_directory/senior_details_screen.dart` has no production references beyond its definition.
- `lib/features/seniors_directory/widgets/senior_card.dart:60` passes `onOpenNotes: () {}`.
- `lib/features/dashboard/dashboard_screen.dart:29` and `:37` declare `onOpenNotes`, but it is not used in the dashboard body.

**Impact:** Dead navigation/callback code increases maintenance cost and makes the intended senior-card behavior unclear.

**Recommended action:** Remove the orphaned screen and unused callback, or wire them into the intended flow.

#### HIGHLIGHTS-04 — Initial highlight index is not clamped

**Status: Resolved in Batch 1 (2026-11-06).** `_currentIndex` is now clamped for empty and out-of-range inputs.

**Evidence:** `lib/features/dashboard/daily_highlights_book_screen.dart:37` initializes `_currentIndex` from `widget.initialIndex` without clamping to the available list. The dashboard currently passes a valid index.

**Impact:** Direct or future reuse with an out-of-range index can crash on first build.

**Recommended action:** Clamp `initialIndex` to `0..length-1` during initialization.

#### CAPTION-01 — Viewer ignores `captionYPercent` (local change observation)

**Evidence:**
- `lib/features/dashboard/daily_highlights_book_screen.dart:444-491` always places the caption at `bottom: 8`.
- `lib/features/dashboard/add_highlight_sheet.dart` still previews and uploads `captionYPercent`.
- The working tree already contains a local change that removed the previous positioned-caption implementation.

**Impact:** Caption position selected during upload is not reflected in the viewer. This appears to be an intentional local change rather than an audit-discovered regression, but it should be reviewed before release.

**Recommended action:** Confirm whether bottom-only captions are intended; if not, restore position-aware rendering.

#### PLATFORM-01 — Desktop/web runtime support is inconsistent with mobile-only plugins

**Evidence:**
- `pubspec.yaml:43-44` includes `webview_flutter` and `webview_flutter_android`; no Windows/web WebView implementation is present.
- `lib/features/profile/widgets/spotify_preview.dart` uses `WebViewController`.
- Image upload flows use `dart:io` `File` and `Image.file`.

**Impact:** Spotify previews and file-based image previews may fail at runtime on Windows/web even though those targets compile. This is not a blocker if the release target is Android/iOS only.

**Recommended action:** Confirm supported platforms. If desktop/web are release targets, add platform implementations or hide unsupported features there.

## Repair Plan

### Phase 1 — Release blockers

1. Confirm and fix the auth onboarding contract (`AUTH-01`). **Still open.**
2. Guard the empty-highlight deletion path and add a one-item deletion regression test (`HIGHLIGHTS-01`). **Done in Batch 1.**
3. Re-run the full test suite and resolve the `OPEN BOOK` finder failure at `test/widget_test.dart:306`. **Done in Batch 1; suite is green.**

### Phase 2 — Session and data consistency

1. Make token clearing failure-safe (`SESSION-01`). **Done in Batch 1.**
2. Force-refresh profile data after social-link and favorite-song saves (`PROFILE-01`). **Done in Batch 1.**
3. Add profile-level error/retry states (`PROFILE-02`).
4. Normalize relative media URLs consistently (`DATA-01`).
5. Confirm the memoryboard response contract (`DATA-02`).

### Phase 3 — UX and dead code

1. Implement or remove `ADD NOTE` (`NOTES-01`).
2. Add OTP resend (`AUTH-02`).
3. Add disabled styling to `RetroButton` (`RETRO-01`).
4. Remove or wire the orphaned senior details screen and unused callback (`DEAD-01`).
5. Add leaderboard pagination or document the 100-user limit (`LEADERBOARD-01`).

### Phase 4 — Hardening and coverage

1. Add mounted guards and safe error messages in Notes, highlights, and add-memory flows.
2. Add image-decode error handling.
3. Add regression tests for session cleanup, profile refresh, last-highlight deletion, and notes actions.
4. Raise coverage above the current 44.79%, prioritizing core API/session/model and primary UI flows.

## Readiness Verdict

**Not release-ready.** The application compiles for Windows, web, and Android, the test suite is now green, and an Android launch/login smoke pass succeeded. However, `AUTH-01` remains an unresolved P1 contract issue, coverage is still modest, and Windows/web runtime smoke testing remains incomplete. The project should not be considered ready for release until the auth contract is resolved and a fuller real-device/emulator pass is completed.

## Blocked Verification

- **Windows runtime:** Launching `build\windows\x64\runner\Debug\seniors_27.exe` remains blocked by Windows Application Control policy.
- **Android runtime:** The full APK still cannot install on the `Pixel_7a` emulator due to `INSTALL_FAILED_INSUFFICIENT_STORAGE`. Batch 1 worked around this by building and installing `app-x86_64-debug.apk`; the app launched to the login screen and navigated to the email step. The emulator raised a one-time "System UI isn't responding" dialog, which was dismissed; no app fatal log appeared. Full authenticated flows were not exercised.
- **Web runtime:** Chrome is not installed. A web build was produced, but no browser runtime smoke test was completed.
- **Backend contract:** Findings that depend on server response shape, especially memoryboard envelopes and relative media URLs, are marked as conditional until confirmed against the real API.

## Notes

- The original audit made no production changes. Batch 1 subsequently applied the scoped fixes listed above.
- Batch 1 formatted all changed Dart files. The full `dart format --output=none --set-exit-if-changed lib test` check still reports the pre-existing `lib/features/dashboard/models/daily_highlight.dart`; it was not written.
- The three pre-existing working-tree modifications remain present and were preserved.
- AUTH-01 was intentionally not changed because no backend contract or product decision was available to justify restoring or removing the username/gender steps.
