import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class AdminAstroConsultDetailScreen extends StatefulWidget {
  const AdminAstroConsultDetailScreen({
    super.key,
    required this.token,
    required this.initial,
  });

  final String token;
  final AstroConsultView initial;

  @override
  State<AdminAstroConsultDetailScreen> createState() =>
      _AdminAstroConsultDetailScreenState();
}

class _AdminAstroConsultDetailScreenState
    extends State<AdminAstroConsultDetailScreen> {
  final ApiService _api = ApiService();
  late TextEditingController _noteCtrl;
  late String _status;
  bool _saving = false;
  bool _dirty = false;

  static const _statuses = ['new', 'contacted', 'answered', 'closed'];

  @override
  void initState() {
    super.initState();
    _noteCtrl = TextEditingController(text: widget.initial.adminNote);
    _status = widget.initial.status;
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final ok = await _api.adminPatchAstroConsult(
      widget.token,
      widget.initial.id,
      AstroConsultPatchRequest(
        status: _status,
        adminNote: _noteCtrl.text.trim(),
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Saved' : 'Failed to save'),
        backgroundColor: ok
            ? Theme.of(context).colorScheme.primary
            : AppColors.urgentRed,
      ),
    );
    if (ok) {
      _dirty = true;
    }
  }

  Future<void> _callPhone() async {
    final uri = Uri.parse('tel:${widget.initial.phone}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _copyPhone() async {
    await Clipboard.setData(ClipboardData(text: widget.initial.phone));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Phone copied')),
    );
  }

  String _fmtDate(String iso) {
    if (iso.isEmpty) return '-';
    try {
      return DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.initial;
    final theme = Theme.of(context);
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _dirty);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(title: Text(v.name)),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(v.name, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: 4,
                      children: [
                        Chip(label: Text('Topic: ${v.category}')),
                        Chip(label: Text('Status: ${v.status}')),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _callPhone,
                            icon: const Icon(Icons.call),
                            label: Text(v.phone),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Copy phone',
                          onPressed: _copyPhone,
                          icon: const Icon(Icons.copy),
                        ),
                      ],
                    ),
                    if (v.email != null && v.email!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.email_outlined, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(v.email!)),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    if (v.subject.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          v.subject,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                    Text(v.question, style: theme.textTheme.bodyLarge),
                    const SizedBox(height: AppSpacing.md),
                    if (v.dobDate != null || v.birthPlace != null)
                      _detailBlock('Birth details', [
                        if (v.dobDate != null) 'DOB: ${v.dobDate}',
                        if (v.dobTime != null) 'Time: ${v.dobTime}',
                        if (v.birthPlace != null && v.birthPlace!.isNotEmpty)
                          'Place: ${v.birthPlace}',
                      ]),
                    const SizedBox(height: 8),
                    Text(
                      'Submitted ${_fmtDate(v.createdAt)}',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.warmGrey),
                    ),
                    if (v.answeredAt != null && v.answeredAt!.isNotEmpty)
                      Text(
                        'Answered ${_fmtDate(v.answeredAt!)}'
                        '${v.answeredByName != null ? ' by ${v.answeredByName}' : ''}',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.warmGrey),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Update', style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<String>(
                      // ignore: deprecated_member_use
                      value: _status,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: _statuses
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child:
                                  Text(s[0].toUpperCase() + s.substring(1)),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _status = v);
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _noteCtrl,
                      minLines: 3,
                      maxLines: 8,
                      decoration: const InputDecoration(
                        labelText: 'Internal note',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              )
                            : const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailBlock(String title, List<String> lines) {
    if (lines.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.labelLarge),
          const SizedBox(height: 4),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                line,
                style: theme.textTheme.bodyMedium,
              ),
            ),
        ],
      ),
    );
  }
}
