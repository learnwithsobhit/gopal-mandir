// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

class PickedPdfFile {
  final String name;
  final Uint8List bytes;

  const PickedPdfFile({required this.name, required this.bytes});
}

/// Flutter Web implementation — bypasses `file_picker` (which throws
/// `LateInitializationError: Field '' has not been initialized` in some
/// browser/version combos when asked for a single PDF with `withData: true`)
/// and uses a plain `<input type="file" accept="application/pdf">` element
/// driven by the same pattern already used for image/video uploads in
/// `web_upload_picker_web.dart`.
Future<PickedPdfFile?> pickPdfForUpload() async {
  final completer = Completer<html.File?>();
  final input = html.FileUploadInputElement()
    ..accept = 'application/pdf,.pdf'
    ..multiple = false;

  input.onChange.listen((_) {
    if (completer.isCompleted) return;
    final files = input.files;
    if (files != null && files.isNotEmpty) {
      completer.complete(files.first);
    } else {
      completer.complete(null);
    }
  });

  input.click();

  final file = await completer.future.timeout(
    const Duration(minutes: 5),
    onTimeout: () => null,
  );
  if (file == null) return null;

  final bytes = await _readFileAsBytes(file);
  if (bytes == null || bytes.isEmpty) return null;
  return PickedPdfFile(name: file.name, bytes: bytes);
}

Future<Uint8List?> _readFileAsBytes(html.File file) async {
  try {
    final reader = html.FileReader();
    final completer = Completer<void>();
    reader.onLoadEnd.listen((_) {
      if (!completer.isCompleted) completer.complete();
    });
    reader.onError.listen((_) {
      if (!completer.isCompleted) completer.complete();
    });
    reader.readAsArrayBuffer(file);
    await completer.future.timeout(
      const Duration(minutes: 2),
      onTimeout: () {},
    );
    final dynamic result = reader.result;
    if (result == null) return null;
    if (result is Uint8List) return result;
    if (result is ByteBuffer) return result.asUint8List();
    if (result is List<int>) return Uint8List.fromList(result);
    try {
      return (result as ByteBuffer).asUint8List();
    } catch (_) {}
    return null;
  } catch (_) {
    return null;
  }
}
