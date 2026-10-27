# Oathfall: Clash of Pantheons

A fully 2D, offline mythology card battler built with Godot 4.7.1. Play any of seven pantheons (Greek, Norse, Roman, Egyptian, Japanese, Chinese, Aztec) against an AI rival from a random other pantheon. All 85 card designs are unlocked.

## Play

Open `project.godot` in Godot 4.7.1 and press F6 with `main.tscn` open, or F5 to run the project. Choose **Enter the Arena**, then a pantheon.

- Both Sanctums start with 25 health; reduce your rival's to zero to win.
- Each turn increases and refills Power (maximum 10), draws a card, and readies your units.
- Click/tap a hand card, then confirm **Summon** or **Cast** in the inspector. Damage spells are cast by selecting an enemy unit or Sanctum.
- Click/tap a ready friendly unit, then an enemy. New units rest for one turn. Guard units protect other targets. Rush can attack units immediately.
- Use **End Turn** to give control to the AI. The match menu pauses AI actions and allows conceding. Empty decks cause increasing fatigue damage.

Full instructions are also available in the main menu. Completed matches and sound preferences save locally. Cards use one reusable scene with separate generated portraits, a frame, editable text, and live statistics. Hidden cards always use the same generated Oathfall back.

## Android

The latest debug APK is exported to `build/Oathfall-0.1.1-debug.apk` (build output is excluded from Git). The package is `com.codervlsi.oathfall`, in landscape, supporting ARMv7 and ARM64 devices on Android 7.0/API 24 and newer. Tap input maps to the same controls as mouse input. Version 0.1.1 includes the new Oathfall launcher icon.

Installable testing builds are attached to the repository's [GitHub Releases](https://github.com/CoderVLSI/Oathfall-Clash-of-Pantheons/releases).

GitHub Actions builds an installable debug APK on pushes to `main`/`master`, pull requests, and manual runs. Download it from the run's **Artifacts** section. This is a testing build, not a Play Store release. CI preserves its debug key using the Actions cache; a local APK and CI APK may need an uninstall between them because they use different debug signing identities.

Local export requires Godot 4.7.1 Android export templates, JDK 17, Android SDK Platform 35 and Build Tools 35.0.1. Configure `ANDROID_HOME` and `JAVA_HOME`, run `tools/configure_android.gd` with the headless editor, then export the **Android** preset.

## Verify

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --script res://tests/test_rules.gd
godot --headless --path . --script res://tests/test_ui.gd
godot --headless --path . --export-debug Android build/Oathfall-0.1.1-debug.apk
```

The rules suite covers combat, Ward, Lifesteal, Deathrattle, draw and buff effects, card-data validation, target validation, Guard, Rush, healing, fatigue, victory/defeat/draws, board limits, and 60 seeded complete matches across all seven pantheons. The UI suite covers menu navigation, both decks, confirmed plays, targeting, results, and AI turn completion. `tests/capture_screens.gd` produces visual QA screenshots in `qa/`.

## Art and tools

All game illustrations, frame art, backgrounds, UI icon atlas, card back, and application icon were generated with the built-in ImageGen tool for this project. See `docs/ART_DIRECTION.md`. Fonts are Cinzel and Lato under their included SIL Open Font Licenses. Sound effects are original procedural audio; rebuild them with `python tools/generate_audio.py`.

Only the Godot AI addon was initially copied from Kurukshetra; no old gameplay or artwork was copied. The addon was then upgraded to v4.2.3 to match the MCP server (HTTP 8102, WebSocket 8103). The game itself contains no 3D scenes or nodes.
