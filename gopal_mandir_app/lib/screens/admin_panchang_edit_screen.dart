import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../models/models.dart';

class AdminPanchangEditScreen extends StatefulWidget {
  const AdminPanchangEditScreen({super.key, required this.token, this.existing});

  final String token;
  final HinduPanchang? existing;

  @override
  State<AdminPanchangEditScreen> createState() => _AdminPanchangEditScreenState();
}

class _AdminPanchangEditScreenState extends State<AdminPanchangEditScreen> {
  final ApiService _api = ApiService();
  final _contentCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _contentCtrl.text = e.content;
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
    _contentCtrl.dispose();
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.krishnaBlue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.darkBrown,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    final content = _contentCtrl.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Content cannot be empty')),
      );
      return;
    }

    setState(() => _saving = true);

    HinduPanchang? result;
    if (_isEdit) {
      result = await _api.adminPatchPanchang(
        widget.token,
        widget.existing!.id,
        {'for_date': _formattedDate, 'content': content},
      );
    } else {
      result = await _api.adminCreatePanchang(
        widget.token,
        forDate: _formattedDate,
        content: content,
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
        SnackBar(content: Text(_isEdit ? 'Update failed' : 'Create failed — date may already exist')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Panchang' : 'New Panchang'),
        backgroundColor: AppColors.krishnaBlue,
        foregroundColor: Colors.white,
      ),
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
                child: Text(
                  _formattedDate,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(
                  child: Text('Panchang Content',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                ),
                IconButton(
                  icon: const Icon(Icons.paste, size: 20),
                  tooltip: 'Paste from clipboard',
                  onPressed: () async {
                    final data = await Clipboard.getData(Clipboard.kTextPlain);
                    if (data?.text != null && data!.text!.isNotEmpty) {
                      _contentCtrl.text = data.text!;
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Pasted from clipboard'), duration: Duration(seconds: 1)),
                        );
                      }
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Clipboard is empty')),
                        );
                      }
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  tooltip: 'Copy content',
                  onPressed: () {
                    final text = _contentCtrl.text.trim();
                    if (text.isEmpty) return;
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard'), duration: Duration(seconds: 1)),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _contentCtrl,
              decoration: const InputDecoration(
                hintText: 'तिथि, नक्षत्र, योग, करण, राहुकाल…',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 12,
              minLines: 6,
              keyboardType: TextInputType.multiline,
              enableInteractiveSelection: true,
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
