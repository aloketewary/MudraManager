import 'dart:async';

class Event {
  final String type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  Event(this.type, this.data) : timestamp = DateTime.now();
}

class EventBus {
  static final EventBus _instance = EventBus._();
  factory EventBus() => _instance;
  EventBus._();

  final _controller = StreamController<Event>.broadcast();
  Stream<Event> get stream => _controller.stream;

  void emit(String type, Map<String, dynamic> data) {
    _controller.add(Event(type, data));
  }

  StreamSubscription<Event> on(String type, Function(Event) handler) {
    return stream.where((e) => e.type == type).listen(handler);
  }

  void dispose() => _controller.close();
}
