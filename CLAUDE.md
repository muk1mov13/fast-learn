# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

"Texnik ijodkorlik va konstruksiyalash" — a Flutter mobile learning app for the eponymous university course (Uzbek language). Built as the practical output of a master's dissertation. Fully offline: all content is bundled as JSON assets, progress stored locally via `shared_preferences`.

**No codegen required.** No `build_runner`, no `freezed`. After `flutter pub get`, the app runs immediately.

## Commands

```bash
flutter pub get          # Install dependencies
flutter run              # Run on connected device/emulator
flutter test             # Run all tests
flutter analyze          # Static analysis (uses flutter_lints)
flutter test test/models_test.dart   # Run model unit tests
flutter test test/widget_test.dart   # Run a single test file
```

First-time setup (if `android/`/`ios/` platform folders are missing):
```bash
flutter create .         # Generates platform files without overwriting lib/
flutter pub get
flutter run
```

## Architecture

### Data Flow

```
assets/content/topic_N.json
    → LocalContentRepository.loadTopics()
    → topicsProvider (FutureProvider)
    → UI screens

SharedPreferences ('progress_v1' JSON key)
    → SharedPrefsProgressRepository
    → ProgressNotifier (StateNotifier)
    → progressProvider (StateNotifierProvider)
    → UI screens
```

### State (lib/state/providers.dart)

All app state lives in two Riverpod providers:

- **`topicsProvider`** (`FutureProvider<List<Topic>>`): loads all 8 topics from JSON assets once.
- **`progressProvider`** (`StateNotifierProvider<ProgressNotifier, ProgressState>`): owns all gamification state — per-topic completion flags (`video`, `lesson`, `test`), `points`, `badges`, `streak`. Persisted to SharedPreferences on every mutation.

`ProgressState.isUnlocked(topicId)` implements sequential topic gating: topic N unlocks only when topic N−1 is `isCompleted` (video + lesson + test ≥ 60%).

### Repository Interfaces

`ContentRepository` and `ProgressRepository` are abstract classes — the current implementations are `Local*` variants. Swapping to Firebase means adding a new implementation class without touching the UI layer.

### Routing (lib/app/router/app_router.dart)

Three routes via `go_router`:
- `/splash` → `SplashScreen`
- `/` → `HomeShell` (bottom nav shell with Home / Progress / Profile tabs)
- `/topic/:id?tab=N` → `TopicScreen` — `tab` query param opens a specific stage directly

### Topic Learning Flow

`TopicScreen` renders 7 tabs for each topic (in order):
1. **Video** — YouTube player (`youtube_player_iframe`, unlisted videos); auto-completes at 90% watched, manual button also available
2. **Dars** (Lesson) — markdown body rendered as scrollable text
3. **Glossariy** — 3D flip flashcards
4. **Krossvord** — crossword puzzle stage
5. **Savollar** — discussion questions
6. **Amaliyot** — practical task description
7. **Test** — A/B/C/D auto-graded quiz; ≥60% required to mark topic complete

Only `video`, `lesson`, and `test` stages contribute to `TopicProgress.percent` (33% each). The other tabs are supplementary.

### Content Format

Edit `assets/content/topic_N.json` to update any learning content without touching Dart code. Key fields:
- `video.youtubeId`: unlisted YouTube video ID streamed by `VideoStage` (e.g. `"dQw4w9WgXcQ"`); empty string shows a static placeholder. (`video.assetPath` — legacy local-MP4 field, still parsed but no longer used by the player.)
- `correctIndex`: 0=A, 1=B, 2=C, 3=D
- `test: []` — empty array is valid; UI shows "Test tez orada" gracefully
- `isUnlocked` in JSON is the base state; runtime unlocking is controlled by `ProgressState.isUnlocked()`

### Scoring & Badges

| Action | Points |
|---|---|
| Complete video (first time) | +10 |
| Complete lesson (first time) | +10 |
| Pass test (first time, ≥60%) | `+correct × 5` |

Badges: `first` (any topic complete), `perfect` (100% test), `half` (4+ topics complete), `streak7` (streak ≥ 7).

### Theming

`AppTheme.light()` / `AppTheme.dark()` in `lib/app/theme/`. Theme mode toggled via `themeModeProvider` (StateProvider). Extensions on `BuildContext` in `app_theme.dart` expose shorthand color getters (`context.surfaceColor`, `context.mutedColor`, etc.).

### VideoStage

`VideoStage` (`lib/features/topic/stages/video_stage.dart`) is a `ConsumerStatefulWidget`. It streams an unlisted YouTube video via `youtube_player_iframe`: `initState` builds a `YoutubePlayerController.fromVideoId(topic.video.youtubeId)` (fullscreen enabled, autoplay off) and subscribes to `videoStateStream`. The listener tracks watch progress and calls `completeStage(isVideo: true)` once when playback reaches 90%, showing a "+10 ball" snackbar. A manual "Videoni yakunlash" button stays disabled until `_watchPercent >= 0.9` (backup path; the stream normally auto-completes first). If `youtubeId` is empty, a static placeholder player is shown instead. (The legacy `assetPath`/local-MP4 + Chewie path was removed; `assetPath` still exists on the model but is unused by this stage.)

## Planned Extensions (not yet implemented)

- **Firebase**: swap `LocalContentRepository` → `FirebaseContentRepository`, `SharedPrefsProgressRepository` → `FirestoreProgressRepository`. Interfaces are already in place.
- Teacher admin panel
- 3D constructor module (`model_viewer_plus`)
- Lottie confetti animations
