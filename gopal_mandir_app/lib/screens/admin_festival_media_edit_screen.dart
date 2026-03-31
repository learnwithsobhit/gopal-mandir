import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_service.dart';

class AdminFestivalMediaEditScreen extends StatefulWidget {
  const AdminFestivalMediaEditScreen({
    super.key,
    required this.token,
    required this.festivalId,
    this.existing,
  });

  final String token;
  final int festivalId;
  final FestivalMediaItem? existing;

  @override
  State<AdminFestivalMediaEditScreen> createState() => _AdminFestivalMediaEditScreenState();
}

class _AdminFestivalMediaEditScreenState extends State<AdminFestivalMediaEditScreen> {
  final ApiService _api = ApiService();
  final _titleCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();
  final _videoCtrl = TextEditingController();
  final _sortCtrl = TextEditingController(text: '0');
  String _type = 'image';
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _titleCtrl.text = e.title;
      _imageCtrl.text = e.imageUrl;
      _videoCtrl.text = e.videoUrl;
      _sortCtrl.text = e.sortOrder.toString();
      _type = e.mediaType;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _imageCtrl.dispose();
    _videoCtrl.dispose();
    _sortCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final sort = int.tryParse(_sortCtrl.text.trim()) ?? 0;
    FestivalMediaItem? out;
    if (_isEdit) {
      out = await _api.adminPatchFestivalMedia(widget.token, widget.existing!.id, {
        'title': _titleCtrl.text.trim(),
        'image_url': _imageCtrl.text.trim(),
        'video_url': _videoCtrl.text.trim(),
        'media_type': _type,
        'sort_order': sort,
      });
    } else {
      out = await _api.adminCreateFestivalMedia(
        widget.token,
        widget.festivalId,
        title: _titleCtrl.text.trim(),
        imageUrl: _imageCtrl.text.trim(),
        videoUrl: _videoCtrl.text.trim(),
        mediaType: _type,
        sortOrder: sort,
      );
    }
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.pop(context, out != null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Festival Media' : 'New Festival Media')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _type,
            items: const [
              DropdownMenuItem(value: 'image', child: Text('Image')),
              DropdownMenuItem(value: 'video', child: Text('Video')),
            ],
            onChanged: (v) => setState(() => _type = v ?? 'image'),
            decoration: const InputDecoration(labelText: 'Media type', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _imageCtrl,
            decoration: const InputDecoration(
              labelText: 'Image URL',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _videoCtrl,
            decoration: const InputDecoration(
              labelText: 'Video URL',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _sortCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Sort order', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Saving...' : 'Save'),
          ),
        ],
      ),
    );
  }
}
