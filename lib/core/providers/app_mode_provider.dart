import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';

enum AppMode { simple, full }

class AppModeNotifier extends Notifier<AppMode> {
  @override
  AppMode build() {
    final stored = SharedPrefsUtil.instance.getAppMode();
    return stored == 'full' ? AppMode.full : AppMode.simple;
  }

  Future<void> setMode(AppMode mode) async {
    await SharedPrefsUtil.instance.setAppMode(mode.name);
    state = mode;
  }
}

final appModeProvider = NotifierProvider<AppModeNotifier, AppMode>(
  AppModeNotifier.new,
);

/// Convenience — true when features should be hidden.
final isSimpleModeProvider = Provider<bool>((ref) {
  return ref.watch(appModeProvider) == AppMode.simple;
});
