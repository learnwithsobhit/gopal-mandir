import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../models/models.dart';

class AdminEventDonationsScreen extends StatefulWidget {
  const AdminEventDonationsScreen({
    super.key,
    required this.token,
    this.initialEventId,
  });

  final String token;
  final int? initialEventId;

  @override
  State<AdminEventDonationsScreen> createState() =>
      _AdminEventDonationsScreenState();
}

class _AdminEventDonationsScreenState
    extends State<AdminEventDonationsScreen> {
  final ApiService _api = ApiService();
  List<EventDonationView> _items = [];
  List<Event> _events = [];
  bool _loading = true;
  int? _eventIdFilter;

  @override
  void initState() {
    super.initState();
    _eventIdFilter = widget.initialEventId;
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
    final list = await _api.adminListEventDonations(
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

  String _fmtAmount(double amount) {
    if (amount == amount.truncateToDouble()) {
      return '₹${amount.toInt()}';
    }
    return '₹${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Donations'),
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
                    ? const Center(child: Text('No donations'))
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: AppColors.krishnaBlue,
                        child: ListView.builder(
                          itemCount: _items.length,
                          itemBuilder: (context, i) {
                            final d = _items[i];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.peacockGreen.withAlpha(24),
                                  child: const Icon(Icons.volunteer_activism, color: AppColors.peacockGreen),
                                ),
                                title: Text(
                                  '${d.name}  •  ${_fmtAmount(d.amount)}',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  'Event: ${d.eventTitle}'
                                  '\nPhone: ${d.phone ?? "—"}'
                                  '\nRef: ${d.referenceId}'
                                  '${d.message != null && d.message!.isNotEmpty ? "\nMsg: ${d.message}" : ""}',
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
