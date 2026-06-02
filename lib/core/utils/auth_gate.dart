import 'package:mudra_manager/core/providers/state_value.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mudra_manager/core/utils/dialog_utils.dart';
import 'package:mudra_manager/core/providers/auth_service.dart';
import 'package:mudra_manager/features/profile/presentation/widgets/pin_entry_dialog.dart';
import 'package:mudra_manager/shared/widgets/adaptive_text.dart';
import 'package:mudra_manager/core/router/app_routes.dart';

final _authStateProvider = NotifierProvider<StateValue<bool>, bool>(
  () => StateValue(false),
);
final _authInitProvider = NotifierProvider<StateValue<bool>, bool>(
  () => StateValue(false),
);

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
        ref.read(_authInitProvider.notifier).set(true);
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
      container.read(_authStateProvider.notifier).set(false);
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
      container.read(_authStateProvider.notifier).set(true);
      return;
    }

    if (mounted) setState(() => _showLockScreen = true);

    if (bioEnabled && autoTriggerBiometric) {
      _authInProgress = true;
      try {
        final ok = await auth.authenticateBiometric();
        if (ok) {
          container.read(_authStateProvider.notifier).set(true);
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
        container.read(_authStateProvider.notifier).set(true);
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
      container.read(_authStateProvider.notifier).set(true);
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
        if (location == AppRoutes.home) {
          final shouldExit = await DialogUtils.showConfirmation(
            context,
            title: 'Exit Mudra Manager?',
            message: 'Are you sure you want to exit?',
            icon: LucideIcons.logOut,
            confirmText: 'Exit',
          );
          if (shouldExit == true) SystemNavigator.pop();
        } else {
          context.go(AppRoutes.home);
        }
      },
      child: Stack(
        children: [
          // Hide from accessibility when locked
          ExcludeSemantics(
            excluding: !unlocked,
            child: Visibility(
              visible: unlocked,
              maintainState: true,
              maintainAnimation: true,
              maintainSize: true,
              child: widget.child,
            ),
          ),
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
                    LucideIcons.scanFace,
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
                      const Icon(LucideIcons.scanFace, size: 24),
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
