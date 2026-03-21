import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../models/models.dart';

class AdminAartiEditScreen extends StatefulWidget {
  const AdminAartiEditScreen({super.key, required this.token, this.existing});

  final String token;
  final AartiSchedule? existing;

  @override
  State<AdminAartiEditScreen> createState() => _AdminAartiEditScreenState();
}

class _AdminAartiEditScreenState extends State<AdminAartiEditScreen> {
  final ApiService _api = ApiService();
  final _nameCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _isSpecial = false;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text = e.name;
      _timeCtrl.text = e.time;
      _descCtrl.text = e.description;
      _isSpecial = e.isSpecial;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _timeCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final time = _timeCtrl.text.trim();
    if (name.isEmpty || time.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and time are required')),
      );
      return;
    }

    setState(() => _saving = true);

    final body = <String, dynamic>{
      'name': name,
      'time': time,
      'description': _descCtrl.text.trim(),
      'is_special': _isSpecial,
    };

    dynamic result;
    if (_isEdit) {
      result = await _api.adminPatchAarti(widget.token, widget.existing!.id, body);
    } else {
      result = await _api.adminCreateAarti(widget.token, body);
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
        title: Text(_isEdit ? 'Edit Aarti' : 'New Aarti'),
        backgroundColor: AppColors.krishnaBlue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. Mangla Aarti',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _timeCtrl,
              decoration: const InputDecoration(
                labelText: 'Time',
                hintText: 'e.g. 05:00 AM',
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
              maxLines: 4,
              minLines: 2,
            ),
            const SizedBox(height: 14),
            SwitchListTile(
              title: const Text('Special Aarti'),
              subtitle: Text(_isSpecial ? 'Highlighted in the schedule' : 'Regular aarti'),
              value: _isSpecial,
              activeColor: AppColors.templeGold,
              onChanged: (v) => setState(() => _isSpecial = v),
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
