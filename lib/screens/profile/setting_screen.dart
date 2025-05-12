import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/providers/auth_service.dart';
import 'package:mudra_manager/screens/profile/pin_entry_dialog.dart';

class SecuritySettingsScreen extends ConsumerStatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  ConsumerState<SecuritySettingsScreen> createState() =>
      _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState
    extends ConsumerState<SecuritySettingsScreen> {
  bool _biometricAvailable = false;
  bool _pinEnabled = false;
  bool _bioEnabled = false; // <— add this

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final auth = ref.read(authServiceProvider);
    final canBio = await auth.canCheckBiometrics();
    final hasPin = await auth.hasPin();
    final bioOn = await auth.isBiometricEnabled(); // <— read from storage

    setState(() {
      _biometricAvailable = canBio;
      _pinEnabled = hasPin;
      _bioEnabled = bioOn;
    });
  }

  Future<void> _toggleBiometric(bool on) async {
    final auth = ref.read(authServiceProvider);
    if (on) {
      // ask once to confirm
      final ok = await auth.authenticateBiometric();
      if (!ok) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Biometric auth failed')));
        return;
      }
    }
    await auth.setBiometricEnabled(on);
    setState(() => _bioEnabled = on);
  }

  Future<void> _togglePin(bool on) async {
    final auth = ref.read(authServiceProvider);
    if (on) {
      final pin = await showDialog<String>(
        context: context,
        builder: (_) => const PinEntryDialog(length: 4),
      );
      if (pin == null || pin.length < 4) return;
      await auth.setPin(pin);
    } else {
      await auth.clearPin();
    }
    setState(() => _pinEnabled = on);
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Security Settings',
          style: textTheme.titleLarge?.copyWith(color: color.onPrimary),
        ),
      ),
      body: ListView(
        children: [
          if (_biometricAvailable)
            SwitchListTile(
              title: const Text('Enable Biometric Unlock'),
              subtitle: const Text('Use fingerprint'),
              value: _bioEnabled,
              onChanged: _toggleBiometric,
              activeColor: color.secondary,
            ),
          SwitchListTile(
            title: const Text('Enable PIN Unlock'),
            subtitle: const Text('Use PIN to unlock app'),
            value: _pinEnabled,
            onChanged: _togglePin,
            activeColor: color.secondary,
          ),
          const SizedBox(height: 24),
          const Divider(indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Text(
              'Regarding PIN Unlock:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const Text(
              'The PIN you entered is secured and the digits are randomized every time you enter it.',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
