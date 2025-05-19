import 'package:flutter/material.dart';
import 'package:mudra_manager/l10n/app_localizations.dart';
import 'package:mudra_manager/util/localization_extension.dart';

class PeriodSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChange;

  PeriodSelector({super.key, required this.selected, required this.onChange});

  final double allBoxWidthFactor = 0.2;
  final periods = ['Today', 'Week', 'Month', 'Year'];

  @override
  Widget build(BuildContext c) {
    var color = Theme.of(c).colorScheme;
    var textTheme = Theme.of(c).textTheme;
    final ctxt = AppLocalizations.of(c)!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children:
          periods.map((p) {
            return Expanded(
              flex: (allBoxWidthFactor * 100).toInt(),
              child: SizedBox(
                width: 80,
                child: GestureDetector(
                  onTap: () => onChange(p),
                  child: Container(
                    width: 80,
                    padding: const EdgeInsets.all(8.0),
                    margin: const EdgeInsets.only(right: 4.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.0),
                      color: p == selected ? color.primary : Colors.transparent,
                      border: Border.all(color: color.primary),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            ctxt.translate(p).toUpperCase(),
                            textAlign: TextAlign.center,
                            style: textTheme.labelLarge?.copyWith(color: p == selected ? color.onPrimary : color.primary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }
}
