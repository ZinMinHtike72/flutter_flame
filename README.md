# Game Test

A Flutter and Flame starter using the DMS Sales Commission project's feature-first Clean Architecture, BLoC, GetIt, go_router, localization, shared UI kit, and network package conventions. The only screen is a localized home page with a Flame canvas. No game backend or business rules have been supplied.

## Setup

```bash
make setup
make run-dev
```

`make setup` creates ignored `.env.development` and `.env.production` files from `.env.example`. Their URLs are placeholders. The Android and iOS projects have `development` and `production` flavors; the VS Code launch profiles pass a flavor.

## Structure

- `lib/app/`: app shell, routes, and dependency registration.
- `lib/core/`: Result and UseCase contracts, environment, secure token storage, network wiring.
- `lib/features/`: feature-first presentation, domain, data, and DI as needed.
- `packages/app_ui_kit/`: shared themes, widgets, and cached network images.
- `packages/app_network/`: shared typed Dio transport and authentication contracts.
- `.agents/skills/` and `.claude/skills/`: Flutter skills plus the local `flame-core` skill.
- `documents/project_structure_prompt.md`: reusable full-project setup prompt copied from the reference project.

See [docs/features.md](docs/features.md), [docs/api.md](docs/api.md), and [docs/development-environment.md](docs/development-environment.md). Future features should follow [AGENTS.md](AGENTS.md).
