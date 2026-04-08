import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';

class AdminOwnerAccessScreen extends StatefulWidget {
  const AdminOwnerAccessScreen({super.key, required this.token});

  final String token;

  @override
  State<AdminOwnerAccessScreen> createState() => _AdminOwnerAccessScreenState();
}

class _AdminOwnerAccessScreenState extends State<AdminOwnerAccessScreen> {
  final ApiService _api = ApiService();
  final _phoneCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _minutesCtrl = TextEditingController(text: '30');
  bool _loading = true;
  bool _creating = false;
  String? _lastCode;
  String? _error;
  List<AdminOwnerUser> _admins = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _nameCtrl.dispose();
    _minutesCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final rows = await _api.ownerListAdmins(widget.token);
    if (!mounted) return;
    setState(() {
      _admins = rows;
      _loading = false;
    });
  }

  Future<void> _createCode() async {
    setState(() {
      _creating = true;
      _error = null;
      _lastCode = null;
    });
    final mins = int.tryParse(_minutesCtrl.text.trim()) ?? 30;
    final res = await _api.ownerCreateSecretCode(
      widget.token,
      phone: _phoneCtrl.text.trim(),
      name: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
      expiresInMinutes: mins,
    );
    if (!mounted) return;
    setState(() {
      _creating = false;
      _lastCode = res.code;
      _error = res.error;
    });
    if (res.code != null) {
      await _load();
    }
  }

  Future<void> _toggleStatus(AdminOwnerUser user) async {
    if (user.role == 'owner') return;
    final next = user.status == 'active' ? 'disabled' : 'active';
    final res = await _api.ownerPatchAdmin(widget.token, user.id, status: next);
    if (!mounted) return;
    if (!res.success) {
      setState(() => _error = res.message.isEmpty ? 'Failed to update admin' : res.message);
      return;
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Owner access')),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.krishnaBlue,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Generate one-time secret codes and manage admin rights.',
              style: TextStyle(color: AppColors.warmGrey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Name (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _minutesCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Code expiry minutes',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _creating ? null : _createCode,
              style: FilledButton.styleFrom(backgroundColor: AppColors.krishnaBlue),
              child: Text(_creating ? 'Generating...' : 'Generate secret code'),
            ),
            if (_lastCode != null) ...[
              const SizedBox(height: 8),
              SelectableText(
                'Secret code: $_lastCode',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: AppColors.urgentRed)),
            ],
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Admins',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (_loading)
              const Center(child: CircularProgressIndicator(color: AppColors.krishnaBlue))
            else
              ..._admins.map(
                (a) => Card(
                  child: ListTile(
                    title: Text(a.name.isEmpty ? a.phone : '${a.name} (${a.phone})'),
                    subtitle: Text('${a.role} • ${a.status}'),
                    trailing: a.role == 'owner'
                        ? const Icon(Icons.verified_user, color: AppColors.krishnaBlue)
                        : Switch(
                            value: a.status == 'active',
                            onChanged: (_) => _toggleStatus(a),
                          ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
