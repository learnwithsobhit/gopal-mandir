import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';

class AdminDailyUpasanaEditScreen extends StatefulWidget {
  const AdminDailyUpasanaEditScreen({
    super.key,
    required this.token,
    this.existing,
  });

  final String token;
  final DailyUpasanaItem? existing;

  @override
  State<AdminDailyUpasanaEditScreen> createState() => _AdminDailyUpasanaEditScreenState();
}

class _AdminDailyUpasanaEditScreenState extends State<AdminDailyUpasanaEditScreen> {
  final ApiService _api = ApiService();
  final _titleCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _sortOrderCtrl = TextEditingController(text: '0');
  DateTime _selectedDate = DateTime.now();
  bool _isPublished = true;
  bool _saving = false;

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
      final parts = e.forDate.split('-');
      if (parts.length == 3) {
        _selectedDate = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _categoryCtrl.dispose();
    _contentCtrl.dispose();
    _sortOrderCtrl.dispose();
    super.dispose();
  }

  String get _formattedDate {
    final y = _selectedDate.year.toString().padLeft(4, '0');
    final m = _selectedDate.month.toString().padLeft(2, '0');
    final d = _selectedDate.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();
    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Title and content are required')));
      return;
    }
    final sortOrder = int.tryParse(_sortOrderCtrl.text.trim()) ?? 0;

    setState(() => _saving = true);
    final body = <String, dynamic>{
      'for_date': _formattedDate,
      'title': title,
      'category': _categoryCtrl.text.trim(),
      'content': content,
      'sort_order': sortOrder,
      'is_published': _isPublished,
    };

    final DailyUpasanaItem? result = _isEdit
        ? await _api.adminPatchDailyUpasana(widget.token, widget.existing!.id, body)
        : await _api.adminCreateDailyUpasana(widget.token, body);

    if (!mounted) return;
    setState(() => _saving = false);
    if (result != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_isEdit ? 'Updated' : 'Created')));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_isEdit ? 'Update failed' : 'Create failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Daily Upasana' : 'New Daily Upasana')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date (YYYY-MM-DD)',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(_formattedDate),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleCtrl,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _categoryCtrl,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Category (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _sortOrderCtrl,
              decoration: const InputDecoration(
                labelText: 'Sort order',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Published'),
              subtitle: Text(_isPublished ? 'Visible to users' : 'Draft only'),
              value: _isPublished,
              activeThumbColor: AppColors.templeGold,
              onChanged: (v) => setState(() => _isPublished = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentCtrl,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Content',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              minLines: 5,
              maxLines: 12,
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
                      _titleCtrl.text.trim().isEmpty ? 'Title' : _titleCtrl.text.trim(),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: AppColors.warmGrey,
                      ),
                    ),
                  ],
                ),
              ),
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
              label: Text(_saving ? 'Saving...' : (_isEdit ? 'Update' : 'Create')),
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

