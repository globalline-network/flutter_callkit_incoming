# Flutter Callkit Incoming

> **This is Globalline's fork
> of [hiennguyen92/flutter_callkit_incoming](https://github.com/hiennguyen92/flutter_callkit_incoming).
**
> Installation, usage and the full parameter reference live in upstream's docs — their
> [README](https://github.com/hiennguyen92/flutter_callkit_incoming#readme) or
> [pub.dev](https://pub.dev/packages/flutter_callkit_incoming) — bearing in mind both track
> upstream's latest release, not this fork's baseline (currently `3.1.5`). iOS VoIP setup is in
> [PUSHKIT.md](PUSHKIT.md) — upstream's guide, with our APNs troubleshooting notes appended at the
> end.

A Flutter plugin to show incoming call in your Flutter app (Custom for Android/Callkit for iOS).

Everything else you need to know about the fork is on this page:

- [Consuming this fork](#consuming-this-fork)
- [Updating to the latest upstream version](#updating-to-the-latest-upstream-version)
- [Files that conflict every time](#files-that-conflict-every-time)
- [After a merge: what to check](#after-a-merge-what-to-check)
- [What we changed locally](#what-we-changed-locally)
- [Working in this repo](#working-in-this-repo)
- [Remotes](#remotes)
- [Regenerating serialization code](#regenerating-serialization-code)

## Consuming this fork

Apps depend on the fork by git ref, not from pub.dev:

```yaml
dependencies:
  flutter_callkit_incoming:
    git:
      url: https://github.com/globalline-network/flutter_callkit_incoming.git
      ref: <commit-sha-or-tag>
```

Pin a **commit SHA or tag**, never a branch name — otherwise it's impossible to tell which state of
the fork an app build actually shipped.

## Updating to the latest upstream version

In GitHub Desktop:

**1. Fetch origin** — gets the latest code from their repo. There's no branch to choose: *Fetch
origin* updates every remote at once. The branch you want is upstream's `master`, which is where
hiennguyen92 publishes releases — their `dev` branch is work in progress, don't merge that one.

**2. Merge it into our `master`.** On `master`: *Branch → Merge into current branch…*, then pick
`master` under hiennguyen92's repo, not ours. If their branches aren't listed, the `upstream` remote
isn't set up on this clone — see [Remotes](#remotes).

**3. Resolve the conflicts** — the same few files every time, listed below. Keep **both** sides:
upstream's new code and our changes.

GitHub Desktop will then offer *Push origin*; that's what makes the update live for everyone.

The *Sync fork* button on github.com looks like a shortcut for all this, but it gives up as soon as
there are conflicts — which here is every time.

### Files that conflict every time

Our changes live inside files upstream also edits, so these come up on every sync:

| File                                                    | Why it conflicts                                                                                                        |
|---------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------|
| `android/.../CallkitIncomingActivity.kt`                | Upstream's busiest file, and it holds our `applyRippleSettings()` plus the changed `initView(data)` signature.          |
| `android/.../Call.kt`                                   | Upstream regularly adds fields to `Data`, `toBundle()` and `fromBundle()` — our five `ripple*` fields sit in all three. |
| `android/src/main/res/**/activity_callkit_incoming.xml` | Our caller-name layout change, in both the portrait and landscape variants.                                             |
| `lib/entities/android_params.dart` (and its `.g.dart`)  | Upstream adds parameters here too; ours is `rippleEffect`.                                                              |

If a conflict looks like a choice between upstream's version and ours, it almost certainly isn't —
it needs both.

### After a merge: what to check

```
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

Then build the example app for both platforms, matching what CI does
([.github/workflows/main.yml](.github/workflows/main.yml)):

```
cd example && flutter pub get && flutter build apk --debug
```

```
cd example && flutter build ios --release --no-codesign
```

Finally, check the two fork features by hand on an Android device. This is the part that matters: a
change of ours dropped during conflict resolution still compiles, so nothing above will catch it.

1. Show an incoming call with a `rippleEffect` set (non-default `color` and `scale` are the easiest
   to eyeball) and confirm the glow reflects it. `adb logcat -s CallkitIncoming` prints the values
   `applyRippleSettings()` received.
2. Show an incoming call with a long caller name and confirm it centers and wraps to up to 3 lines
   rather than being cut off with an ellipsis.

## What we changed locally

Current baseline: upstream `3.1.5` (merge base `8df0558`). To see the full fork diff at any time:
`git diff upstream/master...HEAD`.

### 1. Configurable ripple effect (Android)

Upstream hard-codes the pulsing glow behind the caller avatar on the full-screen incoming call
screen. We made it configurable from Dart.

| File                                          | Change                                                                                                                                     |
|-----------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------|
| `lib/entities/ripple_effect_params.dart`      | New `RippleEffectParams` entity: `color`, `amount`, `radius`, `scale`, `duration`.                                                         |
| `lib/entities/ripple_effect_params.g.dart`    | Generated JSON glue (checked in — see [Regenerating serialization code](#regenerating-serialization-code)).                                |
| `lib/entities/android_params.dart`            | Added the `rippleEffect` field to `AndroidParams`.                                                                                         |
| `lib/entities/android_params.g.dart`          | Generated glue for the new field.                                                                                                          |
| `lib/entities/entities.dart`                  | Exports `ripple_effect_params.dart`.                                                                                                       |
| `android/.../Call.kt`                         | Reads `android["rippleEffect"]` into five flat `ripple*` fields, and carries them through `toBundle()` / `fromBundle()`.                   |
| `android/.../CallkitConstants.kt`             | Five new `EXTRA_CALLKIT_RIPPLE_*` bundle keys.                                                                                             |
| `android/.../CallkitIncomingActivity.kt`      | `initView()` now takes the intent `Bundle`, and `applyRippleSettings()` pushes the values into the view *before* `startRippleAnimation()`. |
| `android/.../widgets/RippleRelativeLayout.kt` | New `updateRippleSettings()` that tears down and rebuilds the ripple views and animators.                                                  |

Notes for whoever touches this next:

- The Dart side sends a **nested map** (`android.rippleEffect.*`); the Kotlin side flattens it into
  five bundle extras. Both halves have to change together.
- `applyRippleSettings()` is a no-op when every value equals the Kotlin default
  (`amount=4`, `radius=60f`, `scale=4.5f`, `duration=3000`, empty color), so an app that sends no
  `rippleEffect` gets upstream's original animation.
- `radius` is specified in **dp** from Dart and converted with `Utils.dpToPx()`; `duration` is ms.
- iOS is unaffected — CallKit renders the incoming screen, so there is nothing to style.

### 2. Full-screen caller-name layout (Android)

In `android/src/main/res/layout/activity_callkit_incoming.xml` and
`android/src/main/res/layout-w600dp-land/activity_callkit_incoming.xml`: the caller name is centered
and wraps to 3 lines instead of being ellipsized to 1, and the portrait layout uses a larger top
margin (`base_margin_x5`) below the avatar. Both layout variants must stay in sync.

### 3. APNs troubleshooting notes

[PUSHKIT.md](PUSHKIT.md) has an appended "Integration Guide" section covering `BadDeviceToken`
(sandbox vs production environment) and `TopicDisallowed` (bundle ID / certificate mismatch).

## Working in this repo

Almost every file here is upstream's. Keep our diff against upstream as small as possible, so the
updates above stay mergeable — don't reformat, rename or "tidy" upstream code as a side effect of a
change. Fork-specific documentation goes in this README; `PUSHKIT.md`, `CHANGELOG.md` and `CMD.md`
are upstream's.

The package version in `pubspec.yaml` tracks upstream (currently `3.1.5`) and is **not** bumped for
fork changes. Our own releases are tagged separately — see the `v3.0.0-gl.1` style tags.

## Remotes

| Remote     | URL                                                                  | Role                                                       |
|------------|----------------------------------------------------------------------|------------------------------------------------------------|
| `origin`   | `https://github.com/globalline-network/flutter_callkit_incoming.git` | Our fork. `master` is the branch consuming apps depend on. |
| `upstream` | `https://github.com/hiennguyen92/flutter_callkit_incoming.git`       | Read-only. Source of new releases.                         |

A fresh clone only has `origin`. If GitHub recognises this repo as a fork of hiennguyen92's, clients
pick `upstream` up on their own and nothing needs doing.

Otherwise it has to be added by hand, named exactly `upstream` and pointing at the URL above.
**GitHub Desktop has no UI for adding a second remote** — its Repository settings dialog only edits
`origin`. So either add it from a terminal once, or use a client that manages remotes (Fork,
GitKraken, VS Code, Sourcetree). It's one-time per clone, so a terminal is usually quickest:

```
git remote add upstream https://github.com/hiennguyen92/flutter_callkit_incoming.git
```

## Regenerating serialization code

`lib/entities/*.g.dart` are `json_serializable` output and are **committed** — consuming apps get
this package as a git dependency, so they have to be in the tree.

```
dart run build_runner build --delete-conflicting-outputs
```

Run it after any change to an entity class, and after any upstream merge that touched
`lib/entities/`. Commit the regenerated files; a `.g.dart` that disagrees with its source is a
silent
runtime bug, not a build error.