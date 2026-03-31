import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

class PickedUploadFile {
  final String name;
  final Uint8List bytes;

  const PickedUploadFile({required this.name, required this.bytes});
}

Future<PickedUploadFile?> pickFileForUpload() async {
  final files = await pickFilesForUpload();
  if (files.isEmpty) return null;
  return files.first;
}

Future<List<PickedUploadFile>> pickFilesForUpload() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: const [
      'jpg', 'jpeg', 'png', 'webp', 'gif', 'mp4', 'mov',
    ],
    allowMultiple: true,
    withData: true,
  );
  if (result == null || result.files.isEmpty) return const [];

  final out = <PickedUploadFile>[];
  for (final f in result.files) {
    Uint8List? bytes;
    String name = 'upload.bin';

    try {
      name = f.name;
    } catch (_) {}

    try {
      bytes = f.bytes;
    } catch (_) {}

    if (bytes == null || bytes.isEmpty) continue;
    out.add(PickedUploadFile(name: name, bytes: bytes));
  }
  return out;
}
