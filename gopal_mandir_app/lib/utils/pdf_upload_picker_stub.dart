import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

class PickedPdfFile {
  final String name;
  final Uint8List bytes;

  const PickedPdfFile({required this.name, required this.bytes});
}

/// Mobile/desktop implementation: use `file_picker`. On those platforms
/// `file_picker`'s native bindings are reliable, so we stick with the
/// cross-platform package instead of writing three more wrappers.
Future<PickedPdfFile?> pickPdfForUpload() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['pdf'],
    withData: true,
  );
  if (result == null || result.files.isEmpty) return null;
  final f = result.files.first;
  Uint8List? bytes;
  String name = 'upload.pdf';
  try {
    name = f.name;
  } catch (_) {}
  try {
    bytes = f.bytes;
  } catch (_) {}
  if (bytes == null || bytes.isEmpty) return null;
  return PickedPdfFile(name: name, bytes: bytes);
}
