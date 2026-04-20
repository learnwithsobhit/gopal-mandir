import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_language.dart';
import '../l10n/locale_scope.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';

/// Each daily-upasana item is either a rich-text article or a PDF book; admins
/// pick the mode up-front. Mode is persisted as "content is non-empty" vs
/// "pdf_url is non-empty" on the backend — switching modes clears the other
/// column on save.
enum _UpasanaMode { text, pdf }

class AdminDailyUpasanaEditScreen extends StatefulWidget {
  const AdminDailyUpasanaEditScreen({
    super.key,
    required this.token,
    this.existing,
  });

  final String token;
  final DailyUpasanaItem? existing;

  @override
  State<AdminDailyUpasanaEditScreen> createState() =>
      _AdminDailyUpasanaEditScreenState();
}

class _AdminDailyUpasanaEditScreenState
    extends State<AdminDailyUpasanaEditScreen> {
  final ApiService _api = ApiService();
  final _titleCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _pagesCtrl = TextEditingController();
  final _sortOrderCtrl = TextEditingController(text: '0');

  _UpasanaMode _mode = _UpasanaMode.text;
  bool _isPublished = true;
  bool _saving = false;
  bool _uploadingPdf = false;
  String _pdfUrl = '';
  String? _pdfFilename;

  static const int _maxPdfBytes = 50 * 1024 * 1024;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _titleCtrl.text = e.title;
      _categoryCtrl.text = e.category;
      _contentCtrl.text = e.content;
      _sortOrderCtrl.text = e.sortOrder.toString();
      _isPublished = e.isPublished;
      _pdfUrl = e.pdfUrl;
      _pagesCtrl.text = e.pageCount?.toString() ?? '';
      _mode = e.isPdf ? _UpasanaMode.pdf : _UpasanaMode.text;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _categoryCtrl.dispose();
    _contentCtrl.dispose();
    _pagesCtrl.dispose();
    _sortOrderCtrl.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pickAndUploadPdf() async {
    final s = AppLocaleScope.of(context).strings;
    FilePickerResult? picked;
    try {
      picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
        withData: true,
      );
    } catch (e) {
      _toast('${s.adminUpasanaPickFailed}: $e');
      return;
    }
    if (picked == null || picked.files.isEmpty) return;
    final f = picked.files.first;
    final Uint8List? bytes = f.bytes;
    if (bytes == null || bytes.isEmpty) {
      _toast(s.adminUpasanaPickFailed);
      return;
    }
    if (bytes.length > _maxPdfBytes) {
      _toast(s.adminUpasanaPdfTooLarge);
      return;
    }

    setState(() => _uploadingPdf = true);
    try {
      final presign = await _api.adminPresign(
        widget.token,
        contentType: 'application/pdf',
        fileExt: 'pdf',
        objectKeyPrefix: 'daily_upasana',
        sizeBytes: bytes.length,
        cacheControl: 'public, max-age=604800',
      );
      if (presign == null) {
        _toast(s.adminUpasanaUploadFailed);
        return;
      }
      final ok = await _api.uploadBytesToPresignedUrl(
        presign.uploadUrl,
        contentType: 'application/pdf',
        bytes: bytes,
        cacheControl: presign.cacheControl,
      );
      if (!ok) {
        _toast(s.adminUpasanaUploadFailed);
        return;
      }
      if (!mounted) return;
      setState(() {
        _pdfUrl = presign.publicUrl;
        _pdfFilename = f.name;
      });
      _toast(s.adminUpasanaPdfUploaded);
    } finally {
      if (mounted) setState(() => _uploadingPdf = false);
    }
  }

  Future<void> _save() async {
    final s = AppLocaleScope.of(context).strings;
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      _toast(s.dailyUpasanaAdminRequired);
      return;
    }
    final category = _categoryCtrl.text.trim();
    final sortOrder = int.tryParse(_sortOrderCtrl.text.trim()) ?? 0;

    final isPdf = _mode == _UpasanaMode.pdf;
    final content = _contentCtrl.text.trim();
    if (!isPdf && content.isEmpty) {
      _toast(s.adminUpasanaTextRequired);
      return;
    }
    if (isPdf && _pdfUrl.trim().isEmpty) {
      _toast(s.adminUpasanaPdfRequired);
      return;
    }

    final pagesRaw = _pagesCtrl.text.trim();
    int? pageCount;
    if (isPdf && pagesRaw.isNotEmpty) {
      final n = int.tryParse(pagesRaw);
      if (n != null && n > 0) pageCount = n;
    }

    setState(() => _saving = true);
    // Send both content + pdf_url every time; an empty string on the opposite
    // mode signals the backend to clear that column.
    final body = <String, dynamic>{
      'title': title,
      'category': category,
      'sort_order': sortOrder,
      'is_published': _isPublished,
      'content': isPdf ? '' : content,
      'pdf_url': isPdf ? _pdfUrl.trim() : '',
      'page_count': isPdf ? pageCount : null,
    };

    final DailyUpasanaItem? result = _isEdit
        ? await _api.adminPatchDailyUpasana(
            widget.token, widget.existing!.id, body)
        : await _api.adminCreateDailyUpasana(widget.token, body);

    if (!mounted) return;
    setState(() => _saving = false);
    if (result != null) {
      _toast(_isEdit ? s.updated : s.created);
      Navigator.pop(context, true);
    } else {
      _toast(_isEdit ? s.updateFailed : s.createFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocaleScope.of(context).strings;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? s.dailyUpasanaAdminEdit : s.dailyUpasanaAdminNew),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: s.dailyUpasanaAdminTitle,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _categoryCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: s.dailyUpasanaAdminCategory,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _sortOrderCtrl,
              decoration: InputDecoration(
                labelText: s.dailyUpasanaAdminSort,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: Text(s.dailyUpasanaAdminPublished),
              subtitle: Text(
                _isPublished
                    ? s.dailyUpasanaAdminPublishedSub
                    : s.dailyUpasanaAdminDraftSub,
              ),
              value: _isPublished,
              activeThumbColor: AppColors.templeGold,
              onChanged: (v) => setState(() => _isPublished = v),
            ),
            const SizedBox(height: 12),
            _modePicker(s),
            const SizedBox(height: 16),
            if (_mode == _UpasanaMode.text) _textModeSection(s),
            if (_mode == _UpasanaMode.pdf) _pdfModeSection(s),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: (_saving || _uploadingPdf) ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save),
              label: Text(
                _saving ? s.saving : (_isEdit ? s.update : s.create),
              ),
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

  Widget _modePicker(AppStrings s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.adminUpasanaContentMode,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.darkBrown,
          ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<_UpasanaMode>(
          segments: [
            ButtonSegment(
              value: _UpasanaMode.text,
              label: Text(s.adminUpasanaModeText),
              icon: const Icon(Icons.article_outlined),
            ),
            ButtonSegment(
              value: _UpasanaMode.pdf,
              label: Text(s.adminUpasanaModePdf),
              icon: const Icon(Icons.picture_as_pdf_outlined),
            ),
          ],
          selected: {_mode},
          onSelectionChanged: (sel) {
            final next = sel.first;
            if (next == _mode) return;
            setState(() => _mode = next);
          },
        ),
        const SizedBox(height: 6),
        Text(
          s.adminUpasanaModeHint,
          style: const TextStyle(fontSize: 12, color: AppColors.warmGrey),
        ),
      ],
    );
  }

  Widget _textModeSection(AppStrings s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _contentCtrl,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: s.dailyUpasanaAdminContent,
            hintText: s.dailyUpasanaAdminContentHint,
            border: const OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          minLines: 8,
          maxLines: 16,
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          color: AppColors.krishnaBlue.withAlpha(14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.krishnaBlue.withAlpha(48)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Live preview',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.krishnaBlue,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _titleCtrl.text.trim().isEmpty
                      ? 'Title'
                      : _titleCtrl.text.trim(),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                if (_categoryCtrl.text.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _categoryCtrl.text.trim(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.templeGoldDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  _contentCtrl.text.trim().isEmpty
                      ? 'Content will appear here'
                      : _contentCtrl.text.trim(),
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: AppColors.warmGrey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _pdfModeSection(AppStrings s) {
    final hasPdf = _pdfUrl.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          elevation: 0,
          color: AppColors.templeGold.withAlpha(24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: AppColors.templeGold.withAlpha(70)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.picture_as_pdf_rounded,
                      color: AppColors.templeGoldDark,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        hasPdf
                            ? s.adminUpasanaCurrentPdf
                            : s.adminUpasanaUploadPdf,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkBrown,
                        ),
                      ),
                    ),
                  ],
                ),
                if (hasPdf) ...[
                  const SizedBox(height: 8),
                  SelectableText(
                    _pdfFilename ?? _pdfUrl,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.warmGrey,
                    ),
                    maxLines: 2,
                  ),
                ],
                if (_uploadingPdf) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 10),
                      Text(s.adminUpasanaUploading),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: _uploadingPdf ? null : _pickAndUploadPdf,
                      icon: const Icon(Icons.upload_file),
                      label: Text(
                        hasPdf
                            ? s.adminUpasanaReplacePdf
                            : s.adminUpasanaPickPdf,
                      ),
                    ),
                    if (hasPdf)
                      OutlinedButton.icon(
                        onPressed: _uploadingPdf
                            ? null
                            : () => setState(() {
                                  _pdfUrl = '';
                                  _pdfFilename = null;
                                }),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Remove'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _pagesCtrl,
          decoration: InputDecoration(
            labelText: s.adminUpasanaPdfPages,
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
      ],
    );
  }
}
