import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';

final hasSeenHelpGuideProvider = StateProvider<bool>((ref) {
  return SharedPrefsUtil.instance.hasSeenHelpGuide();
});

