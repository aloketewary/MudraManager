import 'dart:io';
import 'dart:io' show Directory, File;
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

Future<bool> saveExportedFile(
  Uint8List data,
  String fileName, {
  bool askUser = false,
}) async {
  if (askUser) {
    final extension =
        fileName.contains('.') ? fileName.split('.').last.toLowerCase() : null;
    final savedPath = await FilePicker.saveFile(
      fileName: fileName,
      bytes: data,
      type: extension == null ? FileType.any : FileType.custom,
      allowedExtensions: extension == null ? null : [extension],
    );

    if (savedPath == null) return false;

    await OpenFile.open(savedPath);
    return true;
  }

  final directory = await getSaveDirectory();
  final filePath = '${directory.path}/$fileName';
  final file = File(filePath);
  await file.writeAsBytes(data);
  await OpenFile.open(filePath);
  return true;
}
