import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';

class AdminLiveDarshanScreen extends StatefulWidget {
  const AdminLiveDarshanScreen({super.key, required this.token});

  final String token;

  @override
  State<AdminLiveDarshanScreen> createState() => _AdminLiveDarshanScreenState();
}

class _AdminLiveDarshanScreenState extends State<AdminLiveDarshanScreen> {
  final ApiService _api = ApiService();
  final _titleCtrl = TextEditingController();
  final _streamCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _isLive = false;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _streamCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final cfg = await _api.adminGetLiveDarshan(widget.token);
    if (!mounted) return;
    if (cfg != null) {
      _titleCtrl.text = cfg.title;
      _streamCtrl.text = cfg.streamUrl;
      _descCtrl.text = cfg.description;
      _isLive = cfg.isLive;
    }
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final updated = await _api.adminPatchLiveDarshan(widget.token, {
      'title': _titleCtrl.text.trim(),
      'stream_url': _streamCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'is_live': _isLive,
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (updated != null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Save failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Darshan'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.krishnaBlue))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _streamCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Stream URL (HLS / YouTube / etc.)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                ),
                SwitchListTile(
                  title: const Text('Mark as live'),
                  value: _isLive,
                  onChanged: (v) => setState(() => _isLive = v),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.krishnaBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save'),
                ),
              ],
            ),
    );
  }
}
