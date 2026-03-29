import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/admin_payment_status_dialog.dart';

class AdminPoojaBookingsScreen extends StatefulWidget {
  const AdminPoojaBookingsScreen({super.key, required this.token});

  final String token;

  @override
  State<AdminPoojaBookingsScreen> createState() => _AdminPoojaBookingsScreenState();
}

class _AdminPoojaBookingsScreenState extends State<AdminPoojaBookingsScreen> {
  final _api = ApiService();
  List<PoojaBookingView> _bookings = [];
  bool _loading = true;
  String? _statusFilter;
  String? _officiantFilter;
  final _fromCtrl = TextEditingController();
  final _toCtrl = TextEditingController();

  static const _statusChoices = [
    'pending_confirmation',
    'confirmed',
    'completed',
    'cancelled',
  ];

  @override
  void dispose() {
    _fromCtrl.dispose();
    _toCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _api.adminListPoojaBookings(
      widget.token,
      bookingStatus: _statusFilter,
      officiant: _officiantFilter,
      fromDate: _fromCtrl.text.trim().isEmpty ? null : _fromCtrl.text.trim(),
      toDate: _toCtrl.text.trim().isEmpty ? null : _toCtrl.text.trim(),
      limit: 100,
    );
    if (!mounted) return;
    setState(() {
      _bookings = list;
      _loading = false;
    });
  }

  Future<void> _onTapBooking(PoojaBookingView b) async {
    if (b.bookingStatus == 'pending_confirmation') {
      final mode = await showDialog<String>(
        context: context,
        builder: (c) => SimpleDialog(
          title: Text('Confirm ${b.referenceId}'),
          children: [
            const SimpleDialogOption(
              child: Text('Choose payment after confirmation:'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(c, 'online'),
              child: const Text('Online payment'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(c, 'offline'),
              child: const Text('Offline / at temple'),
            ),
          ],
        ),
      );
      if (mode == null) return;
      final resp = await _api.adminPatchPoojaBooking(
        widget.token,
        b.referenceId,
        bookingStatus: 'confirmed',
        paymentExpected: mode,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resp.message)));
      if (resp.success) _load();
      return;
    }

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
    if (picked == null || picked == b.bookingStatus) return;
    final resp = await _api.adminPatchPoojaBooking(
      widget.token,
      b.referenceId,
      bookingStatus: picked,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resp.message)));
    if (resp.success) _load();
  }

  Future<void> _patchPayment(PoojaBookingView b) async {
    if (!adminCanPatchPaymentStatus(b.paymentStatus)) return;
    final result = await showAdminPaymentResolveDialog(
      context,
      title: 'Update payment — ${b.referenceId}',
      currentPaymentStatus: b.paymentStatus,
    );
    if (result == null || !mounted) return;
    final resp = await _api.adminPatchPoojaBookingPayment(
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

  String _payLine(PoojaBookingView b) {
    final buf = StringBuffer('Pay: ${b.paymentStatus}');
    if (b.paymentExpected != null && b.paymentExpected!.isNotEmpty) {
      buf.write(' (${b.paymentExpected})');
    }
    if (b.gatewayOrderId != null && b.gatewayOrderId!.isNotEmpty) {
      buf.write('\nOrder: ${b.gatewayOrderId}');
    }
    if (b.paymentAdminNote != null && b.paymentAdminNote!.isNotEmpty) {
      buf.write('\nAdmin: ${b.paymentAdminNote}');
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pooja bookings'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        value: _statusFilter,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All')),
                          for (final s in _statusChoices)
                            DropdownMenuItem(value: s, child: Text(s)),
                        ],
                        onChanged: (v) {
                          setState(() => _statusFilter = v);
                          _load();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        value: _officiantFilter,
                        decoration: const InputDecoration(
                          labelText: 'Officiant',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('All')),
                          DropdownMenuItem(value: 'guru', child: Text('guru')),
                          DropdownMenuItem(value: 'baba', child: Text('baba')),
                        ],
                        onChanged: (v) {
                          setState(() => _officiantFilter = v);
                          _load();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _fromCtrl,
                        decoration: const InputDecoration(
                          labelText: 'From YYYY-MM-DD',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onSubmitted: (_) => _load(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _toCtrl,
                        decoration: const InputDecoration(
                          labelText: 'To YYYY-MM-DD',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onSubmitted: (_) => _load(),
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.search), onPressed: _load),
                  ],
                ),
              ],
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
                                title: Text(b.offeringName),
                                subtitle: Text(
                                  '${b.referenceId}\n${b.name} · ${b.phone}\n'
                                  '${b.bookingDate} · ${b.slotLabel} · ${b.officiant}\n'
                                  '${_payLine(b)}',
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
                                      label: Text(b.bookingStatus, style: const TextStyle(fontSize: 11)),
                                    ),
                                  ],
                                ),
                                onTap: () => _onTapBooking(b),
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
