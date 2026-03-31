import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import 'admin_festival_edit_screen.dart';
import 'admin_festival_media_screen.dart';

class AdminFestivalsListScreen extends StatefulWidget {
  const AdminFestivalsListScreen({super.key, required this.token});

  final String token;

  @override
  State<AdminFestivalsListScreen> createState() => _AdminFestivalsListScreenState();
}

class _AdminFestivalsListScreenState extends State<AdminFestivalsListScreen> {
  final ApiService _api = ApiService();
  final _searchCtrl = TextEditingController();
  List<FestivalEntry> _items = [];
  bool _loading = true;
  DateTime? _fromDate;
  DateTime? _toDate;

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

  String _fmtDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _api.adminListFestivals(
      widget.token,
      perPage: 200,
      fromDate: _fromDate == null ? null : _fmtDate(_fromDate!),
      toDate: _toDate == null ? null : _fmtDate(_toDate!),
      query: _searchCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  Future<void> _pickFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() => _fromDate = picked);
    _load();
  }

  Future<void> _pickToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() => _toDate = picked);
    _load();
  }

  Future<void> _delete(FestivalEntry item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete festival entry?'),
        content: Text('${item.forDate}\n${item.title}'),
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
    final success = await _api.adminDeleteFestival(widget.token, item.id);
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
        title: const Text('Festivals (admin)'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push<bool>(
            context,
            MaterialPageRoute<bool>(
              builder: (_) => AdminFestivalEditScreen(token: widget.token),
            ),
          );
          _load();
        },
        backgroundColor: AppColors.krishnaBlue,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search title/description',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: _load,
                    ),
                  ),
                  onSubmitted: (_) => _load(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickFromDate,
                        icon: const Icon(Icons.calendar_today),
                        label: Text(_fromDate == null ? 'From date' : _fmtDate(_fromDate!)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickToDate,
                        icon: const Icon(Icons.calendar_today),
                        label: Text(_toDate == null ? 'To date' : _fmtDate(_toDate!)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.krishnaBlue))
                : _items.isEmpty
                    ? const Center(child: Text('No festival entries'))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          itemCount: _items.length,
                          itemBuilder: (context, i) {
                            final item = _items[i];
                            return ListTile(
                              leading: Icon(
                                item.isActive ? Icons.event_note : Icons.event_busy,
                                color: item.isActive ? AppColors.krishnaBlue : AppColors.warmGrey,
                              ),
                              title: Text(item.title),
                              subtitle: Text(
                                '${item.forDate}  |  sort: ${item.sortOrder}\n${item.description}',
                                maxLines: 2,
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
                                          builder: (_) => AdminFestivalEditScreen(
                                            token: widget.token,
                                            existing: item,
                                          ),
                                        ),
                                      );
                                      _load();
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.perm_media_outlined),
                                    onPressed: () async {
                                      await Navigator.push<void>(
                                        context,
                                        MaterialPageRoute<void>(
                                          builder: (_) => AdminFestivalMediaScreen(
                                            token: widget.token,
                                            festival: item,
                                          ),
                                        ),
                                      );
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
          ),
        ],
      ),
    );
  }
}
