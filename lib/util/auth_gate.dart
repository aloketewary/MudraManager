import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/providers/auth_service.dart';
import 'package:mudra_manager/screens/profile/pin_entry_dialog.dart'
    show PinEntryDialog;

final _authUnlockedProvider = StateProvider<bool>((ref) => false);

class AuthGate extends ConsumerWidget {
  final Widget child;
  const AuthGate({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlocked = ref.watch(_authUnlockedProvider);
    
    if (!unlocked) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _runAuthFlow(context, ref);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return child;
  }

  Future<void> _runAuthFlow(BuildContext context, WidgetRef ref) async {
    final auth = ref.read(authServiceProvider);

    final pinSet = await auth.hasPin();
    final bioEnabled = await auth.isBiometricEnabled() && await auth.canCheckBiometrics();

    if (pinSet) {
      await _promptPin(context, ref, auth);
    } else if (bioEnabled) {
      final ok = await auth.authenticateBiometric();
      if (!ok) return _runAuthFlow(context, ref);
    }
    ref.read(_authUnlockedProvider.notifier).state = true;
  }

  Future<void> _promptPin(BuildContext context, WidgetRef ref, AuthService auth) async {
    final pin = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PinEntryDialog(length: 4),
    );
    if (pin == null || !await auth.validatePin(pin)) {
      return _runAuthFlow(context, ref);
    }
  }
}
