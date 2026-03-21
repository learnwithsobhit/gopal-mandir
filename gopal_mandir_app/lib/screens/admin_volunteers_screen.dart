import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../models/models.dart';

class AdminVolunteersScreen extends StatefulWidget {
  const AdminVolunteersScreen({super.key, required this.token});

  final String token;

  @override
  State<AdminVolunteersScreen> createState() => _AdminVolunteersScreenState();
}

class _AdminVolunteersScreenState extends State<AdminVolunteersScreen> {
  final ApiService _api = ApiService();
  List<VolunteerView> _volunteers = [];
  bool _loading = true;
  String? _statusFilter;

  static const _statusChoices = ['new', 'contacted', 'approved', 'rejected'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _api.adminListVolunteers(
      widget.token,
      status: _statusFilter,
    );
    if (mounted) setState(() { _volunteers = data; _loading = false; });
  }

  Future<void> _changeStatus(VolunteerView v) async {
    final chosen = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('Update Status for ${v.name}'),
        children: _statusChoices.map((s) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, s),
            child: Row(
              children: [
                Icon(
                  s == v.status ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: _statusColor(s),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(s[0].toUpperCase() + s.substring(1)),
              ],
            ),
          );
        }).toList(),
      ),
    );
    if (chosen == null || chosen == v.status) return;

    final ok = await _api.adminPatchVolunteerStatus(widget.token, v.id, chosen);
    if (ok) {
      _load();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update volunteer status')),
      );
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'new':
        return Colors.blue;
      case 'contacted':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
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
      appBar: AppBar(title: const Text('Volunteer Requests')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text('Status: '),
                const SizedBox(width: 8),
                DropdownButton<String?>(
                  value: _statusFilter,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All')),
                    ..._statusChoices.map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Text(s[0].toUpperCase() + s.substring(1)),
                      ),
                    ),
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
                : _volunteers.isEmpty
                    ? const Center(child: Text('No volunteer requests found'))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _volunteers.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) => _card(_volunteers[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _card(VolunteerView v) {
    return Card(
      child: InkWell(
        onTap: () => _changeStatus(v),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(v.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  ),
                  Chip(
                    label: Text(
                      v.status[0].toUpperCase() + v.status.substring(1),
                      style: const TextStyle(fontSize: 11, color: Colors.white),
                    ),
                    backgroundColor: _statusColor(v.status),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              _infoRow(Icons.phone, v.phone),
              if (v.email != null && v.email!.isNotEmpty)
                _infoRow(Icons.email_outlined, v.email!),
              if (v.area.isNotEmpty) _infoRow(Icons.category_outlined, 'Area: ${v.area}'),
              if (v.availability.isNotEmpty) _infoRow(Icons.schedule, 'Availability: ${v.availability}'),
              if (v.message.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(v.message, style: TextStyle(fontSize: 13, color: AppColors.warmGrey)),
              ],
              const SizedBox(height: 4),
              Text('Submitted ${_fmtDate(v.createdAt)}', style: TextStyle(fontSize: 11, color: AppColors.warmGrey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.warmGrey),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
