import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';

class AdminDainikShlokScreen extends StatefulWidget {
  const AdminDainikShlokScreen({super.key, required this.token});

  final String token;

  @override
  State<AdminDainikShlokScreen> createState() => _AdminDainikShlokScreenState();
}

class _AdminDainikShlokScreenState extends State<AdminDainikShlokScreen> {
  final ApiService _api = ApiService();
  final _shlokCtrl = TextEditingController();
  final _translationCtrl = TextEditingController();
  final _sourceCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _shlokCtrl.dispose();
    _translationCtrl.dispose();
    _sourceCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _api.adminGetDailyQuote(widget.token);
    if (!mounted) return;
    if (data != null) {
      _shlokCtrl.text = data.shlok;
      _translationCtrl.text = data.translation;
      _sourceCtrl.text = data.source;
    }
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    final shlok = _shlokCtrl.text.trim();
    final translation = _translationCtrl.text.trim();
    final source = _sourceCtrl.text.trim();
    if (shlok.isEmpty || translation.isEmpty || source.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('All fields are required')));
      return;
    }

    setState(() => _saving = true);
    final updated = await _api.adminPatchDailyQuote(widget.token, {
      'shlok': shlok,
      'translation': translation,
      'source': source,
    });
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(updated != null ? 'Dainik shlok updated' : 'Update failed')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dainik Shlok (admin)'),
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
                  TextField(
                    controller: _shlokCtrl,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Shlok',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    minLines: 3,
                    maxLines: 6,
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _translationCtrl,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Translation',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    minLines: 3,
                    maxLines: 6,
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _sourceCtrl,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Source',
                      hintText: 'e.g. Bhagavad Gita 2.47',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 18),
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
                          Row(
                            children: const [
                              Icon(Icons.preview_rounded, size: 18, color: AppColors.krishnaBlue),
                              SizedBox(width: 8),
                              Text(
                                'Live preview',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.krishnaBlue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _shlokCtrl.text.trim().isEmpty
                                ? 'Shlok will appear here'
                                : _shlokCtrl.text.trim(),
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _translationCtrl.text.trim().isEmpty
                                ? 'Translation will appear here'
                                : _translationCtrl.text.trim(),
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.45,
                              color: AppColors.warmGrey,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _sourceCtrl.text.trim().isEmpty
                                ? 'Source'
                                : '— ${_sourceCtrl.text.trim()}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
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
                    label: Text(_saving ? 'Saving...' : 'Save'),
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
