import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';

/// Admin view of pooja time bands and Guru/Baba max bookings per slot per day.
class AdminPoojaAvailabilityScreen extends StatefulWidget {
  const AdminPoojaAvailabilityScreen({super.key, required this.token});

  final String token;

  @override
  State<AdminPoojaAvailabilityScreen> createState() => _AdminPoojaAvailabilityScreenState();
}

class _AdminPoojaAvailabilityScreenState extends State<AdminPoojaAvailabilityScreen> {
  final _api = ApiService();
  PoojaMetaData? _meta;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final m = await _api.adminPoojaMeta(widget.token);
      if (!mounted) return;
      setState(() {
        _meta = m;
        _loading = false;
        if (m == null) _error = 'Could not load availability. Pull to retry.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Error: $e';
      });
    }
  }

  static String _slotSubtitle(Map<String, dynamic> row) {
    final start = row['start_time'] ?? row['startTime'];
    final end = row['end_time'] ?? row['endTime'];
    final s = start?.toString() ?? '—';
    final e = end?.toString() ?? '—';
    return '$s – $e';
  }

  static String _slotTitle(Map<String, dynamic> row) {
    final label = row['label'] ?? row['name'];
    if (label == null) return 'Slot';
    final t = label.toString().trim();
    return t.isNotEmpty ? t : 'Slot';
  }

  Future<void> _editCapacity() async {
    final meta = _meta;
    if (meta == null) return;
    final guru = TextEditingController(text: '${meta.guruMaxPerSlot}');
    final baba = TextEditingController(text: '${meta.babaMaxPerSlot}');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Max bookings per slot per day'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Each value applies separately to every time band (Morning, Afternoon, …) for that officiant.',
                style: TextStyle(fontSize: 13, color: AppColors.warmGrey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: guru,
                decoration: const InputDecoration(
                  labelText: 'Guru Ji max per slot',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: baba,
                decoration: const InputDecoration(
                  labelText: 'Baba Ji max per slot',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok != true) return;
    final g = int.tryParse(guru.text.trim());
    final b = int.tryParse(baba.text.trim());
    final resp = await _api.adminPoojaPatchCapacity(
      widget.token,
      guruMaxPerSlot: g,
      babaMaxPerSlot: b,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resp.message)));
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pooja availability'),
        actions: [
          if (_meta != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Guru / Baba limits',
              onPressed: _editCapacity,
            ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.krishnaBlue))
          : _error != null && _meta == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.krishnaBlue,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        color: AppColors.softWhite,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Members choose one time band per booking day. The limits below apply to '
                            'each band separately (e.g. Morning and Afternoon each allow up to N Guru Ji bookings).',
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: AppColors.darkBrown.withAlpha(220),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Daily time bands',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkBrown,
                            ),
                      ),
                      const SizedBox(height: 8),
                      if (_meta!.slots.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('No slots returned from server.'),
                          ),
                        )
                      else
                        ..._meta!.slots.map((row) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const Icon(Icons.schedule, color: AppColors.krishnaBlue),
                              title: Text(_slotTitle(row)),
                              subtitle: Text(_slotSubtitle(row)),
                            ),
                          );
                        }),
                      const SizedBox(height: 24),
                      Text(
                        'Guru Ji & Baba Ji — capacity',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkBrown,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        child: Column(
                          children: [
                            ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: AppColors.krishnaBlue,
                                child: Icon(Icons.person, color: Colors.white, size: 20),
                              ),
                              title: const Text('Guru Ji'),
                              subtitle: Text('Max bookings per slot per day: ${_meta!.guruMaxPerSlot}'),
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: AppColors.peacockGreen,
                                child: Icon(Icons.person, color: Colors.white, size: 20),
                              ),
                              title: const Text('Baba Ji'),
                              subtitle: Text('Max bookings per slot per day: ${_meta!.babaMaxPerSlot}'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _editCapacity,
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Edit Guru & Baba limits'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.krishnaBlue,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }
}
