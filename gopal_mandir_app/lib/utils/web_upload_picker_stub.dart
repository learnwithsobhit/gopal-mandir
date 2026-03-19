import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

class PickedUploadFile {
  final String name;
  final Uint8List bytes;

  const PickedUploadFile({required this.name, required this.bytes});
}

Future<PickedUploadFile?> pickFileForUpload() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: const [
      'jpg', 'jpeg', 'png', 'webp', 'gif', 'mp4', 'mov',
    ],
    withData: true,
  );
  if (result == null || result.files.isEmpty) return null;

  final f = result.files.first;
  Uint8List? bytes;
  String name = 'upload.bin';

  try {
    name = f.name;
  } catch (_) {}

  try {
    bytes = f.bytes;
  } catch (_) {}

  if (bytes == null || bytes.isEmpty) return null;
  return PickedUploadFile(name: name, bytes: bytes);
}
