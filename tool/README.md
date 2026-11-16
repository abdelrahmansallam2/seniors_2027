# Memoryboard Preview

Work lives on `codex/memoryboard-motion-preview`. It is not merged into `sallam`
or `main`.

Build the isolated Android app from PowerShell:

```powershell
.\tool\build_memoryboard_preview.ps1
```

Output: `build/preview/seniors2027-memoryboard-preview.apk`.

- Launcher name: **Seniors 2027 Preview**.
- Application ID: `com.seniors2027.app.preview`.
- Separate app data and login; the existing app is not replaced or signed out.
- The build script verifies the application ID before publishing the preview APK.
- The backend is still the existing backend, not a sandbox. Uploading/deleting
  content in this preview affects real backend data.
- Normal builds, without the opt-in `--dart-define=SENIORS_PREVIEW=true`, keep the
  original application ID and launcher name.

The memoryboard supports horizontal page swipes as well as PREV./NEXT. Photos
keep their original image providers, fall in as their first decoded frame is
ready, and use stable scattered placements. Reduced-motion settings show ready
photos without the falling animation.

## Loading Performance

- Original photo files are cached on disk, without resizing or recompression.
  The board and full-screen preview share the same provider/cache key.
- The cache retains up to 36 recently used files with a seven-day stale period;
  server cache headers still govern freshness. The OS may clear temporary files.
- Only after the active board's images finish loading does the next board warm
  its original files. At most two background downloads run, and obsolete queued
  work is canceled when navigating away. Prefetch does not decode full bitmaps.
- The shared image downloader admits four requests at a time instead of the
  library default of ten, to avoid overwhelming the current image origin.
- Preview-only `[MemoryPerf]` logs separate list timing, transferred bytes/time,
  and photo readiness (decoded images or fallback placeholders). They never
  include URLs, names, or tokens.
- This improves repeat loads and prepared next boards. It does not guarantee a
  faster first download on a slow connection or with a slow original-image host.
