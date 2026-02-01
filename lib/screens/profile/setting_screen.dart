import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/providers/auth_service.dart';
import 'package:mudra_manager/screens/profile/pin_entry_dialog.dart';
import 'package:mudra_manager/theme/app_colors.dart';
import 'package:mudra_manager/util/snackbar_service.dart';

class SecuritySettingsScreen extends ConsumerStatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  ConsumerState<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends ConsumerState<SecuritySettingsScreen> {
  bool _biometricAvailable = false;
  bool _pinEnabled = false;
  bool _bioEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final auth = ref.read(authServiceProvider);
    final canBio = await auth.canCheckBiometrics();
    final hasPin = await auth.hasPin();
    final bioOn = await auth.isBiometricEnabled();
    setState(() {
      _biometricAvailable = canBio;
      _pinEnabled = hasPin;
      _bioEnabled = bioOn;
    });
  }

  Future<void> _toggleBiometric(bool on) async {
    HapticFeedback.mediumImpact();
    final auth = ref.read(authServiceProvider);
    if (on) {
      final ok = await auth.authenticateBiometric();
      if (!ok) {
        SnackbarService.error('Biometric auth failed');
        return;
      }
    }
    await auth.setBiometricEnabled(on);
    setState(() => _bioEnabled = on);
    SnackbarService.success(on ? 'Biometric enabled' : 'Biometric disabled');
  }

  Future<void> _togglePin(bool on) async {
    HapticFeedback.mediumImpact();
    final auth = ref.read(authServiceProvider);
    if (on) {
      final pin = await showDialog<String>(context: context, builder: (_) => const PinEntryDialog(length: 4));
      if (pin == null || pin.length < 4) return;
      await auth.setPin(pin);
      SnackbarService.success('PIN enabled');
    } else {
      await auth.clearPin();
      SnackbarService.success('PIN disabled');
    }
    setState(() => _pinEnabled = on);
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradientColors = AppColors.glassGradient(color.primary, isDark);

    return Scaffold(
      appBar: AppBar(title: const Text('Security Settings')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          if (_biometricAvailable) Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.primary.withValues(alpha: 0.3), width: 1.5),
              boxShadow: AppColors.glassShadow(color.primary, isDark),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: color.primary.withValues(alpha: 0.2), blurRadius: 8, offset: Offset(0, 2))]),
                  child: Icon(Icons.fingerprint, color: color.primary, size: 24),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Biometric Unlock', style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: color.primary)),
                      SizedBox(height: 2),
                      Text('Use fingerprint or face', style: textTheme.bodySmall?.copyWith(color: color.primary)),
                    ],
                  ),
                ),
                Switch(value: _bioEnabled, onChanged: _toggleBiometric),
              ],
            ),
          ),
          if (_biometricAvailable) SizedBox(height: 8),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.primary.withValues(alpha: 0.3), width: 1.5),
              boxShadow: AppColors.glassShadow(color.primary, isDark),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: color.primary.withValues(alpha: 0.2), blurRadius: 8, offset: Offset(0, 2))]),
                  child: Icon(Icons.pin, color: color.primary, size: 24),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PIN Unlock', style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: color.primary)),
                      SizedBox(height: 2),
                      Text('Use PIN to unlock app', style: textTheme.bodySmall?.copyWith(color: color.primary)),
                    ],
                  ),
                ),
                Switch(value: _pinEnabled, onChanged: _togglePin),
              ],
            ),
          ),
          SizedBox(height: 24),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppColors.glassGradient(color.primary, isDark),
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.primary.withValues(alpha: 0.3), width: 1.5),
              boxShadow: AppColors.glassShadow(color.primary, isDark),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: color.primary, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('About PIN Security', style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: color.primary)),
                      SizedBox(height: 4),
                      Text('Your PIN is securely stored and digits are randomized on entry for enhanced security.', style: textTheme.bodySmall?.copyWith(color: color.primary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
