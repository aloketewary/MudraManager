import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionFilterSheet extends StatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final bool? initialFilterIncome;
  final String initialSearchQuery;
  final Function(DateTime?, DateTime?, bool?, String) onApply;

  const TransactionFilterSheet({
    super.key,
    this.initialStartDate,
    this.initialEndDate,
    this.initialFilterIncome,
    this.initialSearchQuery = '',
    required this.onApply,
  });

  @override
  State<TransactionFilterSheet> createState() => _TransactionFilterSheetState();
}

class _TransactionFilterSheetState extends State<TransactionFilterSheet> {
  late DateTime? _startDate;
  late DateTime? _endDate;
  late bool? _filterIncome;
  late String _searchQuery;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
    _filterIncome = widget.initialFilterIncome;
    _searchQuery = widget.initialSearchQuery;
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            color: color.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: color.primary.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter Transactions',
                style: textTheme.titleLarge?.copyWith(
                  color: color.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Search by sender',
                  prefixIcon: Icon(LucideIcons.search, color: color.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: color.primary.withValues(alpha: 0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: color.primary.withValues(alpha: 0.3)),
                  ),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
                controller: TextEditingController(text: _searchQuery),
              ),
              const SizedBox(height: 16),
              Text(
                'Type',
                style: textTheme.titleMedium?.copyWith(color: color.primary),
              ),
              const SizedBox(height: 8),
              SegmentedButton<bool?>(
                segments: const [
                  ButtonSegment(
                    value: null,
                    label: Text('All'),
                    icon: Icon(LucideIcons.infinity),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('Income'),
                    icon: Icon(LucideIcons.arrowDown),
                  ),
                  ButtonSegment(
                    value: false,
                    label: Text('Expense'),
                    icon: Icon(LucideIcons.arrowUp),
                  ),
                ],
                selected: {_filterIncome},
                onSelectionChanged: (Set<bool?> selected) {
                  setState(() => _filterIncome = selected.first);
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _startDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) setState(() => _startDate = date);
                      },
                      icon: const Icon(LucideIcons.calendar),
                      label: Text(
                        _startDate == null
                            ? 'Start Date'
                            : DateFormat('dd MMM').format(_startDate!),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _endDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) setState(() => _endDate = date);
                      },
                      icon: const Icon(LucideIcons.calendar),
                      label: Text(
                        _endDate == null
                            ? 'End Date'
                            : DateFormat('dd MMM').format(_endDate!),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _startDate = null;
                          _endDate = null;
                          _filterIncome = null;
                          _searchQuery = '';
                        });
                        widget.onApply(null, null, null, '');
                        Navigator.pop(context);
                      },
                      child: const Text('Clear'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: color.primary,
                        foregroundColor: color.onPrimary,
                      ),
                      onPressed: () {
                        widget.onApply(_startDate, _endDate, _filterIncome, _searchQuery);
                        Navigator.pop(context);
                      },
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
