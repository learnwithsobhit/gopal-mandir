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

  static String _formatYmd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickFromDate() async {
    final now = DateTime.now();
    DateTime initial = now;
    if (_fromCtrl.text.trim().isNotEmpty) {
      try {
        initial = DateTime.parse(_fromCtrl.text.trim());
      } catch (_) {}
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (picked == null || !mounted) return;
    setState(() => _fromCtrl.text = _formatYmd(picked));
    _load();
  }

  Future<void> _pickToDate() async {
    final now = DateTime.now();
    DateTime first = DateTime(now.year - 1);
    if (_fromCtrl.text.trim().isNotEmpty) {
      try {
        final from = DateTime.parse(_fromCtrl.text.trim());
        if (from.isAfter(first)) first = from;
      } catch (_) {}
    }
    DateTime initial = now;
    if (_toCtrl.text.trim().isNotEmpty) {
      try {
        initial = DateTime.parse(_toCtrl.text.trim());
      } catch (_) {}
    }
    if (initial.isBefore(first)) initial = first;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: DateTime(now.year + 3),
    );
    if (picked == null || !mounted) return;
    setState(() => _toCtrl.text = _formatYmd(picked));
    _load();
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
                        isExpanded: true,
                        value: _statusFilter,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All')),
                          for (final s in _statusChoices)
                            DropdownMenuItem(
                              value: s,
                              child: Text(s, overflow: TextOverflow.ellipsis),
                            ),
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
                        isExpanded: true,
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
                        readOnly: true,
                        onTap: _pickFromDate,
                        decoration: InputDecoration(
                          labelText: 'From date',
                          hintText: 'YYYY-MM-DD',
                          border: const OutlineInputBorder(),
                          isDense: true,
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_today_outlined, size: 20),
                            tooltip: 'Pick from date',
                            onPressed: _pickFromDate,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _toCtrl,
                        readOnly: true,
                        onTap: _pickToDate,
                        decoration: InputDecoration(
                          labelText: 'To date',
                          hintText: 'YYYY-MM-DD',
                          border: const OutlineInputBorder(),
                          isDense: true,
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_today_outlined, size: 20),
                            tooltip: 'Pick to date',
                            onPressed: _pickToDate,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.search),
                      tooltip: 'Search',
                      onPressed: _load,
                    ),
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
                              child: InkWell(
                                onTap: () => _onTapBooking(b),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              b.offeringName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              '${b.referenceId}\n${b.name} · ${b.phone}\n'
                                              '${b.bookingDate} · ${b.slotLabel} · ${b.officiant}\n'
                                              '${_payLine(b)}',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Not inside ListTile.trailing — avoids ~48px height cap that caused bottom overflow
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Chip(
                                            padding: const EdgeInsets.symmetric(horizontal: 6),
                                            labelPadding: EdgeInsets.zero,
                                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            visualDensity: VisualDensity.compact,
                                            label: Text(
                                              b.bookingStatus,
                                              style: const TextStyle(fontSize: 11),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (adminCanPatchPaymentStatus(b.paymentStatus))
                                            IconButton(
                                              visualDensity: VisualDensity.compact,
                                              constraints: const BoxConstraints(
                                                minWidth: 40,
                                                minHeight: 36,
                                              ),
                                              padding: EdgeInsets.zero,
                                              icon: const Icon(Icons.payments_outlined, size: 22),
                                              tooltip: 'Update payment',
                                              onPressed: () => _patchPayment(b),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
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
