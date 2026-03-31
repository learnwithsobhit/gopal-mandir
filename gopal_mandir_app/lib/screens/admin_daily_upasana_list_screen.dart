import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import 'admin_daily_upasana_edit_screen.dart';

class AdminDailyUpasanaListScreen extends StatefulWidget {
  const AdminDailyUpasanaListScreen({super.key, required this.token});

  final String token;

  @override
  State<AdminDailyUpasanaListScreen> createState() => _AdminDailyUpasanaListScreenState();
}

class _AdminDailyUpasanaListScreenState extends State<AdminDailyUpasanaListScreen> {
  final ApiService _api = ApiService();
  List<DailyUpasanaItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _api.adminListDailyUpasana(widget.token, perPage: 200);
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  Future<void> _delete(DailyUpasanaItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete item?'),
        content: Text('${item.forDate} • ${item.title}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.urgentRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final success = await _api.adminDeleteDailyUpasana(widget.token, item.id);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(success ? 'Deleted' : 'Delete failed')));
    if (success) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Upasana (admin)'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push<bool>(
            context,
            MaterialPageRoute<bool>(
              builder: (_) => AdminDailyUpasanaEditScreen(token: widget.token),
            ),
          );
          _load();
        },
        backgroundColor: AppColors.krishnaBlue,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.krishnaBlue))
          : _items.isEmpty
              ? const Center(child: Text('No daily upasana entries'))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.krishnaBlue,
                  child: ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (context, i) {
                      final item = _items[i];
                      final preview = item.content.length > 90
                          ? '${item.content.substring(0, 90)}...'
                          : item.content;
                      return ListTile(
                        leading: Icon(
                          item.isPublished ? Icons.check_circle : Icons.pending,
                          color: item.isPublished ? Colors.green : AppColors.warmGrey,
                        ),
                        title: Text(item.title),
                        subtitle: Text(
                          '${item.forDate}${item.category.isEmpty ? '' : ' • ${item.category}'}\n$preview',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () async {
                                await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute<bool>(
                                    builder: (_) => AdminDailyUpasanaEditScreen(
                                      token: widget.token,
                                      existing: item,
                                    ),
                                  ),
                                );
                                _load();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _delete(item),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

