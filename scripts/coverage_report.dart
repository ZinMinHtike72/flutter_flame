import "dart:io";

/// Merge Flutter LCOV records, including duplicate observations across suites.
/// Generated code and dependencies outside this workspace are excluded.
void main(List<String> arguments) {
  final minimum = double.parse(
    arguments
        .firstWhere((a) => a.startsWith("--min="), orElse: () => "--min=85")
        .substring(6),
  );
  final limit = int.parse(
    arguments
        .firstWhere((a) => a.startsWith("--files="), orElse: () => "--files=10")
        .substring(8),
  );
  final root = Directory.current.absolute.path;
  final files = <String, Map<int, int>>{};
  final suites = [
    ".",
    "packages/app_network",
    "packages/app_ui_kit",
    "packages/yumyum_kitchen",
  ];
  for (final suite in suites) {
    final report = File("$suite/coverage/lcov.info");
    if (!report.existsSync()) {
      stderr.writeln("Missing ${report.path}");
      exitCode = 1;
      continue;
    }
    Map<int, int>? lines;
    for (final row in report.readAsLinesSync()) {
      if (row.startsWith("SF:")) {
        lines = null;
        final name = row.substring(3);
        final absolute = Uri.file(
          "${Directory(suite).absolute.path}/",
        ).resolve(name).normalizePath().toFilePath();
        if (!absolute.startsWith("$root/")) {
          continue;
        }
        final path = absolute.substring(root.length + 1);
        if (!RegExp(r"^(lib/|packages/[^/]+/lib/)").hasMatch(path) ||
            path.endsWith(".g.dart") ||
            path.contains("/gen/")) {
          continue;
        }
        lines = files.putIfAbsent(path, () => {});
      } else if (row.startsWith("DA:") && lines != null) {
        final parts = row.substring(3).split(",");
        final n = int.parse(parts[0]);
        lines[n] = (lines[n] ?? 0) + int.parse(parts[1]);
      }
    }
  }
  final modules = <String, (int, int)>{};
  for (final entry in files.entries) {
    final path = entry.key.split("/");
    final module = path.first == "packages"
        ? path[1]
        : path[1] == "features"
        ? "features/${path[2]}"
        : path[1].endsWith(".dart")
        ? "app"
        : path[1];
    final old = modules[module] ?? (0, 0);
    modules[module] = (
      old.$1 + entry.value.values.where((n) => n > 0).length,
      old.$2 + entry.value.length,
    );
  }
  if (modules.isEmpty) {
    stderr.writeln("No executable source lines measured.");
    exitCode = 1;
  }
  for (final module in modules.keys.toList()..sort()) {
    final (hit, total) = modules[module]!;
    if (total == 0) {
      continue;
    }
    final percent = 100 * hit / total;
    stdout.writeln("$module ${percent.toStringAsFixed(1)}% ($hit/$total)");
    if (percent < minimum) {
      exitCode = 1;
    }
  }
  final uncovered =
      files.entries
          .map(
            (e) => MapEntry(e.key, e.value.values.where((v) => v == 0).length),
          )
          .where((e) => e.value > 0)
          .toList()
        ..sort((a, b) => b.value.compareTo(a.value));
  for (final file in uncovered.take(limit)) {
    stdout.writeln("${file.value} uncovered lines: ${file.key}");
  }
}
