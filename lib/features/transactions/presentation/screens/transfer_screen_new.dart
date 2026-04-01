import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/extension/account_type_extenstion.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/services/widget_service.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/account/data/account_providers.dart';
import 'package:mudra_manager/features/transactions/data/transaction_provider.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';

class TransferScreenNew extends ConsumerStatefulWidget {
  final String? initialAmount;
  final String? initialNote;
  final DateTime? initialDate;
  final Account? initialFromAccount;
  final Account? initialToAccount;
  final int? editFromId;
  final int? editToId;

  const TransferScreenNew({
    super.key,
    this.initialAmount,
    this.initialNote,
    this.initialDate,
    this.initialFromAccount,
    this.initialToAccount,
    this.editFromId,
    this.editToId,
  });

  @override
  ConsumerState<TransferScreenNew> createState() => _TransferScreenNewState();
}

class _TransferScreenNewState extends ConsumerState<TransferScreenNew>
    with SingleTickerProviderStateMixin {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _amountFocus = FocusNode();
  bool get _isEditing => widget.editFromId != null && widget.editToId != null;

  Account? _fromAccount;
  Account? _toAccount;
  DateTime _date = DateTime.now();
  bool _saving = false;
  Map<int, double> _balanceMap = {};
  bool _initialized = false;

  late AnimationController _flowController;

  @override
  void initState() {
    super.initState();
    _flowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    // ── Pre-fill for edit mode ──
    if (widget.initialAmount != null) {
      _amountController.text = widget.initialAmount!;
    }
    if (widget.initialNote != null) {
      _noteController.text = widget.initialNote!;
    }
    if (widget.initialDate != null) {
      _date = widget.initialDate!;
    }
    _fromAccount = widget.initialFromAccount;
    _toAccount = widget.initialToAccount;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _amountFocus.requestFocus();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      ref.read(accountServiceProvider).getAccountBalanceMap().then((val) {
        if (mounted) setState(() => _balanceMap = val);
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _amountFocus.dispose();
    _flowController.dispose();
    super.dispose();
  }

  void _swapAccounts() {
    if (_fromAccount == null && _toAccount == null) return;
    HapticFeedback.mediumImpact();
    setState(() {
      final temp = _fromAccount;
      _fromAccount = _toAccount;
      _toAccount = temp;
    });
  }

  bool get _canTransfer =>
      !_saving &&
      _fromAccount != null &&
      _toAccount != null &&
      _amountController.text.isNotEmpty &&
      (double.tryParse(_amountController.text) ?? 0) > 0;

  Future<void> _executeTransfer() async {
    if (!_canTransfer) return;
    setState(() => _saving = true);

    try {
      HapticFeedback.heavyImpact();
      await ref.read(transactionProvider).transfer(
            from: _fromAccount!,
            to: _toAccount!,
            amount: double.parse(_amountController.text),
            date: _date,
            note: _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
            fromId: widget.editFromId,
            toId: widget.editToId,
          );

      await WidgetService.updateWidget(ref);

      if (mounted) {
        ref.invalidate(transactionProvider);
        ref.invalidate(accountServiceProvider);
        ref.invalidate(allSectionedTransactionsProvider);

        SnackbarService.success(
          _isEditing ? 'Transfer updated' : 'Transfer completed',
        );
        context.pop(true); // return true so list screen knows to refresh
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final isGuestMode = ref.watch(guestModeProvider);

    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            HapticFeedback.mediumImpact();
            context.pop();
          },
        ),
        title: Text(
          _isEditing ? 'Edit Transfer' : 'Transfer',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: accountsAsync.when(
        data: (accounts) {
          if (accounts.isEmpty) {
            return Center(
              child: Text('No accounts available', style: textTheme.bodyLarge),
            );
          }

          if (_fromAccount == null && accounts.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _fromAccount = accounts.first);
            });
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.cardHorizontal,
                    vertical: spacing.cardVertical,
                  ),
                  children: [
                    // ── AMOUNT ──
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: spacing.cardHorizontal,
                        vertical: spacing.cardVertical,
                      ),
                      decoration: BoxDecoration(
                        color: color.primaryContainer.withValues(alpha: 0.2),
                        borderRadius:
                            BorderRadius.circular(spacing.radiusMedium),
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _amountController,
                            focusNode: _amountFocus,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textAlign: TextAlign.center,
                            style: textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: color.primary,
                            ),
                            decoration: InputDecoration(
                              hintText: '0.00',
                              hintStyle: textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: color.primary.withValues(alpha: 0.2),
                              ),
                              prefixText: '₹ ',
                              prefixStyle: textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: color.primary.withValues(alpha: 0.5),
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: spacing.cardVerticalMax,
                              ),
                              filled: false,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          // Quick amounts
                          Padding(
                            padding:
                                EdgeInsets.only(bottom: spacing.elementGap),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Consumer(
                                  builder: (context, ref, _) {
                                    final amounts =
                                        ref.watch(quickAmountsProvider);
                                    final chips = amounts.valueOrNull ??
                                        [100, 500, 1000, 2000, 5000];
                                    return Wrap(
                                      alignment: WrapAlignment.center,
                                      spacing: 8,
                                      children: chips.map((amt) {
                                        return ActionChip(
                                          label: Text(
                                            '₹$amt',
                                            style:
                                                textTheme.labelSmall?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          onPressed: () {
                                            HapticFeedback.selectionClick();
                                            _amountController.text =
                                                amt.toString();
                                            setState(() {});
                                          },
                                          visualDensity: VisualDensity.compact,
                                          side: BorderSide.none,
                                          backgroundColor: color.primary
                                              .withValues(alpha: 0.08),
                                        );
                                      }).toList(),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: spacing.sectionGap + 8),

                    // ── FROM / SWAP / TO ──
                    _buildAccountCard(
                      label: 'FROM',
                      icon: LucideIcons.arrowUpRight,
                      iconColor: color.error,
                      account: _fromAccount,
                      accounts: accounts
                          .where((a) => a.id != _toAccount?.id)
                          .toList(),
                      isGuestMode: isGuestMode,
                      onSelect: (a) => setState(() => _fromAccount = a),
                      color: color,
                      textTheme: textTheme,
                      spacing: spacing,
                    ),

                    // Swap row
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const SizedBox(width: 20),
                          AnimatedBuilder(
                            animation: _flowController,
                            builder: (_, __) {
                              return CustomPaint(
                                size: const Size(2, 32),
                                painter: _FlowLinePainter(
                                  color: color.primary,
                                  progress: _flowController.value,
                                  enabled: _canTransfer,
                                ),
                              );
                            },
                          ),
                          const Spacer(),
                          Container(
                            decoration: BoxDecoration(
                              color: color.surfaceContainerHighest,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color:
                                    color.outlineVariant.withValues(alpha: 0.5),
                              ),
                            ),
                            child: IconButton(
                              onPressed:
                                  _fromAccount != null || _toAccount != null
                                      ? _swapAccounts
                                      : null,
                              icon: Icon(
                                LucideIcons.arrowUpDown,
                                size: 18,
                                color:
                                    _fromAccount != null || _toAccount != null
                                        ? color.primary
                                        : color.onSurfaceVariant
                                            .withValues(alpha: 0.3),
                              ),
                              visualDensity: VisualDensity.compact,
                              tooltip: 'Swap accounts',
                            ),
                          ),
                          const Spacer(),
                          const SizedBox(width: 22),
                        ],
                      ),
                    ),

                    _buildAccountCard(
                      label: 'TO',
                      icon: LucideIcons.arrowDownLeft,
                      iconColor: const Color(0xFF4CAF50),
                      account: _toAccount,
                      accounts: accounts
                          .where((a) => a.id != _fromAccount?.id)
                          .toList(),
                      isGuestMode: isGuestMode,
                      onSelect: (a) => setState(() => _toAccount = a),
                      color: color,
                      textTheme: textTheme,
                      spacing: spacing,
                    ),

                    SizedBox(height: spacing.sectionGap + 8),

                    // ── NOTE ──
                    TextField(
                      controller: _noteController,
                      decoration: InputDecoration(
                        hintText: 'Add a note (optional)',
                        prefixIcon: Icon(
                          LucideIcons.pencilLine,
                          size: 18,
                          color: color.onSurfaceVariant,
                        ),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(spacing.radiusMedium),
                          borderSide: BorderSide(
                            color: color.outlineVariant.withValues(alpha: 0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(spacing.radiusMedium),
                          borderSide: BorderSide(
                            color: color.outlineVariant.withValues(alpha: 0.3),
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),

                    SizedBox(height: spacing.elementGap + 4),

                    // ── DATE ──
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _date,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          HapticFeedback.lightImpact();
                          setState(() => _date = picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(spacing.radiusMedium),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(spacing.radiusMedium),
                          border: Border.all(
                            color: color.outlineVariant.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.calendar,
                              size: 18,
                              color: color.onSurfaceVariant,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              DateFormat('MMM dd, yyyy').format(_date),
                              style: textTheme.bodyLarge,
                            ),
                            const Spacer(),
                            Icon(
                              LucideIcons.chevronRight,
                              size: 16,
                              color: color.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── SLIDE TO TRANSFER ──
              _SlideToTransferButton(
                enabled: _canTransfer,
                onSlideComplete: _executeTransfer,
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  // ── ACCOUNT CARD ──
  Widget _buildAccountCard({
    required String label,
    required IconData icon,
    required Color iconColor,
    required Account? account,
    required List<Account> accounts,
    required bool isGuestMode,
    required ValueChanged<Account> onSelect,
    required ColorScheme color,
    required TextTheme textTheme,
    required AppSpacing spacing,
  }) {
    final accountColor = account != null
        ? Color(account.colorValue ?? color.primary.toARGB32())
        : color.onSurfaceVariant;
    final balance = account != null ? _balanceMap[account.id] ?? 0.0 : 0.0;
    final displayBalance = GuestModeUtil.applyGuestMode(balance, isGuestMode);

    return InkWell(
      onTap: () => _showAccountPicker(context, accounts, onSelect),
      borderRadius: BorderRadius.circular(spacing.radiusMedium),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: account != null
              ? accountColor.withValues(alpha: 0.06)
              : color.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
          border: Border.all(
            color: account != null
                ? accountColor.withValues(alpha: 0.3)
                : color.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: account != null
            ? Row(
                children: [
                  // Direction icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 16, color: iconColor),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: textTheme.labelSmall?.copyWith(
                            color: iconColor,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          account.name,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Icon(
                        account.accountType.icon,
                        size: 18,
                        color: accountColor,
                      ),
                      const SizedBox(height: 4),
                      CurrencyText(
                        amount: displayBalance,
                        compact: true,
                        style: textTheme.labelMedium?.copyWith(
                          color: color.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.onSurfaceVariant.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 16,
                      color: iconColor.withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'Select $label account',
                    style: textTheme.bodyLarge?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    LucideIcons.chevronRight,
                    size: 16,
                    color: color.onSurfaceVariant,
                  ),
                ],
              ),
      ),
    );
  }

  // ── ACCOUNT PICKER ──
  void _showAccountPicker(
    BuildContext context,
    List<Account> accounts,
    ValueChanged<Account> onSelect,
  ) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.read(spacingProvider);
    final isGuestMode = ref.read(guestModeProvider);

    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(spacing.radiusLarge)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: color.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Select Account',
              style:
                  textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...accounts.map((account) {
              final acColor =
                  Color(account.colorValue ?? color.primary.toARGB32());
              final bal = _balanceMap[account.id] ?? 0.0;
              final displayBal = GuestModeUtil.applyGuestMode(bal, isGuestMode);

              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: acColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    account.accountType.icon,
                    color: acColor,
                    size: 20,
                  ),
                ),
                title: Text(
                  account.name,
                  style: textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                trailing: CurrencyText(
                  amount: displayBal,
                  compact: true,
                  style: textTheme.labelLarge?.copyWith(
                    color: color.onSurfaceVariant,
                  ),
                ),
                onTap: () {
                  HapticFeedback.mediumImpact();
                  onSelect(account);
                  ctx.pop();
                },
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ── FLOW LINE PAINTER ──
class _FlowLinePainter extends CustomPainter {
  final Color color;
  final double progress;
  final bool enabled;

  _FlowLinePainter({
    required this.color,
    required this.progress,
    required this.enabled,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final trackPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      trackPaint,
    );

    if (!enabled) return;

    final dotPaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    final y = progress * size.height;
    canvas.drawCircle(Offset(size.width / 2, y), 3, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _FlowLinePainter old) =>
      old.progress != progress || old.enabled != enabled;
}

// ── SLIDE TO TRANSFER ──
class _SlideToTransferButton extends StatefulWidget {
  final bool enabled;
  final VoidCallback onSlideComplete;

  const _SlideToTransferButton({
    required this.enabled,
    required this.onSlideComplete,
  });

  @override
  State<_SlideToTransferButton> createState() => _SlideToTransferButtonState();
}

class _SlideToTransferButtonState extends State<_SlideToTransferButton>
    with TickerProviderStateMixin {
  double _dragPosition = 0.0;
  bool _isCompleted = false;
  double _maxDrag = 0.0;

  late final AnimationController _shimmerController;
  late final AnimationController _snapBackController;
  late final Animation<double> _snapBackAnimation;

  // Haptic milestone tracking
  final _hapticThresholds = {0.25, 0.50, 0.75};
  final _triggeredThresholds = <double>{};

  static const _thumbSize = 60.0;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _snapBackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _snapBackAnimation = CurvedAnimation(
      parent: _snapBackController,
      curve: Curves.elasticOut,
    );
    _snapBackController.addListener(() {
      setState(() {
        _dragPosition = _dragPosition * (1 - _snapBackAnimation.value);
      });
    });
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _snapBackController.dispose();
    super.dispose();
  }

  double get _progress =>
      _maxDrag > 0 ? (_dragPosition / _maxDrag).clamp(0.0, 1.0) : 0.0;

  void _onDragUpdate(DragUpdateDetails details) {
    if (!widget.enabled || _isCompleted) return;
    setState(() {
      _dragPosition = (_dragPosition + details.delta.dx).clamp(0.0, _maxDrag);
    });

    // Milestone haptics
    for (final t in _hapticThresholds) {
      if (_progress >= t && !_triggeredThresholds.contains(t)) {
        _triggeredThresholds.add(t);
        HapticFeedback.lightImpact();
      }
    }
  }

  void _onDragEnd(DragEndDetails details) {
    if (!widget.enabled || _isCompleted) return;

    if (_progress >= 0.85) {
      setState(() => _isCompleted = true);
      HapticFeedback.heavyImpact();
      widget.onSlideComplete();
    } else {
      // Spring snap-back
      _triggeredThresholds.clear();
      final startPos = _dragPosition;
      _snapBackController.reset();
      _snapBackController.forward();
      // Store start position for interpolation
      _dragPosition = startPos;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          _maxDrag = maxWidth - _thumbSize - 8;

          return Container(
            height: 68,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(34),
              border: Border.all(
                color: widget.enabled
                    ? color.primary.withValues(alpha: 0.2)
                    : color.outlineVariant.withValues(alpha: 0.2),
              ),
            ),
            child: Stack(
              children: [
                // ── Background track ──
                Container(
                  decoration: BoxDecoration(
                    color: widget.enabled
                        ? color.primaryContainer.withValues(alpha: 0.4)
                        : color.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(34),
                  ),
                ),

                // ── Progress fill ──
                if (widget.enabled)
                  AnimatedContainer(
                    duration: _dragPosition == 0
                        ? const Duration(milliseconds: 300)
                        : Duration.zero,
                    width: _dragPosition + _thumbSize + 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(34),
                      gradient: LinearGradient(
                        colors: [
                          color.primary.withValues(alpha: 0.25),
                          color.primary.withValues(alpha: 0.08),
                        ],
                      ),
                    ),
                  ),

                // ── Shimmer hint text ──
                Center(
                  child: AnimatedBuilder(
                    animation: _shimmerController,
                    builder: (_, child) {
                      if (!widget.enabled || _isCompleted || _progress > 0.3) {
                        return Text(
                          _isCompleted
                              ? 'Transferring...'
                              : 'Slide to Transfer',
                          style: textTheme.titleSmall?.copyWith(
                            color: widget.enabled
                                ? color.onPrimaryContainer
                                    .withValues(alpha: 0.5)
                                : color.onSurfaceVariant.withValues(alpha: 0.3),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        );
                      }

                      return ShaderMask(
                        shaderCallback: (bounds) {
                          final dx = _shimmerController.value * 2 - 0.5;
                          return LinearGradient(
                            begin: Alignment(dx - 0.3, 0),
                            end: Alignment(dx + 0.3, 0),
                            colors: [
                              color.onPrimaryContainer.withValues(alpha: 0.4),
                              color.primary,
                              color.onPrimaryContainer.withValues(alpha: 0.4),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ).createShader(bounds);
                        },
                        child: Text(
                          'Slide to Transfer',
                          style: textTheme.titleSmall?.copyWith(
                            color: Colors.white, // ShaderMask needs opaque base
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // ── Draggable thumb ──
                AnimatedPositioned(
                  duration:
                      _snapBackController.isAnimating || _dragPosition == 0
                          ? Duration.zero
                          : Duration.zero,
                  left: _dragPosition + 4,
                  top: 4,
                  bottom: 4,
                  child: GestureDetector(
                    onHorizontalDragUpdate: _onDragUpdate,
                    onHorizontalDragEnd: _onDragEnd,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: _thumbSize,
                      height: _thumbSize,
                      decoration: BoxDecoration(
                        color: widget.enabled
                            ? Color.lerp(
                                color.primary,
                                const Color(0xFF4CAF50),
                                _progress,
                              )
                            : color.surfaceContainerHigh,
                        shape: BoxShape.circle,
                        boxShadow: widget.enabled
                            ? [
                                BoxShadow(
                                  color: Color.lerp(
                                    color.primary,
                                    const Color(0xFF4CAF50),
                                    _progress,
                                  )!
                                      .withValues(alpha: 0.3),
                                  blurRadius: 12 + (_progress * 8),
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: _isCompleted
                          ? Icon(
                              LucideIcons.check,
                              color: color.onPrimary,
                              size: 22,
                            )
                          : Icon(
                              _progress > 0.7
                                  ? LucideIcons.checkCheck
                                  : LucideIcons.arrowRight,
                              color: widget.enabled
                                  ? color.onPrimary
                                  : color.onSurfaceVariant
                                      .withValues(alpha: 0.3),
                              size: 22,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
