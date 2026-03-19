import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../models/models.dart';

class AdminEventParticipationsScreen extends StatefulWidget {
  const AdminEventParticipationsScreen({super.key, required this.token});

  final String token;

  @override
  State<AdminEventParticipationsScreen> createState() =>
      _AdminEventParticipationsScreenState();
}

class _AdminEventParticipationsScreenState
    extends State<AdminEventParticipationsScreen> {
  final ApiService _api = ApiService();
  List<EventParticipationView> _items = [];
  List<Event> _events = [];
  bool _loading = true;
  int? _eventIdFilter;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final events = await _api.adminListEvents(widget.token, perPage: 200);
    if (!mounted) return;
    setState(() => _events = events);
    await _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _api.adminListEventParticipations(
      widget.token,
      eventId: _eventIdFilter,
      limit: 100,
    );
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Participations'),
        backgroundColor: AppColors.krishnaBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: DropdownButtonFormField<int?>(
              value: _eventIdFilter,
              decoration: const InputDecoration(
                labelText: 'Filter by event',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              isExpanded: true,
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('All events')),
                for (final e in _events)
                  DropdownMenuItem<int?>(value: e.id, child: Text(e.title)),
              ],
              onChanged: (v) {
                setState(() => _eventIdFilter = v);
                _load();
              },
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.krishnaBlue))
                : _items.isEmpty
                    ? const Center(child: Text('No participations'))
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: AppColors.krishnaBlue,
                        child: ListView.builder(
                          itemCount: _items.length,
                          itemBuilder: (context, i) {
                            final p = _items[i];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Color(0x1A4A6FD6),
                                  child: Icon(Icons.person, color: AppColors.krishnaBlue),
                                ),
                                title: Text(p.name),
                                subtitle: Text(
                                  '${p.phone}\nEvent: ${p.eventTitle}'
                                  '${p.notes != null && p.notes!.isNotEmpty ? '\nNotes: ${p.notes}' : ''}',
                                ),
                                isThreeLine: true,
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
