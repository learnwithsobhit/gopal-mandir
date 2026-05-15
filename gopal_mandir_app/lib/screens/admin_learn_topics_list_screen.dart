import 'package:flutter/material.dart';

import '../l10n/locale_scope.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import 'admin_learn_topic_edit_screen.dart';

class AdminLearnTopicsListScreen extends StatefulWidget {
  const AdminLearnTopicsListScreen({super.key, required this.token});

  final String token;

  @override
  State<AdminLearnTopicsListScreen> createState() =>
      _AdminLearnTopicsListScreenState();
}

class _AdminLearnTopicsListScreenState
    extends State<AdminLearnTopicsListScreen> {
  final ApiService _api = ApiService();
  List<AdminLearnTopic> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _api.adminListLearnTopics(widget.token);
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  Future<void> _openEdit(AdminLearnTopic? existing) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => AdminLearnTopicEditScreen(
          token: widget.token,
          existing: existing,
        ),
      ),
    );
    if (changed == true) _load();
  }

  Future<void> _delete(AdminLearnTopic item) async {
    final s = AppLocaleScope.of(context).strings;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(s.adminLearnDeleteConfirm),
        content: Text(item.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.urgentRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final success = await _api.adminDeleteLearnTopic(widget.token, item.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Deleted' : 'Delete failed (registrations may exist)'),
      ),
    );
    if (success) _load();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocaleScope.of(context).strings;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.adminLearnTopics),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEdit(null),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _items.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.sizeOf(context).height * 0.5,
                          child: Center(child: Text(s.learnEmpty)),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final t = _items[i];
                        return Card(
                          child: ListTile(
                            title: Text(t.title,
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              '${t.categoryKey} · ${s.learnDeliveryLabel(t.deliveryMode)}'
                              '${t.isPublished ? '' : ' · draft'}',
                              style: TextStyle(fontSize: 12, color: AppColors.warmGrey),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () => _openEdit(t),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => _delete(t),
                                ),
                              ],
                            ),
                            onTap: () => _openEdit(t),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
