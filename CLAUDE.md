# CLAUDE.md

Guidance for Claude Code when working in this repository.

## What this repository is

A **fork** of [hiennguyen92/flutter_callkit_incoming](https://github.com/hiennguyen92/flutter_callkit_incoming)
maintained by Globalline. It is a Flutter plugin that shows an incoming call screen — a custom
full-screen activity on Android, CallKit on iOS.

Read [README.md](README.md) before changing anything under `android/` or `lib/entities/`. It is the
fork's own documentation — our local patches, the update procedure, the files that conflict on every
merge, and known gaps. Two facts that change how you should edit:

- Almost every file here is **upstream-owned**. Keep diffs against upstream minimal so updates stay
  mergeable. Don't reformat, rename, or "tidy" upstream code as a side effect of a change.
- `README.md` is ours — upstream's package README was replaced by fork documentation, so upstream's
  installation and usage docs now live only on upstream/pub.dev. `PUSHKIT.md`, `CHANGELOG.md` and
  `CMD.md` are still upstream's; editing them creates merge conflicts for no benefit (`PUSHKIT.md`
  already carries one appended section of ours).

Remotes: `origin` = the fork, `upstream` = hiennguyen92. Current baseline: upstream `3.1.5`.

## Layout

| Path | Contents |
| --- | --- |
| `lib/flutter_callkit_incoming.dart` | The whole public Dart API — static methods on `FlutterCallkitIncoming` over `MethodChannel('flutter_callkit_incoming')` and `EventChannel('flutter_callkit_incoming_events')`. |
| `lib/entities/` | `json_serializable` param/event classes. `*.g.dart` is generated **and committed**. |
| `android/src/main/kotlin/com/hiennv/flutter_callkit_incoming/` | Kotlin implementation. Entry point `FlutterCallkitIncomingPlugin.kt`; the full-screen UI is `CallkitIncomingActivity.kt` + `widgets/RippleRelativeLayout.kt`; arg parsing and bundle marshalling is `Call.kt`; bundle keys are `CallkitConstants.kt`. |
| `android/src/main/res/layout*/activity_callkit_incoming.xml` | Full-screen call layout. Portrait and `layout-w600dp-land` variants must stay in sync. |
| `ios/flutter_callkit_incoming/Classes/` | Swift implementation (`SwiftFlutterCallkitIncomingPlugin.swift`, `CallManager.swift`, …). No fork changes here. |
| `example/` | Runnable demo app. Also what CI builds. |
| `test/` | A single Dart unit test; there is no native test suite. |

## Commands

```
flutter pub get
flutter analyze
flutter test
```

Regenerate serialization code after touching anything in `lib/entities/`, and commit the result:

```
dart run build_runner build --delete-conflicting-outputs
```

Build the example app (this is what [CI](.github/workflows/main.yml) runs, from `example/`):

```
cd example && flutter build apk --debug
```

```
cd example && flutter build ios --release --no-codesign
```

Do **not** run `flutter pub publish`. The `CMD.md` publish commands are upstream's; this fork is
consumed as a git dependency. See [README.md](README.md#dont-publish-to-pubdev).

## Conventions and gotchas

- **Dart↔Kotlin params travel in two hops.** `CallKitParams` → method channel map → `Data` in
  `Call.kt` → `Bundle` extras (`CallkitConstants`) → read back in the activity/service. A new
  parameter needs the entity, the `.g.dart` regeneration, `Data`'s field, `toBundle()`,
  `fromBundle()`, a constant, and the consumer. Missing one of the middle steps fails silently at
  runtime — the value just arrives as its default.
- **Nested vs flat.** Dart sends nested maps (e.g. `android.rippleEffect.*`); bundles are flat. The
  flattening lives in `Call.kt`.
- Android defaults are duplicated between Dart (`null`) and Kotlin (literal defaults in `Data`).
  When changing a default, change the Kotlin side — Dart `null` means "don't override".
- `flutter analyze` uses `flutter_lints` (`analysis_options.yaml`) with no local rule overrides.
- Environment floor: Dart SDK `>=3.0.0 <4.0.0`, Flutter `>=3.10.0`; CI pins Flutter `3.32.x` and
  Java 17.
- The incoming-call screen and CallKit integration can't be verified by tests or a compile. For any
  change to the call UI, notification, or ringtone path, say what needs manual device verification
  rather than reporting it as done.
