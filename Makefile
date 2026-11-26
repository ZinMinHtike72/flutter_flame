.PHONY: setup hooks env run-dev run-prod build-apk-dev build-apk-prod build-ipa-dev build-ipa-prod get l10n codegen watch analyze test test-packages coverage goldens format clean create-feature

setup: env get l10n codegen hooks

env:
	@for f in development production; do \
		if [ ! -f .env.$$f ]; then cp .env.example .env.$$f && echo "Created .env.$$f from .env.example — fill in real values."; fi; \
	done

hooks:
	dart run husky install

get:
	flutter pub get

l10n:
	flutter gen-l10n

codegen:
	dart run build_runner build

watch:
	dart run build_runner watch

analyze:
	flutter analyze

test:
	flutter test

test-packages:
	cd packages/app_network && flutter test --no-pub
	cd packages/app_ui_kit && flutter test --no-pub
	cd packages/yumyum_kitchen && flutter test --no-pub

coverage:
	flutter test --coverage
	cd packages/app_network && flutter test --no-pub --coverage
	cd packages/app_ui_kit && flutter test --no-pub --coverage
	cd packages/yumyum_kitchen && flutter test --no-pub --coverage
	dart run scripts/coverage_report.dart --min=85 --files=70

goldens:
	flutter test --update-goldens test/app/screens_golden_test.dart

format:
	dart format lib test packages

clean:
	flutter clean && flutter pub get

create-feature:
	./scripts/create_feature.sh "$(NAME)" "$(ENTITY)"

run-dev:
	flutter run --flavor development

run-prod:
	flutter run --flavor production

build-apk-dev:
	flutter build apk --flavor development

build-apk-prod:
	flutter build apk --flavor production

build-ipa-dev:
	flutter build ipa --flavor development

build-ipa-prod:
	flutter build ipa --flavor production
