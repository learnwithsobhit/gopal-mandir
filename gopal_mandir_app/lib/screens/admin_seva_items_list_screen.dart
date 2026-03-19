import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../models/models.dart';
import 'admin_seva_item_edit_screen.dart';

class AdminSevaItemsListScreen extends StatefulWidget {
  const AdminSevaItemsListScreen({super.key, required this.token});

  final String token;

  @override
  State<AdminSevaItemsListScreen> createState() => _AdminSevaItemsListScreenState();
}

class _AdminSevaItemsListScreenState extends State<AdminSevaItemsListScreen> {
  final ApiService _api = ApiService();
  List<SevaItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _api.adminListSevaItems(widget.token, perPage: 100);
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  Future<void> _delete(SevaItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete seva item?'),
        content: Text(item.name),
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
    final success = await _api.adminDeleteSevaItem(widget.token, item.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'Deleted' : 'Delete failed — item may have bookings')),
    );
    if (success) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seva Items (admin)'),
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
              builder: (_) => AdminSevaItemEditScreen(token: widget.token),
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
              ? const Center(child: Text('No seva items'))
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
                            backgroundColor: item.available
                                ? AppColors.successGreen.withAlpha(30)
                                : AppColors.warmGrey.withAlpha(30),
                            child: Icon(
                              Icons.volunteer_activism,
                              color: item.available ? AppColors.successGreen : AppColors.warmGrey,
                            ),
                          ),
                          title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            '${item.category} · ₹${item.price.toStringAsFixed(0)}'
                            '${item.available ? '' : ' · Unavailable'}',
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
                                      builder: (_) => AdminSevaItemEditScreen(
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
