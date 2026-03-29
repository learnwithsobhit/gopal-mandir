import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../l10n/locale_scope.dart';
import '../payments/razorpay_donation.dart';
import '../widgets/vrindavan_background.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> with TickerProviderStateMixin {
  final ApiService _api = ApiService();
  final _phoneController = TextEditingController();

  late final TabController _tabs = TabController(length: 3, vsync: this);

  bool _loading = false;
  String? _error;
  List<PrasadOrderView> _prasad = [];
  List<SevaBookingView> _seva = [];
  List<PoojaBookingView> _pooja = [];

  @override
  void dispose() {
    _tabs.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _load(BuildContext context) async {
    final s = AppLocaleScope.of(context).strings;
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _error = s.errorPhoneRequired);
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
        _api.getPoojaBookingsByPhone(phone),
      ]);
      if (!mounted) return;
      setState(() {
        _prasad = results[0] as List<PrasadOrderView>;
        _seva = results[1] as List<SevaBookingView>;
        _pooja = results[2] as List<PoojaBookingView>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = s.errorLoadFailed;
      });
    }
  }

  Future<void> _cancelPrasad(BuildContext context, PrasadOrderView order) async {
    final s = AppLocaleScope.of(context).strings;
    final ok = await _confirmDialog(
      context: context,
      title: s.cancelBooking,
      message: '${s.ref}: ${order.referenceId}',
      actionLabel: s.cancel,
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
    if (resp.success) _load(context);
  }

  Future<void> _cancelSeva(BuildContext context, SevaBookingView booking) async {
    final s = AppLocaleScope.of(context).strings;
    final ok = await _confirmDialog(
      context: context,
      title: s.cancelBooking,
      message: '${s.ref}: ${booking.referenceId}',
      actionLabel: s.cancel,
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
    if (resp.success) _load(context);
  }

  Future<void> _editPrasad(BuildContext context, PrasadOrderView order) async {
    final qtyCtrl = TextEditingController(text: order.quantity.toString());
    final notesCtrl = TextEditingController(text: order.notes ?? '');
    String fulfillment = order.fulfillment;
    final addressCtrl = TextEditingController(text: order.address ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        final s2 = AppLocaleScope.of(context).strings;
        return AlertDialog(
          title: Text(
            s2.editPrasadTitle,
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.darkBrown,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownMenu<String>(
                  initialSelection: fulfillment,
                  width: 320,
                  textStyle: GoogleFonts.poppins(fontSize: 14, color: AppColors.darkBrown),
                  dropdownMenuEntries: [
                    DropdownMenuEntry(value: 'pickup', label: s2.pickup),
                    DropdownMenuEntry(value: 'delivery', label: s2.delivery),
                  ],
                  onSelected: (v) => fulfillment = v ?? fulfillment,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.poppins(fontSize: 14, color: AppColors.darkBrown),
                  decoration: _inputDecoration(s2.quantityLabel),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressCtrl,
                  minLines: 2,
                  maxLines: 3,
                  style: GoogleFonts.poppins(fontSize: 14, color: AppColors.darkBrown),
                  decoration: _inputDecoration(s2.addressDelivery),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  minLines: 2,
                  maxLines: 3,
                  style: GoogleFonts.poppins(fontSize: 14, color: AppColors.darkBrown),
                  decoration: _inputDecoration(s2.notesOptional),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(s2.close, style: GoogleFonts.poppins(color: AppColors.warmGrey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.krishnaBlue,
                foregroundColor: Colors.white,
                textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              child: Text(s2.save),
            ),
          ],
        );
      },
    );

    if (saved != true) return;

    final qty = int.tryParse(qtyCtrl.text.trim());
    final req = UpdatePrasadOrderRequest(
      phone: order.phone,
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
    if (resp.success) _load(context);
  }

  Future<void> _editSeva(BuildContext context, SevaBookingView booking) async {
    final dateCtrl = TextEditingController(text: booking.preferredDate ?? '');
    final notesCtrl = TextEditingController(text: booking.notes ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        final s2 = AppLocaleScope.of(context).strings;
        return AlertDialog(
          title: Text(
            s2.editSevaTitle,
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.darkBrown,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: dateCtrl,
                  readOnly: true,
                  style: GoogleFonts.poppins(fontSize: 14, color: AppColors.darkBrown),
                  decoration: _inputDecoration(s2.preferredDateOptional).copyWith(
                    suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
                  ),
                  onTap: () => _pickDateIntoController(context, dateCtrl),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  minLines: 2,
                  maxLines: 3,
                  style: GoogleFonts.poppins(fontSize: 14, color: AppColors.darkBrown),
                  decoration: _inputDecoration(s2.notesOptional),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Close', style: GoogleFonts.poppins(color: AppColors.warmGrey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.krishnaBlue,
                foregroundColor: Colors.white,
                textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              child: const Text('Save'),
            ),
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
    if (resp.success) _load(context);
  }

  Future<void> _cancelPooja(BuildContext context, PoojaBookingView b) async {
    final s = AppLocaleScope.of(context).strings;
    final ok = await _confirmDialog(
      context: context,
      title: s.cancelBooking,
      message: '${s.ref}: ${b.referenceId}',
      actionLabel: s.cancel,
      destructive: true,
    );
    if (ok != true) return;
    final resp = await _api.cancelPoojaBooking(b.referenceId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(resp.message),
        backgroundColor: resp.success ? AppColors.peacockGreen : AppColors.urgentRed,
      ),
    );
    if (resp.success) _load(context);
  }

  Future<void> _reschedulePooja(BuildContext context, PoojaBookingView b) async {
    final s = AppLocaleScope.of(context).strings;
    final now = DateTime.now();
    final from =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final end = now.add(const Duration(days: 90));
    final to =
        '${end.year.toString().padLeft(4, '0')}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';
    final days = await _api.getPoojaAvailability(officiant: b.officiant, from: from, to: to);
    if (!mounted) return;
    final items = days.where((d) => d.slots.any((sl) => sl.available > 0)).toList();
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.poojaNoSlots)));
      return;
    }

    String? pickedDate;
    int? pickedSlot;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            PoojaAvailabilityDay? day;
            if (pickedDate != null) {
              for (final d in items) {
                if (d.date == pickedDate) {
                  day = d;
                  break;
                }
              }
            }
            return AlertDialog(
              title: Text(s.editPoojaTitle),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(s.poojaPickDate, style: Theme.of(ctx).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: items
                          .map(
                            (d) => ActionChip(
                              label: Text(d.date),
                              onPressed: () => setLocal(() {
                                pickedDate = d.date;
                                pickedSlot = null;
                              }),
                            ),
                          )
                          .toList(),
                    ),
                    if (day != null) ...[
                      const SizedBox(height: 12),
                      Text(s.poojaDateSlot, style: Theme.of(ctx).textTheme.labelLarge),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: day!.slots.map((sl) {
                          final en = sl.available > 0;
                          return ChoiceChip(
                            label: Text(sl.label),
                            selected: pickedSlot == sl.slotId,
                            onSelected: en
                                ? (_) => setLocal(() => pickedSlot = sl.slotId)
                                : null,
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.close)),
                FilledButton(
                  onPressed: pickedDate != null && pickedSlot != null ? () => Navigator.pop(ctx, true) : null,
                  child: Text(s.save),
                ),
              ],
            );
          },
        );
      },
    );
    if (saved != true || pickedDate == null || pickedSlot == null) return;
    final resp = await _api.reschedulePoojaBooking(
      b.referenceId,
      PoojaRescheduleRequest(bookingDate: pickedDate!, slotId: pickedSlot!),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(resp.message),
        backgroundColor: resp.success ? AppColors.peacockGreen : AppColors.urgentRed,
      ),
    );
    if (resp.success) _load(context);
  }

  Future<void> _payPoojaOnline(BuildContext context, PoojaBookingView b) async {
    final checkout = await _api.createPoojaBookingCheckout(b.referenceId);
    if (!mounted) return;
    if (!checkout.success || checkout.orderId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(checkout.error ?? 'Could not start payment'),
          backgroundColor: AppColors.urgentRed,
        ),
      );
      return;
    }
    RazorpayPaymentOutcome? outcome;
    try {
      outcome = await openRazorpayCheckout(
        keyId: checkout.keyId,
        orderId: checkout.orderId,
        amountPaise: checkout.amount,
        name: b.name,
        contact: b.phone,
        email: '',
        description: b.offeringName,
      );
    } catch (e) {
      await _api.notifyRazorpayClientPaymentFailed(
        orderId: checkout.orderId,
        referenceId: checkout.referenceId,
        reason: e.toString(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.urgentRed),
      );
      return;
    }
    if (!mounted) return;
    if (outcome == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            !isRazorpayCheckoutSupported
                ? 'Online payment runs on Android or iOS.'
                : 'Payment was cancelled.',
          ),
        ),
      );
      return;
    }
    final verified = await _api.verifyRazorpayPayment(
      orderId: outcome.orderId,
      paymentId: outcome.paymentId,
      signature: outcome.signature,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          verified ? 'Payment received. Jai Gopal!' : 'Payment may take a moment to confirm.',
        ),
        backgroundColor: AppColors.peacockGreen,
      ),
    );
    _load(context);
  }

  Widget _poojaCard(BuildContext context, PoojaBookingView b) {
    final s = AppLocaleScope.of(context).strings;
    final st = b.bookingStatus.toLowerCase();
    final canMemberChange = st != 'cancelled';
    final canPay = st == 'confirmed' &&
        (b.paymentExpected ?? '').toLowerCase() == 'online' &&
        b.paymentStatus.toLowerCase() == 'pending' &&
        (b.gatewayOrderId == null || b.gatewayOrderId!.isEmpty);

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
                  b.offeringName,
                  style: GoogleFonts.playfairDisplay(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: AppColors.darkBrown,
                  ),
                ),
              ),
              _statusChip(b.bookingStatus),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${s.ref}: ${b.referenceId}',
            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.warmGrey),
          ),
          const SizedBox(height: 6),
          Text(
            '${b.officiant} · ${b.slotLabel} · ${b.bookingDate}',
            style: GoogleFonts.poppins(fontSize: 13, color: AppColors.darkBrown),
          ),
          if ((b.packageName ?? '').isNotEmpty)
            Text(
              '${s.poojaPackage}: ${b.packageName}',
              style: GoogleFonts.poppins(fontSize: 12, color: AppColors.warmGrey),
            ),
          Text(
            '${b.venue}${(b.address ?? '').isNotEmpty ? ' · ${b.address}' : ''}',
            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.warmGrey),
          ),
          if (b.amountPaise != null)
            Text(
              '₹${(b.amountPaise! / 100).toStringAsFixed(0)} · ${b.paymentStatus}'
              '${(b.paymentExpected ?? '').isNotEmpty ? ' (${b.paymentExpected})' : ''}',
              style: GoogleFonts.poppins(fontSize: 12, color: AppColors.warmGrey),
            ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (canMemberChange)
                OutlinedButton(
                  onPressed: () => _reschedulePooja(context, b),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.krishnaBlue,
                    side: const BorderSide(color: AppColors.krishnaBlue),
                  ),
                  child: Text(s.poojaReschedule),
                ),
              if (canPay)
                FilledButton(
                  onPressed: () => _payPoojaOnline(context, b),
                  child: Text(s.poojaPayOnline),
                ),
              if (canMemberChange)
                TextButton(
                  onPressed: () => _cancelPooja(context, b),
                  style: TextButton.styleFrom(foregroundColor: AppColors.urgentRed),
                  child: Text(s.cancel),
                ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(color: AppColors.warmGrey, fontSize: 14),
      filled: true,
      fillColor: AppColors.softWhite,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.krishnaBlue.withAlpha(76)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.krishnaBlue.withAlpha(76)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.krishnaBlue),
      ),
    );
  }

  Future<void> _pickDateIntoController(BuildContext context, TextEditingController ctrl) async {
    final now = DateTime.now();
    DateTime initial = now;
    if (ctrl.text.trim().isNotEmpty) {
      try {
        initial = DateTime.parse(ctrl.text.trim());
      } catch (_) {}
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (picked != null) {
      ctrl.text = '${picked.year.toString().padLeft(4, '0')}-'
          '${picked.month.toString().padLeft(2, '0')}-'
          '${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<bool?> _confirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    required String actionLabel,
    bool destructive = false,
  }) {
    final s = AppLocaleScope.of(context).strings;
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            title,
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.darkBrown,
            ),
          ),
          content: Text(
            message,
            style: GoogleFonts.poppins(fontSize: 14, color: AppColors.warmGrey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(s.no, style: GoogleFonts.poppins(color: AppColors.warmGrey)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: destructive
                  ? TextButton.styleFrom(
                      foregroundColor: AppColors.urgentRed,
                      textStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
                    )
                  : TextButton.styleFrom(
                      foregroundColor: AppColors.krishnaBlue,
                      textStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
              child: Text(actionLabel),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocaleScope.of(context).strings;
    return VrindavanBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(s.myBookings),
          bottom: TabBar(
            controller: _tabs,
            tabs: [
              Tab(text: s.prasad),
              Tab(text: s.seva),
              Tab(text: s.tabPoojaBookings),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: AppSpacing.screenInsets,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: s.phoneNumber,
                      ),
                      onSubmitted: (_) => _load(context),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: _loading ? null : () => _load(context),
                      child: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(s.viewLoad),
                    ),
                  ),
                ],
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(
                  _error!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _prasad.isEmpty && !_loading
                      ? Center(
                          child: Text(
                            s.noPrasadBookings,
                            style: GoogleFonts.poppins(fontSize: 14, color: AppColors.warmGrey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: _prasad.length,
                          itemBuilder: (context, i) => _prasadCard(context, _prasad[i]),
                        ),
                  _seva.isEmpty && !_loading
                      ? Center(
                          child: Text(
                            s.noSevaBookings,
                            style: GoogleFonts.poppins(fontSize: 14, color: AppColors.warmGrey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: _seva.length,
                          itemBuilder: (context, i) => _sevaCard(context, _seva[i]),
                        ),
                  _pooja.isEmpty && !_loading
                      ? Center(
                          child: Text(
                            s.noPoojaBookings,
                            style: GoogleFonts.poppins(fontSize: 14, color: AppColors.warmGrey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: _pooja.length,
                          itemBuilder: (context, i) => _poojaCard(context, _pooja[i]),
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
        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Widget _prasadCard(BuildContext context, PrasadOrderView o) {
    final s = AppLocaleScope.of(context).strings;
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
                  style: GoogleFonts.playfairDisplay(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: AppColors.darkBrown,
                  ),
                ),
              ),
              _statusChip(o.status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${s.ref}: ${o.referenceId}',
            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.warmGrey),
          ),
          const SizedBox(height: 6),
          Text(
            '${s.quantity}: ${o.quantity} • ${o.fulfillment} • ${s.total}: ₹${o.totalAmount.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(fontSize: 14, color: AppColors.darkBrown),
          ),
          if (o.deliveryFee > 0) ...[
            const SizedBox(height: 4),
            Text(
              'Subtotal ₹${o.subtotal.toStringAsFixed(2)} + delivery 10% ₹${o.deliveryFee.toStringAsFixed(2)}',
              style: GoogleFonts.poppins(fontSize: 12, color: AppColors.warmGrey),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            'Pay: ${o.paymentMethod}${o.paymentStatus != null && o.paymentStatus!.isNotEmpty ? ' • ${o.paymentStatus}' : ''}',
            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.warmGrey),
          ),
          if (o.paymentFailureReason != null && o.paymentFailureReason!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Payment note: ${o.paymentFailureReason}',
              style: GoogleFonts.poppins(fontSize: 12, color: AppColors.urgentRed),
            ),
          ],
          if ((o.address ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '${s.address}: ${o.address}',
              style: GoogleFonts.poppins(fontSize: 13, color: AppColors.warmGrey),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              OutlinedButton(
                onPressed: o.status.toLowerCase() == 'cancelled' ? null : () => _editPrasad(context, o),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.krishnaBlue,
                  side: const BorderSide(color: AppColors.krishnaBlue),
                  textStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                child: Text(s.update),
              ),
              const SizedBox(width: 10),
              TextButton(
                onPressed: o.status.toLowerCase() == 'cancelled' ? null : () => _cancelPrasad(context, o),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.urgentRed,
                  textStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                child: Text(s.cancel),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sevaCard(BuildContext context, SevaBookingView b) {
    final s = AppLocaleScope.of(context).strings;
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
                  style: GoogleFonts.playfairDisplay(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: AppColors.darkBrown,
                  ),
                ),
              ),
              _statusChip(b.status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${s.ref}: ${b.referenceId}',
            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.warmGrey),
          ),
          const SizedBox(height: 6),
          Text(
            '${b.sevaCategory} • ₹${b.sevaPrice.toStringAsFixed(0)}',
            style: GoogleFonts.poppins(fontSize: 14, color: AppColors.darkBrown),
          ),
          if ((b.preferredDate ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '${s.preferred}: ${b.preferredDate}',
              style: GoogleFonts.poppins(fontSize: 13, color: AppColors.warmGrey),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              OutlinedButton(
                onPressed: b.status.toLowerCase() == 'cancelled' ? null : () => _editSeva(context, b),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.krishnaBlue,
                  side: const BorderSide(color: AppColors.krishnaBlue),
                  textStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                child: Text(s.update),
              ),
              const SizedBox(width: 10),
              TextButton(
                onPressed: b.status.toLowerCase() == 'cancelled' ? null : () => _cancelSeva(context, b),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.urgentRed,
                  textStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                child: Text(s.cancel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

