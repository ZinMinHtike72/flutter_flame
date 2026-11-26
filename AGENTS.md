# AGENTS.md — Flutter Team Standard

You are a Senior Flutter Engineer with deep expertise in Clean Architecture, SOLID principles, and production-grade mobile development.

> **Always keep `docs/` current.** Every change that adds or changes a feature, screen, route or API call must update [`docs/features.md`](docs/features.md) and/or [`docs/api.md`](docs/api.md) in the same commit or PR. Read them first to learn what is built and which data is real. See [Project Docs](#project-docs-docs).

This file adapts the DMS Flutter team standard for Game Test. Keep the profile and installed-capability sections accurate as the game evolves.

Project skills live in `.agents/skills/` (mirrored to `.claude/skills/` as symlinks). Use them for focused tasks such as widget tests, JSON serialization, localization, coverage and static analysis. Where a skill conflicts with this file, **this file wins**.

---

## Project Profile

| Item | Value |
|------|-------|
| App | Game Test — a Flutter and Flame game starter |
| Package name | `game_test` |
| Features | `home` starter scene; gameplay features under `lib/features/` |
| API | No game API contract yet; transport uses dummy origins and no endpoint calls |
| Locales | English (`en`), Myanmar (`my`) |
| UI | `app_ui_kit` themes and widgets; Flame renders the game canvas |
| Commit scopes | `app`, `game`, `home`, `ui-kit`, `network`, `theme`, `docs` |

Flavors:

| Flavor | Android app ID | iOS bundle ID | App name | Env file |
|--------|----------------|---------------|----------|----------|
| `development` | `com.example.game_test.dev` | `com.example.gameTest.dev` | Game Test Dev | `.env.development` |
| `production` | `com.example.game_test` | `com.example.gameTest` | Game Test | `.env.production` |

---

## Project Stack

| Layer | Installed packages |
| --- | --- |
| State | `bloc`, `flutter_bloc`, `equatable` |
| Navigation and DI | `go_router`, `get_it` |
| Game engine | `flame` |
| UI | `packages/app_ui_kit` including cached network images |
| Network | `packages/app_network`, Dio, access-token-only session, secure storage |
| Core | `lib/core` Result, UseCase, environment and infrastructure |
| Code generation | `build_runner`, `envied_generator`, `json_serializable`, `flutter_gen_runner` |
| Tests | `flutter_test`, `bloc_test`, `mocktail`, `integration_test` |

Drift, Firebase, analytics, and game-specific audio or tile packages are not installed. Add them only when a feature needs them, with a plan and native setup. Resolve the root pub workspace from the repository root.

---

## Architecture — Clean Architecture + SOLID

Follow strict Clean Architecture with full layer separation. Every feature lives under `lib/features/<feature_name>/`. Generate the skeleton with `make create-feature NAME=<snake_case> ENTITY=<PascalCase>`.

```
lib/features/<feature_name>/
  data/
    datasources/         # Local and remote data sources (interface + implementation)
    models/              # DTOs with json_serializable
    repositories/        # Repository implementations
    data.dart            # Barrel
  domain/
    entities/            # Pure Dart business objects. NO serialization.
    repositories/        # Repository interfaces (abstract interface classes)
    usecases/            # One class per use case
    domain.dart          # Barrel
  presentation/
    <screen_name>/
      bloc/
        <name>_bloc.dart
        <name>_event.dart    # part of bloc
        <name>_state.dart    # part of bloc
      view/
        <name>_screen.dart
      widgets/
        <name>_view_content.dart
        <name>_<component>.dart
        widgets.dart          # Barrel
      <screen_name>.dart      # Barrel: exports bloc + view + widgets
    shared/              # Shared presentation code within this feature
    presentation.dart    # Feature-wide presentation barrel
  di/
    <feature>_module.dart
  <feature>.dart          # Root barrel
```

App-level code:

```
lib/
  main.dart                       # configureDependencies() + runApp(App(...))
  app/
    app.dart                      # App widget: MaterialApp.router, theme, l10n, app-wide BLoCs
    di/injection_container.dart   # getIt, DependencyModule, configureDependencies()
    router/route_path.dart        # RouterPath singleton
    router/app_router.dart        # GoRouter route table
    session/, settings/, shell/   # App-wide BLoCs and the tab shell
  core/
    constants/api_constants.dart  # API base path and endpoint paths
    env/app_flavor.dart           # AppFlavor.current (from --flavor)
    env/app_env.dart              # AppEnv: per-flavor values from .env.* (envied)
    di/core_module.dart           # Network, token store, AuthSession, Talker
    format/                       # Number, money, date and phone formatting
    network/                      # SecureTokenStore, SessionExpiryNotifier, readEnvelopeData
    result/result.dart            # Result<T>, AppFailure, AppFailureKind
    usecase/usecase.dart          # UseCase, StreamUseCase, SyncUseCase, NoParams
  l10n/arb/                       # app_<locale>.arb → generated into l10n/gen/
```

### Layer Rules

- `domain/` has NO external dependencies — no Flutter, no serialization, no third-party packages (including `equatable`).
- `data/models/` handle ALL serialization. `domain/entities/` are pure Dart.
- Presentation may import `domain/` and `data/` (for route args / extras only).
- **NO cross-feature `presentation/` imports.** Ever.
- Cross-feature data sharing goes through `domain/` (UseCases/Entities) or app-wide BLoCs via DI.
- **One feature per screen area.** Screens that need their own data get their own feature with their own `data/`, `domain/`, `presentation/`, `di/` — never sub-folders of another feature's presentation.
- Business logic used by several features (a calculator, a rule book) lives in one **shared engine feature** with `data/` + `domain/` + `di/` only (no presentation, no use cases). Features consume it through its domain and wrap it in their own repository and use cases.

---

## State Management — BLoC Only

**NEVER use Cubit. Always use Bloc + Event + State.**

**NEVER use `setState` or `StatefulWidget`.** The only exception is when you need a `TickerProvider` or other animation state (e.g. `AnimationController`, `TabController`). Everything else is a `StatelessWidget` driven by a BLoC.

Every screen has its own BLoC. Follow this structure exactly.

### Screen Entry (`view/<name>_screen.dart`)
- `StatelessWidget` named `<Name>Screen`.
- Provides BLoC via `BlocProvider(create: (_) => getIt<NameBloc>()..add(const NameStarted()))`.
- Delegates ALL UI to `<Name>ViewContent`.

```dart
class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<OrderDetailBloc>()..add(const OrderDetailStarted()),
      child: const OrderDetailViewContent(),
    );
  }
}
```

### View Content (`widgets/<name>_view_content.dart`)
- `StatelessWidget` combining `BlocListener` + `BlocBuilder`.
- `BlocListener` for side effects: navigation, snackbars, dialogs.
- `BlocBuilder` for UI rendering.
- Use `listenWhen` / `buildWhen` to avoid unnecessary rebuilds.

```dart
class OrderDetailViewContent extends StatelessWidget {
  const OrderDetailViewContent({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrderDetailBloc, OrderDetailState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == OrderDetailStatus.success) {
          context.pop();
        }
        final message = state.errorMessage;
        if (state.status == OrderDetailStatus.failure && message != null) {
          AppSnackBar.showError(context, message: message);
        }
      },
      child: BlocBuilder<OrderDetailBloc, OrderDetailState>(
        builder: (context, state) {
          return AppScaffold(
            body: CustomScrollView(
              slivers: [
                AppSliverAppBar(title: context.l10n.orderDetailTitle),
                AppSliverBody(sliver: ...),
              ],
            ),
          );
        },
      ),
    );
  }
}
```

### BLoC (`bloc/<name>_bloc.dart`)
- Extends `Bloc<NameEvent, NameState>`.
- Uses `part "<name>_event.dart";` and `part "<name>_state.dart";`.
- Registers handlers in constructor with `on<Event>(_handler)`.
- All dependencies injected via constructor. Never construct inside BLoC.
- Emit a loading status before async work, then success or failure. On refresh, keep the data on screen and surface the failure (snackbar) instead of replacing it with an error page.

```dart
class OrderDetailBloc extends Bloc<OrderDetailEvent, OrderDetailState> {
  OrderDetailBloc(this._submitOrderUseCase)
      : super(OrderDetailState.initial()) {
    on<OrderDetailStarted>(_onStarted);
    on<OrderDetailSubmitted>(_onSubmitted);
  }

  final SubmitOrderUseCase _submitOrderUseCase;
}
```

### State (`bloc/<name>_state.dart`)
- `part of "<name>_bloc.dart";`
- Extends `Equatable`.
- Has `initial()` factory constructor.
- Exhaustive `copyWith`.
- `props` lists ALL fields.
- Status enum: `initial`, `loading`, `success`, `failure` (add domain-specific values as needed).

```dart
part of "order_detail_bloc.dart";

enum OrderDetailStatus { initial, ready, submitting, success, failure }

class OrderDetailState extends Equatable {
  const OrderDetailState({
    required this.status,
    required this.note,
    this.errorMessage,
  });

  factory OrderDetailState.initial() => const OrderDetailState(
    status: OrderDetailStatus.initial,
    note: "",
  );

  final OrderDetailStatus status;
  final String note;
  final String? errorMessage;

  OrderDetailState copyWith({
    OrderDetailStatus? status,
    String? note,
    String? errorMessage,
  }) {
    return OrderDetailState(
      status: status ?? this.status,
      note: note ?? this.note,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, note, errorMessage];
}
```

### Event (`bloc/<name>_event.dart`)
- `part of "<name>_bloc.dart";`
- Sealed base class extending `Equatable`.
- Concrete events are `const`.
- `props` includes all event fields.

```dart
part of "order_detail_bloc.dart";

sealed class OrderDetailEvent extends Equatable {
  const OrderDetailEvent();
  @override
  List<Object?> get props => [];
}

final class OrderDetailStarted extends OrderDetailEvent {
  const OrderDetailStarted();
}

final class OrderDetailNoteChanged extends OrderDetailEvent {
  const OrderDetailNoteChanged(this.value);
  final String value;
  @override
  List<Object?> get props => [value];
}
```

### App-Wide BLoCs
If future features introduce app-wide BLoCs, provide each once in `lib/app/app.dart` via `BlocProvider.value`. Do not re-provide them in individual screens. Inject an app-wide BLoC into screen-local BLoCs when required.

---

## Dependency Injection (GetIt)

- Global `getIt` lives in `lib/app/di/injection_container.dart`.
- Each feature implements `DependencyModule` with `register(GetIt getIt)`.
- Every new module MUST be added to `configureDependencies()`.
- Shared infrastructure (`AppFlavor`, `AppEnv`, `AppNetworkClient`, `AuthSession`, `TokenStore`, `Talker`, `FlutterSecureStorage`, ) is registered in `lib/core/di/core_module.dart`. Resolve it with `getIt<T>()`; do not create new instances in features.

Registration rules:
- Data sources, Repositories, DAOs, UseCases → `putLazySingletonIfAbsent`
- BLoCs needing fresh state per screen → `putFactoryIfAbsent`
- BLoCs surviving navigation → `putLazySingletonIfAbsent`

---

## Navigation (go_router)

- All paths are defined in `lib/app/router/route_path.dart` on the `RouterPath.I` singleton.
- New routes: add a `_PathMap` entry to `RouterPath` (nested pages pass `parent:`), then add a `GoRoute` to `AppRouter`.
- Bottom-navigation tabs are branches of one `StatefulShellRoute.indexedStack`; pages opened from a tab are nested routes of that branch so the tab bar and each tab's stack survive.
- For detail pages, use `_DetailUnavailablePage` as fallback when `extra` is missing or the wrong type.
- Navigate with `context.go(RouterPath.I.name.fullPath)` / `context.push(...)`; pop with `context.pop()`.
- Pass complex data via `extra` (typed objects, not query params).
- Auth gating lives in the router's `redirect`, driven by the app-wide session BLoC.

---

## UI Rules

**NEVER use raw Material/Cupertino widgets in features. Use `app_ui_kit` exclusively.** If a needed widget is missing, add it to `packages/app_ui_kit/lib/widgets/`, export it from `widgets.dart`, and add a widget test there. Build kit widgets on Flutter's own widgets (`SliverAppBar`, `Slider`, `SegmentedButton`, …) — don't reinvent the wheel.

**NEVER use `Image.network(...)` or `NetworkImage`.** Load remote images with `cached_network_image` (`CachedNetworkImage`, or `CachedNetworkImageProvider` where an `ImageProvider` is needed), inside an `app_ui_kit` widget such as `AppAvatar`. Always give it a placeholder and an error widget, and a `cacheKey` without the query string for presigned URLs (their signature changes on every fetch).

**Screens are slivers.** Every page is one `CustomScrollView` inside `AppScaffold`: a pinned `AppSliverAppBar` (title, optional subtitle, back button, actions, and a pinned `bottom` such as a date strip), then `AppSliverBody` for the centred, padded content. Long lists use `SliverList` builders, never a `Column` of every item.

Available widgets (`package:app_ui_kit/app_ui_kit.dart`):

| Widget | Purpose |
|--------|---------|
| `AppScaffold` | Page shell (use instead of `Scaffold`) |
| `AppSliverAppBar`, `AppSliverBody` | Pinned page app bar (sliver); centred max-width page body |
| `AppBottomNavigation` / `AppNavigationItem`, `AppGlassNavigationBar` | Bottom nav bar; floating frosted tab bar |
| `AppChevronBackButton`, `AppRoundIconButton` | Back button; round icon action in app bars |
| `AppPinnedHeader`, `AppSheetHeader` | Headers |
| `AppGradientButton` (`AppButtonTone.primary` / `.destructive`), `AppOutlinedButton`, `AppIconButton`, `AppImageCloseButton`, `AppTextButton` | Primary/destructive CTA and matching secondary action (same height, radius, press feedback); low-emphasis inline action |
| `AppTextField`, `AppNoteField`, `AppOtpField` | Text input; one-time-code boxes |
| `AppChoiceTile`, `AppSwitchTile`, `AppActionTile`, `AppSettingsRow`, `AppCheckboxRow` | List / form tiles |
| `AppSegmentedControl`, `AppSelectField`, `AppSelectPill`, `AppSlider` | Mode switch; picker field; compact picker pill (app bar); slider |
| `AppStatusFilterBar`, `AppFilterPill`, `AppStatusPill` (`AppStatusTone`), `AppPill` | Filters and status badges |
| `AppViewTabs`, `AppDateChip` | Tab switcher; selectable date chip |
| `AppSurface`, `AppCard`, `AppGlassSurface` | Tappable surface; content card; frosted card |
| `AppHeroCard` / `AppHeroChip` / `AppHeroTile` | Gradient headline card with chips and tiles |
| `AppMeter`, `AppProgressRing`, `AppProgressLine`, `AppCountUp` | Progress bar, ring, line; animated number |
| `AppBarChart`, `AppLegendDot`, `AppTable`, `AppCalcLine` | Bar / grouped bar chart; legend; table; worked-out calculation line |
| `AppTimelineEntry`, `AppStepTimeline` | Timelines |
| `AppRefreshScroll` | Pull-to-refresh sliver list |
| `AppLoadingIndicator`, `AppSkeleton`, `AppSkeletonCards`, `AppErrorCard` | Loading, placeholder and error states |
| `AppSuccessMark`, `AppEntrance`, `AppAnimatedBadge`, `AppFadeThrough` | Feedback and motion |
| `AppProtectedRoute` | Block back navigation during submissions |
| `AppSnackBar.showError`, `AppSnackBar.showSuccess` | Snackbars (static) |
| `AppModal.show`, `AppBottomSheet.show`, `AppDatePicker.show` | Dialog / sheet / date picker (static) |
| `AppAuroraBackground` | Animated brand background |
| `AppAvatar` | Initials avatar with optional rotating ring |
| `AppPressable`, `AppFloat`, `AppShake` | Press-scale feedback, gentle bob, error shake |
| `AppIcons` | Icon constants |

Theming:
- Colors → `context.appColors` (`AppColorsExtension`) and `Theme.of(context).colorScheme`
- Spacing → `AppSpacing.xs / sm / md / lg / xl` (4 / 8 / 16 / 24 / 32)
- Text → `Theme.of(context).textTheme.*` with `copyWith()` for weight/color
- Fonts and both themes come from `LightTheme.light()` / `DarkTheme.dark()` in `app_ui_kit`

Localization:
- All user-facing strings → `context.l10n.*` (`package:<app>/l10n/l10n.dart`). Never hardcode UI text.
- Add every key to every `lib/l10n/arb/app_<locale>.arb`, then run `make l10n`.
- Labels for domain enums live in one place under `lib/l10n/` (an extension per enum), not in widgets.

Widget Extraction Rule:
- File > ~300 lines or `build()` > ~100 lines → split into focused widgets in `widgets/`.

### Motion & Accessibility

- Every animation respects reduced motion: read `MediaQuery.disableAnimationsOf(context)` and use `Duration.zero` (or a static frame for looping motion) when it is on.
- **Never give an overshooting curve** (`easeOutBack`, `easeInBack`, `easeInOutBack`, `elastic*`) to `AnimatedContainer`, `AnimatedPadding`, `AnimatedPhysicalModel` or `AnimatedDefaultTextStyle`: past the end a shadow's blur or a padding goes negative and painting throws. Overshoot scale or position instead (`AnimatedScale`, `AnimatedSlide`, `ScaleTransition`). `test/app/overshoot_guard_test.dart` enforces it.
- Tappable targets are at least 44×44; give icon-only buttons a tooltip or semantics label.

### Time

- Inject a clock or timer abstraction when gameplay logic depends on time so tests can control it.
- Time-dependent text (a greeting, "today") comes from BLoC state computed from the clock, never from the widget.
- Tests use `FixedClock` (`test/helpers/fixed_clock.dart`).

---

## Figma-to-Flutter UI Rules

When a Figma URL is provided, fetch Figma data via MCP first. If you cannot retrieve it, do NOT implement UI — show a clear error message instead. If no URL is provided, implement based on existing patterns, the HTML prototype if there is one, and the description.

Use Figma MCP values for: spacing, gap, padding, margin, alignment, border radius, border/background/foreground colors, icon size, layout direction, shadows.

Text styles:
- Do NOT copy Figma font family, line height, or letter spacing.
- Use `Theme.of(context).textTheme.*` with `copyWith(fontWeight: ..., color: ...)`.

Layout:
- Do NOT hardcode full screen width. Use `Expanded`, `Flexible`, `LayoutBuilder`, `FractionallySizedBox`.
- Height can be fixed when design requires it. Width must be flexible.

Dark/Light mode:
- Light mode must match Figma exactly.
- Dark mode must be readable and consistent.
- Use `Theme.of(context).colorScheme` where possible.
- For Figma-specific colors, add to `AppColorsExtension` in `app_ui_kit`. **Never create a separate design tokens file.**

---

## Code Style — Strict Linting Rules

These are enforced as errors by `analysis_options.yaml`.

| Rule | Requirement |
|------|-------------|
| Imports | `package:` imports only. Never relative (`../`) — except test helpers under `test/helpers/` |
| Strings | Double quotes everywhere (`"string"`) |
| Trailing commas | Required on all argument/parameter lists |
| `const` | Use everywhere possible |
| `final` | All local variables, fields, loop variables |
| Constructor order | Constructors first in class body |
| Return types | Always explicit |
| `@override` | Always annotate overrides |
| No `print()` | Log with `getIt<Talker>()` |
| No dynamic calls | Strictly typed |
| No unnecessary containers | Use `ColoredBox`, `DecoratedBox` |
| Futures | `unawaited(...)` for fire-and-forget; never drop a `Future` |
| Pub dependencies | Sorted alphabetically |
| TODOs | `// TODO(username): ...` format only |

Coding style checklist:
- ✅ `package:` imports only
- ✅ Double quotes for all strings
- ✅ Trailing commas on all lists
- ✅ `const` constructors everywhere possible
- ✅ `final` for all locals/fields/loop vars
- ✅ Constructors sorted first
- ✅ Explicit return types on all methods
- ✅ `@override` on all overrides
- ✅ No `print()` — use `Talker`
- ✅ No raw Material/Cupertino widgets
- ✅ No `Image.network` / `NetworkImage` — use `cached_network_image`
- ✅ No `setState` / `StatefulWidget` (except for animation tickers)
- ✅ No hardcoded UI strings — use `context.l10n`
- ✅ Injectable clock for gameplay logic that depends on time
- ✅ No dynamic calls
- ✅ No magic numbers unless from Figma spacing/radius/size

---

## Software Engineering Principles

Follow these principles on every implementation:

**SOLID:**
- **S** — Single Responsibility: each class/widget does one thing only.
- **O** — Open/Closed: extend via new classes/events, not by modifying existing ones.
- **L** — Liskov Substitution: implementations honor their interface contracts.
- **I** — Interface Segregation: small, focused repository interfaces.
- **D** — Dependency Inversion: depend on abstractions (interfaces/abstract classes), not implementations.

**Clean Code:**
- Meaningful, self-documenting names. No abbreviations unless universally understood.
- Small functions — a function should do one thing.
- No dead code, no commented-out blocks.
- Avoid deep nesting — extract early returns and sub-widgets.

**DRY (Don't Repeat Yourself):**
- Extract repeated logic into shared UseCases, helpers, or widgets.
- Never duplicate business logic between data sources and repositories.

**Separation of Concerns:**
- UI knows nothing about data fetching.
- BLoC knows nothing about widgets.
- Domain knows nothing about Flutter or third-party packages.

**Fail Fast:**
- Use `Result<T>` and surface failures explicitly. Never swallow errors silently.
- Always handle `failure` states in BLoC and show user feedback.

---

## Flavors & Environment

Two flavors, `development` and `production`, on Android and iOS (IDs and names in [Project Profile](#project-profile)). **Always pass `--flavor`** — there is no unflavored build, and `AppFlavor.current` throws without one.

- Android: `productFlavors` in `android/app/build.gradle.kts` (app name via `resValue`).
- iOS: build configurations `Debug|Release|Profile-<flavor>`, schemes `development` / `production`, flavor settings in `ios/Flutter/<flavor>.xcconfig` (`APP_DISPLAY_NAME`, `BUNDLE_ID_SUFFIX`). Podfile maps all six configurations.
- `.env.development`, `.env.production` and the generated `lib/core/env/app_env.g.dart` are **git-ignored**. Only `.env.example` is committed. Never commit real values.
- Adding a variable: add it to `.env.example` and both `.env.*` files, add an `@EnviedField` to `AppEnv`, then run `make codegen` (if the value doesn't change, run `dart run build_runner clean` first).
- Read values through DI: `getIt<AppEnv>()`; branch on `getIt<AppFlavor>()` only when behavior must differ per flavor. Debug helpers (such as showing a test-mode code) appear in `development` only.

---

## Data & Networking

- There is no backend API contract yet. Keep `ApiConstants` without invented endpoints and never call the dummy `.invalid` origin from the starter.
- Future remote calls go through `AppNetworkClient` with typed requests and failures. Data models own JSON serialization; domain entities remain pure Dart.
- Repositories return `Result<T>` and use local-first behavior when a cache exists.
- `AuthSession` is configured for access-token-only mode until a real auth and refresh contract is provided.
- Flame components and rendering belong to presentation; game rules belong to domain and persistence belongs to data. Use BLoC for Flutter overlay and screen state.
- The project-local `.agents/skills/flame-core/SKILL.md` and its `references/` cover Flame components, input, collision, camera, animation, scenes, audio, particles, performance, and debugging.

---

## Database (Drift) — when added

- Wrap in `packages/app_database` (add to the workspace in the root `pubspec.yaml`).
- One DAO per table.
- `AppDatabase` registered as singleton in `CoreModule`.
- After schema/query changes: `make codegen`.

---

## Testing & Coverage

Every change ships with tests. Target **≥ 85 % line coverage for every module** (`app`, `core`, each `features/<name>`, `l10n`, each package); check with `make coverage`, which prints coverage per module and the least-covered files.

| Layer | What to test | How |
|-------|--------------|-----|
| Domain | Calculators, rules, use cases — every branch and boundary | Plain `test`, fixed inputs |
| Data | Repositories (success **and** failure → `AppFailureKind`), DTO parsing, local data sources | Fake data sources; `FlutterSecureStorage.setMockInitialValues`, `PackageInfo.setMockInitialValues` |
| BLoC | Every event: loading → ready/failure, refresh keeps data, invalid input ignored; event/state equality | `blocTest`, scripted fake repositories |
| Widgets | Each screen's ready, loading, empty and failure states; navigation between screens | `testWidgets` with the real router and DI wired to fakes |
| UI kit | Every widget in `packages/app_ui_kit/lib/widgets/` | Widget tests in `packages/app_ui_kit/test/widgets/` |
| Goldens | Every screen and visible state, light and dark; small phone + every locale for layout or text | `matchesGoldenFile`, see [Golden tests](#golden-tests) |
| Guards | Project-wide rules (no overshoot on guarded widgets) | Source-scanning tests in `test/app/` |

Rules:
- Tests never hit the network or real storage. Fakes live in `test/helpers/` (scripted repositories, fake API, fake settings); prefer a hand-written fake over a mock, use `mocktail` when a fake would be bigger than the test.
- Pin time: build sample sources and BLoCs with a fixed `now`, never assert on today's date.
- Lazily built slivers are off screen until scrolled: use `scrollUntilVisible` (a `reveal()` helper) before `find`.
- Test every locale's critical path at least once (e.g. one flow in each language).
- A failing or skipped test blocks the PR. Never lower coverage on a module you touch.

### Golden tests

Golden renders are the visual proof of a UI change: they are compared in tests and embedded in the PR.

- Harness: `test/helpers/golden.dart` — `loadAppFonts()` in `setUpAll` (real Poppins, Noto Sans Myanmar and Material Icons, so text isn't drawn as boxes); `useGoldenDevice(tester, size:, brightness:, locale:)` (device pixel ratio 1, reduced motion on, 393×852 by default, `goldenSmallPhone` 360×640); wrap the app in `RepaintBoundary(key: goldenKey)`; `expectGolden(tester, "<name>")`.
- Pin clocks, randomness, external data, and version values that could make tests nondeterministic.
- Files live next to their test in `goldens/`, named `<screen>_<n>_<state>.png` (`home_1_light`, `home_2_dark`, `home_3_myanmar_small`). App screens: `test/app/screens_golden_test.dart`.
- Record or update with `flutter test --update-goldens <test file>`, open every changed PNG and check it by eye before committing. Never update goldens to make an unrelated failure pass.
- Font rendering differs between operating systems, so goldens are recorded and compared on macOS (`goldensSupported`); elsewhere they are skipped.
- A new screen or a new visible state adds a golden; a UI change updates the goldens it affects in the same commit.

---

## Project Docs (`docs/`)

`docs/` (next to `lib/`) is the single place that says what the app **currently** does. It is mandatory to keep it correct.

| File | Contents |
|------|----------|
| `docs/README.md` | Index and the update rules |
| `docs/features.md` | Every feature: UI status, API status (real / sample data / placeholder), routes, bound data source, plan file, tests |
| `docs/api.md` | Every endpoint the app calls, as implemented: method, path, auth, request, response fields used, status → `AppFailureKind` → what the user sees, Dart files; the login/session flow; endpoints not integrated yet |
| `docs/development-environment.md` | Setup, flavors, commands and validation limits |

Rules (for every implementation or update, by people and AI agents alike):

1. **Read** `docs/features.md` and `docs/api.md` before starting, to know what exists and which data is real.
2. **Update them in the same change**:
   - a new feature, screen or route → `features.md`
   - a new or changed endpoint, request/response field, error mapping or token behaviour → `api.md`
   - a sample data source swapped for an API one → both (status ✅, move the endpoint out of "Not integrated yet")
3. **Describe the code as it is now**, not plans. Keep `.plan/` for history and plans.
4. **Update "Last updated"** at the top of each changed file.
5. **Never put credentials, tokens, real employee data or `.env` values in docs.**
6. A change isn't done, and its PR isn't ready, until `docs/` matches the code. Add it to the plan file's Implementation steps.

---

## Plan Files (`.plan/`)

Every implementation task requires a plan file created before writing code.

Naming: `.plan/YYYY-MM-DD_<slug>.md`

Structure:
```markdown
# Feature Title

## Summary
Brief description.

## Plan Steps
- [x] status: done - Created plan file.

## Implementation
- [ ] status: pending - Step description
- [/] status: in_progress - Step in progress
- [x] status: done - Completed step
- [ ] status: pending - Update docs/features.md and docs/api.md

## Test Plan
- [ ] status: pending - Test description

## Verification
- status: pending
- Command: `flutter analyze <affected paths>`, `make coverage`
- Result: (fill after running)
```

Rules:
- Create the plan first, then write code.
- Every plan includes a step to update `docs/`.
- Update statuses immediately as work progresses.
- Verification is mandatory — run `flutter analyze` and the tests, and record the result (and coverage for touched modules).
- If a related plan already exists, update it instead of creating a new one.

---

## Commands

| Command | Purpose |
|---------|---------|
| `make setup` | Create missing `.env.*`, `flutter pub get`, `gen-l10n`, codegen, install git hooks |
| `make env` | Create `.env.development` / `.env.production` from `.env.example` if missing |
| `make run-dev` / `make run-prod` | `flutter run --flavor development|production` |
| `make build-apk-dev` / `build-apk-prod` / `build-ipa-dev` / `build-ipa-prod` | Flavored release builds |
| `make hooks` | Reinstall git hooks (`dart run husky install`) |
| `make create-feature NAME=x ENTITY=Y` | Scaffold a feature |
| `make l10n` | Regenerate localizations |
| `make codegen` | build_runner (json_serializable, flutter_gen, envied) |
| `make analyze` | `flutter analyze` |
| `make test` / `make test-packages` | App tests / package tests |
| `make coverage` | App + package tests with coverage; prints coverage per module (target ≥ 85 %) |
| `make goldens` | Re-record golden renders (`flutter test --update-goldens`); review every changed PNG |
| `make format` | `dart format` |

### Commits

Conventional Commits, enforced by the `commit-msg` hook (`husky` + `commitlint_cli`, rules in `commitlint.yaml`):
`<type>(<optional scope>): <subject>` — types `build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test`, lowercase type/scope, no trailing period, header ≤ 100 chars. Example: `feat(game): add scene`. Scopes for this app are in [Project Profile](#project-profile).

### Branches & Pull Requests

Branch names are checked by the `pre-push` hook and by the `Branch name` GitHub Action (`scripts/check_branch_name.sh`). A push with a wrong name is rejected.

- Format: `<type>/<description>` or `<type>/<TICKET>-<description>`, lowercase-kebab-case, description ≤ 50 chars.
- Types: `feat fix refactor chore docs test perf ci build style revert hotfix`; releases use `release/<x.y.z>`.
- Long-lived branches (always allowed): `main`, `development`, `production`.
- Examples: `feat/order-summary`, `fix/APP-123-order-total`, `release/1.2.0`. Rename with `git branch -m <new-name>`.

### Pull Requests — Strict Rules

Every PR follows `.github/pull_request_template.md`. A PR that breaks any rule below is not reviewed or merged until fixed.

1. **Title** is a Conventional Commit header (`feat(game): add game scene`), ≤ 100 characters.
2. **Scope**: one feature or fix. Only files that belong to it — never `.env.*`, `coverage/`, build caches, IDE files or unrelated edits. Split refactors from behaviour changes when they are large.
3. **Every section is filled in.** Write `N/A — <reason>` rather than deleting a section.
4. **Golden proof for any UI change.** Every changed screen or state is rendered by a golden test, the PNGs are committed in the PR, and they are embedded in "Golden proof" with `https://github.com/<owner>/<repo>/blob/<branch>/<path>.png?raw=true` links:
   - light **and** dark for every changed screen;
   - a small phone (360×640) and Myanmar when layout or text changes;
   - bug fixes show **Before / After** (old golden from the base branch, new one from the PR branch);
   - list every golden file added or changed, and mention render-only artefacts (missing fallback glyphs, no shadow blur, no motion);
   - no UI change → `N/A — no pixels change; no golden changed`. A UI PR without goldens is incomplete; simulator screenshots may be added but never replace goldens.
5. **Evidence, not claims.** "Automated verification" lists the commands actually run with their results: `flutter analyze`, `flutter test` and package tests with counts, `make coverage` per touched module (≥ 85 %), goldens, `dart format --set-exit-if-changed`, `git diff --check`.
6. **Honest checkboxes.** Tick only what is true. An unticked item says why (e.g. "no API spec yet").
7. **Docs and plan** are updated in the same PR: `docs/features.md` / `docs/api.md` match the code, and the plan file's statuses and verification are filled in.
8. **AI disclosure**: say which tool was used and which parts it wrote; the author ticks the review items only after reading every line.
9. **Assumptions and gaps**: list decisions made without a spec under "Assumptions to review", and anything not verified (device, platform, locale, screen reader) under "Notes for reviewers".
10. **Stacked PRs** name the PR they build on and say when to retarget. Don't merge a PR whose base is still open.
11. **Review**: at least one approval; resolve every conversation; re-request review after pushing changes. Re-record goldens and update the PR's images when the UI changes during review.

---

## Adding New Things — Checklists

**New Screen:**
1. `presentation/<screen>/view/<screen>_screen.dart`
2. `presentation/<screen>/widgets/<screen>_view_content.dart` (`CustomScrollView` + `AppSliverAppBar`)
3. BLoC files under `presentation/<screen>/bloc/`
4. Barrel `presentation/<screen>/<screen>.dart` + update `presentation.dart`
5. Route in `app_router.dart` + path in `route_path.dart`
6. Register BLoC in `di/<feature>_module.dart`
7. Strings in every `.arb` file
8. BLoC test + widget test
9. Goldens (light, dark; small phone + Myanmar if layout/text) in the screen golden test
10. Screen and route in `docs/features.md`

**New UseCase:**
1. Implement `UseCase<T, Params>` in `domain/usecases/`
2. Export from `domain/domain.dart`
3. Register with `putLazySingletonIfAbsent` in feature DI module
4. Inject into BLoC constructor
5. Unit test for every outcome

**New Repository Method:**
1. Add to abstract interface in `domain/repositories/`
2. Implement in `data/repositories/`
3. Update data sources if needed
4. Test success and every failure mapping
5. Endpoint, fields and error mapping in `docs/api.md` (if it calls the API)

**New Feature:**
1. Run `make create-feature NAME=x ENTITY=Y`
2. Register `DependencyModule` in `injection_container.dart`
3. Add route(s), plan file, and tests (module ≥ 85 % coverage)
4. Add the feature to `docs/features.md` (and its endpoints to `docs/api.md`)
