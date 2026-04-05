import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/api_service.dart';
import '../theme/app_colors.dart';

const int _kMaxStreamUrlChars = 2048;

bool adminLiveStreamUrlLooksValid(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return true;
  if (t.length > _kMaxStreamUrlChars) return false;
  final u = Uri.tryParse(t);
  return u != null && u.scheme == 'https' && u.host.isNotEmpty;
}

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

  Future<void> _testOpenStream() async {
    final url = _streamCtrl.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a stream URL first')),
      );
      return;
    }
    if (!adminLiveStreamUrlLooksValid(url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL must be https and at most 2048 characters')),
      );
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null || !await canLaunchUrl(uri)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot open this URL from the device')),
      );
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _save() async {
    final stream = _streamCtrl.text.trim();
    if (_isLive && stream.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Set a stream URL before marking live, or turn off live.')),
      );
      return;
    }
    if (stream.isNotEmpty && !adminLiveStreamUrlLooksValid(stream)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stream URL must be https (max 2048 characters).')),
      );
      return;
    }

    setState(() => _saving = true);
    final updated = await _api.adminPatchLiveDarshan(widget.token, {
      'title': _titleCtrl.text.trim(),
      'stream_url': stream,
      'description': _descCtrl.text.trim(),
      'is_live': _isLive,
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (updated != null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
      _titleCtrl.text = updated.title;
      _streamCtrl.text = updated.streamUrl;
      _descCtrl.text = updated.description;
      _isLive = updated.isLive;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Save failed (check URL is https and live requires URL).')),
      );
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
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Stream URL',
                    hintText: 'https://… (YouTube Live, or HLS .m3u8, or MP4)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 6, left: 4, right: 4),
                  child: Text(
                    'Must be https. YouTube and generic pages open in the browser. '
                    'Direct .m3u8 / .mp4 links can play inside the app (mobile + web). '
                    'You cannot enable Live without a URL.',
                    style: TextStyle(fontSize: 12, color: AppColors.warmGrey),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _testOpenStream,
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Test open stream URL'),
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
