import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/l10n/app_localizations.dart'
    show AppLocalizations;

class MonthTabSelector extends StatefulWidget {
  final Function onMonthSelected;

  const MonthTabSelector({super.key, required this.onMonthSelected});

  @override
  State<MonthTabSelector> createState() => _MonthTabSelectorState();
}

class _MonthTabSelectorState extends State<MonthTabSelector> {
  late final List<DateTime> months;
  late final PageController _pageController;
  final int initialPage = 60; // 60 before, 60 after = 121 total months
  int _selectedIndex = 60;

  @override
  void initState() {
    super.initState();

    months = List.generate(121, (i) {
      final now = DateTime.now();
      return DateTime(now.year, now.month - 60 + i);
    });

    _pageController = PageController(
      initialPage: initialPage,
      viewportFraction: 0.3,
    );

    // Force page jump after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pageController.jumpToPage(initialPage);
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;
    final now = DateTime.now();

    return SizedBox(
      height: 60,
      child: PageView.builder(
        controller: _pageController,
        itemCount: months.length,
        onPageChanged: (index) {
          // Trigger Riverpod update here if needed
        },
        itemBuilder: (context, index) {
          final date = months[index];
          final isSelected = _selectedIndex == index;

          return GestureDetector(
            onTap: () {
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
              setState(() {
                _selectedIndex = index;
              });
              widget.onMonthSelected(months[_selectedIndex]);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected ? color.primary : color.onSurface,
                  ),
                ),
              ),
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('MMMM', ctxt.localeName).format(date),
                      style: textTheme.titleSmall?.copyWith(
                        color: isSelected ? color.primary : color.onSurface,
                        fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    if(now.year != date.year)
                    Text(
                      DateFormat('yyyy', ctxt.localeName).format(date),
                      style: textTheme.labelSmall?.copyWith(
                        color: isSelected ? color.primary : color.onSurface,
                        fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
