# Complete Flutter Project Setup Prompt

Give this entire file to an AI coding agent to complete a new Flutter project's
development setup in one request. It includes the shared UI and network packages,
API infrastructure, cached network images, app architecture, native flavors,
localization, AI files, Git hooks, generation, and verification.

This is a reusable instruction template. Source projects evolve; inspect their
actual files and record checks from the target checkout. This document does not
claim that a source project's current builds or tests have been verified.

## Inputs and defaults

Use supplied inputs first. Infer omitted identity values from the target; keep
existing Android/iOS identifiers. Infer display names from the project name. If
API values are unavailable, use the dummy values below and continue the complete
setup. Ask only when missing information blocks a safe implementation.

| Input | Meaning / default |
| --- | --- |
| `{{PROJECT_PATH}}` | Absolute target project path; use the current Flutter workspace if omitted |
| `{{PACKAGE_NAME}}` | Existing `name:` from the target's pubspec |
| `{{APP_NAME}}` | Production display name, e.g. `Cannopy Fleet` |
| `{{DEV_APP_NAME}}` | Short development display name, e.g. `Fleet Dev` |
| `{{ANDROID_APP_ID}}` | Preserve the target's existing production application ID and namespace |
| `{{IOS_BUNDLE_ID}}` | Preserve the target's existing production bundle identifier |
| `{{API_BASE_PATH}}` | Supplied API prefix with trailing slash; use `/` until the contract is known |
| `{{DEV_API_URL}}` | Supplied development origin; otherwise `https://dev-api.example.invalid` |
| `{{PROD_API_URL}}` | Supplied production origin; otherwise `https://api.example.invalid` |
| `{{EXAMPLE_SCOPE}}` | A lowercase domain word, e.g. `fleet` |
| `{{TICKET_PREFIX}}` | Ticket prefix, e.g. `FLEET`; derive from the project name if omitted |
| `{{STARTER_PATH}}` | Complete reusable starter; default `/Users/zinminhtike/Desktop/Projects/cannopy_fleet` |
| `{{HR_REFERENCE_PATH}}` | Historical starter/reference; default `/Users/zinminhtike/Desktop/Projects/cannopy_hr` |
| `{{DMS_REFERENCE_PATH}}` | Tooling/reference example; default `/Users/zinminhtike/Desktop/Projects/dms_sales_commission` |

On another machine, use the corresponding local clones. If the target is also the
starter path, reuse its verified existing files and obtain missing generic files
from the references; never copy a directory onto itself.

---

## Prompt for the agent

You are a Senior Flutter Engineer. Complete `{{PROJECT_PATH}}` using the team's
Clean Architecture, BLoC, GetIt, go_router, and shared-package conventions.

**Complete means the runnable app starter and its required packages are present,
registered, generated, and checked. Installing only AI files, hooks, or flavors
is incomplete.** Work through every required section below in this request.

### 1. Inspect, plan, and choose reusable sources

1. Read applicable `AGENTS.md`, the Flutter skill-routing file when present, and
   the target's README, `docs/features.md`, `docs/api.md`, and related `.plan/`.
   Follow project rules when adapting examples. Inspect actual exported APIs.
2. Inspect Git status, package name, Flutter/Dart versions, native identifiers,
   flavors, dependencies, and existing code. Preserve unrelated changes.
3. Create/update `.plan/YYYY-MM-DD_project-setup.md` **before implementation**.
   Include each required component, tests, and actual verification results.
4. Back up existing files that will be adapted. A counter/template app can be
   replaced by the localized starter. In an app with real features, add missing
   infrastructure through targeted merges; retain its routes, DI registrations,
   features, tests, configuration, and native IDs. Obtain approval only for an
   unavoidable overwrite of real work that has not already been authorized.
5. Use an exact allow-list, not a whole-current-project copy. Current HR and DMS
   have business features; copying their entire `lib/`, `test/`, `assets/`, root
   pubspec, or hidden directories would import unrelated application behavior.
6. Prefer the complete starter's reusable files. For the original generic
   baseline, inspect HR Git revision `f4e34dd` (the initial structure commit),
   e.g. `git -C "{{HR_REFERENCE_PATH}}" show f4e34dd:pubspec.yaml`. Extract only
   manifest paths below to a temporary staging directory, then adapt them.
   Inspect current generic package fixes before selecting a newer package.
7. Keep provenance in the plan: source path/revision and files selected. If a
   source file or dependency is unavailable, report the specific gap; inspect
   alternatives or implement the missing generic helper against real package
   APIs and test it. Do not invent a backend contract or quietly omit a component.

### 2. Required file manifest

Copy/adapt these reusable paths. Merge root manifests and entry points into an
existing app. Generated files are regenerated in the target.

| Target path | Required result |
| --- | --- |
| `packages/app_network/` | Generic Dio transport, typed requests/results/failures, public/protected client, auth session contracts, tests, README |
| `packages/app_ui_kit/` | Exported shared widgets, light/dark themes, colors/spacing, cached network-image wrapper, tests, README |
| `pubspec.yaml` | Root pub workspace, both path dependencies, complete baseline dependencies/dev tooling, fonts/assets/generation |
| `lib/main.dart`, `lib/app/app.dart` | Flavor-aware bootstrap and localized themed router app |
| `lib/app/di/injection_container.dart` | GetIt, DependencyModule, idempotent registration helpers, core and feature modules |
| `lib/app/router/route_path.dart`, `app_router.dart` | Central paths, home route, unavailable-detail/error fallback |
| `lib/core/env/` | AppFlavor, dual-flavor Envied configuration; no copied generated values |
| `lib/core/constants/api_constants.dart` | Trusted base URI construction and only supplied API paths |
| `lib/core/di/`, `lib/core/network/` | Shared client/transport/session, secure token storage, expiry notification, API envelope/failure helpers, safe logging boundary |
| `lib/core/result/`, `lib/core/usecase/` | Pure Dart Result/AppFailure and reusable use-case contracts |
| `lib/features/home/` | Minimal localized Home Screen + ViewContent + Bloc/Event/State + DI/barrels; keep real target home features if present |
| `l10n.yaml`, `lib/l10n/arb/`, `lib/l10n/l10n.dart` | English/Myanmar ARBs and context.l10n; generate localization output |
| `assets/fonts/`, `assets/images/` | Poppins + Noto Sans Myanmar, font licenses, target-owned asset directory; no reference business images |
| `test/` | Only generic app/route/DI/env/core/home tests that match the target; retain unrelated target tests |
| `scripts/create_feature.sh` | Target-renamed feature scaffolder that generates analyzable Clean Architecture/BLoC code |
| `scripts/check_branch_name.sh`, `scripts/setup_ios_flavors.rb` | Branch rules and inspected xcodeproj-based native flavor initializer |
| `scripts/configure_secure_storage.rb` | Idempotent native secure-token-storage prerequisites, preserving existing access groups |
| `Makefile` | setup/env/get/l10n/codegen/hooks/analyze/test/test-packages/format/create-feature/run/build commands |
| `analysis_options.yaml` | Strict type/lint configuration matching the team's rules |
| `.husky/commit-msg`, `.husky/pre-push`, `commitlint.yaml` | Commit-message and pushed-branch validation |
| `.github/pull_request_template.md`, `.github/workflows/branch-name.yml` | Target-neutral review template and branch validation CI |
| `.env.example`, `.gitignore` | Dummy env template, ignored real env/generated values/build/local AI artifacts |
| `AGENTS.md`, `CLAUDE.md`, `.agents/skills/`, `.claude/skills/` | Accurate target profile, team rules, relevant skills, relative Claude symlinks |
| `.vscode/launch.json`, `.vscode/settings.json` | Flavor launch profiles and Dart formatter settings |
| `README.md`, `docs/README.md`, `docs/features.md`, `docs/api.md`, `docs/development-environment.md` | Accurate onboarding, installed capabilities, placeholder/API status, commands and limitations |
| `documents/project_structure_prompt.md` | This same reusable prompt; keep template inputs/reference paths intact |

**Never copy** `.git`, build/tool/package caches, Pods, coverage, IDE user files,
`.metadata`, source `.env*` values, generated `app_env.g.dart`, generated l10n or
asset code, `.husky/_`, local Claude permissions/settings, worktrees, agent-run
logs, source plans, Firebase project files/credentials, signing material, or
business features. Copy `.env.example` only after checking it contains dummy
values. Preserve symlinks; do not follow links outside the approved skill tree.
Keep the target's existing native projects and adapt them in section 8.

### 3. Install all baseline development dependencies

Register both packages in root `workspace:` and under path `dependencies:`;
package pubspecs use `resolution: workspace`. Resolve dependencies from the root.
Copy compatible constraints from the inspected starter, preserving target
constraints where compatible. Do not blindly upgrade versions or replace a real
app's pubspec. Sort dependency keys alphabetically.

Required baseline capability/dependency matrix:

| Capability | Packages |
| --- | --- |
| Shared packages | `app_network`, `app_ui_kit` as workspace path dependencies |
| BLoC | `bloc`, `flutter_bloc`, `equatable` |
| Router and DI | `go_router`, `get_it` |
| API transport and secure credentials | `dio`, `flutter_secure_storage` |
| Environment and JSON | `envied`, `json_annotation` |
| Logging | `talker`, `talker_dio_logger` available for explicitly safe host logging |
| Remote images from the start | `cached_network_image` and direct `flutter_cache_manager` dependencies in `app_ui_kit`; root dependencies only if app code directly imports them |
| Localization | Flutter SDK, `flutter_localizations` SDK, `intl` |
| Reusable baseline utilities | Retain `package_info_plus`, `url_launcher`, `uuid` when included/used by the selected starter; document actual installed utilities |
| Development/code generation | `build_runner`, `envied_generator`, `flutter_gen_runner`, `json_serializable`, `flutter_lints` |
| Tests | `flutter_test` SDK, `integration_test` SDK, `bloc_test`, `mocktail` |
| Git hooks | `husky`, `commitlint_cli` |

Add other dependencies required by the copied reusable widget implementations
(e.g. `flutter_svg` only when those widgets import it). Include those packages'
assets, licenses, native prerequisites, and tests.

Feature-dependent packages are a separate decision: Drift/app_database,
SharedPreferences/app_storage, camera, maps/location, notifications/Firebase,
biometrics, scanners, or monitoring. Copy an available generic package and wire
its native setup when the target needs that capability. Never import nonexistent
`app_core`, `app_logger`, `app_storage`, or `app_database` wrappers just because a
standards table names them; use the actual inspected implementation and document
what is installed. Dummy API setup does not require invented Firebase projects,
map keys, permissions, backend endpoints, or vendor credentials.

### 4. Cached network images are required

Install `cached_network_image` and expose `AppNetworkImage` from `app_ui_kit`.
The kit's public cache-manager API imports `flutter_cache_manager`, so declare it
as a direct production dependency (the current starter uses `^3.4.1`). The
`file` package used by its in-memory filesystem test harness is test-only and
belongs in kit dev_dependencies (the current starter uses `^7.0.1`).
Reuse the complete starter's wrapper, or add/test it against the actual installed
package API if missing. Do not leave image support as a future TODO.

The starter wrapper accepts a nullable `url`, optional width/height/fit/radius,
semantic label, explicit `cacheKey`, optional `BaseCacheManager? cacheManager`,
headers, loading/fallback builders, and optional memory-cache dimensions.
Preserve existing compatible public APIs.

Requirements:

- Validate URLs before loading (supported HTTP/HTTPS, nonblank host, no embedded
  credentials); null, blank, or invalid URLs show a deterministic fallback.
- Use CachedNetworkImage/CachedNetworkImageProvider behind the shared widget;
  no Image.network or raw NetworkImage in feature UI.
- Provide constrained loading and error states so image failure does not break
  layout. Respect light/dark colors, reduced motion, fit, dimensions, clipping,
  semantic labels, and decorative-image exclusion.
- Keep the full URL as the default cache identity. A caller may supply a stable
  key for a known signed resource; include tenant/user, resource version, and any
  content-selecting query parameters. Do not blindly strip all query parameters
  or forward API auth tokens to arbitrary image hosts.
- Add deterministic offline widget tests for loading, cached success, failed
  loading, null/empty/invalid URL fallback, and semantics. Forward an injected
  cacheManager to CachedNetworkImage so tests can supply a fake cache without
  initializing the default singleton or native cache plugins. Use test-controlled
  cache/image streams; never depend on an external image server in tests.
- Document a real usage example with the wrapper's actual constructor and
  `context.l10n` text. The placeholder home may show a local/empty image fallback;
  do not make setup success depend on a remote image being reachable.

### 5. API and core infrastructure must be wired

- Inspect/copy the generic `app_network` public API and package tests. Keep its
  transport, auth, cancellation, decoding, replay/idempotency, and failure
  contracts consistent. Do not transplant source-app login/recovery endpoints.
- Register the active AppFlavor and AppEnv, Talker, secure storage, TokenStore,
  NetworkTransport/DioNetworkTransport, AuthSession, SessionExpiryNotifier, and
  AppNetworkClient through CoreModule and `configureDependencies()`.
- Use one shared secure token store/session. Public calls must not attach tokens;
  protected calls use the session. Expiry notification is injected host behavior,
  not navigation inside the network package. Global BLoCs are provided once.
- Until a real refresh contract exists, use access-token-only behavior. Leave
  refresh as an explicit host extension; never invent an endpoint or token schema.
- Build the trusted API URI from the active dummy/real origin and supplied base
  prefix. Unknown API prefix means `/`. Keep endpoint constants empty until
  documented by the user/API specification. Do not send a fabricated health/login
  request from the placeholder home.
- Keep Result/AppFailure and UseCase/NoParams in pure Dart core. Repositories map
  typed network failures to Result failures; data DTOs own JSON serialization;
  domain objects have no Flutter/serialization/third-party dependencies.
- Use local-first repositories when an offline feature and its cache exist;
  adding transport infrastructure does not imply that a database is installed.
- Logging must have a usable injected boundary and safe defaults. Log selected
  metadata only in development; do not copy raw request/response body logging,
  headers, tokens, URLs containing signed query strings, credentials, or PII.
  Production logging must not expose those values.
- Test client/DI registration, success and failure mapping, public/protected
  behavior, secure-store failures and session expiry using in-memory fakes and
  storage mocks. Preserve the package's existing deterministic tests.

### 6. Finish the app starter, localization, and scaffolder

Replace a counter template with a minimal ready Home screen. Use StatelessWidget,
Bloc + Event + State, a screen-local factory registration, part files, Equatable
state/events, initial factory, complete copyWith/props, focused ViewContent,
BlocListener + BlocBuilder with filters, and shared kit widgets. Do not create
sample business rules or fake authenticated behavior. Preserve real target UI.

Provide centralized RouterPath/AppRouter, an unavailable-detail fallback for
missing/wrong typed route extras, root DI, and the localized themed App wrapper.
Use actual kit theme exports (e.g. LightTheme/DarkTheme), context.appColors,
AppSpacing and textTheme. No cross-feature presentation imports, Cubit, setState,
raw Material/Cupertino feature controls, or hardcoded user-facing strings.

Initialize English/Myanmar ARBs, context.l10n, generation configuration, Poppins
and Noto Sans Myanmar fonts with fallback, licenses, and the asset directory.
Register font/assets/codegen configuration in the root pubspec. Keep generated
paths aligned with imports. On reruns, merge keys and retain target translations.

Adapt create_feature.sh for the target package and verify all generated imports
and DI APIs exist. Makefile must include the complete setup commands, package
tests, localization and codegen, feature creation, both flavor runs, Android
builds, iOS simulator builds, and signed archive commands. Serialize setup stages
and native build verification; do not overlap flavor builds sharing generated
files or the same iOS output directory.

### 7. AI files, Git hooks, docs, and renaming

Copy only AGENTS.md/CLAUDE.md, the approved skills tree, and Claude skill symlinks;
never source-machine permission settings/worktrees. Update the project profile to
reflect actual installed packages and capabilities. Preserve the team's standards
and skill routing. Verify every relative skill link resolves inside the target.

Install Husky and check core.hooksPath is `.husky`. Keep commitlint scope rules
valid (disabled scope-enum still needs its required rule items). Validate messages
with the actual commit-msg hook and branch names with the actual pre-push hook.
Support main/development/production and the target's existing long-lived branch;
allow `codex/` branches alongside the team's feature/fix/release patterns. Preserve
the existing branch and do not silently rename it. Copy the branch-name workflow
and PR template; remote branch protection requires repository-host configuration
and must not be claimed configured by local hooks.

Rename only staged/copied project-specific text, longest matches first: native
IDs if explicitly requested, then package imports, production/dev names, API
prefix, editor labels, feature example scope and ticket prefix. Keep generic
`app_network`/`app_ui_kit` names. Do not rewrite this prompt's template/reference
names, skill documentation, target business content, or generated/native files
with a global text replacement. Check for stale source package imports and
source endpoints in copied app/core/config; a legitimate app name containing
Cannopy is not a stale-reference error.

Keep README and docs accurate: installed vs optional packages, one-command setup,
all routes/features, dummy vs actual API state, image usage, commands, and checks
not performed. Make docs/features.md and docs/api.md describe this target, not
HR/DMS business functionality. Do not copy source historical plans.

### 8. Native development and production flavors

Preserve native base IDs unless the user explicitly supplies replacements. Add
`.dev` only to development IDs; use `{{DEV_APP_NAME}}` and `{{APP_NAME}}` as native
labels. Inspect existing flavors first; merge/repair missing configuration rather
than rerunning a one-shot initializer or duplicating configurations.

Android requirements:

- environment flavor dimension, development and production productFlavors;
  `.dev` applicationIdSuffix and `-dev` versionNameSuffix in development.
- Native names via flavor `resValue("string", "app_name", ...)` and manifest
  `android:label="@string/app_name"`; Internet permission in the main manifest.
- Retain compatible namespace/MainActivity layout, Java/Gradle settings, plugins,
  existing permissions, and target signing configuration. Debug signing is not
  evidence that release distribution is configured.
- Apply the installed flutter_secure_storage version's Android prerequisites:
  a compatible minSdk and backup handling. The starter uses
  `android:allowBackup="false"`; if an existing app needs backup, follow the
  plugin's documented exclusions rather than overwriting that policy blindly.

iOS requirements:

- Use the inspected `setup_ios_flavors.rb` / xcodeproj gem for a fresh unflavored
  project; do not hand-edit project.pbxproj with text substitutions.
- `flutter pub get` may not create a Podfile for a plugin-free app. If missing,
  copy the installed Flutter SDK's `packages/flutter_tools/templates/cocoapods/Podfile-ios`
  template; locate that SDK from the resolved Flutter executable. Do not borrow
  a source app's flavored Podfile or guess the local SDK path.
- Create Debug/Release/Profile configurations for each flavor, correct Pods +
  Generated.xcconfig + flavor includes, matching development/production schemes,
  and all six Podfile mappings. RunnerTests uses the correct flavor-specific ID
  and CocoaPods-owned base configurations.
- Flavor xcconfigs set APP_DISPLAY_NAME and BUNDLE_ID_SUFFIX (`.dev`/empty);
  Info.plist uses `$(APP_DISPLAY_NAME)`, and Runner's bundle ID expands the suffix.
- Preserve current native plugins and project references. Inspect configuration
  mappings after the script; for an already flavored project, validate/adapt
  idempotently instead of aborting the entire setup.

After flavors, run the starter's inspected native storage initializer:

```bash
ruby scripts/configure_secure_storage.rb
```

For an existing app, adapt the initializer before running if it has an
intentional backup policy or access groups that must be retained.

Use the installed flutter_secure_storage README and platform implementation as
the authority. For unconfigured Runner flavors, the starter creates
DebugProfile.entitlements and Release.entitlements with the required
keychain-access-groups entry and binds CODE_SIGN_ENTITLEMENTS through xcodeproj.
Preserve custom CODE_SIGN_ENTITLEMENTS paths, existing access groups, and all
unrelated capabilities; merge required storage settings into those existing
files. Verify a second initializer run retains them. Verify both native
platforms' effective settings and rebuild after adding the plugin; Dart storage
mocks alone do not prove native Keychain/backup configuration. Real device
read/write behavior is a separate check from simulator compilation.

### 9. Environments, install, and generation

Preserve existing target env values. Create missing env files with supplied
values or the dummy `.invalid` defaults; never read/copy reference env values.
`.env.example` contains a dummy origin. `.gitignore` excludes `.env`, `.env.*`
except `.env.example`, generated env secrets, build/tool caches, coverage,
Pods/generated native files, and local AI permissions/worktrees.

Keep AppEnv's dual Envied annotations and per-flavor factory consistent; access
configuration through DI. main() must initialize Flutter bindings, select
AppFlavor.current from `--flavor`, configure dependencies, and run App. No silent
production/development fallback when a native flavor is omitted.

Run equivalent complete setup commands, from the root, in dependency order:

```bash
make setup
```

The setup must create missing env files, resolve the workspace, run
`flutter gen-l10n`, `dart run build_runner build`, and `dart run husky install`.
Use supported options for the installed build_runner; the removed
`--delete-conflicting-outputs` option must not be relied on. After changing env
values, regenerate; if stale, run `dart run build_runner clean` before codegen.
Do not commit generated env values. On a fresh clone, setup must recreate every
required generated file without copying machine state from the source.

### 10. Verify the complete target

Run checks, fix applicable failures, and record actual results/counts in the
plan. Do not report an unrun command as passing or apply old source-project
results to this target. Report toolchain/backend/device limitations precisely.

Required checks:

```bash
flutter analyze
flutter test
(cd packages/app_network && flutter test --no-pub)
(cd packages/app_ui_kit && flutter test --no-pub)
dart format --output=none --set-exit-if-changed lib test packages
git diff --check
```

Also verify:

- UI kit tests include offline network-image loading/cached-success/error/invalid
  URL states and accessibility. No test depends on a live API or image server.
- Root DI constructs core/client dependencies and fresh screen BLoCs; startup,
  home route, unavailable route, themes and supported locales are exercised.
- `.env.development`, `.env.production`, and app_env.g.dart are Git-ignored;
  `.env.example` is not. Inspect ignored/generated output separately from the diff.
- Every copied AI skill symlink resolves; local permissions/credentials were not
  copied. `git config --get core.hooksPath` prints `.husky`.
- Actual commit-msg hook rejects `added stuff` and accepts
  `feat({{EXAMPLE_SCOPE}}): add summary`. Use a unique temporary message file and
  delete only that file afterward. Actual pre-push hook accepts valid pushed
  branch refs and rejects invalid ones; check long-lived, codex, feature/ticket,
  release, uppercase, wrong-prefix, double-hyphen, and overlong cases.
- Run `make create-feature NAME=setup_probe ENTITY=SetupProbe` only after checking
  that name does not exist; analyze its output. Remove only that newly generated
  probe directory afterward, then confirm the working tree contains no probe.
- Installed optional packages have their own tests and native prerequisites
  verified. Unrequested or unavailable capabilities are documented as optional.

Build sequentially, inspecting each finished artifact before the next build
(overwritten iOS output paths must not lose the first flavor's evidence):

```bash
flutter build apk --debug --flavor development
flutter build apk --debug --flavor production
flutter build ios --simulator --debug --flavor development
flutter build ios --simulator --debug --flavor production
```

For APKs use the installed Android SDK's `aapt dump badging` to check app ID,
label and version suffix. For each completed iOS build read Runner.app/Info.plist
with PlistBuddy or plistlib to check CFBundleIdentifier and CFBundleDisplayName.
Check `.dev`/development labels and unchanged production IDs. Compile success
alone does not prove device interaction, signed releases, real backend behavior,
notifications, cloud builds, or repository-host branch protection.

### 11. Completion requirements

- Every required manifest item and baseline capability is implemented or has a
  specific blocker reported. Do not silently reduce this to a tooling-only task.
- App and packages are registered, generated, runnable, and checked; image support
  and API infrastructure are available from the start even with dummy URLs.
- README/AGENTS/docs reflect actual installed APIs and target behavior, with no
  copied reference business features, endpoints, credentials or machine state.
- Verification results and any remaining placeholders are recorded in the plan.
- When maintaining this shared prompt in multiple projects, copy the same bytes
  to every requested location and verify equality/checksums.
- Leave changes uncommitted and do not push. Report what changed, what passed,
  and what still needs real service URLs, app identity/signing, or device checks.
