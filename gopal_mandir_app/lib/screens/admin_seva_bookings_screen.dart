import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../models/models.dart';
import '../widgets/admin_payment_status_dialog.dart';

class AdminSevaBookingsScreen extends StatefulWidget {
  const AdminSevaBookingsScreen({super.key, required this.token});

  final String token;

  @override
  State<AdminSevaBookingsScreen> createState() => _AdminSevaBookingsScreenState();
}

class _AdminSevaBookingsScreenState extends State<AdminSevaBookingsScreen> {
  final ApiService _api = ApiService();
  List<SevaBookingView> _bookings = [];
  bool _loading = true;
  String? _statusFilter;

  static const _statusChoices = [
    'pending',
    'confirmed',
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
    final list = await _api.adminListSevaBookings(
      widget.token,
      status: _statusFilter,
      limit: 100,
    );
    if (!mounted) return;
    setState(() {
      _bookings = list;
      _loading = false;
    });
  }

  Future<void> _changeStatus(SevaBookingView b) async {
    final picked = await showDialog<String>(
      context: context,
      builder: (c) => SimpleDialog(
        title: Text('Status — ${b.referenceId}'),
        children: [
          for (final s in _statusChoices)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(c, s),
              child: Text(s),
            ),
        ],
      ),
    );
    if (picked == null || picked == b.status) return;
    final resp = await _api.adminPatchSevaBookingStatus(widget.token, b.referenceId, picked);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resp.message)));
    if (resp.success) _load();
  }

  String _paymentLine(SevaBookingView b) {
    final buf = StringBuffer('Pay: ${b.paymentStatus}');
    if (b.gateway != null && b.gateway!.isNotEmpty) buf.write(' • ${b.gateway}');
    if (b.gatewayOrderId != null && b.gatewayOrderId!.isNotEmpty) {
      buf.write('\nOrder: ${b.gatewayOrderId}');
    }
    if (b.gatewayPaymentId != null && b.gatewayPaymentId!.isNotEmpty) {
      buf.write('\nPayment: ${b.gatewayPaymentId}');
    }
    if (b.paymentFailureReason != null && b.paymentFailureReason!.isNotEmpty) {
      buf.write('\nFailure: ${b.paymentFailureReason}');
    }
    if (b.paymentAdminNote != null && b.paymentAdminNote!.isNotEmpty) {
      buf.write('\nAdmin note: ${b.paymentAdminNote}');
    }
    return buf.toString();
  }

  Future<void> _patchPayment(SevaBookingView b) async {
    if (!adminCanPatchPaymentStatus(b.paymentStatus)) return;
    final result = await showAdminPaymentResolveDialog(
      context,
      title: 'Update payment — ${b.referenceId}',
      currentPaymentStatus: b.paymentStatus,
    );
    if (result == null || !mounted) return;
    final resp = await _api.adminPatchSevaBookingPayment(
      widget.token,
      b.referenceId,
      paymentStatus: result.paymentStatus,
      gatewayPaymentId: result.gatewayPaymentId,
      adminNote: result.adminNote,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resp.message)));
    if (resp.success) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seva Bookings'),
        backgroundColor: AppColors.krishnaBlue,
        foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: DropdownButtonFormField<String?>(
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
                : _bookings.isEmpty
                    ? const Center(child: Text('No bookings'))
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: AppColors.krishnaBlue,
                        child: ListView.builder(
                          itemCount: _bookings.length,
                          itemBuilder: (context, i) {
                            final b = _bookings[i];
                            final payHighlight =
                                b.paymentStatus == 'failed' || b.paymentStatus == 'pending';
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              color: payHighlight ? AppColors.urgentRed.withAlpha(14) : null,
                              child: ListTile(
                                title: Text(b.sevaName),
                                subtitle: Text(
                                  '${b.referenceId}\n${b.name} · ${b.phone}'
                                  '${b.preferredDate != null ? '\nDate: ${b.preferredDate}' : ''}'
                                  '\n${b.sevaCategory} · ₹${b.sevaPrice.toStringAsFixed(0)}'
                                  '\n${_paymentLine(b)}',
                                ),
                                isThreeLine: true,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (adminCanPatchPaymentStatus(b.paymentStatus))
                                      IconButton(
                                        icon: const Icon(Icons.payments_outlined),
                                        tooltip: 'Update payment',
                                        onPressed: () => _patchPayment(b),
                                      ),
                                    Chip(
                                      label: Text(b.status, style: const TextStyle(fontSize: 11)),
                                      backgroundColor: AppColors.krishnaBlue.withAlpha(28),
                                    ),
                                  ],
                                ),
                                onTap: () => _changeStatus(b),
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
