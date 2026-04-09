import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/extension/case_extention.dart';
import 'package:mudra_manager/core/extension/string_extention.dart';

void main() {
  group('StringUtil extension', () {
    test('substringAfterLast', () {
      expect('a.b.c'.substringAfterLast('.'), 'c');
      expect('no_dot'.substringAfterLast('.'), 'no_dot');
      expect('one.two'.substringAfterLast('.'), 'two');
    });

    test('substringAfter', () {
      expect('a.b.c'.substringAfter('.'), 'b.c');
      expect('no_dot'.substringAfter('.'), 'no_dot');
    });

    test('substringBefore', () {
      expect('a.b.c'.substringBefore('.'), 'a');
      expect('no_dot'.substringBefore('.'), 'no_dot');
    });

    test('substringBeforeLast', () {
      expect('a.b.c'.substringBeforeLast('.'), 'a.b');
      expect('no_dot'.substringBeforeLast('.'), 'no_dot');
    });

    test('toInt', () {
      expect('42'.toInt(), 42);
      expect('abc'.toInt(), 0);
      expect('abc'.toInt(defaultValue: -1), -1);
    });

    test('isNotNumeric', () {
      expect('123'.isNotNumeric(), false);
      expect('12.5'.isNotNumeric(), false);
      expect('1,234'.isNotNumeric(), false); // comma stripped
      expect('abc'.isNotNumeric(), true);
      expect(''.isNotNumeric(), true);
    });

    test('toDouble', () {
      expect('3.14'.toDouble(), 3.14);
      expect('1,234'.toDouble(), 1234.0);
      expect('abc'.toDouble(), 0.0);
      expect('abc'.toDouble(defaultValue: -1), -1.0);
    });

    test('toNumericOnly', () {
      expect('₹1,234.50'.toNumericOnly(), '1234.50');
      expect('USD 99'.toNumericOnly(), '99');
      expect('abc'.toNumericOnly(), '');
    });
  });

  group('CaseExtension', () {
    test('toTitleCase', () {
      expect('hello world'.toTitleCase(), 'Hello World');
      expect('HELLO WORLD'.toTitleCase(), 'Hello World');
    });

    test('toSnakeCase', () {
      expect('hello world'.toSnakeCase(), 'hello_world');
      expect('Hello World'.toSnakeCase(), 'hello_world');
    });

    test('toKebabCase', () {
      expect('hello world'.toKebabCase(), 'hello-world');
    });

    test('capitalize', () {
      expect('hello world'.capitalize(), 'Hello World');
    });

    test('toPascalCase', () {
      expect('hello world'.toPascalCase(), 'Hello World');
    });

    test('toCamelCase', () {
      expect('hello world'.toCamelCase(), 'HelloWorld');
    });
  });
}
