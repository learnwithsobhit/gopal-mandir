import 'package:flutter/material.dart';
import '../l10n/locale_scope.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../models/models.dart';
import '../widgets/vrindavan_background.dart';
import '../widgets/app_surface.dart';
import '../services/api_service.dart';
import '../payments/razorpay_donation.dart';

class SevaBookingScreen extends StatefulWidget {
  final SevaItem item;

  const SevaBookingScreen({
    super.key,
    required this.item,
  });

  @override
  State<SevaBookingScreen> createState() => _SevaBookingScreenState();
}

class _SevaBookingScreenState extends State<SevaBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _api = ApiService();

  final _amountController = TextEditingController(text: '100');
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _preferredDateController = TextEditingController();
  final _notesController = TextEditingController();

  bool _submitting = false;

  double? _parseContributionAmount() {
    final raw = _amountController.text.trim().replaceAll(',', '');
    if (raw.isEmpty) return null;
    final n = double.tryParse(raw);
    if (n == null || n < 100 || n > 500000) return null;
    return n;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _preferredDateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickPreferredDate() async {
    final now = DateTime.now();
    final current = now;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      _preferredDateController.text = '${picked.year.toString().padLeft(4, '0')}-'
          '${picked.month.toString().padLeft(2, '0')}-'
          '${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _confirm() async {
    final s = AppLocaleScope.of(context).strings;
    final form = _formKey.currentState;
    if (form == null) return;
    if (!form.validate()) return;

    final amount = _parseContributionAmount();
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.enterValidAmountMin100),
          backgroundColor: AppColors.urgentRed,
        ),
      );
      return;
    }

    final req = SevaBookingRequest(
      sevaItemId: widget.item.id,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      amount: amount,
      preferredDate: _preferredDateController.text.trim().isEmpty
          ? null
          : _preferredDateController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    setState(() => _submitting = true);
    try {
      final checkout = await _api.createSevaBookingCheckout(req);

      if (!mounted) return;

      if (!checkout.success || checkout.orderId.isEmpty) {
        final err = checkout.error ?? s.paymentStartFailed;
        final ref = checkout.referenceId;
        final msg = ref.isNotEmpty
            ? '$err\n${s.referenceSaved(ref)}'
            : err;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
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
          name: _nameController.text.trim(),
          contact: _phoneController.text.trim(),
          email: '',
          description: widget.item.name,
        );
      } catch (e) {
        if (checkout.referenceId.isNotEmpty) {
          await _api.notifyRazorpayClientPaymentFailed(
            orderId: checkout.orderId,
            referenceId: checkout.referenceId,
            reason: e.toString(),
          );
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.errorWithDetail(e.toString())), backgroundColor: AppColors.urgentRed),
        );
        return;
      }

      if (!mounted) return;

      if (outcome == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              !isRazorpayCheckoutSupported
                  ? s.onlineDonationMobileOnly
                  : s.paymentCancelled,
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

      final msg = verified
          ? s.paymentReceivedSeva
          : s.paymentCompletedSeva;
      await _showBookingSuccess(msg, checkout.referenceId);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _showBookingSuccess(String message, String referenceId) async {
    final s = AppLocaleScope.of(context).strings;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(s.sevaBookingDialogTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              if (referenceId.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  s.referenceId(referenceId),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(s.okLabel),
            ),
          ],
        );
      },
    );

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(s.sevaBookedToast(widget.item.name)),
        backgroundColor: AppColors.peacockGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocaleScope.of(context).strings;
    return VrindavanBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text(s.sevaBookingTitle)),
        body: SingleChildScrollView(
          padding: AppSpacing.screenInsets,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSurface(
                  level: AppSurfaceLevel.low,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary.withAlpha(100),
                              Theme.of(context).colorScheme.primary.withAlpha(50),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.self_improvement, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.item.name,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontFamily: 'Playfair Display',
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              widget.item.description,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppSurface(
                  level: AppSurfaceLevel.low,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.yourDetails,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        s.contributionAmountTitle,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: s.amountMin100Label,
                          prefixText: '₹ ',
                          prefixStyle: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        validator: (v) {
                          final raw = (v ?? '').trim().replaceAll(',', '');
                          if (raw.isEmpty) return s.enterAmount;
                          final n = double.tryParse(raw);
                          if (n == null) return s.enterValidNumber;
                          if (n < 100) return s.minimumDonation100;
                          if (n > 500000) return s.maximumDonationLimit;
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        s.staffContactPaymentDisclaimer,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.warmGrey,
                              height: 1.4,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(labelText: s.fullName),
                        validator: (v) => v == null || v.trim().isEmpty ? s.pleaseEnterName : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(labelText: s.phoneNumberLabel),
                        validator: (v) {
                          final raw = (v ?? '').trim();
                          if (raw.isEmpty) return s.pleaseEnterPhone;
                          final digits = raw.replaceAll(RegExp(r'\D'), '');
                          if (digits.length < 10) return s.enterValidPhone;
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _preferredDateController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: s.preferredDateOptional,
                          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
                        ),
                        onTap: _pickPreferredDate,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _notesController,
                        minLines: 2,
                        maxLines: 4,
                        decoration: InputDecoration(labelText: s.notesOptionalLabel),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                FilledButton(
                  onPressed: _submitting ? null : _confirm,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(s.payAndBookSeva),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

