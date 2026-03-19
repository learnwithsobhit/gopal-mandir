import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../models/models.dart';

class AdminSevaItemEditScreen extends StatefulWidget {
  const AdminSevaItemEditScreen({super.key, required this.token, this.existing});

  final String token;
  final SevaItem? existing;

  @override
  State<AdminSevaItemEditScreen> createState() => _AdminSevaItemEditScreenState();
}

class _AdminSevaItemEditScreenState extends State<AdminSevaItemEditScreen> {
  final ApiService _api = ApiService();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  bool _available = true;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text = e.name;
      _descCtrl.text = e.description;
      _priceCtrl.text = e.price.toStringAsFixed(0);
      _categoryCtrl.text = e.category;
      _available = e.available;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final category = _categoryCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text.trim());
    if (name.isEmpty || category.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and category are required')),
      );
      return;
    }
    if (price == null || price < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid price')),
      );
      return;
    }

    setState(() => _saving = true);

    final body = <String, dynamic>{
      'name': name,
      'description': _descCtrl.text.trim(),
      'price': price,
      'category': category,
      'available': _available,
    };

    dynamic result;
    if (_isEdit) {
      result = await _api.adminPatchSevaItem(widget.token, widget.existing!.id, body);
    } else {
      result = await _api.adminCreateSevaItem(widget.token, body);
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
        title: Text(_isEdit ? 'Edit Seva Item' : 'New Seva Item'),
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
            TextField(
              controller: _priceCtrl,
              decoration: const InputDecoration(
                labelText: 'Price (₹)',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _categoryCtrl,
              decoration: const InputDecoration(
                labelText: 'Category',
                hintText: 'e.g. Daily Seva, Special Seva',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            SwitchListTile(
              title: const Text('Available'),
              subtitle: Text(_available ? 'Visible to devotees' : 'Hidden from devotees'),
              value: _available,
              activeColor: AppColors.krishnaBlue,
              onChanged: (v) => setState(() => _available = v),
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
