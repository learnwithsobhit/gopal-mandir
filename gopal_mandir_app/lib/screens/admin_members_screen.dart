import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../models/models.dart';

class AdminMembersScreen extends StatefulWidget {
  const AdminMembersScreen({super.key, required this.token});

  final String token;

  @override
  State<AdminMembersScreen> createState() => _AdminMembersScreenState();
}

class _AdminMembersScreenState extends State<AdminMembersScreen> {
  final ApiService _api = ApiService();
  List<MemberProfile> _members = [];
  bool _loading = true;
  String? _statusFilter;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _api.adminListMembers(
      widget.token,
      status: _statusFilter,
      search: _searchQuery.isEmpty ? null : _searchQuery,
    );
    if (mounted) setState(() { _members = data; _loading = false; });
  }

  Future<void> _toggleStatus(MemberProfile m) async {
    final newStatus = m.status == 'active' ? 'suspended' : 'active';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${newStatus == 'suspended' ? 'Suspend' : 'Activate'} Member?'),
        content: Text('Set ${m.name} (${m.phone}) to "$newStatus"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(newStatus == 'suspended' ? 'Suspend' : 'Activate'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final ok = await _api.adminPatchMemberStatus(widget.token, m.id, newStatus);
    if (ok) {
      _load();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update member status')),
      );
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'suspended':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _fmtDate(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    try {
      final dt = DateTime.parse(iso);
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Members')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by name or phone…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          _searchQuery = '';
                          _load();
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
              onSubmitted: (v) {
                _searchQuery = v.trim();
                _load();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                const Text('Status: '),
                const SizedBox(width: 8),
                DropdownButton<String?>(
                  value: _statusFilter,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All')),
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(value: 'suspended', child: Text('Suspended')),
                  ],
                  onChanged: (v) {
                    _statusFilter = v;
                    _load();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _members.isEmpty
                    ? const Center(child: Text('No members found'))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _members.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) => _memberCard(_members[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _memberCard(MemberProfile m) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _statusColor(m.status).withAlpha(30),
          child: Icon(Icons.person, color: _statusColor(m.status)),
        ),
        title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(m.phone),
            if (m.email.isNotEmpty) Text(m.email, style: TextStyle(fontSize: 12, color: AppColors.warmGrey)),
            Text('Member since ${_fmtDate(m.createdAt)}', style: TextStyle(fontSize: 11, color: AppColors.warmGrey)),
          ],
        ),
        trailing: Chip(
          label: Text(m.status, style: const TextStyle(fontSize: 11, color: Colors.white)),
          backgroundColor: _statusColor(m.status),
          padding: EdgeInsets.zero,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        isThreeLine: true,
        onTap: () => _toggleStatus(m),
      ),
    );
  }
}
