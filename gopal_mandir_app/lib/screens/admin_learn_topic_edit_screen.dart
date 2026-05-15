import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/locale_scope.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';

class AdminLearnTopicEditScreen extends StatefulWidget {
  const AdminLearnTopicEditScreen({
    super.key,
    required this.token,
    this.existing,
  });

  final String token;
  final AdminLearnTopic? existing;

  @override
  State<AdminLearnTopicEditScreen> createState() =>
      _AdminLearnTopicEditScreenState();
}

class _AdminLearnTopicEditScreenState extends State<AdminLearnTopicEditScreen> {
  final ApiService _api = ApiService();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleCtrl;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _teacherCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _scheduleCtrl;
  late final TextEditingController _durationCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _maxCtrl;
  late final TextEditingController _sortCtrl;

  String _delivery = 'online';
  bool _published = false;
  bool _saving = false;

  bool get _isNew => widget.existing == null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _categoryCtrl = TextEditingController(text: e?.categoryKey ?? 'general');
    _teacherCtrl = TextEditingController(text: e?.teacherName ?? '');
    _descriptionCtrl = TextEditingController(text: e?.description ?? '');
    _scheduleCtrl = TextEditingController(text: e?.scheduleSummary ?? '');
    _durationCtrl = TextEditingController(text: e?.durationSummary ?? '');
    _locationCtrl = TextEditingController(text: e?.locationNote ?? '');
    _maxCtrl = TextEditingController(
      text: e?.maxParticipants != null ? '${e!.maxParticipants}' : '',
    );
    _sortCtrl = TextEditingController(text: '${e?.sortOrder ?? 0}');
    _delivery = e?.deliveryMode ?? 'online';
    _published = e?.isPublished ?? false;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _categoryCtrl.dispose();
    _teacherCtrl.dispose();
    _descriptionCtrl.dispose();
    _scheduleCtrl.dispose();
    _durationCtrl.dispose();
    _locationCtrl.dispose();
    _maxCtrl.dispose();
    _sortCtrl.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      _toast('Title required');
      return;
    }
    final sort = int.tryParse(_sortCtrl.text.trim()) ?? 0;
    int? max;
    final maxRaw = _maxCtrl.text.trim();
    if (maxRaw.isNotEmpty) {
      max = int.tryParse(maxRaw);
      if (max == null || max <= 0) {
        _toast('Max participants must be a positive number or empty');
        return;
      }
    }

    final body = <String, dynamic>{
      'title': title,
      'category_key': _categoryCtrl.text.trim().isEmpty
          ? 'general'
          : _categoryCtrl.text.trim(),
      'teacher_name': _teacherCtrl.text.trim(),
      'description': _descriptionCtrl.text.trim(),
      'delivery_mode': _delivery,
      'schedule_summary': _scheduleCtrl.text.trim(),
      'duration_summary': _durationCtrl.text.trim(),
      'location_note': _locationCtrl.text.trim().isEmpty
          ? null
          : _locationCtrl.text.trim(),
      'max_participants': max,
      'is_published': _published,
      'sort_order': sort,
    };

    setState(() => _saving = true);
    AdminLearnTopic? result;
    try {
      result = _isNew
          ? await _api.adminCreateLearnTopic(widget.token, body)
          : await _api.adminPatchLearnTopic(
              widget.token,
              widget.existing!.id,
              body,
            );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    if (!mounted) return;
    if (result != null) {
      Navigator.pop(context, true);
    } else {
      _toast('Save failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocaleScope.of(context).strings;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? s.adminLearnNewTopicTitle : s.adminLearnEditTopicTitle),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleCtrl,
              decoration: InputDecoration(labelText: s.adminLearnTopicTitle),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _categoryCtrl,
              decoration: InputDecoration(labelText: s.adminLearnCategoryKey),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _teacherCtrl,
              decoration: InputDecoration(labelText: s.adminLearnTeacher),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _delivery,
              decoration: InputDecoration(labelText: s.adminLearnDeliveryMode),
              items: [
                DropdownMenuItem(value: 'online', child: Text(s.learnDeliveryOnline)),
                DropdownMenuItem(value: 'offline', child: Text(s.learnDeliveryOffline)),
                DropdownMenuItem(value: 'both', child: Text(s.learnDeliveryBoth)),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _delivery = v);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _scheduleCtrl,
              decoration: InputDecoration(labelText: s.adminLearnScheduleSummary),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _durationCtrl,
              decoration: InputDecoration(labelText: s.adminLearnDurationSummary),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _locationCtrl,
              decoration: InputDecoration(labelText: s.adminLearnLocationNote),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _maxCtrl,
              decoration: InputDecoration(labelText: s.adminLearnMaxParticipantsHint),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _sortCtrl,
              decoration: InputDecoration(labelText: s.adminLearnSortOrder),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'-?[0-9]*'))],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionCtrl,
              decoration: InputDecoration(labelText: s.adminLearnDescription),
              maxLines: 6,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: Text(s.adminLearnPublished),
              value: _published,
              onChanged: (v) => setState(() => _published = v),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.krishnaBlue,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(s.adminLearnSave),
            ),
          ],
        ),
      ),
    );
  }
}
