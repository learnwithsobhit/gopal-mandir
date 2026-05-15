import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/locale_scope.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';

class AdminLearnRegistrationsScreen extends StatefulWidget {
  const AdminLearnRegistrationsScreen({super.key, required this.token});

  final String token;

  @override
  State<AdminLearnRegistrationsScreen> createState() =>
      _AdminLearnRegistrationsScreenState();
}

class _AdminLearnRegistrationsScreenState
    extends State<AdminLearnRegistrationsScreen> {
  final ApiService _api = ApiService();
  List<AdminLearnRegistrationView> _rows = [];
  List<AdminLearnTopic> _topics = [];
  bool _loading = true;
  int? _topicFilter;
  String? _statusFilter;

  static const _statuses = ['new', 'confirmed', 'cancelled', 'waitlist'];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() => _loading = true);
    final topics = await _api.adminListLearnTopics(widget.token);
    final regs = await _api.adminListLearnRegistrations(
      widget.token,
      topicId: _topicFilter,
      status: _statusFilter,
    );
    if (!mounted) return;
    setState(() {
      _topics = topics;
      _rows = regs;
      _loading = false;
    });
  }

  Future<void> _loadRegs() async {
    setState(() => _loading = true);
    final regs = await _api.adminListLearnRegistrations(
      widget.token,
      topicId: _topicFilter,
      status: _statusFilter,
    );
    if (!mounted) return;
    setState(() {
      _rows = regs;
      _loading = false;
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'new':
        return Colors.blue;
      case 'confirmed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'waitlist':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _fmtDate(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    try {
      return DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  Future<void> _edit(AdminLearnRegistrationView r) async {
    final s = AppLocaleScope.of(context).strings;
    final noteCtrl = TextEditingController(text: r.adminNote);
    String status = r.status;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(s.adminLearnUpdateRegistration),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(r.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: status,
                      decoration: InputDecoration(labelText: s.adminLearnFilterStatus),
                      items: _statuses
                          .map(
                            (x) => DropdownMenuItem(
                              value: x,
                              child: Text(x[0].toUpperCase() + x.substring(1)),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setDialogState(() => status = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: noteCtrl,
                      decoration: InputDecoration(labelText: s.adminLearnAdminNote),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(s.adminLearnSave),
                ),
              ],
            );
          },
        );
      },
    );

    final noteText = noteCtrl.text;
    noteCtrl.dispose();
    if (saved != true) return;

    final ok = await _api.adminPatchLearnRegistration(
      widget.token,
      r.id,
      status: status == r.status ? null : status,
      adminNote: noteText,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Updated' : 'Update failed')),
    );
    if (ok) _loadRegs();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocaleScope.of(context).strings;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.adminLearnRegistrations),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _bootstrap),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    value: _topicFilter,
                    decoration: InputDecoration(labelText: s.adminLearnFilterTopic),
                    items: [
                      DropdownMenuItem<int?>(
                        value: null,
                        child: Text(s.adminLearnFilterAll),
                      ),
                      ..._topics.map(
                        (t) => DropdownMenuItem<int?>(
                          value: t.id,
                          child: Text(
                            t.title,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (v) {
                      _topicFilter = v;
                      _loadRegs();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: _statusFilter,
                    decoration:
                        InputDecoration(labelText: s.adminLearnFilterStatus),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(s.adminLearnFilterAll),
                      ),
                      ..._statuses.map(
                        (x) => DropdownMenuItem<String?>(
                          value: x,
                          child: Text(x[0].toUpperCase() + x.substring(1)),
                        ),
                      ),
                    ],
                    onChanged: (v) {
                      _statusFilter = v;
                      _loadRegs();
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _rows.isEmpty
                    ? Center(child: Text(s.learnEmpty))
                    : RefreshIndicator(
                        onRefresh: _bootstrap,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _rows.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) => _card(_rows[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _card(AdminLearnRegistrationView r) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _edit(r),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      r.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Chip(
                    label: Text(
                      r.status[0].toUpperCase() + r.status.substring(1),
                      style: const TextStyle(fontSize: 11, color: Colors.white),
                    ),
                    backgroundColor: _statusColor(r.status),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                r.topicTitle,
                style: TextStyle(fontSize: 13, color: AppColors.krishnaBlue),
              ),
              _infoRow(Icons.phone, r.phone),
              if (r.email != null && r.email!.trim().isNotEmpty)
                _infoRow(Icons.email_outlined, r.email!),
              if (r.notes != null && r.notes!.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    r.notes!,
                    style: TextStyle(fontSize: 13, color: AppColors.warmGrey),
                  ),
                ),
              if (r.adminNote.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Note: ${r.adminNote}',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: AppColors.darkBrown.withAlpha(200),
                    ),
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                _fmtDate(r.createdAt),
                style: TextStyle(fontSize: 11, color: AppColors.warmGrey),
              ),
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
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: AppColors.warmGrey),
            ),
          ),
        ],
      ),
    );
  }
}
