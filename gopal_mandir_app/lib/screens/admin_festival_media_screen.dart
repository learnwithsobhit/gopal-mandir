import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import 'admin_festival_media_edit_screen.dart';
import '../utils/web_upload_picker_stub.dart'
    if (dart.library.html) '../utils/web_upload_picker_web.dart';

class AdminFestivalMediaScreen extends StatefulWidget {
  const AdminFestivalMediaScreen({
    super.key,
    required this.token,
    required this.festival,
  });

  final String token;
  final FestivalEntry festival;

  @override
  State<AdminFestivalMediaScreen> createState() => _AdminFestivalMediaScreenState();
}

class _AdminFestivalMediaScreenState extends State<AdminFestivalMediaScreen> {
  final ApiService _api = ApiService();
  static const int _parallelUploadLimit = 4;
  static const int _maxPresignBytes = 100 * 1024 * 1024; // backend MAX_PRESIGN_BYTES
  bool _loading = true;
  bool _uploading = false;
  String _uploadStatus = '';
  List<FestivalMediaItem> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await _api.adminListFestivalMedia(widget.token, widget.festival.id);
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _delete(FestivalMediaItem item) async {
    final ok = await _api.adminDeleteFestivalMedia(widget.token, item.id);
    if (ok) _load();
  }

  static (String ext, String mime, String mediaType) _mediaForFileName(String name) {
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return (ext, 'image/jpeg', 'image');
      case 'png':
        return (ext, 'image/png', 'image');
      case 'webp':
        return (ext, 'image/webp', 'image');
      case 'gif':
        return (ext, 'image/gif', 'image');
      case 'mp4':
        return (ext, 'video/mp4', 'video');
      case 'mov':
        return (ext, 'video/quicktime', 'video');
      default:
        return (ext, 'application/octet-stream', '');
    }
  }

  static String _titleFromFileName(String name) {
    final lastDot = name.lastIndexOf('.');
    final base = lastDot > 0 ? name.substring(0, lastDot) : name;
    return base.replaceAll('_', ' ').trim();
  }

  static const String _allowedTypesNote = 'Allowed: JPG, JPEG, PNG, WEBP, GIF, MP4, MOV (DNG not supported)';

  Future<void> _batchUploadToS3() async {
    final files = await pickFilesForUpload();
    if (files.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No files selected')),
      );
      return;
    }

    final currentMaxSort = _items.isEmpty
        ? 0
        : _items.map((e) => e.sortOrder).reduce((a, b) => a > b ? a : b);

    setState(() {
      _uploading = true;
      _uploadStatus = 'Starting upload...';
    });

    var uploaded = 0;
    var failed = 0;
    var skipped = 0;
    var completed = 0;
    var tooLarge = 0;
    final unsupportedExts = <String>{};

    Future<String> processSingleFile(int i) async {
      final file = files[i];
      final sortOrder = currentMaxSort + 1 + i;
      if (!mounted) return 'failed';
      setState(() {
        _uploadStatus = 'Uploading ${i + 1}/${files.length}: ${file.name}';
      });

      final (ext, mime, mediaType) = _mediaForFileName(file.name);
      if (mediaType.isEmpty || file.bytes.isEmpty) {
        if (ext.isNotEmpty) unsupportedExts.add(ext.toUpperCase());
        return 'skipped';
      }
      if (file.bytes.length > _maxPresignBytes) {
        tooLarge++;
        return 'skipped';
      }

      final presign = await _api.adminPresign(
        widget.token,
        contentType: mime,
        fileExt: ext.isEmpty ? (mediaType == 'video' ? 'mp4' : 'jpg') : ext,
        objectKeyPrefix: 'festival-media',
        sizeBytes: file.bytes.length,
      );
      if (presign == null) return 'failed';

      final putOk = await _api.uploadBytesToPresignedUrl(
        presign.uploadUrl,
        contentType: mime,
        bytes: file.bytes,
      );
      if (!putOk) return 'failed';

      final created = await _api.adminCreateFestivalMedia(
        widget.token,
        widget.festival.id,
        title: _titleFromFileName(file.name),
        imageUrl: mediaType == 'image' ? presign.publicUrl : '',
        videoUrl: mediaType == 'video' ? presign.publicUrl : '',
        mediaType: mediaType,
        sortOrder: sortOrder,
      );
      return created == null ? 'failed' : 'uploaded';
    }

    for (var start = 0; start < files.length; start += _parallelUploadLimit) {
      final end = (start + _parallelUploadLimit) > files.length
          ? files.length
          : (start + _parallelUploadLimit);
      final futures = <Future<String>>[];
      for (var i = start; i < end; i++) {
        futures.add(processSingleFile(i));
      }
      final results = await Future.wait(futures);
      for (final result in results) {
        if (result == 'uploaded') {
          uploaded++;
        } else if (result == 'skipped') {
          skipped++;
        } else {
          failed++;
        }
        completed++;
      }
      if (!mounted) return;
      setState(() {
        _uploadStatus = 'Uploaded progress: $completed/${files.length}';
      });
    }

    if (!mounted) return;
    setState(() {
      _uploading = false;
      _uploadStatus = '';
    });
    await _load();
    if (!mounted) return;
    final unsupportedMsg = unsupportedExts.isEmpty
        ? ''
        : ' Unsupported format(s): ${unsupportedExts.join(', ')}. $_allowedTypesNote';
    final tooLargeMsg = tooLarge == 0
        ? ''
        : ' $tooLarge file(s) skipped because size is over 100 MB.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Batch upload complete: uploaded $uploaded, failed $failed, skipped $skipped.$tooLargeMsg$unsupportedMsg'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Media: ${widget.festival.title}')),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: _uploading
            ? null
            : () async {
          await Navigator.push<bool>(
            context,
            MaterialPageRoute<bool>(
              builder: (_) => AdminFestivalMediaEditScreen(
                token: widget.token,
                festivalId: widget.festival.id,
              ),
            ),
          );
          _load();
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FilledButton.icon(
                  onPressed: _uploading ? null : _batchUploadToS3,
                  icon: _uploading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.cloud_upload),
                  label: Text(_uploading ? (_uploadStatus.isEmpty ? 'Uploading...' : _uploadStatus) : 'Upload files to S3 (multiple)'),
                ),
                const SizedBox(height: 6),
                Text(
                  'Note: uploads run in parallel (max 4 files at a time). $_allowedTypesNote',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (_, i) {
                      final item = _items[i];
                      return ListTile(
                        leading: Icon(item.isVideo ? Icons.videocam : Icons.image),
                        title: Text(item.title),
                        subtitle: Text('${item.mediaType} | sort: ${item.sortOrder}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () async {
                                await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute<bool>(
                                    builder: (_) => AdminFestivalMediaEditScreen(
                                      token: widget.token,
                                      festivalId: widget.festival.id,
                                      existing: item,
                                    ),
                                  ),
                                );
                                _load();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _delete(item),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
