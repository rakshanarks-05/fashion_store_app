# Coding standards

## Language and tooling

- **Dart** — follow the [Effective Dart](https://dart.dev/effective-dart) guidance for style, documentation, and usage.
- **Flutter** — prefer idiomatic widget composition; keep `build` methods readable and push logic into models, controllers, or services as complexity grows.

## Linting

This project uses **`flutter_lints`** via `analysis_options.yaml`:

```yaml
include: package:flutter_lints/flutter.yaml
```

- Run **`flutter analyze`** before opening a pull request or merging.
- Prefer fixing lint findings over broad `// ignore` comments; use targeted ignores only with a short reason when necessary.

## Project conventions

- **Feature modules** — new capabilities should live under `lib/features/<feature>/` with `domain/` (entities, repository interfaces, use cases), `data/` (datasources, models, repository implementations), and `presentation/` (Riverpod providers, pages, widgets). Prefer depending “inward”: presentation → domain ← data.
- **Documentation** — when you add or change user-facing features, update [features.md](./features.md) (and [architecture.md](./architecture.md) if folder, routing, or Firestore layout changes) so the `docs/` folder stays accurate.
- **Formatting** — use `dart format .` (or your IDE’s format-on-save) so style stays consistent.
- **Imports** — order and group imports as encouraged by the analyzer / IDE; avoid unused imports.
- **Widgets** — use `const` constructors where possible to reduce rebuild work.
- **Naming** — `UpperCamelCase` for types, `lowerCamelCase` for members, `lower_snake_case` for files (see Effective Dart).
- **Tests** — place tests under `test/`; name files `*_test.dart` to match `flutter test` discovery.

## Dependencies

- Declare packages in `pubspec.yaml` with explicit version constraints appropriate for the team (pinned or ranged).
- Run `flutter pub get` after manifest changes; avoid committing broken dependency states.

## Security and quality

- Do not commit secrets (API keys, tokens, keystores). Use environment-specific configuration or CI secrets.
- Validate and sanitize user input and network data at boundaries (forms, API responses).

## References

- [Dart linter rules](https://dart.dev/lints)
- [Flutter style guide](https://github.com/flutter/flutter/wiki/Style-guide-for-Flutter-repo) (useful patterns; not all rules apply to app repos)
- [Architecture](./architecture.md)
