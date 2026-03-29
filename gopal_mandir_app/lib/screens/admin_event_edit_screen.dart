import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../models/models.dart';
import '../utils/web_upload_picker_stub.dart'
    if (dart.library.html) '../utils/web_upload_picker_web.dart';

class AdminEventEditScreen extends StatefulWidget {
  const AdminEventEditScreen({super.key, required this.token, this.existing});

  final String token;
  final Event? existing;

  @override
  State<AdminEventEditScreen> createState() => _AdminEventEditScreenState();
}

class _AdminEventEditScreenState extends State<AdminEventEditScreen> {
  final ApiService _api = ApiService();
  final _titleCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();
  bool _isFeatured = false;
  bool _saving = false;
  bool _uploading = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _titleCtrl.text = e.title;
      _dateCtrl.text = e.date;
      _descCtrl.text = e.description;
      _imageUrlCtrl.text = e.imageUrl ?? '';
      _isFeatured = e.isFeatured;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _dateCtrl.dispose();
    _descCtrl.dispose();
    _imageUrlCtrl.dispose();
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
            const SnackBar(content: Text('Could not read file bytes.')),
          );
        }
        setState(() => _uploading = false);
        return;
      }
      final (ext, mime) = _mimeForFileName(name);
      if (mime == 'application/octet-stream') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unsupported file type — use JPG, PNG, WebP or GIF')),
          );
        }
        setState(() => _uploading = false);
        return;
      }

      final presign = await _api.adminPresign(
        widget.token,
        contentType: mime,
        fileExt: ext.isEmpty ? 'jpg' : ext,
        objectKeyPrefix: 'events',
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

      setState(() => _imageUrlCtrl.text = presign.publicUrl);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload complete')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    final date = _dateCtrl.text.trim();
    if (title.isEmpty || date.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and date are required')),
      );
      return;
    }

    setState(() => _saving = true);

    final body = <String, dynamic>{
      'title': title,
      'date': date,
      'description': _descCtrl.text.trim(),
      'image_url': _imageUrlCtrl.text.trim().isEmpty ? null : _imageUrlCtrl.text.trim(),
      'is_featured': _isFeatured,
    };

    dynamic result;
    if (_isEdit) {
      result = await _api.adminPatchEvent(widget.token, widget.existing!.id, body);
    } else {
      result = await _api.adminCreateEvent(widget.token, body);
    }

    if (!mounted) return;
    setState(() => _saving = false);

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEdit ? 'Updated' : 'Created')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEdit ? 'Update failed' : 'Create failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Event' : 'New Event'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _dateCtrl,
              decoration: const InputDecoration(
                labelText: 'Date',
                hintText: 'e.g. March 30, 2026',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              minLines: 3,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _imageUrlCtrl,
              decoration: const InputDecoration(
                labelText: 'Image URL',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: _uploading ? null : _pickAndUpload,
              child: _uploading
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Uploading…'),
                      ],
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.upload, size: 18),
                        SizedBox(width: 6),
                        Text('Upload image'),
                      ],
                    ),
            ),
            const SizedBox(height: 14),
            SwitchListTile(
              title: const Text('Featured'),
              subtitle: Text(_isFeatured ? 'Shown on home screen' : 'Regular event'),
              value: _isFeatured,
              activeColor: AppColors.templeGold,
              onChanged: (v) => setState(() => _isFeatured = v),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save),
              label: Text(_saving ? 'Saving…' : (_isEdit ? 'Update' : 'Create')),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.krishnaBlue,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
