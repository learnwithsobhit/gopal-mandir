import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../payments/razorpay_donation.dart';
import '../widgets/app_amount_chips.dart';
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

  int _presetAmount = 501;
  bool _useCustomAmount = false;
  final _customAmountController = TextEditingController(text: '500');
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  bool _submitting = false;

  final List<int> _presetAmounts = [100, 251, 501, 1001, 2101, 5001];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('दान')),
      body: SingleChildScrollView(
        padding: AppSpacing.screenInsets,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppScreenHeader(
                title: widget.event.title,
                subtitle: 'Donate for this event',
                icon: Icons.favorite_rounded,
              ),
              const SizedBox(height: AppSpacing.xxl),
              AppSectionTitle(title: 'Select Amount (₹)'),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  AppAmountChips(
                    amounts: _presetAmounts,
                    selectedAmount: _useCustomAmount ? -1 : _presetAmount,
                    enabled: !_submitting,
                    onSelect: (a) => setState(() {
                      _useCustomAmount = false;
                      _presetAmount = a;
                    }),
                  ),
                  FilterChip(
                    label: Text(
                      'Other',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: _useCustomAmount ? Colors.white : cs.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    selected: _useCustomAmount,
                    onSelected: _submitting
                        ? null
                        : (v) => setState(() => _useCustomAmount = v),
                    showCheckmark: false,
                    selectedColor: cs.primary,
                    backgroundColor: cs.surfaceContainerHigh,
                    side: BorderSide(
                      color: _useCustomAmount ? cs.primary : cs.outline.withAlpha(120),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
                    ),
                  ),
                ],
              ),
              if (_useCustomAmount) ...[
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _customAmountController,
                  enabled: !_submitting,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Amount (₹, min 100)',
                    prefixText: '₹ ',
                    prefixStyle: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600),
                  ),
                  validator: (v) {
                    final raw = (v ?? '').trim().replaceAll(',', '');
                    if (raw.isEmpty) return 'Enter an amount';
                    final n = double.tryParse(raw);
                    if (n == null) return 'Enter a valid number';
                    if (n < 100) return 'Minimum donation is ₹100';
                    if (n > 500000) return 'Maximum amount is ₹5,00,000';
                    return null;
                  },
                ),
              ],
              const SizedBox(height: AppSpacing.xxl),
              AppTextFormField(
                labelText: 'Your Name',
                prefixIcon: Icon(Icons.person_outline, color: cs.primary),
                controller: _nameController,
                enabled: !_submitting,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Please enter your name';
                  if (v.trim().length < 2) return 'Name is too short';
                  return null;
                },
              ),
              AppTextFormField(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone_outlined, color: cs.primary),
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                enabled: !_submitting,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  final raw = (v ?? '').trim();
                  if (raw.isEmpty) return 'Please enter phone number';
                  final digits = raw.replaceAll(RegExp(r'\D'), '');
                  if (digits.length < 10) return 'Enter a valid phone number';
                  return null;
                },
              ),
              AppTextFormField(
                labelText: 'Email (optional)',
                prefixIcon: Icon(Icons.email_outlined, color: cs.primary),
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                enabled: !_submitting,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  final raw = (v ?? '').trim();
                  if (raw.isEmpty) return null;
                  final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(raw);
                  return ok ? null : 'Enter a valid email';
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
                    labelText: 'Message (optional)',
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
                    : Text('Donate ₹${_donateAmountLabel()}'),
              ),
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: Text(
                  'Secure & Trusted',
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
    if (_useCustomAmount) {
      final raw = _customAmountController.text.trim().replaceAll(',', '');
      final n = double.tryParse(raw);
      if (n == null) return '…';
      if (n == n.roundToDouble()) return n.round().toString();
      return n.toStringAsFixed(2);
    }
    return _presetAmount.toString();
  }

  double? _effectiveDonationAmount() {
    if (_useCustomAmount) {
      final raw = _customAmountController.text.trim().replaceAll(',', '');
      final n = double.tryParse(raw);
      if (n == null || n < 100 || n > 500000) return null;
      return n;
    }
    return _presetAmount.toDouble();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null) return;
    if (!form.validate()) return;

    final amount = _effectiveDonationAmount();
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Enter a valid amount (minimum ₹100).'),
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
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          message: _messageController.text.trim().isEmpty ? null : _messageController.text.trim(),
        ),
      );

      if (!mounted) return;

      if (!checkout.success || checkout.orderId.isEmpty) {
        final err = checkout.error ?? 'Could not start payment. Try again later.';
        final ref = checkout.referenceId;
        final msg = ref.isNotEmpty
            ? '$err\nReference saved: $ref — team can follow up.'
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
            content: Text(e.toString()),
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
                  ? 'Online donation runs on Android or iOS. Open the app on your phone to pay.'
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

      final thankYou = verified
          ? 'Dhanyavaad! Your donation of ₹${_donateAmountLabel()} for this event was received. Jai Gopal!'
          : 'Dhanyavaad! Your payment completed. Confirmation may arrive in a moment. Jai Gopal!';

      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Dhanyavaad!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(thankYou),
                if (checkout.referenceId.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Reference ID: ${checkout.referenceId}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
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
    _customAmountController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}
