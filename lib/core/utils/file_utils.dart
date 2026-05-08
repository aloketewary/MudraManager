import 'dart:io';
import 'dart:typed_data' show Uint8List;

import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

Future<Directory> getSaveDirectory({bool askUser = false}) async {
  if (askUser) {
    // SAF: Let user pick location
    final String? selectedDirectory = await FilePicker.getDirectoryPath();
    if (selectedDirectory != null) {
      return Directory(selectedDirectory);
    }
  }

  // Use app-specific storage (no permission needed)
  final fallbackDir = await getExternalStorageDirectory();
  return fallbackDir!;
}

Future<void> saveExportedFile(
  Uint8List data,
  String fileName, {
  bool askUser = false,
}) async {
  final directory = await getSaveDirectory(askUser: askUser);
  final filePath = '${directory.path}/$fileName';

  final file = File(filePath);
  await file.writeAsBytes(data);

  // Optional: open it after save
  OpenFile.open(filePath);
}
