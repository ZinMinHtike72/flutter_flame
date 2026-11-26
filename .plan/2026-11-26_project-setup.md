# Game Test Flutter project setup

## Summary
Adapt the DMS Sales Commission Flutter starter architecture and tooling for a new Flame game, without importing DMS business code or secrets.

## Plan Steps
- [x] status: done - Inspected the target, DMS structure, reusable setup prompt, skill routing, and Flame skill.

## Implementation
- [x] status: done - Added project-specific AI guidance and 23 skills, including flame-core and 10 references.
- [x] status: done - Set up shared packages, Clean Architecture app shell, BLoC home, routing, DI, localization, and Flame canvas.
- [x] status: done - Adapted root tooling, VS Code, analysis options, scripts, docs, and Android/iOS development and production flavors.

## Test Plan
- [x] status: done - Resolved packages and generated localization, Envied, and Flutter assets.
- [x] status: done - Flutter analyze passed; root tests 2/2, app_network 65/65, app_ui_kit 106/106 passed.
- [x] status: done - Checked 23 skill links, both Android APKs, both iOS simulator builds, formatting, feature generator, and Git hooks.

## Verification
- status: complete
- Command: `flutter analyze`
- Result: `flutter analyze` passed with no issues.

## Verification details
- `make setup` passed after cleaning a stale build_runner cache left by replacing the UI package during setup. A repeat `make codegen` generated no new outputs.
- `flutter test --no-pub`: 2 passed. `packages/app_network`: 65 passed. `packages/app_ui_kit`: 106 passed.
- `dart format --output=none --set-exit-if-changed lib test packages`: 145 files checked, 0 changes.
- Android debug APKs: development `com.example.game_test.dev` / `Game Test Dev` / `1.0.0-dev`; production `com.example.game_test` / `Game Test` / `1.0.0`.
- iOS simulator builds: development `com.example.gameTest.dev` / `Game Test Dev`; production `com.example.gameTest` / `Game Test`.
- Temporary `setup_probe` feature generated and analyzed without issues, then removed.
- All 23 `.claude/skills` links resolve; Flame skill has 10 reference files; reusable prompt matches the DMS source byte-for-byte.
- Git hooks installed. Commit-msg accepted `feat(game): add scene` and rejected `added stuff`; pre-push accepted main, codex, feature ticket, and release names and rejected invalid names.
- No real API origin, signing credentials, Firebase configuration, live backend, or device interaction was provided or tested.

## Provenance
- Reference: `/Users/zinminhtike/Desktop/Projects/dms_sales_commission` (structure, AGENTS.md, tooling, project_structure_prompt.md).
- Global Flame skill: `/Users/zinminhtike/.codex/skills/flame-core`.
- No DMS feature code, environment values, generated output, or local AI permissions will be copied.
