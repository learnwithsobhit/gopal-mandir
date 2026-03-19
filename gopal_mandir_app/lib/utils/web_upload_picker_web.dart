import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

class PickedUploadFile {
  final String name;
  final Uint8List bytes;

  const PickedUploadFile({required this.name, required this.bytes});
}

Future<PickedUploadFile?> pickFileForUpload() async {
  final completer = Completer<html.File?>();
  final input = html.FileUploadInputElement()
    ..accept = 'image/jpeg,image/png,image/webp,image/gif,video/mp4,video/quicktime';

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
  return PickedUploadFile(name: file.name, bytes: bytes);
}

Future<Uint8List?> _readFileAsBytes(html.File file) async {
  try {
    final reader = html.FileReader();
    final loadCompleter = Completer<void>();

    reader.onLoadEnd.listen((_) {
      if (!loadCompleter.isCompleted) loadCompleter.complete();
    });
    reader.onError.listen((_) {
      if (!loadCompleter.isCompleted) loadCompleter.complete();
    });

    reader.readAsArrayBuffer(file);

    await loadCompleter.future.timeout(
      const Duration(minutes: 2),
      onTimeout: () {},
    );

    final dynamic result = reader.result;
    if (result == null) return null;

    if (result is Uint8List) return result;
    if (result is ByteBuffer) return result.asUint8List();
    if (result is List<int>) return Uint8List.fromList(result);

    // For JS ArrayBuffer objects that don't match Dart ByteBuffer,
    // try wrapping via Uint8List.view on the dynamic cast.
    try {
      return (result as ByteBuffer).asUint8List();
    } catch (_) {}

    // Try constructing Uint8List from the native buffer via html helper
    try {
      final blob = html.Blob([result]);
      final blobReader = html.FileReader();
      final blobCompleter = Completer<Uint8List?>();
      blobReader.onLoadEnd.listen((_) {
        if (blobCompleter.isCompleted) return;
        final r = blobReader.result;
        if (r is String) {
          // data URL -> decode base64
          final comma = r.indexOf(',');
          if (comma >= 0) {
            try {
              final decoded = html.window.atob(r.substring(comma + 1));
              final bytes = Uint8List(decoded.length);
              for (var i = 0; i < decoded.length; i++) {
                bytes[i] = decoded.codeUnitAt(i);
              }
              blobCompleter.complete(bytes);
              return;
            } catch (_) {}
          }
        }
        blobCompleter.complete(null);
      });
      blobReader.onError.listen((_) {
        if (!blobCompleter.isCompleted) blobCompleter.complete(null);
      });
      blobReader.readAsDataUrl(blob);
      return await blobCompleter.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () => null,
      );
    } catch (_) {}

    return null;
  } catch (_) {
    return null;
  }
}
