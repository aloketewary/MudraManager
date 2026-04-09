import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_boring_avatars/flutter_boring_avatars.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/shared/widgets/currency_badge.dart';
import 'package:mudra_manager/core/db/models/trip.dart';
import 'package:mudra_manager/core/entitlement/entitlement_provider.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:mudra_manager/core/utils/dialog_utils.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/profile/data/user_profile_provider.dart';
import 'package:mudra_manager/features/trip/data/trip_provider.dart';

class ManageTripScreen extends ConsumerStatefulWidget {
  final int? tripId;
  final bool isTrip;

  const ManageTripScreen({
    super.key,
    this.tripId,
    this.isTrip = true,
  });

  @override
  ConsumerState<ManageTripScreen> createState() => _ManageTripScreenState();
}

class _ManageTripScreenState extends ConsumerState<ManageTripScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _budgetController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 3));
  final List<TripParticipant> _participants = [];
  String? _ownerName;
  String? _tripCurrency;
  bool _isActive = true;
  bool _isInitialized = false;

  bool get isEditMode => widget.tripId != null;
  late bool _isTrip;

  @override
  void initState() {
    super.initState();
    _isTrip = widget.isTrip;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  void _initializeData(Trip trip) {
    if (_isInitialized) return;
    _nameController.text = trip.name;
    _descController.text = trip.description ?? '';
    _budgetController.text = trip.budget?.toString() ?? '';
    _startDate = trip.startDate;
    _endDate = trip.endDate;
    _participants.clear();
    _participants.addAll(trip.participants.toList());
    _isActive = trip.isActive;
    _isTrip = trip.isTrip;
    _tripCurrency = trip.currencyCode;
    _isInitialized = true;
  }

  void _addParticipant() {
    final nameController = TextEditingController();
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: color.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: color.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.userPlus,
                size: 32,
                color: color.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.editTrip_addParticipant,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.editTrip_name,
                hintText: AppLocalizations.of(context)!.editTrip_enterName,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(LucideIcons.user),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => ctx.pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(AppLocalizations.of(context)!.common_cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      if (nameController.text.trim().isNotEmpty) {
                        setState(
                          () => _participants.add(
                            TripParticipant.create(
                              name: nameController.text.trim(),
                            ),
                          ),
                        );
                        ctx.pop();
                      }
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Add'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _saveTrip(Trip? originalTrip) async {
    if (_nameController.text.trim().isEmpty) {
      SnackbarService.error(BuddyMessages.tripNameRequired(_isTrip));
      return;
    }

    if (_participants.isEmpty) {
      SnackbarService.error(BuddyMessages.addParticipant);
      return;
    }
    if (!isEditMode) {
      final canCreate = await ref.read(canCreateTripProvider.future);
      if (!canCreate) {
        SnackbarService.warning(BuddyMessages.tripLimitReached(_isTrip));
        return;
      }
    }
    HapticFeedback.mediumImpact();

    final budget = _isTrip && _budgetController.text.trim().isNotEmpty
        ? double.tryParse(_budgetController.text.trim())
        : null;
    // For split groups, use wide date range
    final startDate = _isTrip ? _startDate : DateTime(2000);
    final endDate = _isTrip ? _endDate : DateTime(2099);

    if (isEditMode && originalTrip != null) {
      final datesChanged = _isTrip &&
          (!DateUtils.isSameDay(_startDate, originalTrip.startDate) ||
              !DateUtils.isSameDay(_endDate, originalTrip.endDate));

      originalTrip.name = _nameController.text.trim();
      originalTrip.description = _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim();
      originalTrip.startDate = startDate;
      originalTrip.endDate = endDate;
      originalTrip.budget = budget;
      originalTrip.isActive = _isActive;
      originalTrip.isTrip = _isTrip;
      originalTrip.currencyCode = _tripCurrency;

      await ref.read(tripServiceProvider).updateTrip(
            originalTrip,
            newParticipants: _participants,
            clearTransactions: datesChanged,
          );

      ref.invalidate(allTripsProvider);
      ref.invalidate(tripByIdProvider(widget.tripId!));
      SnackbarService.success(BuddyMessages.tripUpdated(_isTrip));
    } else {
      final trip = Trip.create(
        name: _nameController.text.trim(),
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        startDate: startDate,
        endDate: endDate,
        budget: budget,
        isActive: _isActive,
        isTrip: _isTrip,
      );
      trip.currencyCode = _tripCurrency;

      await ref.read(tripServiceProvider).createTrip(trip, _participants);
      ref.invalidate(allTripsProvider);
      SnackbarService.success(BuddyMessages.tripCreated(_isTrip));
    }

    if (mounted) context.pop();
  }

  Future<void> _finalizeTrip(Trip trip) async {
    final confirm = await DialogUtils.showConfirmation(
      context,
      title: _isTrip ? 'Finalize Trip' : 'Close Group',
      message: _isTrip
          ? 'This will mark the trip as ended. You can\'t add expenses after this.'
          : 'This will close the group. You can\'t add expenses after this.',
      confirmText: _isTrip ? 'Finalize' : 'Close',
      icon: LucideIcons.circleCheck,
    );
    if (confirm != true) return;

    trip.isActive = false;
    await ref.read(tripServiceProvider).updateTrip(
          trip,
          newParticipants: _participants,
          clearTransactions: false,
        );
    ref.invalidate(allTripsProvider);
    SnackbarService.success(BuddyMessages.tripFinalized(_isTrip));
    if (mounted) context.pop();
  }


  @override
  Widget build(BuildContext context) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final userProfileAsync = ref.watch(userProfileProvider);

    userProfileAsync.maybeWhen(
      data: (profile) {
        if (profile != null && _participants.isEmpty && !isEditMode) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _participants.isEmpty) {
              setState(() {
                _ownerName = profile.name;
                _participants.add(TripParticipant.create(name: _ownerName!, isOwner: true));
              });
            }
          });
        }
      },
      orElse: () {},
    );

    if (isEditMode) {
      final tripAsync = ref.watch(tripByIdProvider(widget.tripId!));
      return tripAsync.when(
        data: (trip) {
          if (trip == null) {
            return Scaffold(
              appBar: AppBar(title: Text(_isTrip ? 'Trip Not Found' : 'Group Not Found')),
              body: Center(child: Text(_isTrip ? 'Trip not found' : 'Group not found')),
            );
          }

          _initializeData(trip);

          final userProfile = ref.read(userProfileProvider).value;
          if (userProfile != null && _ownerName == null) {
            _ownerName = userProfile.name;
          }

          return _buildContent(spacing, color, textTheme, trip);
        },
        loading: () => Scaffold(
          appBar: AppBar(title: Text(_isTrip ? 'Edit Trip' : 'Edit Group')),
          body: ListView(children: List.generate(3, (_) => DashboardCardSkeleton())),
        ),
        error: (e, _) => Scaffold(
          appBar: AppBar(title: Text(BuddyMessages.genericError)),
          body: Center(child: Text(BuddyMessages.errorWith('$e'))),
        ),
      );
    }

    return _buildContent(spacing, color, textTheme, null);
  }

  Widget _buildContent(
    AppSpacing spacing,
    ColorScheme color,
    TextTheme textTheme,
    Trip? trip,
  ) {
    final duration = _endDate.difference(_startDate).inDays + 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditMode
              ? (_isTrip ? 'Edit Trip' : 'Edit Split Group')
              : (_isTrip ? 'Create Trip' : 'Create Split Group'),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: () {
            HapticFeedback.mediumImpact();
            context.pop();
          },
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(LucideIcons.save),
            label: Text(isEditMode ? 'Update' : 'Create'),
            onPressed: () {
              HapticFeedback.mediumImpact();
              _saveTrip(trip);
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          if (!isEditMode)
            Padding(
              padding: EdgeInsets.fromLTRB(
                spacing.cardInner,
                spacing.cardInner,
                spacing.cardInner,
                0,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: _isTrip
                      ? color.primaryContainer
                      : color.tertiaryContainer,
                  borderRadius:
                      BorderRadius.circular(spacing.radiusMedium),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isTrip ? LucideIcons.plane : LucideIcons.split,
                      size: 20,
                      color: _isTrip
                          ? color.onPrimaryContainer
                          : color.onTertiaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _isTrip ? 'Travel Trip' : 'Split Group',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _isTrip
                            ? color.onPrimaryContainer
                            : color.onTertiaryContainer,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      LucideIcons.lock,
                      size: 14,
                      color: _isTrip
                          ? color.onPrimaryContainer.withValues(alpha: 0.5)
                          : color.onTertiaryContainer.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.all(spacing.cardInner),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.info, color: color.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _isTrip ? AppLocalizations.of(context)!.editTrip_tripDetails : AppLocalizations.of(context)!.editTrip_groupDetails,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: _isTrip ? 'Trip Name' : 'Group Name',
                    hintText: _isTrip
                        ? 'e.g., Goa Trip 2024'
                        : 'e.g., Weekend dinner split',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(spacing.radiusMedium),
                    ),
                    prefixIcon: Icon(
                      _isTrip ? LucideIcons.mapPin : LucideIcons.users,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.editTrip_descriptionOptional,
                    hintText: _isTrip
                        ? 'Beach vacation with friends'
                        : 'Split expenses with friends',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(spacing.radiusMedium),
                    ),
                    prefixIcon: const Icon(LucideIcons.fileText),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                if (_isTrip)
                  TextField(
                    controller: _budgetController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.editTrip_budgetOptional,
                      hintText: 'e.g., 50000',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(spacing.radiusMedium),
                      ),
                      prefixIcon: Icon(currencyIcon(_tripCurrency)),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                if (_isTrip) const SizedBox(height: 16),
                // Currency picker
                InkWell(
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    final picked = await showModalBottomSheet<String>(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (_) => _TripCurrencyPicker(
                        selected: _tripCurrency,
                      ),
                    );
                    if (picked != null) {
                      setState(() => _tripCurrency = picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Currency',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(spacing.radiusMedium),
                      ),
                      prefixIcon: const Icon(LucideIcons.coins),
                    ),
                    child: Row(
                      children: [
                        _tripCurrency != null
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CurrencyBadge(code: _tripCurrency!, size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    currencyName(_tripCurrency),
                                    style: textTheme.bodyLarge,
                                  ),
                                ],
                              )
                            : Text(
                                'Base currency (default)',
                                style: textTheme.bodyLarge,
                              ),
                        const Spacer(),
                        if (_tripCurrency != null)
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              setState(() => _tripCurrency = null);
                            },
                            child: Icon(
                              LucideIcons.x,
                              size: 18,
                              color: color.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isTrip) ...[
          SizedBox(height: spacing.sectionGap),
          Padding(
            padding: EdgeInsets.all(spacing.cardInner),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.calendar, color: color.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.editTrip_duration,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.primaryContainer,
                        borderRadius:
                            BorderRadius.circular(spacing.radiusSmall),
                      ),
                      child: Text(
                        '$duration ${duration == 1 ? 'day' : 'days'}',
                        style: textTheme.labelSmall?.copyWith(
                          color: color.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    HapticFeedback.mediumImpact();

                    if (isEditMode && trip != null) {
                      final range = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                        initialDateRange: DateTimeRange(
                          start: _startDate,
                          end: _endDate,
                        ),
                      );
                      if (range != null) {
                        final datesChanged =
                            !DateUtils.isSameDay(range.start, trip.startDate) ||
                                !DateUtils.isSameDay(range.end, trip.endDate);
                        if (datesChanged) {
                          final confirm = await DialogUtils.showConfirmation(
                            context,
                            title: 'Warning: Date Change',
                            message:
                                'Changing dates will remove all linked transactions. Continue?',
                            confirmText: 'Proceed',
                            icon: LucideIcons.triangleAlert,
                          );
                          if (confirm != true) return;
                        }
                        setState(() {
                          _startDate = range.start;
                          _endDate = range.end;
                        });
                      }
                    } else {
                      final range = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                        initialDateRange: DateTimeRange(
                          start: _startDate,
                          end: _endDate,
                        ),
                      );
                      if (range != null) {
                        setState(() {
                          _startDate = range.start;
                          _endDate = range.end;
                        });
                      }
                    }
                  },
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: color.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(spacing.radiusMedium),
                      border: Border.all(
                        color: color.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Start Date',
                                style: textTheme.labelSmall?.copyWith(
                                  color: color.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('MMM d, yyyy').format(_startDate),
                                style: textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          LucideIcons.arrowRight,
                          color: color.onSurfaceVariant,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'End Date',
                                style: textTheme.labelSmall?.copyWith(
                                  color: color.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('MMM d, yyyy').format(_endDate),
                                style: textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          LucideIcons.calendarDays,
                          color: color.primary,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          ],
          SizedBox(height: spacing.sectionGap),
          if (isEditMode)
            Padding(
              padding: EdgeInsets.all(spacing.cardInner),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.power, color: color.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _isTrip ? 'Active Trip' : 'Active Group',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isTrip
                        ? 'Mark as active to track expenses in real-time'
                        : 'Mark as active to keep splitting expenses',
                    style: textTheme.bodySmall?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    value: _isActive,
                    onChanged: (val) => setState(() => _isActive = val),
                    title: Text(_isActive ? 'Active' : 'Inactive'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          if (isEditMode) SizedBox(height: spacing.sectionGap),
          Padding(
            padding: EdgeInsets.all(spacing.cardInner),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.users, color: color.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Participants',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.primaryContainer,
                        borderRadius:
                            BorderRadius.circular(spacing.radiusSmall),
                      ),
                      child: Text(
                        '${_participants.length}',
                        style: textTheme.labelSmall?.copyWith(
                          color: color.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _participants.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              _addParticipant();
                            },
                            child: Column(
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: color.primary,
                                      width: 2,
                                      strokeAlign: BorderSide.strokeAlignInside,
                                    ),
                                    color: color.primaryContainer,
                                  ),
                                  child: Icon(
                                    LucideIcons.plus,
                                    color: color.primary,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: 70,
                                  child: Text(
                                    'Add',
                                    style: textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: color.primary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      final p = _participants[index - 1];
                      final isOwner = p.name == _ownerName;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                SizedBox(
                                  width: 64,
                                  height: 64,
                                  child: ClipOval(
                                    child: BoringAvatar(
                                      name: p.name,
                                      palette: BoringAvatarPalette([
                                        color.primary,
                                        color.tertiary,
                                        color.primaryContainer,
                                        color.tertiaryContainer,
                                      ]),
                                      type: BoringAvatarType.beam,
                                    ),
                                  ),
                                ),
                                if (!isOwner)
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: () {
                                        HapticFeedback.mediumImpact();
                                        setState(
                                          () => _participants.remove(p),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: color.error,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: color.surface,
                                            width: 2,
                                          ),
                                        ),
                                        child: Icon(
                                          LucideIcons.x,
                                          size: 12,
                                          color: color.onError,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (isOwner)
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: color.tertiary,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: color.surface,
                                          width: 2,
                                        ),
                                      ),
                                      child: Icon(
                                        LucideIcons.star,
                                        size: 12,
                                        color: color.onTertiary,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: 70,
                              child: Text(
                                isOwner ? 'You' : p.name,
                                style: textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          if (isEditMode && trip != null) ...[
            SizedBox(height: spacing.sectionGap),
            Padding(
              padding: EdgeInsets.all(spacing.cardInner),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        LucideIcons.triangleAlert,
                        color: color.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Danger Zone',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => _finalizeTrip(trip),
                    icon: const Icon(LucideIcons.circleCheck, size: 20),
                    label: Text(_isTrip ? 'Finalize Trip' : 'Finalize Group'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      side: BorderSide(color: color.error),
                      foregroundColor: color.error,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

class _TripCurrencyPicker extends StatefulWidget {
  final String? selected;
  const _TripCurrencyPicker({this.selected});

  @override
  State<_TripCurrencyPicker> createState() => _TripCurrencyPickerState();
}

class _TripCurrencyPickerState extends State<_TripCurrencyPicker> {
  String _query = '';

  List<CurrencyMeta> get _filtered {
    final all = kCurrencies.values.toList();
    if (_query.isEmpty) return all;
    final q = _query.toLowerCase();
    return all
        .where((c) =>
            c.code.toLowerCase().contains(q) ||
            c.name.toLowerCase().contains(q),)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: color.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search currency...',
                prefixIcon: const Icon(Icons.search, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: color.outlineVariant),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: _filtered.length,
              itemBuilder: (context, i) {
                final c = _filtered[i];
                final isSelected = c.code == widget.selected;
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.primary.withValues(alpha: 0.12)
                          : color.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      c.symbol,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? color.primary : color.onSurface,
                      ),
                    ),
                  ),
                  title: Text(c.code),
                  subtitle: Text(c.name, style: textTheme.bodySmall),
                  trailing: isSelected
                      ? Icon(Icons.check_circle, color: color.primary)
                      : null,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).pop(c.code);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
