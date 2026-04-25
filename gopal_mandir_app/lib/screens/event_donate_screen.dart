import 'package:flutter/material.dart';
import '../l10n/locale_scope.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../payments/razorpay_donation.dart';
import '../widgets/app_screen_header.dart';
import '../widgets/app_section_title.dart';
import '../widgets/app_text_form_field.dart';

class EventDonateScreen extends StatefulWidget {
  final Event event;

  const EventDonateScreen({super.key, required this.event});

  @override
  State<EventDonateScreen> createState() => _EventDonateScreenState();
}

class _EventDonateScreenState extends State<EventDonateScreen> {
  final ApiService _api = ApiService();
  final _formKey = GlobalKey<FormState>();

  final _amountController = TextEditingController(text: '100');
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final s = AppLocaleScope.of(context).strings;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(s.donateLabel)),
      body: SingleChildScrollView(
        padding: AppSpacing.screenInsets,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppScreenHeader(
                title: widget.event.title,
                subtitle: s.donateForEvent,
                icon: Icons.favorite_rounded,
              ),
              const SizedBox(height: AppSpacing.xxl),
              AppSectionTitle(title: s.contributionAmountTitle),
              TextFormField(
                controller: _amountController,
                enabled: !_submitting,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: s.amountMin100Label,
                  prefixText: '₹ ',
                  prefixStyle: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600),
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
              const SizedBox(height: AppSpacing.md),
              Text(
                s.staffContactPaymentDisclaimer,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.warmGrey,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              AppTextFormField(
                labelText: s.yourNameLabel,
                prefixIcon: Icon(Icons.person_outline, color: cs.primary),
                controller: _nameController,
                enabled: !_submitting,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return s.pleaseEnterName;
                  if (v.trim().length < 2) return s.nameTooShort;
                  return null;
                },
              ),
              AppTextFormField(
                labelText: s.phoneNumberLabel,
                prefixIcon: Icon(Icons.phone_outlined, color: cs.primary),
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                enabled: !_submitting,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  final raw = (v ?? '').trim();
                  if (raw.isEmpty) return s.pleaseEnterPhone;
                  final digits = raw.replaceAll(RegExp(r'\D'), '');
                  if (digits.length < 10) return s.enterValidPhone;
                  return null;
                },
              ),
              AppTextFormField(
                labelText: s.emailOptionalLabel,
                prefixIcon: Icon(Icons.email_outlined, color: cs.primary),
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                enabled: !_submitting,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  final raw = (v ?? '').trim();
                  if (raw.isEmpty) return null;
                  final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(raw);
                  return ok ? null : s.enterValidEmail;
                },
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: TextFormField(
                  controller: _messageController,
                  enabled: !_submitting,
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: s.messageOptionalLabel,
                    prefixIcon: Icon(Icons.message_outlined, color: cs.primary),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.templeGold,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : Text(s.donateWithAmount(_donateAmountLabel())),
              ),
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: Text(
                  s.secureTrusted,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _donateAmountLabel() {
    final raw = _amountController.text.trim().replaceAll(',', '');
    final n = double.tryParse(raw);
    if (n == null) return '…';
    if (n == n.roundToDouble()) return n.round().toString();
    return n.toStringAsFixed(2);
  }

  double? _effectiveDonationAmount() {
    final raw = _amountController.text.trim().replaceAll(',', '');
    final n = double.tryParse(raw);
    if (n == null || n < 100 || n > 500000) return null;
    return n;
  }

  Future<void> _submit() async {
    final s = AppLocaleScope.of(context).strings;
    final form = _formKey.currentState;
    if (form == null) return;
    if (!form.validate()) return;

    final amount = _effectiveDonationAmount();
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.enterValidAmountMin100),
          backgroundColor: AppColors.urgentRed,
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final checkout = await _api.createEventDonationCheckout(
        widget.event.id,
        EventDonationRequest(
          eventId: widget.event.id,
          name: _nameController.text.trim(),
          amount: amount,
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          message: _messageController.text.trim().isEmpty ? null : _messageController.text.trim(),
        ),
      );

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
          email: _emailController.text.trim(),
          description: widget.event.title,
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
          SnackBar(
            content: Text(s.errorWithDetail(e.toString())),
            backgroundColor: AppColors.urgentRed,
          ),
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

      final thankYou = verified
          ? s.eventDonationReceived(_donateAmountLabel())
          : s.paymentCompletedAwaitingConfirm;

      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(s.thankYouTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(thankYou),
                if (checkout.referenceId.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    s.referenceId(checkout.referenceId),
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
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}
