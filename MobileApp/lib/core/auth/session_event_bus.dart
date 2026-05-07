import 'dart:async';

enum SessionEvent { expired }

class SessionEventBus {
  final _controller = StreamController<SessionEvent>.broadcast();

  Stream<SessionEvent> get stream => _controller.stream;

  void emit(SessionEvent event) => _controller.add(event);

  Future<void> dispose() => _controller.close();
}
