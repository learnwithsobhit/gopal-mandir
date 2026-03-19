import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../models/models.dart';
import 'admin_panchang_edit_screen.dart';

class AdminPanchangListScreen extends StatefulWidget {
  const AdminPanchangListScreen({super.key, required this.token});

  final String token;

  @override
  State<AdminPanchangListScreen> createState() => _AdminPanchangListScreenState();
}

class _AdminPanchangListScreenState extends State<AdminPanchangListScreen> {
  final ApiService _api = ApiService();
  List<HinduPanchang> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _api.adminListPanchang(widget.token, perPage: 100);
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  Future<void> _delete(HinduPanchang item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete panchang entry?'),
        content: Text('Date: ${item.forDate}'),
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
    final success = await _api.adminDeletePanchang(widget.token, item.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'Deleted' : 'Delete failed')),
    );
    if (success) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panchang (admin)'),
        backgroundColor: AppColors.krishnaBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push<bool>(
            context,
            MaterialPageRoute<bool>(
              builder: (_) => AdminPanchangEditScreen(token: widget.token),
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
              ? const Center(child: Text('No panchang entries'))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.krishnaBlue,
                  child: ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (context, i) {
                      final item = _items[i];
                      final preview = item.content.length > 80
                          ? '${item.content.substring(0, 80)}…'
                          : item.content;
                      return ListTile(
                        leading: const Icon(Icons.calendar_today, color: AppColors.templeGold),
                        title: Text(item.forDate),
                        subtitle: Text(preview, maxLines: 2, overflow: TextOverflow.ellipsis),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () async {
                                await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute<bool>(
                                    builder: (_) => AdminPanchangEditScreen(
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
