import "dart:async";

/// Broadcast bridge from shared network callbacks to application session state.
final class SessionExpiryNotifier {
  /// Creates a notifier shared by the auth graph.
  SessionExpiryNotifier();
  final StreamController<void> _controller = StreamController<void>.broadcast();

  /// Terminal session-expiration events.
  Stream<void> get expirations => _controller.stream;

  /// Announces rejection after the host's generation check.
  void notify() => _controller.add(null);

  /// Releases listeners when the host dependency container is disposed.
  Future<void> close() => _controller.close();
}
