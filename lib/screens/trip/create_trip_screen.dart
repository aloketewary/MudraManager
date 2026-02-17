import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mudra_manager/db/models/trip.dart';
import 'package:mudra_manager/providers/user_profile_provider.dart';
import 'package:mudra_manager/providers/trip_provider.dart';
import 'package:mudra_manager/util/snackbar_service.dart';

class CreateTripScreen extends ConsumerStatefulWidget {
  const CreateTripScreen({super.key});

  @override
  ConsumerState<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends ConsumerState<CreateTripScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(Duration(days: 3));
  final List<TripParticipant> _participants = [];
  String? _ownerName;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _addParticipant() {
    final nameController = TextEditingController();
    showModalBottomSheet(
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

  Future<void> _saveTrip() async {
    if (_nameController.text.trim().isEmpty) {
      SnackbarService.error('Please enter trip name');
      return;
    }

    final trip = Trip.create(name: _nameController.text.trim(), description: _descController.text.trim().isEmpty ? null : _descController.text.trim(), startDate: _startDate, endDate: _endDate);

    await ref.read(tripServiceProvider).createTrip(trip, _participants);
    ref.invalidate(allTripsProvider);
    SnackbarService.success('Trip created successfully!');
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final userProfileAsync = ref.watch(userProfileProvider);

    userProfileAsync.whenData((profile) {
      if (profile != null && _participants.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _participants.isEmpty) {
            setState(() {
              _ownerName = profile.name;
              _participants.add(TripParticipant.create(name: _ownerName!));
            });
          }
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('Create Trip', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: CustomScrollView(
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
                              initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
                            );
                            if (range != null) {
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
                                      Text('${_startDate.day}/${_startDate.month}/${_startDate.year}', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                      Text('to', style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant)),
                                      Text('${_endDate.day}/${_endDate.month}/${_endDate.year}', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.people, color: color.primary),
                                SizedBox(width: 8),
                                Text('Participants', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                              ],
                            ),
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
                                      _addParticipant();
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
                  onPressed: _saveTrip,
                  style: FilledButton.styleFrom(
                    minimumSize: Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  child: Text('CREATE TRIP', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 16)),
                ),
                SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
