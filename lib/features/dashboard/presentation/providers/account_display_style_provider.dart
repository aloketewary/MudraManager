import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';

enum AccountDisplayStyle { carousel, stack, bento }

final accountDisplayStyleProvider =
    NotifierProvider<AccountDisplayStyleNotifier, AccountDisplayStyle>(
  AccountDisplayStyleNotifier.new,
);

class AccountDisplayStyleNotifier extends Notifier<AccountDisplayStyle> {
  static AccountDisplayStyle _fromString(String s) => switch (s) {
        'stack' => AccountDisplayStyle.stack,
        'bento' => AccountDisplayStyle.bento,
        _ => AccountDisplayStyle.carousel,
      };

  @override
  AccountDisplayStyle build() {
    return _fromString(SharedPrefsUtil.instance.getAccountDisplayStyle());
  }

  void set(AccountDisplayStyle style) {
    SharedPrefsUtil.instance.setAccountDisplayStyle(style.name);
    state = style;
  }
}
