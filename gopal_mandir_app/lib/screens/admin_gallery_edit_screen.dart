import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../models/models.dart';
import '../utils/web_upload_picker_stub.dart'
    if (dart.library.html) '../utils/web_upload_picker_web.dart';

class AdminGalleryEditScreen extends StatefulWidget {
  const AdminGalleryEditScreen({super.key, required this.token, this.existing});

  final String token;
  final GalleryItem? existing;

  @override
  State<AdminGalleryEditScreen> createState() => _AdminGalleryEditScreenState();
}

class _AdminGalleryEditScreenState extends State<AdminGalleryEditScreen> {
  final ApiService _api = ApiService();
  final _titleCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();
  final _videoUrlCtrl = TextEditingController();

  String _mediaType = 'image';
  bool _saving = false;
  bool _uploading = false;
  String _uploadStatus = '';

  // Matches server-side MAX_PRESIGN_BYTES in gopal_mandir_api/src/admin.rs.
  static const int _maxPresignBytes = 100 * 1024 * 1024;
  // Keep in sync with admin_festival_media_screen.dart for consistent UX.
  static const int _parallelUploadLimit = 4;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _titleCtrl.text = e.title;
      _categoryCtrl.text = e.category;
      _imageUrlCtrl.text = e.imageUrl;
      _videoUrlCtrl.text = e.videoUrl;
      final mt = e.mediaType.toLowerCase();
      if (mt == 'video') {
        _mediaType = 'video';
      } else if (mt == 'audio') {
        _mediaType = 'audio';
      } else {
        _mediaType = 'image';
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _categoryCtrl.dispose();
    _imageUrlCtrl.dispose();
    _videoUrlCtrl.dispose();
    super.dispose();
  }

  bool get _isNewItem => widget.existing == null;

  static (String ext, String mime) _mimeForFileName(String name) {
    final (ext, mime, _) = _mediaForFileName(name);
    return (ext, mime);
  }

  /// Infer (extension, MIME, mediaType) from a file name. Returns an empty
  /// mediaType when the extension is unknown so callers can skip the file.
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
      case 'mp3':
        return (ext, 'audio/mpeg', 'audio');
      default:
        return (ext, 'application/octet-stream', '');
    }
  }

  static String _titleFromFileName(String name) {
    final lastDot = name.lastIndexOf('.');
    final base = lastDot > 0 ? name.substring(0, lastDot) : name;
    return base.replaceAll('_', ' ').trim();
  }

  static const String _allowedTypesNote =
      'Allowed: JPG, JPEG, PNG, WEBP, GIF, MP4, MOV';

  /// New-item flow: pick multiple files and create one gallery row per file.
  ///
  /// Uploads run in parallel batches of [_parallelUploadLimit] so a large pick
  /// still feels responsive. Form `title` is used as a shared override when
  /// set; otherwise each row gets a title derived from its filename.
  Future<void> _batchPickAndUpload() async {
    final category = _categoryCtrl.text.trim();
    if (category.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category is required before uploading')),
      );
      return;
    }
    final sharedTitle = _titleCtrl.text.trim();

    final files = await pickFilesForUpload();
    if (files.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No files selected')),
      );
      return;
    }

    setState(() {
      _uploading = true;
      _uploadStatus = 'Starting upload…';
    });

    var uploaded = 0;
    var failed = 0;
    var skipped = 0;
    var completed = 0;
    var tooLarge = 0;
    final unsupportedExts = <String>{};

    Future<String> processSingleFile(int i) async {
      final file = files[i];
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
        fileExt: ext.isEmpty
            ? (mediaType == 'video'
                ? 'mp4'
                : mediaType == 'audio'
                    ? 'mp3'
                    : 'jpg')
            : ext,
        objectKeyPrefix: 'gallery',
        sizeBytes: file.bytes.length,
      );
      if (presign == null) return 'failed';

      final putOk = await _api.uploadBytesToPresignedUrl(
        presign.uploadUrl,
        contentType: mime,
        bytes: file.bytes,
      );
      if (!putOk) return 'failed';

      final title = sharedTitle.isNotEmpty
          ? sharedTitle
          : _titleFromFileName(file.name);
      final body = <String, dynamic>{
        'title': title,
        'category': category,
        'media_type': mediaType,
        'image_url': mediaType == 'image' ? presign.publicUrl : '',
        'video_url': mediaType == 'image' ? null : presign.publicUrl,
      };
      final created = await _api.adminCreateGallery(widget.token, body);
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

    final unsupportedMsg = unsupportedExts.isEmpty
        ? ''
        : ' Unsupported format(s): ${unsupportedExts.join(', ')}. $_allowedTypesNote';
    final tooLargeMsg =
        tooLarge == 0 ? '' : ' $tooLarge file(s) skipped (>100 MB).';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Batch upload complete: created $uploaded, failed $failed, skipped $skipped.$tooLargeMsg$unsupportedMsg',
        ),
      ),
    );

    if (uploaded > 0 && mounted) {
      Navigator.pop(context, true);
    }
  }

  /// Edit-mode flow: pick a single file and drop its public URL into the
  /// relevant form field so the user can click "Save to database" to update
  /// just this one gallery row. Unchanged from the original behavior.
  Future<void> _pickAndUploadSingle() async {
    setState(() => _uploading = true);
    try {
      final picked = await pickFileForUpload();
      if (picked == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No file selected or could not read file.')),
          );
        }
        setState(() => _uploading = false);
        return;
      }
      final Uint8List bytes = picked.bytes;
      final String name = picked.name;

      if (bytes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not read selected file bytes. Please pick again.')),
          );
        }
        setState(() => _uploading = false);
        return;
      }
      final (ext, mime) = _mimeForFileName(name);
      if (mime == 'application/octet-stream') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unsupported file type')));
        }
        setState(() => _uploading = false);
        return;
      }

      final presign = await _api.adminPresign(
        widget.token,
        contentType: mime,
        fileExt: ext.isEmpty
            ? (mime.contains('video')
                ? 'mp4'
                : mime.startsWith('audio/')
                    ? 'mp3'
                    : 'jpg')
            : ext,
        objectKeyPrefix: 'gallery',
        sizeBytes: bytes.length,
      );
      if (presign == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Presign failed — check S3 env on server')),
          );
        }
        setState(() => _uploading = false);
        return;
      }

      final put = await http.put(
        Uri.parse(presign.uploadUrl),
        headers: {'Content-Type': mime},
        body: bytes,
      );
      if (put.statusCode < 200 || put.statusCode >= 300) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Upload failed: ${put.statusCode}')),
          );
        }
        setState(() => _uploading = false);
        return;
      }

      if (mime.startsWith('video/')) {
        setState(() {
          _mediaType = 'video';
          _videoUrlCtrl.text = presign.publicUrl;
          if (_imageUrlCtrl.text.trim().isEmpty) {
            _imageUrlCtrl.text = '';
          }
        });
      } else if (mime.startsWith('audio/')) {
        setState(() {
          _mediaType = 'audio';
          _videoUrlCtrl.text = presign.publicUrl;
        });
      } else {
        setState(() {
          _mediaType = 'image';
          _imageUrlCtrl.text = presign.publicUrl;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload complete')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    final category = _categoryCtrl.text.trim();
    if (title.isEmpty || category.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title and category required')));
      return;
    }
    setState(() => _saving = true);
    try {
      // Only edit mode reaches this code path now; new-item mode uses the
      // batch upload flow above which creates rows server-side directly.
      final body = <String, dynamic>{
        'title': title,
        'category': category,
        'media_type': _mediaType,
        'image_url': _imageUrlCtrl.text.trim(),
        'video_url': _videoUrlCtrl.text.trim(),
      };
      final updated = await _api.adminPatchGallery(widget.token, widget.existing!.id, body);
      if (!mounted) return;
      if (updated != null) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Update failed')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = _isNewItem;
    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? 'New gallery item(s)' : 'Edit gallery item'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleCtrl,
            decoration: InputDecoration(
              labelText: isNew ? 'Title (optional — defaults to filename)' : 'Title',
              helperText: isNew
                  ? 'If left blank, each uploaded file gets its own title from the filename.'
                  : null,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _categoryCtrl,
            decoration: const InputDecoration(
              labelText: 'Category (required)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          if (!isNew)
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _mediaType,
              decoration: const InputDecoration(labelText: 'Media type', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'image', child: Text('Image')),
                DropdownMenuItem(value: 'video', child: Text('Video')),
                DropdownMenuItem(value: 'audio', child: Text('Audio (MP3)')),
              ],
              onChanged: (v) => setState(() => _mediaType = v ?? 'image'),
            ),
          if (!isNew) const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _uploading
                ? null
                : (isNew ? _batchPickAndUpload : _pickAndUploadSingle),
            icon: _uploading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.cloud_upload),
            label: Text(
              _uploading
                  ? (_uploadStatus.isEmpty ? 'Uploading…' : _uploadStatus)
                  : (isNew
                      ? 'Pick files & upload (multiple)'
                      : 'Pick file & upload to S3'),
            ),
            style: FilledButton.styleFrom(backgroundColor: AppColors.peacockGreen),
          ),
          if (isNew) ...[
            const SizedBox(height: 8),
            Text(
              'Uploads run in parallel (max 4 at a time) and create one gallery item per file. $_allowedTypesNote',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (!isNew) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _imageUrlCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Image URL (thumbnail / poster)',
                helperText: _mediaType == 'audio' ? 'Optional cover art for the gallery tile' : null,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _videoUrlCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: _mediaType == 'audio' ? 'Audio URL (MP3)' : 'Video URL',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.krishnaBlue,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save to database'),
            ),
          ],
        ],
      ),
    );
  }
}
