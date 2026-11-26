# Development environment

Run `make setup` after cloning. It creates ignored dummy environment files, resolves the workspace, generates localizations and environment code, and installs Git hooks when this is a Git repository. Replace API URLs only when a backend contract exists.

Use `make run-dev` or `make run-prod` on a configured device. Native development and production flavors preserve the base application IDs and add `.dev` to development builds. The repository does not include signing credentials or Firebase configuration.

Use `make analyze`, `make test`, and `make test-packages` for static and unit checks. Device behavior and real service access require separate validation.

`make test` runs `flutter test --enable-vmservice` so the allocation guard in `test/app/performance_test.dart` can read the VM's allocation traces; plain `flutter test` skips that one test. Regenerate packed art with `dart run tool/pack_art.dart` in `packages/yumyum_kitchen` (needs `cwebp`).
