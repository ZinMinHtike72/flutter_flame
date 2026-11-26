<!--
STRICT PR RULES (AGENTS.md → "Pull Requests — Strict Rules"). A PR that breaks one is not reviewed.
- Title = Conventional Commit header, e.g. `feat(game): add game summary`.
- One feature or fix per PR. Only files that belong to it.
- Fill in EVERY section. Write "N/A — <reason>" instead of deleting one.
- Any UI change needs golden proof: committed golden PNGs embedded below (light + dark).
- Paste the real output of the verification commands; never tick a box that isn't true.
-->

## Summary

<!-- What changes for the user, and why. 1–3 sentences a reviewer can read first.
     If stacked on another PR, say which and when to retarget. -->

## Related

- Ticket / issue:
- Plan file: `.plan/YYYY-MM-DD_<slug>.md`
- Figma / API spec / prototype:
- Docs updated: `docs/features.md` / `docs/api.md`
- Stacked on: <!-- owner/repo#123, or "—" -->

## Type of change

- [ ] ✨ Feature
- [ ] 🐛 Bug fix
- [ ] ♻️ Refactor (no behavior change)
- [ ] 🎨 UI / style only
- [ ] 🧪 Tests only
- [ ] 🔧 Build, CI, dependencies or tooling
- [ ] 📝 Docs
- [ ] 💥 Breaking change (describe the migration below)

## Changes

<!-- Bullet the notable changes by layer. Point reviewers to the files that matter most. -->

- Domain:
- Data:
- Presentation:
- Packages (`app_ui_kit`, `app_network`):
- Strings (keys added per locale):

## Golden proof (required for any UI change)

<!--
Every visible change is proven by golden renders from `flutter test`, committed with the PR:
- Files live next to their test: `test/**/goldens/<screen>_<n>_<state>.png`
  (record with `flutter test --update-goldens <test file>`, see AGENTS.md → "Golden tests").
- Embed them so they render here:
  ![name](https://github.com/<owner>/<repo>/blob/<branch>/test/<path>/goldens/<file>.png?raw=true)
- Required: every changed screen or state in light mode, plus dark mode.
  Add a small phone (360×640) and Myanmar render when layout or text changes.
- Bug fix: show Before and After (the old golden from the base branch, the new one from this branch).
- Mention render-only artefacts (missing system fallback glyphs, no shadow blur, no motion).
- No UI change: write "N/A — no pixels change; no golden changed".
-->

Golden files added / changed:

-

| Screen / state | Light | Dark |
|----------------|-------|------|
|                |       |      |

<!-- Bug fixes only:
| Before | After |
|--------|-------|
|        |       |
-->

## How to test

- Flavor: `development` / `production`
- Platform tested: Android ☐ iOS ☐ (device / simulator: )
- Data / accounts: <!-- sample data, fake API, test numbers — never real credentials -->
- Steps:
  1.
  2.
- Expected result:

### Automated verification

<!-- Paste the real results. Counts, not "passes". -->

- `flutter analyze`:
- `flutter test`: <!-- N passed -->
- `make test-packages`: <!-- app_network N, app_ui_kit N -->
- `make coverage`: <!-- every touched module ≥ 85 %; list them -->
- Goldens: <!-- N goldens, compared on macOS -->
- `dart format --set-exit-if-changed lib test packages` and `git diff --check`:

## Acceptance criteria

<!-- From the ticket. Tick only what this PR meets; say why for anything unticked. "N/A — no ticket" otherwise. -->

- [ ] AC-1:

## Checklist

### Architecture (see AGENTS.md)
- [ ] Feature code follows `data/ domain/ presentation/ di/` with barrel exports
- [ ] `domain/` has no Flutter, serialization or third-party imports
- [ ] No cross-feature `presentation/` imports
- [ ] `Bloc<Event, State>` only — no Cubit, no `setState` / `StatefulWidget` (except animation tickers)
- [ ] New dependencies are registered in the feature `DependencyModule`, and the module in `configureDependencies()`
- [ ] Routes added to `RouterPath` + `AppRouter`; complex data passed via typed `extra`

### UI & localization
- [ ] Only `app_ui_kit` widgets; new shared widgets added there with a test
- [ ] Colors from `context.appColors` / `colorScheme`, spacing from `AppSpacing`
- [ ] No hardcoded strings — keys added to **every** `app_<locale>.arb`
- [ ] Animations respect reduced motion; no overshooting curve on decoration, padding or text-style animations
- [ ] Remote images use `cached_network_image` (no `Image.network`)
- [ ] Golden renders committed and embedded above for every changed screen, light and dark
- [ ] Checked on a small screen and in every locale

### Data & safety
- [ ] Endpoints and JSON fields match the API spec (not guessed)
- [ ] Repositories return `Result<T>`; failures surfaced to the user, never swallowed
- [ ] No secrets, tokens, real staff data or `.env.*` files committed; new env variables added to `.env.example`
- [ ] No new package without agreement (listed in the summary if added)
- [ ] Code that uses the date or time takes it from the injected `AppClock`

### Quality
- [ ] `flutter analyze` — no issues
- [ ] `flutter test` (and `make test-packages` if `packages/` changed) — all pass, goldens included
- [ ] Tests added/updated for new logic (BLoC, use case, repository, widgets)
- [ ] `make coverage` — every touched module ≥ 85 % line coverage (numbers above)
- [ ] `docs/features.md` / `docs/api.md` updated to match the code (features, routes, endpoints, API vs sample data)
- [ ] Plan file statuses and verification results updated
- [ ] `AGENTS.md` / README updated if a convention, command or package changed
- [ ] Only files that belong to this change (no build caches, `coverage/`, unrelated edits)

## AI assistance

<!-- Agents can produce confident but wrong code. Be explicit so reviewers know where to look. -->

- [ ] No AI-generated code in this PR
- [ ] AI-generated code is included, and I have:
  - [ ] read and understood every line I'm submitting
  - [ ] confirmed every class, widget, method and package it uses actually exists
  - [ ] verified endpoints and fields against the API spec, and UI against Figma / the prototype
- Tool / agent used:
- Parts that were AI-generated:

## Assumptions to review

<!-- Decisions made without a spec (rules, copy, edge cases) that a reviewer or the business must confirm. "None" if there are none. -->

-

## Notes for reviewers

<!-- Risky areas, open questions, follow-ups, and anything NOT verified (e.g. "not tested on a physical iPhone"). -->
