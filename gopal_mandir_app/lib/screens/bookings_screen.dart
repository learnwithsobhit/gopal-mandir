import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../widgets/vrindavan_background.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> with TickerProviderStateMixin {
  final ApiService _api = ApiService();
  final _phoneController = TextEditingController();

  late final TabController _tabs = TabController(length: 2, vsync: this);

  bool _loading = false;
  String? _error;
  List<PrasadOrderView> _prasad = [];
  List<SevaBookingView> _seva = [];

  @override
  void dispose() {
    _tabs.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _error = 'Enter your phone number to view bookings');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _api.getPrasadOrdersByPhone(phone),
        _api.getSevaBookingsByPhone(phone),
      ]);
      if (!mounted) return;
      setState(() {
        _prasad = results[0] as List<PrasadOrderView>;
        _seva = results[1] as List<SevaBookingView>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to load bookings. Please try again.';
      });
    }
  }

  Future<void> _cancelPrasad(PrasadOrderView order) async {
    final ok = await _confirmDialog(
      title: 'Cancel booking?',
      message: 'Reference: ${order.referenceId}',
      actionLabel: 'Cancel',
      destructive: true,
    );
    if (ok != true) return;

    final resp = await _api.cancelPrasadOrder(order.referenceId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(resp.message),
        backgroundColor: resp.success ? AppColors.peacockGreen : AppColors.urgentRed,
      ),
    );
    if (resp.success) _load();
  }

  Future<void> _cancelSeva(SevaBookingView booking) async {
    final ok = await _confirmDialog(
      title: 'Cancel booking?',
      message: 'Reference: ${booking.referenceId}',
      actionLabel: 'Cancel',
      destructive: true,
    );
    if (ok != true) return;

    final resp = await _api.cancelSevaBooking(booking.referenceId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(resp.message),
        backgroundColor: resp.success ? AppColors.peacockGreen : AppColors.urgentRed,
      ),
    );
    if (resp.success) _load();
  }

  Future<void> _editPrasad(PrasadOrderView order) async {
    final qtyCtrl = TextEditingController(text: order.quantity.toString());
    final notesCtrl = TextEditingController(text: order.notes ?? '');
    String fulfillment = order.fulfillment;
    final addressCtrl = TextEditingController(text: order.address ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update Prasad booking'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownMenu<String>(
                  initialSelection: fulfillment,
                  width: 320,
                  dropdownMenuEntries: const [
                    DropdownMenuEntry(value: 'pickup', label: 'Pickup'),
                    DropdownMenuEntry(value: 'delivery', label: 'Delivery'),
                  ],
                  onSelected: (v) => fulfillment = v ?? fulfillment,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressCtrl,
                  minLines: 2,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Address (for delivery)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  minLines: 2,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Notes (optional)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Close')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
          ],
        );
      },
    );

    if (saved != true) return;

    final qty = int.tryParse(qtyCtrl.text.trim());
    final req = UpdatePrasadOrderRequest(
      quantity: qty,
      fulfillment: fulfillment,
      address: addressCtrl.text.trim().isEmpty ? null : addressCtrl.text.trim(),
      notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
    );

    final resp = await _api.updatePrasadOrder(order.referenceId, req);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(resp.message),
        backgroundColor: resp.success ? AppColors.peacockGreen : AppColors.urgentRed,
      ),
    );
    if (resp.success) _load();
  }

  Future<void> _editSeva(SevaBookingView booking) async {
    final dateCtrl = TextEditingController(text: booking.preferredDate ?? '');
    final notesCtrl = TextEditingController(text: booking.notes ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update Seva booking'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: dateCtrl,
                  decoration: const InputDecoration(labelText: 'Preferred date (optional)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  minLines: 2,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Notes (optional)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Close')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
          ],
        );
      },
    );

    if (saved != true) return;

    final req = UpdateSevaBookingRequest(
      preferredDate: dateCtrl.text.trim().isEmpty ? null : dateCtrl.text.trim(),
      notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
    );

    final resp = await _api.updateSevaBooking(booking.referenceId, req);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(resp.message),
        backgroundColor: resp.success ? AppColors.peacockGreen : AppColors.urgentRed,
      ),
    );
    if (resp.success) _load();
  }

  Future<bool?> _confirmDialog({
    required String title,
    required String message,
    required String actionLabel,
    bool destructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: destructive ? TextButton.styleFrom(foregroundColor: AppColors.urgentRed) : null,
              child: Text(actionLabel),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return VrindavanBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('My Bookings'),
          backgroundColor: AppColors.krishnaBlue,
          foregroundColor: Colors.white,
          bottom: TabBar(
            controller: _tabs,
            tabs: const [
              Tab(text: 'Prasad'),
              Tab(text: 'Seva'),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Phone number',
                        labelStyle: const TextStyle(fontFamily: 'Poppins'),
                        filled: true,
                        fillColor: AppColors.softWhite,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onSubmitted: (_) => _load(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _load,
                      child: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Load'),
                    ),
                  ),
                ],
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(_error!, style: const TextStyle(color: AppColors.urgentRed)),
              ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _prasad.isEmpty && !_loading
                      ? const Center(child: Text('No prasad bookings found'))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: _prasad.length,
                          itemBuilder: (context, i) => _prasadCard(_prasad[i]),
                        ),
                  _seva.isEmpty && !_loading
                      ? const Center(child: Text('No seva bookings found'))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: _seva.length,
                          itemBuilder: (context, i) => _sevaCard(_seva[i]),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    final s = status.toLowerCase();
    final color = s == 'cancelled'
        ? AppColors.urgentRed
        : (s == 'pending' ? AppColors.templeGoldDark : AppColors.peacockGreen);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Text(
        status,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Widget _prasadCard(PrasadOrderView o) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.softWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: AppColors.krishnaBlue.withAlpha(10), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  o.prasadName,
                  style: const TextStyle(fontFamily: 'PlayfairDisplay', fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
              _statusChip(o.status),
            ],
          ),
          const SizedBox(height: 6),
          Text('Ref: ${o.referenceId}', style: TextStyle(color: AppColors.warmGrey)),
          const SizedBox(height: 6),
          Text('Qty: ${o.quantity} • ${o.fulfillment} • Total: ₹${o.totalAmount.toStringAsFixed(0)}'),
          if ((o.address ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Address: ${o.address}'),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              OutlinedButton(
                onPressed: o.status.toLowerCase() == 'cancelled' ? null : () => _editPrasad(o),
                child: const Text('Update'),
              ),
              const SizedBox(width: 10),
              TextButton(
                onPressed: o.status.toLowerCase() == 'cancelled' ? null : () => _cancelPrasad(o),
                style: TextButton.styleFrom(foregroundColor: AppColors.urgentRed),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sevaCard(SevaBookingView b) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.softWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: AppColors.krishnaBlue.withAlpha(10), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  b.sevaName,
                  style: const TextStyle(fontFamily: 'PlayfairDisplay', fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
              _statusChip(b.status),
            ],
          ),
          const SizedBox(height: 6),
          Text('Ref: ${b.referenceId}', style: TextStyle(color: AppColors.warmGrey)),
          const SizedBox(height: 6),
          Text('${b.sevaCategory} • ₹${b.sevaPrice.toStringAsFixed(0)}'),
          if ((b.preferredDate ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Preferred: ${b.preferredDate}'),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              OutlinedButton(
                onPressed: b.status.toLowerCase() == 'cancelled' ? null : () => _editSeva(b),
                child: const Text('Update'),
              ),
              const SizedBox(width: 10),
              TextButton(
                onPressed: b.status.toLowerCase() == 'cancelled' ? null : () => _cancelSeva(b),
                style: TextButton.styleFrom(foregroundColor: AppColors.urgentRed),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

