import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/locale_scope.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../utils/web_upload_picker_stub.dart'
    if (dart.library.html) '../utils/web_upload_picker_web.dart';

/// Create / edit a single [Succession] row. The photo is uploaded via the
/// existing presigned-S3 flow (mirrors [AdminGalleryEditScreen]) so we never
/// stream bytes through the API server.
class AdminSuccessionEditScreen extends StatefulWidget {
  const AdminSuccessionEditScreen({
    super.key,
    required this.token,
    this.existing,
  });

  final String token;
  final Succession? existing;

  @override
  State<AdminSuccessionEditScreen> createState() =>
      _AdminSuccessionEditScreenState();
}

class _AdminSuccessionEditScreenState extends State<AdminSuccessionEditScreen> {
  final ApiService _api = ApiService();
  final _formKey = GlobalKey<FormState>();

  final _positionCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _tenureTextCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _quoteCtrl = TextEditingController();
  final _photoUrlCtrl = TextEditingController();

  DateTime? _tenureStart;
  DateTime? _tenureEnd;
  bool _saving = false;
  bool _uploading = false;

  bool get _isNew => widget.existing == null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _positionCtrl.text = '${e.position}';
      _nameCtrl.text = e.name;
      _titleCtrl.text = e.title ?? '';
      _tenureTextCtrl.text = e.tenureText ?? '';
      _bioCtrl.text = e.bio ?? '';
      _quoteCtrl.text = e.quote ?? '';
      _photoUrlCtrl.text = e.photoUrl ?? '';
      _tenureStart = e.tenureStart;
      _tenureEnd = e.tenureEnd;
    }
  }

  @override
  void dispose() {
    _positionCtrl.dispose();
    _nameCtrl.dispose();
    _titleCtrl.dispose();
    _tenureTextCtrl.dispose();
    _bioCtrl.dispose();
    _quoteCtrl.dispose();
    _photoUrlCtrl.dispose();
    super.dispose();
  }

  static (String ext, String mime) _mimeForFileName(String name) {
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return (ext, 'image/jpeg');
      case 'png':
        return (ext, 'image/png');
      case 'webp':
        return (ext, 'image/webp');
      case 'gif':
        return (ext, 'image/gif');
      default:
        return (ext, 'application/octet-stream');
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    setState(() => _uploading = true);
    try {
      final picked = await pickFileForUpload();
      if (picked == null) {
        setState(() => _uploading = false);
        return;
      }
      final Uint8List bytes = picked.bytes;
      final name = picked.name;
      if (bytes.isEmpty) {
        _toast('Could not read file bytes');
        setState(() => _uploading = false);
        return;
      }
      final (ext, mime) = _mimeForFileName(name);
      if (!mime.startsWith('image/')) {
        _toast('Only images supported');
        setState(() => _uploading = false);
        return;
      }
      final presign = await _api.adminPresign(
        widget.token,
        contentType: mime,
        fileExt: ext.isEmpty ? 'jpg' : ext,
        objectKeyPrefix: 'successions',
        sizeBytes: bytes.length,
      );
      if (presign == null) {
        _toast('Presign failed');
        setState(() => _uploading = false);
        return;
      }
      final ok = await _api.uploadBytesToPresignedUrl(
        presign.uploadUrl,
        contentType: mime,
        bytes: bytes,
      );
      if (!ok) {
        _toast('Upload failed');
        setState(() => _uploading = false);
        return;
      }
      setState(() => _photoUrlCtrl.text = presign.publicUrl);
      _toast('Photo uploaded');
    } catch (e) {
      _toast('Error: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pickDate(bool isStart) async {
    final initial =
        (isStart ? _tenureStart : _tenureEnd) ?? DateTime(1900, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1500),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _tenureStart = picked;
      } else {
        _tenureEnd = picked;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final position = int.tryParse(_positionCtrl.text.trim());
    if (position == null) {
      _toast('Position must be a number');
      return;
    }
    final body = <String, dynamic>{
      'position': position,
      'name': _nameCtrl.text.trim(),
      'title': _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
      'tenure_text': _tenureTextCtrl.text.trim().isEmpty
          ? null
          : _tenureTextCtrl.text.trim(),
      'tenure_start': _formatDate(_tenureStart),
      'tenure_end': _formatDate(_tenureEnd),
      'bio': _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
      'quote': _quoteCtrl.text.trim().isEmpty ? null : _quoteCtrl.text.trim(),
      'photo_url': _photoUrlCtrl.text.trim().isEmpty
          ? null
          : _photoUrlCtrl.text.trim(),
    };

    setState(() => _saving = true);
    try {
      final result = _isNew
          ? await _api.adminCreateSuccession(widget.token, body)
          : await _api.adminPatchSuccession(
              widget.token,
              widget.existing!.id,
              body,
            );
      if (!mounted) return;
      if (result == null) {
        _toast('Save failed');
      } else {
        _toast('Saved');
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  static String? _formatDate(DateTime? d) {
    if (d == null) return null;
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocaleScope.of(context).strings;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? s.adminSuccessionNew : s.adminSuccessionEdit),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _positionCtrl,
              decoration: InputDecoration(
                labelText: s.fieldPosition,
                hintText: '1, 2, 3 …',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                labelText: s.fieldTitle,
                hintText: 'Mahant, Acharya …',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _tenureTextCtrl,
              decoration: InputDecoration(
                labelText: s.fieldTenure,
                hintText: 'c. 1890 – 1945',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DateField(
                    label: s.fieldTenureStart,
                    value: _tenureStart,
                    onTap: () => _pickDate(true),
                    onClear: () => setState(() => _tenureStart = null),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateField(
                    label: s.fieldTenureEnd,
                    value: _tenureEnd,
                    onTap: () => _pickDate(false),
                    onClear: () => setState(() => _tenureEnd = null),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bioCtrl,
              decoration: InputDecoration(labelText: s.fieldBio),
              maxLines: 6,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _quoteCtrl,
              decoration: InputDecoration(labelText: s.fieldQuote),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            Text(
              s.fieldPhoto,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.darkBrown,
              ),
            ),
            const SizedBox(height: 8),
            // Listen to the controller so pasted URLs also refresh the
            // preview (upload already calls setState, but manual edits do
            // not trigger a parent rebuild on their own).
            AnimatedBuilder(
              animation: _photoUrlCtrl,
              builder: (_, __) => _PhotoPreview(url: _photoUrlCtrl.text),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _photoUrlCtrl,
              decoration: const InputDecoration(
                labelText: 'Photo URL (optional)',
                helperText: 'Auto-filled after upload',
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _uploading ? null : _pickAndUploadPhoto,
                icon: _uploading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload_file),
                label: Text(_uploading ? 'Uploading…' : 'Upload photo'),
              ),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.templeGoldDark,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(_saving ? 'Saving…' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    required this.onClear,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final text = value == null
        ? '—'
        : '${value!.year.toString().padLeft(4, '0')}-${value!.month.toString().padLeft(2, '0')}-${value!.day.toString().padLeft(2, '0')}';
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: value == null
              ? const Icon(Icons.calendar_today, size: 18)
              : IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onClear,
                ),
        ),
        child: Text(text),
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.trim().isEmpty) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.templeGold.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.warmGrey.withAlpha(60)),
        ),
        alignment: Alignment.center,
        child: const Text(
          'No photo',
          style: TextStyle(color: AppColors.warmGrey),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 160,
        width: double.infinity,
        child: CachedNetworkImage(
          imageUrl: ApiService.galleryProxyUrl(url, width: 600, quality: 80),
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            color: AppColors.templeGold.withAlpha(20),
          ),
          errorWidget: (_, __, ___) => Container(
            color: AppColors.templeGold.withAlpha(40),
            alignment: Alignment.center,
            child: const Icon(Icons.broken_image_outlined),
          ),
        ),
      ),
    );
  }
}
