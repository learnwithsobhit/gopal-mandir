import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_colors.dart';

class AdminTempleAboutScreen extends StatefulWidget {
  const AdminTempleAboutScreen({super.key, required this.token});

  final String token;

  @override
  State<AdminTempleAboutScreen> createState() => _AdminTempleAboutScreenState();
}

class _AdminTempleAboutScreenState extends State<AdminTempleAboutScreen> {
  final ApiService _api = ApiService();
  final _contentCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _api.getTempleInfo();
    if (!mounted) return;
    _contentCtrl.text = data.aboutContent;
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final updated = await _api.adminPatchTempleAbout(widget.token, _contentCtrl.text);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(updated != null ? 'About temple updated' : 'Update failed')),
    );
    if (updated != null) {
      _contentCtrl.text = updated.aboutContent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Temple (admin)'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loading ? null : _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.krishnaBlue))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'This text appears on More → About Temple for all users.',
                    style: TextStyle(color: AppColors.warmGrey, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _contentCtrl,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'About / history',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    minLines: 12,
                    maxLines: 24,
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save),
                    label: Text(_saving ? 'Saving…' : 'Save'),
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
