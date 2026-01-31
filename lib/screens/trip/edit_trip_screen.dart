import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/db/models/trip.dart';
import 'package:mudra_manager/providers/user_profile_provider.dart';
import 'package:mudra_manager/providers/trip_provider.dart';
import 'package:mudra_manager/util/dialog_utils.dart';
import 'package:mudra_manager/util/snackbar_service.dart';

class EditTripScreen extends ConsumerStatefulWidget {
  final int tripId;

  const EditTripScreen({super.key, required this.tripId});

  @override
  ConsumerState<EditTripScreen> createState() => _EditTripScreenState();
}

class _EditTripScreenState extends ConsumerState<EditTripScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  
  DateTime? _startDate;
  DateTime? _endDate;
  List<TripParticipant> _participants = [];
  bool _isInitialized = false;
  String? _ownerName;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _initializeData(Trip trip) {
    if (_isInitialized) return;
    _nameController.text = trip.name;
    _descController.text = trip.description ?? '';
    _startDate = trip.startDate;
    _endDate = trip.endDate;
    _participants = trip.participants.toList();
    
    final userProfileAsync = ref.read(userProfileProvider);
    userProfileAsync.whenData((profile) {
      if (profile != null) {
        _ownerName = profile.name;
      }
    });
    
    _isInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final tripAsync = ref.watch(tripByIdProvider(widget.tripId));
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Trip', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: tripAsync.when(
        data: (trip) {
          if (trip == null) return Center(child: Text('Trip not found'));
          _initializeData(trip);

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Card(
                      elevation: 0,
                      color: color.surfaceContainerHighest,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, color: color.primary),
                                SizedBox(width: 8),
                                Text('Trip Details', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            SizedBox(height: 16),
                            TextField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Trip Name',
                                hintText: 'e.g., Goa Trip 2024',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: color.surface,
                                prefixIcon: Icon(Icons.card_travel),
                              ),
                            ),
                            SizedBox(height: 16),
                            TextField(
                              controller: _descController,
                              decoration: InputDecoration(
                                labelText: 'Description (Optional)',
                                hintText: 'Beach vacation with friends',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: color.surface,
                                prefixIcon: Icon(Icons.description),
                              ),
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Card(
                      elevation: 0,
                      color: color.surfaceContainerHighest,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.calendar_today, color: color.primary),
                                SizedBox(width: 8),
                                Text('Duration', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            SizedBox(height: 16),
                            InkWell(
                              onTap: () async {
                                HapticFeedback.mediumImpact();
                                final range = await showDateRangePicker(
                                  context: context,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                  initialDateRange: DateTimeRange(start: _startDate!, end: _endDate!),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: ColorScheme.light(primary: Colors.teal),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (range != null) {
                                  final datesChanged = !DateUtils.isSameDay(range.start, trip.startDate) || !DateUtils.isSameDay(range.end, trip.endDate);
                                  if (datesChanged) {
                                    final confirm = await DialogUtils.showConfirmation(
                                      context,
                                      title: 'Warning: Date Change',
                                      message: 'Changing dates will remove all linked transactions. Continue?',
                                      confirmText: 'Proceed',
                                      icon: Icons.warning_amber_rounded,
                                    );
                                    if (confirm != true) return;
                                  }
                                  setState(() {
                                    _startDate = range.start;
                                    _endDate = range.end;
                                  });
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: color.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: color.outline),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.date_range, color: color.primary),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('${_startDate!.day}/${_startDate!.month}/${_startDate!.year}', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                          Text('to', style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant)),
                                          Text('${_endDate!.day}/${_endDate!.month}/${_endDate!.year}', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.edit_calendar, color: color.onSurfaceVariant),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Card(
                      elevation: 0,
                      color: color.surfaceContainerHighest,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.people, color: color.primary),
                                SizedBox(width: 8),
                                Text('Participants', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            SizedBox(height: 16),
                            SizedBox(
                              height: 100,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _participants.length + 1,
                                itemBuilder: (context, index) {
                                  if (index == 0) {
                                    return Padding(
                                      padding: EdgeInsets.only(right: 12),
                                      child: GestureDetector(
                                        onTap: () {
                                          HapticFeedback.mediumImpact();
                                          _showAddParticipantDialog();
                                        },
                                        child: Column(
                                          children: [
                                            Container(
                                              width: 64,
                                              height: 64,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(color: Colors.teal, width: 2),
                                                color: Colors.teal.withValues(alpha: 0.1),
                                              ),
                                              child: Icon(Icons.add, color: Colors.teal, size: 32),
                                            ),
                                            SizedBox(height: 8),
                                            SizedBox(
                                              width: 70,
                                              child: Text(
                                                'Add',
                                                style: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600, color: Colors.teal),
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
                                    padding: EdgeInsets.only(right: 12),
                                    child: Column(
                                      children: [
                                        Stack(
                                          children: [
                                            CircleAvatar(
                                              radius: 32,
                                              backgroundColor: isOwner ? Colors.amber : Colors.teal,
                                              child: Text(
                                                p.name[0].toUpperCase(),
                                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
                                              ),
                                            ),
                                            if (!isOwner)
                                              Positioned(
                                                top: 0,
                                                right: 0,
                                                child: GestureDetector(
                                                  onTap: () {
                                                    HapticFeedback.mediumImpact();
                                                    setState(() => _participants.remove(p));
                                                  },
                                                  child: Container(
                                                    padding: EdgeInsets.all(4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.red,
                                                      shape: BoxShape.circle,
                                                      border: Border.all(color: Colors.white, width: 2),
                                                    ),
                                                    child: Icon(Icons.close, size: 12, color: Colors.white),
                                                  ),
                                                ),
                                              ),
                                            if (isOwner)
                                              Positioned(
                                                bottom: 0,
                                                right: 0,
                                                child: Container(
                                                  padding: EdgeInsets.all(4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.amber,
                                                    shape: BoxShape.circle,
                                                    border: Border.all(color: Colors.white, width: 2),
                                                  ),
                                                  child: Icon(Icons.star, size: 12, color: Colors.white),
                                                ),
                                              ),
                                          ],
                                        ),
                                        SizedBox(height: 8),
                                        SizedBox(
                                          width: 70,
                                          child: Text(
                                            isOwner ? 'You' : p.name,
                                            style: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
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
                    ),
                    SizedBox(height: 24),
                    FilledButton(
                      onPressed: () => _saveTrip(trip),
                      style: FilledButton.styleFrom(
                        minimumSize: Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                      child: Text('SAVE CHANGES', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 16)),
                    ),
                    SizedBox(height: 80),
                  ]),
                ),
              ),
            ],
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _showAddParticipantDialog() async {
    final nameController = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            SizedBox(height: 24),
            Icon(Icons.person_add, size: 48, color: Colors.teal),
            SizedBox(height: 16),
            Text('Add Participant', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            SizedBox(height: 24),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                hintText: 'Enter participant name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                prefixIcon: Icon(Icons.person),
              ),
              autofocus: true,
            ),
            SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => ctx.pop(),
                    style: OutlinedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: Text('Cancel'),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      if (nameController.text.trim().isNotEmpty) {
                        setState(() => _participants.add(TripParticipant.create(name: nameController.text.trim())));
                        ctx.pop();
                      }
                    },
                    style: FilledButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: Text('Add'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _saveTrip(Trip originalTrip) async {
    if (_nameController.text.trim().isEmpty) {
      SnackbarService.error('Please enter trip name');
      return;
    }
    if (_participants.isEmpty) {
      SnackbarService.error('Add at least one participant');
      return;
    }

    HapticFeedback.mediumImpact();

    final datesChanged = !DateUtils.isSameDay(_startDate, originalTrip.startDate) || !DateUtils.isSameDay(_endDate, originalTrip.endDate);

    originalTrip.name = _nameController.text.trim();
    originalTrip.description = _descController.text.trim().isEmpty ? null : _descController.text.trim();
    originalTrip.startDate = _startDate!;
    originalTrip.endDate = _endDate!;

    await ref.read(tripServiceProvider).updateTrip(originalTrip, newParticipants: _participants, clearTransactions: datesChanged);

    ref.invalidate(allTripsProvider);
    ref.invalidate(tripByIdProvider(widget.tripId));
    SnackbarService.success('Trip updated successfully');
    if (mounted) context.pop();
  }
}
