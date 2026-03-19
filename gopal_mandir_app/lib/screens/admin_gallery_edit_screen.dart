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

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _titleCtrl.text = e.title;
      _categoryCtrl.text = e.category;
      _imageUrlCtrl.text = e.imageUrl;
      _videoUrlCtrl.text = e.videoUrl;
      _mediaType = e.mediaType.toLowerCase() == 'video' ? 'video' : 'image';
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

  static (String ext, String mime) _mimeForFileName(String name) {
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    String mime;
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        mime = 'image/jpeg';
        break;
      case 'png':
        mime = 'image/png';
        break;
      case 'webp':
        mime = 'image/webp';
        break;
      case 'gif':
        mime = 'image/gif';
        break;
      case 'mp4':
        mime = 'video/mp4';
        break;
      case 'mov':
        mime = 'video/quicktime';
        break;
      default:
        mime = 'application/octet-stream';
    }
    return (ext, mime);
  }

  Future<void> _pickAndUpload() async {
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
        fileExt: ext.isEmpty ? (mime.contains('video') ? 'mp4' : 'jpg') : ext,
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
      if (widget.existing == null) {
        final body = <String, dynamic>{
          'title': title,
          'category': category,
          'media_type': _mediaType,
          'image_url': _imageUrlCtrl.text.trim(),
          'video_url': _videoUrlCtrl.text.trim().isEmpty ? null : _videoUrlCtrl.text.trim(),
        };
        final created = await _api.adminCreateGallery(widget.token, body);
        if (!mounted) return;
        if (created != null) {
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Create failed')));
        }
      } else {
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
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'New gallery item' : 'Edit gallery item'),
        backgroundColor: AppColors.krishnaBlue,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _categoryCtrl,
            decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            // ignore: deprecated_member_use
            value: _mediaType,
            decoration: const InputDecoration(labelText: 'Media type', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'image', child: Text('Image')),
              DropdownMenuItem(value: 'video', child: Text('Video')),
            ],
            onChanged: (v) => setState(() => _mediaType = v ?? 'image'),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _uploading ? null : _pickAndUpload,
            icon: _uploading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.cloud_upload),
            label: Text(_uploading ? 'Uploading…' : 'Pick file & upload to S3'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.peacockGreen),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _imageUrlCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Image URL (thumbnail / poster)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _videoUrlCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Video URL',
              border: OutlineInputBorder(),
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
      ),
    );
  }
}
