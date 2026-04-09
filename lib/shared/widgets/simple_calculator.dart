import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:math_expressions/math_expressions.dart';

class SimpleCalculator extends StatefulWidget {
  final Function(double) onResultSelected;

  const SimpleCalculator({super.key, required this.onResultSelected});

  @override
  State<SimpleCalculator> createState() => _SimpleCalculatorState();
}

class _SimpleCalculatorState extends State<SimpleCalculator> {
  String input = '';
  String result = '';

  void onButtonPressed(String value) {
    HapticFeedback.mediumImpact();
    setState(() {
      if (value == 'AC') {
        input = '';
        result = '';
      } else if (value == '⌫') {
        if (input.isNotEmpty) {
          input = input.substring(0, input.length - 1);
          result = '';
        }
      } else if (value == '=') {
        try {
          final expression = input.replaceAll('×', '*').replaceAll('÷', '/');
          final eval = double.parse(_evaluate(expression));
          result = eval.toString();
        } catch (e) {
          result = 'Error';
        }
      } else if (value == '✓') {
        if (result.isNotEmpty && result != 'Error') {
          HapticFeedback.mediumImpact();
          widget.onResultSelected(double.tryParse(result) ?? 0);
        }
      } else {
        input += value;
        result = '';
      }
    });
  }

  String _evaluate(String expression) {
    try {
      ExpressionParser p = ShuntingYardParser();
      Expression exp = p.parse(expression);
      var evaluate = exp.evaluate(EvaluationType.REAL, ContextModel());
      return evaluate.toStringAsFixed(evaluate.truncateToDouble() == evaluate ? 0 : 2);
    } catch (err) {
      return '0';
    }
  }

  @override
  Widget build(BuildContext context) {
    var textTheme = Theme.of(context).textTheme;
    var color = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      child: Container(
        decoration: BoxDecoration(
          color: color.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.primaryContainer.withValues(alpha: 0.3), color.surface],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    input.isEmpty ? '0' : input,
                    style: textTheme.headlineSmall?.copyWith(
                      color: color.onSurfaceVariant,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    result.isEmpty ? '' : '= $result',
                    style: textTheme.headlineMedium?.copyWith(
                      color: color.primary,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                children: [
                  _buildButtonRow(['AC', '⌫', '÷'], color, textTheme),
                  SizedBox(height: 8),
                  _buildButtonRow(['7', '8', '9', '×'], color, textTheme),
                  SizedBox(height: 8),
                  _buildButtonRow(['4', '5', '6', '-'], color, textTheme),
                  SizedBox(height: 8),
                  _buildButtonRow(['1', '2', '3', '+'], color, textTheme),
                  SizedBox(height: 8),
                  _buildButtonRow(['0', '.', '=', '✓'], color, textTheme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtonRow(List<String> buttons, ColorScheme color, TextTheme textTheme) {
    return Row(
      children: buttons.map((btn) => Expanded(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 3),
          child: _buildButton(btn, color, textTheme),
        ),
      )).toList(),
    );
  }

  Widget _buildButton(String text, ColorScheme color, TextTheme textTheme) {
    final isOperator = ['÷', '×', '-', '+', '='].contains(text);
    final isSpecial = ['AC', '⌫', '✓'].contains(text);
    final isConfirm = text == '✓';
    
    Color bgColor;
    Color textColor;
    
    if (isConfirm) {
      bgColor = color.primary;
      textColor = color.onPrimary;
    } else if (isSpecial) {
      bgColor = color.errorContainer;
      textColor = color.onErrorContainer;
    } else if (isOperator) {
      bgColor = color.primaryContainer;
      textColor = color.onPrimaryContainer;
    } else {
      bgColor = color.surfaceContainerHighest;
      textColor = color.onSurface;
    }

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => onButtonPressed(text),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 56,
          alignment: Alignment.center,
          child: Text(
            text,
            style: textTheme.titleLarge?.copyWith(
              color: textColor,
              fontWeight: isOperator || isSpecial ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
