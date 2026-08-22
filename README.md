# Home Talk — Elderly Visual Communication Tablet App

A single-device Flutter tablet app that lets an elderly person communicate household
needs to a foreign-language caregiver **by recognizing pictures and tapping them** —
no reading, typing, menus, or technology knowledge required.

It is **not** a translation app. The user's intent is captured as language-independent
**semantic data**, and words/speech are produced only at the final display stage.

```
Elder taps pictures  →  SemanticIntent { object, action, destination, quantity }
                     →  IntentRenderer + HouseholdConfig
                     →  Final full-screen view (caregiver language + elder language + emoji)
```

## Core interaction (works today)

`Home → 🍳 Kitchen → 🥣 Bowl → 🫴 Bring → 👵 Me → "Bring me a bowl." / "جيبلي جاط."`

Plus: one-tap **Common Requests**, **Routines** (Morning/Night), **Help** (pre-phrased),
**Repeat last**, consistent Back/Home, edge guards against accidental grip taps.

## Architecture

Local-first, offline, **data-driven** (content is data, never hardcoded in widgets).

| Layer | Location | Notes |
|-------|----------|-------|
| Models | `lib/core/models/models.dart` | `SemanticIntent`, `HouseholdConfig`, entities |
| Data | `lib/core/data/` | `ConfigRepository` interface + sample impl |
| Services | `lib/core/services/intent_renderer.dart` | Deterministic phrase assembly — **no AI** |
| Design | `lib/core/design/design.dart` | Colors, sizes, theme (large, high-contrast) |
| UI strings | `lib/core/localization/ui_strings.dart` | The few fixed chrome strings, per language |
| Elder UI | `lib/features/elder/` | Home + flow screens + shared widgets |
| Admin | `lib/features/admin/` | Hold-to-enter gate + config overview |

Default sample household: **elder = Arabic, caregiver = English** (any languages supported).

## Roadmap

- [x] **Phase 1 — Functional prototype**: home, common requests, situation→object→action→destination flow, intent builder, final screen, routines, help, back/home, admin gate.
- [x] **Phase 2 — SQLite** — `SqliteConfigRepository` behind the same `ConfigRepository` interface; seeds from sample data on first run; runs on Android via sqflite and on desktop via `sqflite_common_ffi`.
- [x] **Phase 3 — Admin editing** — full editors for Household, Situations, Objects, Actions, Destinations, Common Requests, Routines, Help. Edits persist to SQLite and Elder Mode refreshes immediately.
- [x] **Phase 4 — Routines editing** — add/remove/reorder steps via the intent picker (part of Admin).
- [ ] **Phase 5 — Accessibility polish & device testing** (edge guards already in; needs on-device tuning).
- [x] **Phase 6 — Text-to-speech** — the "🔊 Play" button speaks the caregiver-language sentence; optional and degrades gracefully.
- [ ] **Phase 7 — Optional AI** (setup assistance, voice input) — never in the core path.
- [x] **Photos** — camera/gallery capture for objects & situations (`image_picker`), stored as local files under `<appSupport>/photos/` and shown on elder cards + the final screen (emoji fallback).

## Windows desktop dev note

The `flutter_tts` Windows plugin builds via CMake and needs `nuget.exe` on `PATH`
(`nuget.exe not found` otherwise). Drop `nuget.exe` into the Flutter SDK `bin/` folder
(already on PATH) — download from <https://dist.nuget.org/win-x86-commandline/latest/nuget.exe>.
Camera capture is Android-only; on Windows use **Gallery** (camera degrades gracefully).

## Run

```bash
flutter run            # attach an Android tablet (landscape) or run on desktop
flutter test           # renderer + widget smoke tests
```
