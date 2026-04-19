import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Generic replacement for StateProvider in Riverpod 3.x.
///
/// Usage:
/// ```dart
/// // Regular:
/// final myProvider = NotifierProvider<StateValue<int>, int>(
///   () => StateValue(0),
/// );
///
/// // Auto-dispose:
/// final myProvider = NotifierProvider.autoDispose<StateValue<int>, int>(
///   () => StateValue(0),
/// );
///
/// // Read/write:
/// final value = ref.watch(myProvider);
/// ref.read(myProvider.notifier).set(5);
/// ref.read(myProvider.notifier).update((v) => v + 1);
/// ```
class StateValue<T> extends Notifier<T> {
  final T _initial;
  StateValue(this._initial);

  @override
  T build() => _initial;

  void set(T value) => state = value;

  void update(T Function(T current) updater) => state = updater(state);
}
