import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class FilePickerService {
  /*
A utility service to handle file picking across the app. It uses the file_picker package to allow users to select files from their device. The service provides a method to show the file picker dialog and returns the selected file's path. It also restricts the allowed file types to common document and image formats for better user experience.
  */

  static Future<String?> showFilePicker(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
    );

    if (result != null && result.files.isNotEmpty) {
      return result.files.single.path;
    }
    return null;
  }

  static Future<String?> showMultipleFilesPicker(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
    );

    if (result != null && result.files.isNotEmpty) {
      return result.files.single.path;
    }
    return null;
  }
}

final filePickerService = FilePickerService();
