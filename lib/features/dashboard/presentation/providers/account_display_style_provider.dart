import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';

enum AccountDisplayStyle { carousel, stack, bento }

final accountDisplayStyleProvider =
    StateNotifierProvider<AccountDisplayStyleNotifier, AccountDisplayStyle>(
  (ref) => AccountDisplayStyleNotifier(),
);

class AccountDisplayStyleNotifier extends StateNotifier<AccountDisplayStyle> {
  AccountDisplayStyleNotifier()
      : super(_fromString(SharedPrefsUtil.instance.getAccountDisplayStyle()));

  static AccountDisplayStyle _fromString(String s) => switch (s) {
        'stack' => AccountDisplayStyle.stack,
        'bento' => AccountDisplayStyle.bento,
        _ => AccountDisplayStyle.carousel,
      };

  void set(AccountDisplayStyle style) {
    SharedPrefsUtil.instance.setAccountDisplayStyle(style.name);
    state = style;
  }
}
