import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/providers/auth_service.dart';
import 'package:mudra_manager/screens/profile/pin_entry_dialog.dart'
    show PinEntryDialog;

class AuthGate extends ConsumerStatefulWidget {
  final Widget child;
  const AuthGate({required this.child, Key? key}) : super(key: key);

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  bool _initialized = false;
  bool _unlocked    = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _runAuthFlow();
    }
  }

  Future<void> _runAuthFlow() async {
    final auth = ref.read(authServiceProvider);

    final pinSet = await auth.hasPin();
    final bioEnabled = await auth.isBiometricEnabled() && await auth.canCheckBiometrics();

    // 1) If PIN is set, require PIN entry
    if (pinSet) {
      await _promptPin(auth);
    }
    // 2) Else if biometric is enabled, require biometric
    else if (bioEnabled) {
      final ok = await auth.authenticateBiometric();
      if (!ok) return _runAuthFlow(); // retry on failure
    }
    // 3) Otherwise, no lock configured—just unlock
    setState(() => _unlocked = true);
  }


  Future<void> _promptPin(AuthService auth) async {
    final pin = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PinEntryDialog(length: 4),
    );
    if (pin == null || !await auth.validatePin(pin)) {
      // retry until success
      return _runAuthFlow();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_unlocked) {
      // blank or splash while locking
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return widget.child;
  }
}
