import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mudra_manager/components/adaptive_text.dart';
import 'package:mudra_manager/providers/auth_service.dart';
import 'package:mudra_manager/screens/profile/pin_entry_dialog.dart'
    show PinEntryDialog;

final _authStateProvider = StateProvider<bool>((ref) => false);
final _authInitProvider = StateProvider<bool>((ref) => false);

class AuthGate extends ConsumerStatefulWidget {
  final Widget child;
  const AuthGate({required this.child, super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  bool _showLockScreen = false;
  ProviderSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = ref.listenManual(_authStateProvider, (_, __) {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!ref.read(_authInitProvider)) {
        ref.read(_authInitProvider.notifier).state = true;
        _runAuthFlow();
      }
    });
  }

  @override
  void dispose() {
    _subscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = ref.watch(_authStateProvider);
    if (!unlocked) {
      return _showLockScreen
          ? BiometricLockScreen(onRetry: _runAuthFlow)
          : Scaffold(body: SizedBox.shrink());
    }
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final location = GoRouterState.of(context).uri.toString();
          if (location == '/home') {
            final shouldExit = await showModalBottomSheet<bool>(
              context: context,
              builder: (context) => Container(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.exit_to_app, size: 48, color: Theme.of(context).colorScheme.error),
                    SizedBox(height: 16),
                    Text('Exit Mudra Manager?', style: Theme.of(context).textTheme.titleLarge),
                    SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text('Cancel'),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text('Exit'),
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
        }
      },
      child: widget.child,
    );
  }

  Future<void> _runAuthFlow() async {
    if (mounted) setState(() => _showLockScreen = false);

    final container = ProviderScope.containerOf(context, listen: false);
    final auth = container.read(authServiceProvider);
    final pinSet = await auth.hasPin();
    final bioEnabled =
        await auth.isBiometricEnabled() && await auth.canCheckBiometrics();

    if (bioEnabled) {
      final ok = await auth.authenticateBiometric();
      if (ok) {
        container.read(_authStateProvider.notifier).state = true;
      } else {
        if (mounted) setState(() => _showLockScreen = true);
      }
    } else if (pinSet) {
      if (mounted) setState(() => _showLockScreen = true);
      await _promptPin(auth, container);
    } else {
      container.read(_authStateProvider.notifier).state = true;
    }
  }

  Future<void> _promptPin(AuthService auth, ProviderContainer container) async {
    final pin = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PinEntryDialog(length: 4),
    );
    if (pin != null && await auth.validatePin(pin)) {
      container.read(_authStateProvider.notifier).state = true;
    }
  }
}

class BiometricLockScreen extends StatelessWidget {
  final VoidCallback onRetry;
  const BiometricLockScreen({required this.onRetry, super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: color.primaryContainer
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: color.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.primary.withValues(alpha: 0.3),
                        blurRadius: 30,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.fingerprint,
                    size: 80,
                    color: color.primary,
                  ),
                ),
                SizedBox(height: 40),
                AdaptiveText(
                  'Mudra Manager',
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color.primary,
                  ),
                  maxLines: 1,
                ),
                SizedBox(height: 16),
                AdaptiveText(
                  'Unlock to continue',
                  style: textTheme.titleMedium?.copyWith(
                    color: color.primary.withValues(alpha: 0.8),
                  ),
                  maxLines: 1,
                ),
                SizedBox(height: 60),
                ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    onRetry();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color.primary,
                    foregroundColor: color.onPrimary,
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.fingerprint, size: 24),
                      SizedBox(width: 12),
                      Text(
                        'Unlock',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
