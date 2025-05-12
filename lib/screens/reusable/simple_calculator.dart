import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:mudra_manager/screens/reusable/common_button.dart';

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
    setState(() {
      if (value == 'Clr') {
        input = '';
        result = '';
      } else if (value == 'C') {
        if(input.isNotEmpty) {
          input = input.substring(0, input.length - 1);
          result = '';
        }
      } else if (value == '=') {
        try {
          final expression = input.replaceAll('×', '*').replaceAll('÷', '/');
          final eval = double.parse(_evaluate(expression).toStringAsFixed(2));
          result = eval.toString();
        } catch (e) {
          result = 'Error';
        }
      } else if (value == 'Use') {
        if (result.isNotEmpty) {
          widget.onResultSelected(double.tryParse(result) ?? 0);
        }
      } else {
        input += value;
      }
    });
  }

  double _evaluate(String expression) {
    // Very basic parser: recommend `math_expressions` for production
    final exp = expression.replaceAll(' ', '');
    return double.parse(_simpleEval(exp));
  }

  String _simpleEval(String expression) {
    // You can replace this with a better parser like `math_expressions`
    try {
      ExpressionParser p = ShuntingYardParser();
      Expression exp = p.parse(expression);
      var evaluate = exp.evaluate(EvaluationType.REAL, ContextModel());
      return evaluate.toStringAsFixed(evaluate.truncateToDouble() == evaluate ? 0 : 2);
    } catch (err) {
      print(err);
      return '0';
    }
  }

  @override
  Widget build(BuildContext context) {
    var textTheme = Theme.of(context).textTheme;
    var color = Theme.of(context).colorScheme;
    const buttons = [
      ['7', '8', '9', '÷'],
      ['4', '5', '6', '×'],
      ['1', '2', '3', '-'],
      ['0', '.', '=', '+'],
      ['Clr', 'C', 'Use'],
    ];

    return Column(
      children: [
        Text(
          input,
          style: textTheme.titleLarge?.copyWith(color: color.secondary),
        ),
        Text(
          result,
          style: textTheme.titleLarge?.copyWith(
            color: color.primary,
            fontSize: 24,
          ),
        ),
        ...buttons.map(
          (row) => Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children:
                row.map((btn) {
                  return Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CommonButton(
                      onPressed: () => onButtonPressed(btn),
                      text: btn,
                      textStyle: textTheme.titleLarge?.copyWith(
                        color: color.onPrimary,
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }
}
