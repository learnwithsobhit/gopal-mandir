import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../models/models.dart';

class AdminPrasadOrdersScreen extends StatefulWidget {
  const AdminPrasadOrdersScreen({super.key, required this.token});

  final String token;

  @override
  State<AdminPrasadOrdersScreen> createState() => _AdminPrasadOrdersScreenState();
}

class _AdminPrasadOrdersScreenState extends State<AdminPrasadOrdersScreen> {
  final ApiService _api = ApiService();
  List<PrasadOrderView> _orders = [];
  bool _loading = true;
  String? _statusFilter;

  static const _statusChoices = [
    'pending',
    'confirmed',
    'ready',
    'completed',
    'cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _api.adminListPrasadOrders(
      widget.token,
      status: _statusFilter,
      limit: 100,
    );
    if (!mounted) return;
    setState(() {
      _orders = list;
      _loading = false;
    });
  }

  Future<void> _changeStatus(PrasadOrderView o) async {
    final picked = await showDialog<String>(
      context: context,
      builder: (c) => SimpleDialog(
        title: Text('Status — ${o.referenceId}'),
        children: [
          for (final s in ['pending', 'confirmed', 'ready', 'completed', 'cancelled'])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(c, s),
              child: Text(s),
            ),
        ],
      ),
    );
    if (picked == null || picked == o.status) return;
    final resp = await _api.adminPatchPrasadOrderStatus(widget.token, o.referenceId, picked);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resp.message)));
    if (resp.success) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prasad orders'),
        backgroundColor: AppColors.krishnaBlue,
        foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: DropdownButtonFormField<String?>(
              // ignore: deprecated_member_use — filter changes on user selection
              value: _statusFilter,
              decoration: const InputDecoration(
                labelText: 'Filter status',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('All')),
                for (final s in _statusChoices)
                  DropdownMenuItem<String?>(value: s, child: Text(s)),
              ],
              onChanged: (v) {
                setState(() => _statusFilter = v);
                _load();
              },
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.krishnaBlue))
                : _orders.isEmpty
                    ? const Center(child: Text('No orders'))
                    : ListView.builder(
                        itemCount: _orders.length,
                        itemBuilder: (context, i) {
                          final o = _orders[i];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: ListTile(
                              title: Text(o.prasadName),
                              subtitle: Text(
                                '${o.referenceId}\n${o.name} · ${o.phone}\nQty ${o.quantity} · ₹${o.totalAmount.toStringAsFixed(0)} · ${o.fulfillment}',
                              ),
                              isThreeLine: true,
                              trailing: Chip(
                                label: Text(o.status, style: const TextStyle(fontSize: 11)),
                                backgroundColor: AppColors.krishnaBlue.withAlpha(28),
                              ),
                              onTap: () => _changeStatus(o),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
