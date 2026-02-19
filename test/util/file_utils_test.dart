import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/utils/file_utils.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getExternalStoragePath() async {
    return '/mock/external/storage';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    PathProviderPlatform.instance = MockPathProviderPlatform();
  });

  group('getSaveDirectory', () {
    test('returns app-specific directory without permission', () async {
      final directory = await getSaveDirectory(askUser: false);
      
      expect(directory, isNotNull);
      expect(directory.path, contains('/mock/external/storage'));
    });

    test('does not require storage permission', () async {
      final directory = await getSaveDirectory(askUser: false);
      
      expect(directory, isNotNull);
    });
  });

  group('File Operations', () {
    test('saveExportedFile accepts Uint8List data', () {
      final testData = Uint8List.fromList([1, 2, 3, 4, 5]);
      final fileName = 'test_export.txt';
      
      expect(
        () => saveExportedFile(testData, fileName, askUser: false),
        returnsNormally,
      );
    });
  });
}
