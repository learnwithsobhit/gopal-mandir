import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';

class AdminFestivalEditScreen extends StatefulWidget {
  const AdminFestivalEditScreen({super.key, required this.token, this.existing});

  final String token;
  final FestivalEntry? existing;

  @override
  State<AdminFestivalEditScreen> createState() => _AdminFestivalEditScreenState();
}

class _AdminFestivalEditScreenState extends State<AdminFestivalEditScreen> {
  final ApiService _api = ApiService();
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _sortOrderCtrl = TextEditingController(text: '0');
  DateTime _selectedDate = DateTime.now();
  bool _isActive = true;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _titleCtrl.text = e.title;
      _descriptionCtrl.text = e.description;
      _sortOrderCtrl.text = e.sortOrder.toString();
      _isActive = e.isActive;
      final parts = e.forDate.split('-');
      if (parts.length == 3) {
        _selectedDate = DateTime(
          int.tryParse(parts[0]) ?? _selectedDate.year,
          int.tryParse(parts[1]) ?? _selectedDate.month,
          int.tryParse(parts[2]) ?? _selectedDate.day,
        );
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _sortOrderCtrl.dispose();
    super.dispose();
  }

  String get _forDate {
    final y = _selectedDate.year.toString().padLeft(4, '0');
    final m = _selectedDate.month.toString().padLeft(2, '0');
    final d = _selectedDate.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    final description = _descriptionCtrl.text.trim();
    final sortOrder = int.tryParse(_sortOrderCtrl.text.trim()) ?? 0;
    if (title.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and description are required')),
      );
      return;
    }

    setState(() => _saving = true);
    FestivalEntry? result;
    if (_isEdit) {
      result = await _api.adminPatchFestival(
        widget.token,
        widget.existing!.id,
        {
          'for_date': _forDate,
          'title': title,
          'description': description,
          'sort_order': sortOrder,
          'is_active': _isActive,
        },
      );
    } else {
      result = await _api.adminCreateFestival(
        widget.token,
        forDate: _forDate,
        title: title,
        description: description,
        sortOrder: sortOrder,
        isActive: _isActive,
      );
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
      appBar: AppBar(title: Text(_isEdit ? 'Edit Festival' : 'New Festival')),
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
                child: Text(_forDate),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _descriptionCtrl,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _sortOrderCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Sort Order',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
              activeThumbColor: AppColors.krishnaBlue,
              title: const Text('Active'),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save),
              label: Text(_saving ? 'Saving...' : (_isEdit ? 'Update' : 'Create')),
              style: FilledButton.styleFrom(backgroundColor: AppColors.krishnaBlue),
            ),
          ],
        ),
      ),
    );
  }
}
