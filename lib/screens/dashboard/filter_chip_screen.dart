import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/db/filter_type.dart' show FilterType;
import 'package:mudra_manager/l10n/app_localizations.dart' show AppLocalizations;
import 'package:mudra_manager/providers/app_filter_chip.dart';
import 'package:mudra_manager/providers/filter_provider.dart';
import 'package:mudra_manager/util/localization_extension.dart';

class FilterChips extends ConsumerWidget {
  const FilterChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFilter = ref.watch(filterProvider);
    double allBoxWidthFactor = 0.2;
    final ctxt = AppLocalizations.of(context)!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ...FilterType.values.skip(1).map((filter) {
          final label = filter.name[0].toUpperCase() + filter.name.substring(1);
          return Expanded(
            flex: (allBoxWidthFactor * 100).toInt(),
            child: SizedBox(
              width: 80,
              child: AppFilterChip(
                label: ctxt.translate(label.toLowerCase()),
                isSelected: selectedFilter == filter,
                onTap: () {
                  ref.read(filterProvider.notifier).state = filter;
                },
              ),
            ),
          );
        }),
      ],
    );
  }
}
