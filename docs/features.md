# Features

Last updated: 2026-11-26

| Feature | Route | UI | Data/API | Tests |
| --- | --- | --- | --- | --- |
| Home | `/` | Localized starter screen with an embedded Flame canvas | Local only; no backend calls | `test/home_bloc_test.dart`, `test/app_test.dart` |

New game areas belong in `lib/features/<feature>/` with domain, data, presentation, and DI layers when those layers have responsibilities. Flame components stay in the owning feature's presentation/game code. Game rules and persistent state belong in domain/data respectively.
