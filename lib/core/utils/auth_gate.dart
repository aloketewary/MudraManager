import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mudra_manager/core/providers/auth_service.dart';
import 'package:mudra_manager/features/profile/presentation/widgets/pin_entry_dialog.dart';
import 'package:mudra_manager/shared/widgets/adaptive_text.dart';

final _authStateProvider = StateProvider<bool>((ref) => false);
final _authInitProvider = StateProvider<bool>((ref) => false);

class AuthGate extends ConsumerStatefulWidget {
  final Widget child;
  const AuthGate({required this.child, super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate>
    with WidgetsBindingObserver {
  bool _showLockScreen = false;
  bool _pinDialogOpen = false;
  bool _authInProgress = false;
  ProviderSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _subscription = ref.listenManual(_authStateProvider, (_, __) {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!ref.read(_authInitProvider)) {
        ref.read(_authInitProvider.notifier).state = true;
        _runAuthFlow(autoTriggerBiometric: true);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      if (_authInProgress) return;

      final container = ProviderScope.containerOf(context, listen: false);
      container.read(_authStateProvider.notifier).state = false;
      _dismissPinDialog();
      if (mounted) setState(() => _showLockScreen = false);
    } else if (state == AppLifecycleState.resumed) {
      if (_authInProgress) return;

      final unlocked = ref.read(_authStateProvider);
      if (!unlocked) {
        // Only show lock screen on resume — don't auto-trigger biometric
        _runAuthFlow(autoTriggerBiometric: false);
      }
    }
  }

  void _dismissPinDialog() {
    if (_pinDialogOpen && mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      _pinDialogOpen = false;
    }
  }

  Future<void> _runAuthFlow({bool autoTriggerBiometric = false}) async {
    if (_pinDialogOpen || _authInProgress) return;

    final container = ProviderScope.containerOf(context, listen: false);
    final auth = container.read(authServiceProvider);
    final pinSet = await auth.hasPin();
    final bioEnabled =
        await auth.isBiometricEnabled() && await auth.canCheckBiometrics();

    if (!pinSet && !bioEnabled) {
      container.read(_authStateProvider.notifier).state = true;
      return;
    }

    if (mounted) setState(() => _showLockScreen = true);

    if (bioEnabled && autoTriggerBiometric) {
      _authInProgress = true;
      try {
        final ok = await auth.authenticateBiometric();
        if (ok) {
          container.read(_authStateProvider.notifier).state = true;
          return;
        }
      } finally {
        _authInProgress = false;
      }
      // Bio failed — stay on lock screen
    } else if (!bioEnabled && pinSet) {
      await _showPinDialog(auth, container);
    }
    // If bioEnabled but not autoTrigger — just show lock screen,
    // user taps "Unlock" or "Use PIN"
  }

  Future<void> _retryBiometric() async {
    if (_authInProgress || _pinDialogOpen) return;

    final container = ProviderScope.containerOf(context, listen: false);
    final auth = container.read(authServiceProvider);

    _authInProgress = true;
    try {
      final ok = await auth.authenticateBiometric();
      if (ok) {
        container.read(_authStateProvider.notifier).state = true;
      }
    } finally {
      _authInProgress = false;
    }
  }

  Future<void> _pinFallback() async {
    if (_pinDialogOpen || _authInProgress) return;
    final container = ProviderScope.containerOf(context, listen: false);
    final auth = container.read(authServiceProvider);
    await _showPinDialog(auth, container);
  }

  Future<void> _showPinDialog(
    AuthService auth,
    ProviderContainer container,
  ) async {
    if (_pinDialogOpen || !mounted) return;
    _pinDialogOpen = true;

    final pin = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PinEntryDialog(length: 4),
    );

    _pinDialogOpen = false;

    if (pin != null && await auth.validatePin(pin)) {
      container.read(_authStateProvider.notifier).state = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = ref.watch(_authStateProvider);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (!unlocked) return;
        final location = GoRouterState.of(context).uri.toString();
        if (location == '/home') {
          final shouldExit = await showModalBottomSheet<bool>(
            context: context,
            builder: (context) => Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.exit_to_app,
                    size: 48,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Exit Mudra Manager?',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Exit'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
          if (shouldExit == true) SystemNavigator.pop();
        } else {
          context.go('/home');
        }
      },
      child: Stack(
        children: [
          // Always keep child mounted to preserve navigation state
          widget.child,
          // Show lock screen on top when not unlocked
          if (!unlocked)
            Positioned.fill(
              child: _showLockScreen
                  ? BiometricLockScreen(
                      onRetry: _retryBiometric,
                      onUsePinInstead: _pinFallback,
                    )
                  : const Scaffold(body: SizedBox.shrink()),
            ),
        ],
      ),
    );
  }
}

class BiometricLockScreen extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback? onUsePinInstead;

  const BiometricLockScreen({
    required this.onRetry,
    super.key,
    this.onUsePinInstead,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(color: color.primaryContainer),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: color.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.primary.withValues(alpha: 0.3),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.fingerprint,
                    size: 80,
                    color: color.primary,
                  ),
                ),
                const SizedBox(height: 40),
                AdaptiveText(
                  'Mudra Manager',
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color.primary,
                  ),
                  maxLines: 1,
                ),
                const SizedBox(height: 16),
                AdaptiveText(
                  'Unlock to continue',
                  style: textTheme.titleMedium?.copyWith(
                    color: color.primary.withValues(alpha: 0.8),
                  ),
                  maxLines: 1,
                ),
                const SizedBox(height: 60),
                ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    onRetry();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color.primary,
                    foregroundColor: color.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 50,
                      vertical: 18,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.fingerprint, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        'Unlock',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onUsePinInstead != null) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: onUsePinInstead,
                    child: const Text('Use PIN instead'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
