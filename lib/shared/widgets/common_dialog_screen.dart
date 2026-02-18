import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

class CommonDialogScreen extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback onConfirm;

  const CommonDialogScreen({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(title, style: textTheme.titleLarge),
      content: Text(message, style: textTheme.bodyLarge),
      actions: [
        OutlinedButton(
          onPressed: () => context.pop(false),
          child: Text(
            cancelLabel.toUpperCase(),
            style: textTheme.labelLarge?.copyWith(color: color.primary),
          ),
        ),
        OutlinedButton(
          onPressed: () => context.pop(true),
          style: OutlinedButton.styleFrom(
            backgroundColor: color.primary,
          ),
          child: Text(
            confirmLabel.toUpperCase(),
            style: textTheme.labelLarge?.copyWith(color: color.onPrimary),
          ),
        ),
      ],
    );

    // final confirm = await showDialog<bool>(
    //   context: context,
    //   builder:
    //       (ctx) =>
    //       AlertDialog(
    //         title: Text(
    //           'Delete Budget?',
    //           style: textTheme.titleLarge,
    //         ),
    //         content: Text(
    //           'This will remove the budget and its allocations.',
    //           style: textTheme.bodyLarge,
    //         ),
    //         actions: [
    //           OutlinedButton(
    //             onPressed: () => Navigator.pop(ctx, false),
    //             child: Text(
    //               'Cancel'.toUpperCase(),
    //               style: textTheme.labelLarge?.copyWith(
    //                 color: color.primary,
    //               ),
    //             ),
    //           ),
    //           OutlinedButton(
    //             onPressed: () => Navigator.pop(ctx, true),
    //             style: OutlinedButton.styleFrom(
    //               backgroundColor: color.primary,
    //             ),
    //             child: Text(
    //               'Delete'.toUpperCase(),
    //               style: textTheme.labelLarge?.copyWith(
    //                 color: color.onPrimary,
    //               ),
    //             ),
    //           ),
    //         ],
    //       ),
    // );
    // if (confirm == true) {
    //   await ref
    //       .read(budgetServiceProvider)
    //       .deleteBudget(b.id);
    //   ref.invalidate(budgetsWithProgressProvider);
    // }
  }
}
