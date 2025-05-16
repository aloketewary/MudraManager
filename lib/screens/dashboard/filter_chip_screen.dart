// In your home/dashboard screen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/db/filter_type.dart' show FilterType;
import 'package:mudra_manager/l10n/app_localizations.dart' show AppLocalizations;
import 'package:mudra_manager/providers/filter_provider.dart';
import 'package:mudra_manager/util/localization_extension.dart';

class FilterChips extends ConsumerWidget {
  const FilterChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFilter = ref.watch(filterProvider);
    var color = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;
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
              child: GestureDetector(
                onTap: () => {ref.read(filterProvider.notifier).state = filter},
                child: Container(
                  width: 80,
                  padding: const EdgeInsets.all(8.0),
                  margin: const EdgeInsets.only(right: 4.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.0),
                    color:
                        selectedFilter == filter
                            ? color.primary
                            : Colors.transparent,
                    // Light background color
                    border: Border.all(color: color.primary), // Subtle border
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          ctxt.translate(label.toLowerCase()).toUpperCase(),
                          textAlign: TextAlign.center,
                          style: textTheme.labelLarge?.copyWith(
                            color:
                                selectedFilter == filter
                                    ? color.onPrimary
                                    : color.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
