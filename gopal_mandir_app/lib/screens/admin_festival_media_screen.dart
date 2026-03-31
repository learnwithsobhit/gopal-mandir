import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import 'admin_festival_media_edit_screen.dart';

class AdminFestivalMediaScreen extends StatefulWidget {
  const AdminFestivalMediaScreen({
    super.key,
    required this.token,
    required this.festival,
  });

  final String token;
  final FestivalEntry festival;

  @override
  State<AdminFestivalMediaScreen> createState() => _AdminFestivalMediaScreenState();
}

class _AdminFestivalMediaScreenState extends State<AdminFestivalMediaScreen> {
  final ApiService _api = ApiService();
  bool _loading = true;
  List<FestivalMediaItem> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await _api.adminListFestivalMedia(widget.token, widget.festival.id);
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _delete(FestivalMediaItem item) async {
    final ok = await _api.adminDeleteFestivalMedia(widget.token, item.id);
    if (ok) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Media: ${widget.festival.title}')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push<bool>(
            context,
            MaterialPageRoute<bool>(
              builder: (_) => AdminFestivalMediaEditScreen(
                token: widget.token,
                festivalId: widget.festival.id,
              ),
            ),
          );
          _load();
        },
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _items.length,
              itemBuilder: (_, i) {
                final item = _items[i];
                return ListTile(
                  leading: Icon(item.isVideo ? Icons.videocam : Icons.image),
                  title: Text(item.title),
                  subtitle: Text('${item.mediaType} | sort: ${item.sortOrder}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () async {
                          await Navigator.push<bool>(
                            context,
                            MaterialPageRoute<bool>(
                              builder: (_) => AdminFestivalMediaEditScreen(
                                token: widget.token,
                                festivalId: widget.festival.id,
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
    );
  }
}
