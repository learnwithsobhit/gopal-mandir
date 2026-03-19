import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../models/models.dart';
import 'admin_event_edit_screen.dart';

class AdminEventsListScreen extends StatefulWidget {
  const AdminEventsListScreen({super.key, required this.token});

  final String token;

  @override
  State<AdminEventsListScreen> createState() => _AdminEventsListScreenState();
}

class _AdminEventsListScreenState extends State<AdminEventsListScreen> {
  final ApiService _api = ApiService();
  List<Event> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _api.adminListEvents(widget.token, perPage: 100);
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  Future<void> _delete(Event item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete event?'),
        content: Text('${item.title}\n\nThis also deletes all participations, likes and comments.'),
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
    final success = await _api.adminDeleteEvent(widget.token, item.id);
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
        title: const Text('Events (admin)'),
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
              builder: (_) => AdminEventEditScreen(token: widget.token),
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
              ? const Center(child: Text('No events'))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.krishnaBlue,
                  child: ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (context, i) {
                      final item = _items[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: item.isFeatured
                                ? AppColors.templeGold.withAlpha(30)
                                : AppColors.krishnaBlue.withAlpha(20),
                            child: Icon(
                              Icons.event,
                              color: item.isFeatured ? AppColors.templeGold : AppColors.krishnaBlue,
                            ),
                          ),
                          title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            '${item.date}${item.isFeatured ? '  ★ Featured' : ''}',
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
                                      builder: (_) => AdminEventEditScreen(
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
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
