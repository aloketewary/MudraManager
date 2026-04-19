import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';
import 'package:mudra_manager/core/providers/state_value.dart';

final hasSeenHelpGuideProvider = NotifierProvider<StateValue<bool>, bool>(
  () => StateValue(SharedPrefsUtil.instance.hasSeenHelpGuide()),
);
