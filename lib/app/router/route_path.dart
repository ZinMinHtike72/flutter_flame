final class RouterPath {
  RouterPath._();

  static final RouterPath I = RouterPath._();

  final home = const _PathMap("home", "/");
}

final class _PathMap {
  const _PathMap(this.name, this.fullPath);

  final String name;
  final String fullPath;
}
