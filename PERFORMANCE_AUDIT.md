# Performance Audit — Seniors 2027

Date: 2026-11-14
Repo: `D:\fluuter_projects\Seniors_27`
Branch: `sallam`
Scope: Flutter client performance, network usage, asset and bundle efficiency, and what can be verified without backend source or production access.
Constraint: The audit phase was read-only. A first approved client-side batch was then implemented: dashboard requests were parallelized, notes was switched to `CurrentUserCache`, quality-degrading memoryboard decode limits were removed, and runtime asset declarations were narrowed. No backend, dependency, auth, native-file, layout, or visual-design changes were made.

## Environment

- Flutter 3.44.8, Dart 3.12.2, DevTools 2.57.0
- Backend: `https://sneiors2027.runasp.net` (`lib/core/api/api_constants.dart:4`)
- Connected targets: Windows desktop and Edge web. Android device present but unauthorized. No iOS/macOS target.
- Backend source, database, hosting dashboard, CDN configuration, and production telemetry were not available.

## Commands Run

| Command | Result |
|---|---|
| `flutter analyze` | 0 errors, 0 warnings, 4 pre-existing info-level diagnostics (`api_client.dart:239`, `events_empty_state.dart:13,55`, `senior_details_screen.dart:248`) |
| `flutter test --coverage` | 76 tests passed |
| LCOV parse (`coverage/lcov.info`) | 2,375 / 4,938 lines, 48.10% coverage, 72 records |
| `curl -I https://sneiors2027.runasp.net/` | HTTP 404, `X-Powered-By: ASP.NET`, no cache/CDN/encoding headers |
| `curl -I .../api/portal-content/announcements` | HTTP 405, no cache/CDN/encoding headers |
| `curl .../api/portal-content/announcements` (GET, unauthenticated) | HTTP 401, 201 bytes, TTFB 0.563 s, IP 178.63.129.209, no `Content-Encoding`/`Cache-Control`/`ETag` |
| Release build before batch | `main.dart.js` 3,680,585 B; `build/web/assets` 3,924,918 B / 23 files; total 46,145,862 B / 54 files |
| Release build after batch | `main.dart.js` 3,678,780 B; `build/web/assets` 2,759,998 B / 21 files; total 44,979,137 B / 52 files |
| Release delta | Total −1,166,725 B (−2.53%); assets −1,164,920 B (−29.68%); JS −1,805 B (−0.05%) |

Both size measurements are `flutter build web --release` outputs. The prior debug `build/web` output was not used as release-size evidence.

## Executive Summary

Batch 1 resolved four confirmed client issues:

1. Dashboard now starts its three independent section requests concurrently with `Future.wait` and keeps independent loading/error states (`dashboard_screen.dart:115-122`).
2. Notes now reuses `CurrentUserCache` instead of calling `/api/Auth/me` again (`notes_open_book_screen.dart:67`).
3. The memoryboard quality regression was removed: grid and full-screen images once again use the original `NetworkImage` URL with no undersized `cacheWidth`/`cacheHeight` (`memoryboard_screen.dart:463,651`).
4. Tooling-only launcher/splash source images are no longer runtime assets. The release web asset directory dropped from 3,924,918 B / 23 files to 2,759,998 B / 21 files; total release output dropped by 1,166,725 B (−2.53%).

Remaining confirmed issues are:

1. Notes still loads every page sequentially before first render, then builds every note card at once (`notes_open_book_screen.dart:80-151,530-555`).
2. Leaderboard always fetches 100 users and eagerly builds 100 rows and avatars (`leaderboard_screen.dart:56,241-242,291`).
3. Network images have no server-side resized/WebP/AVIF variants. Removing the quality-degrading decode limits restores sharpness but can increase decoded-image memory until a server-side thumbnail strategy exists.
4. Server responses observed from the audit machine showed no `Content-Encoding`, `Cache-Control`, `ETag`, `Vary`, CDN, or load-balancer headers. Large authenticated payload behavior remains unverified.

No catastrophic performance defect was found. The remaining issues are concentrated in eager list rendering, server image variants, payload over-fetching, and missing observability.

## Checklist Verdict

Status values: `Verified`, `Issue found`, `Resolved in batch 1`, `Partially resolved`, `Blocked or unverified`, `Not applicable`.

| # | Checklist item | Status | Owner | Evidence | Impact |
|---|---|---|---|---|---|
| 1 | Skeleton loading | Issue found | Client | Loading states are text, spinners, or blank placeholders: `dashboard_screen.dart:354-377,642-656`; `leaderboard_screen.dart:125-139`; `seniors_directory_screen.dart:206-220`; `profile_gallery_card.dart:93-106`. No skeleton/shimmer widgets. | Perceived slowness and layout movement when content replaces placeholders. |
| 2 | WebP/AVIF | Partially resolved | Client + Backend | Memoryboard now uses original full-resolution images without decode limits (`memoryboard_screen.dart:463,651`), so the prior undersized-grid regression is fixed. Other network images still use raw `Image.network`/`NetworkImage` URLs with no width/height/format negotiation (e.g., `leaderboard_screen.dart:291`, `profile_screen.dart:707,1657`, `note_card.dart:172`, `senior_card.dart:27`). Tooling-only `app_icon_foreground.png` and `native_splash_logo.png` are excluded from the runtime bundle; `polaroid_frame.png` (751,012 B) and `app_logo_backup.png` (71,937 B) remain bundled. | Restored image sharpness. Large transfers and decoded-image memory remain until server-side variants or correctly sized thumbnails exist; remote WebP/AVIF availability cannot be verified. |
| 3 | Duplicate API calls | Resolved in batch 1 | Client | GET dedupe exists (`api_client.dart:161-174`), tabs are lazy (`main_app_shell.dart:111-118`), and notes now resolves the current user through `CurrentUserCache` (`notes_open_book_screen.dart:67`), with `/me` only used on a cache miss. Dashboard now loads its three sections concurrently without duplicating requests. | Profile → notes no longer repeats `/me` while the 60 s cache is fresh; logout invalidation is preserved. |
| 4 | Debounce | Verified | Client | Directory search uses a 600 ms timer, cancels on dispose, and guards stale responses with a request id (`seniors_directory_screen.dart:46,71,92,101,153-161`). Mention search also debounces. | Search typing does not flood the API. |
| 5 | Pagination | Issue found | Client + Backend | Directory uses 9/page but only parses pagination metadata when the response is a `Map` (`seniors_directory_screen.dart:146-151`). Memoryboard downloads all photos and paginates/filter client-side (`memoryboard_api_service.dart:12-14`, `memoryboard_screen.dart:34,73-78`). Leaderboard requests 100 once (`leaderboard_screen.dart:56`). Notes sequentially loads every page up to 100 (`notes_open_book_screen.dart:80-151`). Gallery has no paging params (`profile_gallery_api_service.dart:11-12`). | List responses may silently stay on page 1; large albums/notes load everything. |
| 6 | CDN | Blocked or unverified | Infrastructure + Backend | No CDN configuration in repo. Observed responses have no CDN headers; single A record 178.63.129.209. Media URLs point directly to the API host. | Cannot confirm edge caching or media delivery performance. |
| 7 | Background job queues | Blocked or unverified | Backend + Infrastructure | No backend source. Client awaits uploads before continuing (`add_memory_sheet.dart`, highlight upload, note send). | Server-side queueing and retry behavior cannot be verified. |
| 8 | N+1 | Blocked or unverified | Backend | No ORM, query logs, or backend source available. Client does not issue per-item follow-up requests. | Cannot verify query count per screen. |
| 9 | Brotli/Gzip | Issue found | Backend + Infrastructure | Requests advertised `Accept-Encoding: gzip, br`; observed 401/404/405 responses had no `Content-Encoding` or `Vary`. Large authenticated payloads are unverified. | Static/error responses are uncompressed; large JSON/media compression remains unknown. |
| 10 | Redis | Blocked or unverified | Backend + Infrastructure | No backend source or infrastructure access. | Cache-hit behavior and hot-key performance cannot be verified. |
| 11 | Unused dependencies | Partially resolved | Client | `pubspec.yaml` now declares explicit runtime assets instead of whole directories; launcher/splash source images are excluded from the runtime bundle (`pubspec.yaml:71-80`), while remaining available to generators (`:89,92,99`). `cupertino_icons` still has no direct `lib` import but its 257.6 KB font remains bundled. `polaroid_frame.png` is still referenced only by an unused constant (`app_assets.dart:10`); `app_logo_backup.png` is unused; logos remain duplicated three times. | Runtime assets fell by 1,164,920 B, mostly from excluding two tooling-only PNGs. Remaining cleanup can reduce roughly another 1 MB. |
| 12 | API timeouts | Issue found | Client | Timeouts are set: connect 10 s, receive 16 s, send 30 s, upload 60 s (`api_client.dart:29-31,242`). No `CancelToken` usage found. No retry for idempotent GETs; mutations correctly avoid blind retries. | No cancellation on navigation; transient GET failures require manual retry. |
| 13 | AI streaming | Not applicable | N/A | No AI feature, dependency, endpoint, or streaming code found in `lib/`. | No streaming path exists. |
| 14 | Optimistic UI | Verified | Client | Note posting pops only after server success (`send_note_screen.dart:44-53`); reactions and votes wait for server results before updating. Errors are surfaced; no false-success path found. | Safe, but slower perceived response. Optional future improvement. |
| 15 | Lazy loading | Issue found | Client | Positive: tabs are lazily created (`main_app_shell.dart:111-118`); Spotify WebView activates only on tap (`spotify_preview.dart:44-49`). Negative: leaderboard builds all 100 rows/images, notes builds all cards, dashboard/profile sections build eagerly. | Up-front work on non-visible rows and slower first paint. |
| 16 | Parallel requests | Resolved in batch 1 | Client | Dashboard starts announcements, events, and highlights together via `Future.wait` (`dashboard_screen.dart:115-122`). Each helper retains its own error handling and request-generation guard. Profile already fired gallery and notes without awaiting (`profile_screen.dart:128-129`). | Dashboard no longer pays the sum of three round trips; widget coverage asserts all three start before any completes. |
| 17 | Database indexes | Blocked or unverified | Backend + Database | No schema, query plans, migration files, or database access. | Cannot verify search/leaderboard/pagination query cost. |
| 18 | OpenTelemetry | Issue found | Client + Backend | No OpenTelemetry, tracing, RUM, or crash-reporting packages. Only `debugPrint` logs gated by `kDebugMode` (`app_log.dart:3-5`). | No production visibility into slow requests, jank, or errors. |
| 19 | Proximity | Blocked or unverified | Infrastructure | Single A record 178.63.129.209; unauthenticated GET TTFB 0.563 s from the audit machine. Database/hosting region unknown. | Cannot determine whether API, media, and database are co-located with users. |
| 20 | SSR/static generation | Not applicable | N/A | Flutter client app with default web bootstrap; no server-rendered routes or SEO surface in repo. | SSR is not an appropriate fix unless a separate public web/SEO target is required. |
| 21 | Third-party scripts | Verified | Client | `web/index.html` loads only Flutter bootstrap; no analytics or third-party scripts. Spotify WebView is user-activated. | No third-party script main-thread cost. |
| 22 | Code splitting | Verified | Client | No deferred imports found. The release web build emits one `main.dart.js` of 3,678,780 B; batch 1 did not change that. Mobile is the primary target. | Low priority unless web startup becomes a target metric. |
| 23 | Virtualization | Issue found | Client | Leaderboard uses `SingleChildScrollView` + `Column` + a `for` loop (`leaderboard_screen.dart:106-117,241-242`). Notes uses the same pattern for every note (`notes_open_book_screen.dart:331-334,530-555`). Directory and memoryboard nest `GridView.builder(shrinkWrap: true, physics: NeverScrollableScrollPhysics())` inside `SingleChildScrollView` (`seniors_directory_screen.dart:332-345`; `memoryboard_screen.dart:372-396`). | All items build and stay mounted; 100 leaderboard rows and all notes are expensive. |
| 24 | Required columns | Issue found | Backend + Client | Announcements embed every poll voter (`poll_option.dart:37-43`) for up to six announcements (`dashboard_api_service.dart`), although counts drive most of the UI. Leaderboard fetches full user rows for 100 users (`leaderboard_screen.dart:56`; `senior_student.dart:22-34`). `/api/Auth/me` returns the full profile. No field projection exists. | Oversized JSON, slower parsing, and higher memory use. |
| 25 | Connection pooling | Blocked or unverified | Client + Backend | Dio's default adapter is used with no explicit pool settings. Backend/server pooling configuration is unavailable. | Cannot verify connection reuse under load. |
| 26 | Re-renders | Issue found | Client | Dashboard calls `setState` separately as each section resolves (`dashboard_screen.dart:144,161,178`). Notes reaction toggles rebuild the whole notes list and every card. Profile uses whole-screen state. No measured DevTools frame trace was captured. | Likely unnecessary rebuilds on large lists; actual jank is unmeasured. |
| 27 | Browser caching | Issue found | Client + Infrastructure | Flutter 3.44 service worker unregisters itself in the local build; no cache policy in `web/index.html`; observed API responses had no cache headers. Release static-asset headers unknown. | Repeat web visits may re-download assets; authenticated API caching is not defined. |
| 28 | Load balancing | Blocked or unverified | Infrastructure | Deployment topology unknown; one A record observed. | Cannot confirm redundancy or horizontal scaling. |
| 29 | Fonts | Issue found | Client | No custom font declaration. Bundled fonts include MaterialIcons 1.6 MB, Font Awesome Solid 414.7 KB, Brands 215.1 KB, Regular 87.3 KB, and CupertinoIcons 257.6 KB (unused). App uses only a handful of Font Awesome brand icons. `monospace` uses platform fallback. | Bundle weight and inconsistent emoji/monospace rendering across platforms. |
| 30 | RUM | Issue found | Client + Infrastructure | No Sentry, Firebase Crashlytics, analytics, or real-user monitoring dependency. Only debug-gated logs (`app_log.dart:3-5`). | No production measurement or alerting for performance regressions. |
| 31 | Performance testing | Issue found | Client + QA | 76 functional tests pass and line coverage is 48.10%, including new concurrency, cache-reuse, and image-provider regression tests. No performance benchmarks, integration tests, or profile-mode measurements were found or run. | Startup, jank, and memory regressions are not automatically detected. |

## Implemented Batch 1

Scope was limited to client-side changes that do not reduce image quality, alter layouts/styles/auth/navigation/animations, or require backend contract changes.

| Area | Change | Verification |
|---|---|---|
| Dashboard latency | Announcements, events, and highlights now start concurrently; independent error states and stale-response guards remain. | `test/dashboard_parallel_load_test.dart`, `test/dashboard_stale_vote_test.dart` |
| Duplicate current-user fetch | Notes uses `CurrentUserCache`; `/me` runs only on a miss or expired/forced refresh. | `test/notes_current_user_cache_test.dart`, `test/profile_refresh_test.dart` |
| Memoryboard image quality | Removed grid and preview `cacheWidth`/`cacheHeight`; grid and full-screen use the original URL. | `test/memoryboard_image_quality_test.dart` |
| Runtime assets | Explicit runtime asset list; tooling-only launcher/splash images excluded from the bundle but retained on disk. | Release build measurement |
| Release size | Total 46,145,862 B → 44,979,137 B (−1,166,725 B, −2.53%); assets 3,924,918 B → 2,759,998 B (−1,164,920 B, −29.68%). | Pre/post `flutter build web --release` |

Changed source files:

- `lib/features/dashboard/dashboard_screen.dart`
- `lib/features/notes/notes_open_book_screen.dart`
- `lib/features/memoryboard/memoryboard_screen.dart`
- `pubspec.yaml`
- `test/dashboard_parallel_load_test.dart` (new)
- `test/notes_current_user_cache_test.dart` (new)
- `test/memoryboard_image_quality_test.dart` (new)

Known issue observed while adding tests: `Memory.fromJson` casts `json['id']` with `(json['id'] as num?)`, so a string id from the API would throw. This is unrelated to batch 1 and was not changed; the image-quality test uses a numeric id.

## Detailed Findings

### P1 — High impact

#### 1. Dashboard serializes three independent requests — resolved in batch 1

Original diagnosis: `dashboard_screen.dart:115` awaited announcements, then `:139` awaited events, then `:153` awaited highlights. At the observed 0.563 s unauthenticated TTFB, three sequential calls created roughly a 1.7 s lower bound before parsing.

Implementation: `_loadData` now starts `_loadAnnouncementsSection`, `_loadEventsSection`, and `_loadHighlightsSection` together via `Future.wait` (`dashboard_screen.dart:115-122`). Each helper keeps its own state and error handling, the announcement version guard is preserved, and stale request generations are ignored. The in-flight flag is cleared in `finally`.

Verification: `test/dashboard_parallel_load_test.dart` asserts all three calls start before any completes, successful sections render independently, an events failure does not hide announcements/highlights, and disposal completes without exceptions. `test/dashboard_stale_vote_test.dart` still passes.

Residual: section completions still call `setState` separately, so the dashboard may rebuild up to three times on a fast network. That is a lower-priority re-render concern, not a latency issue.

#### 2. Notes loads every page sequentially and renders every card

`notes_open_book_screen.dart:80-151` requests page 1..N at 20 notes/page, sequentially, with a 100-page safety cap. Rendering starts only after the loop completes (`:155-159`), and all notes are built in a non-virtualized `Column` (`:530-555`).

Consequences:
- N sequential round trips before first render.
- First-paint delay grows linearly with note count.
- Parsing, sorting, and retaining every page in memory.
- All cards and avatars remain mounted.

Recommended fix: render a virtualized `ListView.builder`/`CustomScrollView`, load page 1 first, and append subsequent pages on scroll or via explicit load-more. If the API supports a single larger page or cursor, use it.

#### 3. Leaderboard eagerly fetches and renders 100 users

`leaderboard_screen.dart:56` always requests `pageSize: 100`. The list is sorted client-side, and `:241-242` builds every row inside a `SingleChildScrollView`. `:291` loads every avatar eagerly.

Consequences:
- Large JSON and 100 round-trip image requests.
- Up to 100 decoded avatars resident; Flutter's image cache may evict and re-decode.
- No pagination for classes larger than 100.

Recommended fix: paginate or virtualize with `ListView.builder`, and add a server-side leaderboard endpoint or at least a smaller page size with load-more.

#### 4. Non-virtualized nested grids

`seniors_directory_screen.dart:332-345` and `memoryboard_screen.dart:372-396` use `GridView.builder` with `shrinkWrap: true` and `NeverScrollableScrollPhysics` inside a `SingleChildScrollView`. This forces the grid to lay out all children and disables lazy viewport culling.

The current directory page size is only 9, so the immediate cost is small, but the pattern will not scale. Memoryboard additionally downloads all photos before applying client-side approval filters and 12-item paging (`memoryboard_api_service.dart:12-14`, `memoryboard_screen.dart:34,73-78`).

Recommended fix: move to a single scrollable (`CustomScrollView`/slivers) or a bounded grid with its own scroll view. Move memoryboard filtering and paging to the API.

#### 5. Image pipeline and bundle weight — partially resolved in batch 1

Quality regression fixed: commit `4f08afc` had added square `cacheWidth`/`cacheHeight` decode limits to the memoryboard. The grid used `90 * dpr` clamped to 90–360 for roughly 115 dp-wide 3-column cards, which is undersized at common device pixel ratios. The full-screen preview used `500 * dpr` / `420 * dpr` decode limits and therefore was not actually full resolution. Both limits were removed; grid and full-screen now use the original `NetworkImage` URL (`memoryboard_screen.dart:463,651`). No upload compression or other image-quality reduction was found.

Bundle fixes: `pubspec.yaml` now lists individual runtime assets instead of whole directories. `app_icon_foreground.png` (754,626 B) and `native_splash_logo.png` (409,882 B) remain on disk for launcher/splash generators but are excluded from the runtime bundle. The release web asset directory dropped from 3,924,918 B / 23 files to 2,759,998 B / 21 files.

Remaining bundled image files:

| File | Size | Runtime usage |
|---|---:|---|
| `assets/images/polaroid_frame.png` | 751,012 B | Unused; constant only |
| `assets/images/senior_card_sticker.svg` | 109,000 B | Used |
| `assets/icons/trophy_winner.svg` | 88,549 B | Used |
| `assets/images/app_logo_backup.png` | 71,937 B | Unused |
| `assets/images/app_logo.png` | 71,937 B | Used by tooling |
| `assets/icons/app_logo.png` | 71,937 B | Used |
| `assets/icons/ic_rank_3.svg` | 19,584 B | Used |
| `assets/icons/ic_rank_2.svg` | 17,443 B | Used |
| `assets/images/06_memoryboard_board_texture.png` | 15,548 B | Used |
| `assets/icons/ic_rank_1.svg` | 14,888 B | Used |

Remaining recommendations:
- Remove `polaroid_frame.png` or use it; remove `app_logo_backup.png`; deduplicate the logo copies.
- For avatars and list thumbnails, request server-side resized variants or set decode sizes that are not below the rendered size. Do not reintroduce the prior undersized memoryboard limits.
- Request WebP/AVIF variants where the backend/CDN supports them.
- Measure release builds only; the post-batch release total is 44,979,137 B / 52 files.

#### 6. Payload over-fetching

`poll_option.dart:37-43` parses the complete voter list for every poll option in every announcement. Six announcements with popular polls can return thousands of voter objects even though the UI mainly needs counts until a voter list is opened.

Leaderboard and directory use full user rows. `/api/Auth/me` returns the full profile. No field selection or summary endpoints are used.

Recommended fix: add summary/detail contracts. Return counts in list responses and fetch voters only on demand. Return only leaderboard/directory fields for list screens.

#### 7. Server compression, CDN, and cache headers are absent or unverified

The audit machine sent `Accept-Encoding: gzip, br`. Observed responses returned no `Content-Encoding`, `Cache-Control`, `ETag`, `Vary`, CDN, or proxy headers. The API is behind ASP.NET and resolves to one IP.

This does not prove large authenticated JSON is uncompressed, but it does show that small/error responses are not compressed and that caching policy is not exposed.

Recommended fix (backend/infrastructure): enable Brotli/gzip for JSON and SVG, set immutable cache headers for media and static assets, put media behind a CDN, and verify with response headers for a real authenticated payload.

### P2 — Moderate impact

#### 8. No skeletons and uneven loading transitions

All major screens use text/spinner loading states. Content-heavy sections replace small placeholders with differently sized cards, causing visual movement. Add lightweight skeletons matching final card dimensions for dashboard sections, directory, leaderboard, notes, and profile.

#### 9. Duplicate `/api/Auth/me` work — resolved in batch 1

Original diagnosis: `notes_open_book_screen.dart` bypassed `CurrentUserCache`, so opening notes after profile could fetch `/me` again.

Implementation: notes now calls `CurrentUserCache.get(...)` with the same `/me` fetcher and `ProfileUser.fromJson` parser used elsewhere (`notes_open_book_screen.dart:67`). The existing 60 s freshness, in-flight dedupe, logout/unauthorized invalidation, and non-caching of failed fetches are unchanged. An optional `apiService` constructor parameter supports testing without changing production call sites.

Verification: `test/notes_current_user_cache_test.dart` confirms a fresh cache hit performs no `/me` call, a cache miss fetches once and reuses the result, and invalidation forces exactly one refetch. `test/profile_refresh_test.dart` and `test/current_user_cache_test.dart` still pass.

#### 10. No request cancellation

No `CancelToken` usage exists. Leaving a screen does not cancel its requests; `mounted` and request-id checks only suppress late UI updates. Add cancellation for list/detail requests and retain the current no-blind-retry behavior for mutations. A bounded retry for idempotent GETs is optional.

#### 11. Re-render scope is broad

Dashboard rebuilds as each section resolves. Notes reaction toggles rebuild the whole screen and every card. Profile uses whole-screen state. This is a code-level risk; no DevTools frame timing was captured.

Recommended fix: isolate sections with `ValueNotifier`/`ValueListenableBuilder`, split list items into independent widgets, and pass per-item state rather than rebuilding the parent list.

#### 12. Missing production observability

There is no RUM, crash reporting, tracing, or request correlation. Only debug logs exist. Add client error/performance monitoring and server request IDs exposed in responses. Prefer OpenTelemetry-compatible instrumentation if infrastructure supports it.

#### 13. Directory pagination metadata fragility

`_parsePaginationMeta` only updates state for `Map` responses (`seniors_directory_screen.dart:146-151`). A bare list response leaves `_totalPages` at 1 and hides pagination controls even if more data exists.

Recommended fix: treat a full page (`items.length == pageSize`) as evidence of a possible next page when metadata is absent, or normalize the API contract.

#### 14. Memoryboard loads all photos before filtering

`getPhotos()` has no pagination/filter parameters (`memoryboard_api_service.dart:12-14`). The client filters and pages the full list. Move approval filtering and paging to the API, and keep only the visible page in memory.

#### 15. Gallery has no paging

`ProfileGalleryApiService.getUserGallery` takes only a user id (`profile_gallery_api_service.dart:11-12`). Large galleries download all metadata and full images. Add page/limit and thumbnail variants.

### P3 — Low impact / follow-up

#### 16. Font weight can be reduced

Bundled fonts include MaterialIcons 1.6 MB, Font Awesome Solid/Brands/Regular totaling about 717 KB, and CupertinoIcons 258 KB. The app uses few Font Awesome icons. Consider Material icons/SVGs or a subset, and remove the unused direct `cupertino_icons` dependency if not required by a platform package.

No custom web fonts are downloaded, so there is no network-font FOUT risk.

#### 17. Dependency and asset cleanup

- Launcher/splash source images are no longer bundled, but remain on disk for generators.
- Remove `cupertino_icons` if no direct/indirect platform requirement remains; confirm with a build-size comparison.
- Remove duplicate logos and unused `app_logo_backup.png` / `polaroid_frame.png`.
- Keep `flutter_launcher_icons` and `flutter_native_splash` as dev dependencies.

#### 18. Browser caching and web release output

The local service worker unregisters itself (Flutter 3.44 behavior), and observed responses had no cache headers. A release web build is now available, but hosting headers were not available to verify hashed asset caching, `Cache-Control`, compression, or service-worker policy. Treat this as blocked for production until hosting headers are available.

#### 19. Code splitting

No deferred imports or route-level splitting exists. This is acceptable for a mobile-first Flutter app. Revisit only if web startup becomes a tracked metric.

#### 20. Optimistic UI

No optimistic mutations exist, and none currently produce misleading success states. If reaction/vote latency becomes noticeable, add optimistic updates with rollback and reconciliation on failure.

## Blocked / Unverified Backend and Infrastructure Items

The following cannot be passed or failed from the Flutter repository:

- CDN configuration and edge cache hit rate
- Background job queue behavior for uploads/notifications
- Server-side N+1 query patterns and ORM behavior
- Redis usage and hit rate
- Database indexes and query plans
- Connection pooling and server limits
- Deployment regions and proximity to users/database
- Load balancing and horizontal scaling
- OpenTelemetry server traces
- RUM aggregation and real-device latency distributions
- Compression and cache headers for large authenticated responses
- Production media formats and resizing/transcoding support

Required access: backend source or query logs, database read-only access or `EXPLAIN` output, hosting/CDN dashboard, and an approved production-like environment with test credentials.

## Prioritized Repair Plan

Completed in batch 1:

1. Parallel dashboard section loads with independent error states.
2. Reuse `CurrentUserCache` from notes.
3. Remove quality-degrading memoryboard decode limits.
4. Narrow runtime asset declarations and exclude tooling-only source images.

Remaining, in priority order:

1. Replace leaderboard and notes eager rendering with virtualized lists; add pagination/load-more.
2. Stop loading all memoryboard/gallery metadata; move filtering and paging to the API.
3. Request server-side thumbnail/resized variants for avatars and list images, and WebP/AVIF where supported. Preserve enough resolution for the rendered size.
4. Reduce list payloads: poll summaries instead of full voter lists, leaderboard/directory field projections.
5. Add skeletons matching final layouts.
6. Add `CancelToken` to screen-scoped requests.
7. Scope rebuilds to sections/items and verify with DevTools profile mode.
8. Add client RUM/crash reporting and request correlation.
9. Backend/infrastructure: compression, media CDN, cache headers, index/query review, pooling, and tracing.
10. Remove remaining unused/duplicate bundled assets and evaluate the `cupertino_icons` dependency with a release-size comparison.

## Implemented Batch

Batch 1 was completed with the scope below:

1. Dashboard `Future.wait` refactor.
2. Notes `CurrentUserCache` reuse.
3. Removal of quality-degrading memoryboard `cacheWidth`/`cacheHeight`.
4. Runtime asset declarations narrowed; tooling-only source images excluded.
5. Targeted widget/unit tests for concurrency, cache reuse, and original image providers.

It did not require backend changes and did not change layouts, styles, auth flows, navigation, animations, dependencies, or native files. Virtualization, pagination, skeletons, and server-side image variants remain future work because they change list behavior or require backend support.

## Verification Plan

Completed for batch 1:

- `flutter analyze`: 0 errors, 0 warnings, 4 pre-existing info diagnostics.
- `flutter test --coverage`: 76 tests passed; 2,375 / 4,938 lines, 48.10%.
- Pre/post `flutter build web --release` size comparison.
- Tests assert concurrent dashboard starts, independent partial failures, cache reuse/invalidation, and original memoryboard image providers.

Still required:

- Add tests for list pagination/load-more and empty/error states.
- Profile on Windows desktop and Edge for startup and scroll frames; authorize an Android device for realistic mobile measurement.
- Verify visual image quality on an authenticated device with real memoryboard media.
- Measure startup, image decode cost, and jank with DevTools profile mode.
- Verify production cache headers, compression, and service-worker behavior.
- With backend access, record payload sizes, response compression, query counts, and p95 latency for dashboard, directory, leaderboard, notes, and profile.

## Artifacts Added

- `PERFORMANCE_AUDIT.md` (this report)
- `coverage/lcov.info` generated by `flutter test --coverage`
- `test/dashboard_parallel_load_test.dart`
- `test/notes_current_user_cache_test.dart`
- `test/memoryboard_image_quality_test.dart`

Batch 1 modified the dashboard, notes, memoryboard, and runtime asset declarations listed above. No backend, dependency, auth, native-file, layout, or visual-design changes were made.
