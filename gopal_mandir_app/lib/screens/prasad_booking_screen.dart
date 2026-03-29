import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../models/models.dart';
import '../widgets/vrindavan_background.dart';
import '../widgets/app_surface.dart';
import '../services/api_service.dart';
import '../payments/razorpay_donation.dart';

enum PrasadFulfillment { pickup, delivery }

enum PrasadPickupPayment { temple, online }

class PrasadBookingScreen extends StatefulWidget {
  final PrasadItem item;

  const PrasadBookingScreen({
    super.key,
    required this.item,
  });

  @override
  State<PrasadBookingScreen> createState() => _PrasadBookingScreenState();
}

class _PrasadBookingScreenState extends State<PrasadBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _api = ApiService();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  int _qty = 1;
  PrasadFulfillment _fulfillment = PrasadFulfillment.pickup;
  PrasadPickupPayment _pickupPayment = PrasadPickupPayment.temple;
  bool _submitting = false;

  double get _subtotal => widget.item.price * _qty;

  double get _deliveryFee => _fulfillment == PrasadFulfillment.delivery
      ? ((_subtotal * 0.10 * 100).round() / 100.0)
      : 0.0;

  double get _grandTotal => ((_subtotal + _deliveryFee) * 100).round() / 100.0;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  PrasadOrderRequest _buildRequest() {
    return PrasadOrderRequest(
      prasadItemId: widget.item.id,
      quantity: _qty,
      fulfillment: _fulfillment == PrasadFulfillment.pickup ? 'pickup' : 'delivery',
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _fulfillment == PrasadFulfillment.delivery ? _addressController.text.trim() : null,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );
  }

  bool get _needsOnlinePayment =>
      _fulfillment == PrasadFulfillment.delivery ||
      (_fulfillment == PrasadFulfillment.pickup && _pickupPayment == PrasadPickupPayment.online);

  Future<void> _confirm() async {
    final form = _formKey.currentState;
    if (form == null) return;
    if (!form.validate()) return;

    if (_needsOnlinePayment && _grandTotal < 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Online payment requires a minimum order total of ₹100.'),
          backgroundColor: AppColors.urgentRed,
        ),
      );
      return;
    }

    if (_needsOnlinePayment) {
      setState(() => _submitting = true);
      try {
        final checkout = await _api.createPrasadOrderCheckout(_buildRequest());
        if (!mounted) return;

        if (!checkout.success || checkout.orderId.isEmpty) {
          final err = checkout.error ?? 'Could not start payment.';
          final ref = checkout.referenceId;
          final msg = ref.isNotEmpty
              ? '$err\nReference saved: $ref — team can follow up.'
              : err;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: AppColors.urgentRed),
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
            description: 'Prasad: ${widget.item.name}',
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
                    ? 'Online payment runs on Android or iOS. Open the app on your phone to pay.'
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
            ? 'Payment received. Your prasad order is confirmed. Jai Gopal!'
            : 'Payment completed. Confirmation may take a moment. Jai Gopal!';
        await _showBookingSuccess(thankYou, checkout.referenceId);
      } finally {
        if (mounted) setState(() => _submitting = false);
      }
      return;
    }

    setState(() => _submitting = true);
    final resp = await _api.submitPrasadOrder(
      PrasadOrderRequest(
        prasadItemId: widget.item.id,
        quantity: _qty,
        fulfillment: _fulfillment == PrasadFulfillment.pickup ? 'pickup' : 'delivery',
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _fulfillment == PrasadFulfillment.delivery ? _addressController.text.trim() : null,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        paymentMethod: 'temple',
      ),
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (!resp.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(resp.message), backgroundColor: AppColors.urgentRed),
      );
      return;
    }

    await _showBookingSuccess(resp.message, resp.referenceId);
  }

  Future<void> _showBookingSuccess(String message, String referenceId) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Booking Confirmed'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              if (referenceId.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Reference ID: $referenceId',
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

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🙏 ${widget.item.name} booked! Jai Gopal!'),
        backgroundColor: AppColors.peacockGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return VrindavanBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Book Prasad')),
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
                            colors: [AppColors.templeGold.withAlpha(40), AppColors.templeGold.withAlpha(20)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.cookie, color: AppColors.templeGoldDark, size: 28),
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
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '₹${widget.item.price.toInt()}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.peacockGreen,
                              fontWeight: FontWeight.bold,
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
                      'Quantity',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _submitting || _qty <= 1 ? null : () => setState(() => _qty -= 1),
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.krishnaBlue.withAlpha(10),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$_qty',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        IconButton(
                          onPressed: _submitting ? null : () => setState(() => _qty += 1),
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Subtotal: ₹${_subtotal.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                    if (_fulfillment == PrasadFulfillment.delivery) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Delivery (10%): ₹${_deliveryFee.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Total: ₹${_grandTotal.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.peacockGreen,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    if (_needsOnlinePayment && _grandTotal < 100)
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Text(
                          'Minimum ₹100 for online payment — increase quantity.',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.urgentRed),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Fulfillment',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SegmentedButton<PrasadFulfillment>(
                      segments: const [
                        ButtonSegment(
                          value: PrasadFulfillment.pickup,
                          label: Text('Pickup'),
                          icon: Icon(Icons.temple_hindu),
                        ),
                        ButtonSegment(
                          value: PrasadFulfillment.delivery,
                          label: Text('Delivery'),
                          icon: Icon(Icons.local_shipping_outlined),
                        ),
                      ],
                      selected: {_fulfillment},
                      onSelectionChanged: _submitting
                          ? null
                          : (value) => setState(() => _fulfillment = value.first),
                    ),
                    if (_fulfillment == PrasadFulfillment.pickup) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Payment',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SegmentedButton<PrasadPickupPayment>(
                        segments: const [
                          ButtonSegment(
                            value: PrasadPickupPayment.temple,
                            label: Text('Pay at temple'),
                            icon: Icon(Icons.payments_outlined),
                          ),
                          ButtonSegment(
                            value: PrasadPickupPayment.online,
                            label: Text('Pay online'),
                            icon: Icon(Icons.phone_android),
                          ),
                        ],
                        selected: {_pickupPayment},
                        onSelectionChanged: _submitting
                            ? null
                            : (value) => setState(() => _pickupPayment = value.first),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              _field(
                label: 'Your Name',
                icon: Icons.person,
                controller: _nameController,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Please enter your name';
                  if (v.trim().length < 2) return 'Name is too short';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              _field(
                label: 'Phone Number',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                controller: _phoneController,
                validator: (v) {
                  final raw = (v ?? '').trim();
                  if (raw.isEmpty) return 'Please enter phone number';
                  final digits = raw.replaceAll(RegExp(r'\D'), '');
                  if (digits.length < 10) return 'Enter a valid phone number';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              if (_fulfillment == PrasadFulfillment.delivery) ...[
                _field(
                  label: 'Delivery Address',
                  icon: Icons.location_on_outlined,
                  controller: _addressController,
                  minLines: 2,
                  maxLines: 3,
                  validator: (v) {
                    if (_fulfillment != PrasadFulfillment.delivery) return null;
                    if (v == null || v.trim().isEmpty) return 'Please enter delivery address';
                    if (v.trim().length < 10) return 'Address is too short';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              _field(
                label: 'Notes (optional)',
                icon: Icons.sticky_note_2_outlined,
                controller: _notesController,
                minLines: 2,
                maxLines: 3,
              ),

              const SizedBox(height: AppSpacing.xl),

              FilledButton(
                onPressed: _submitting ? null : _confirm,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.peacockGreen,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : Text(
                        _needsOnlinePayment
                            ? 'Pay ₹${_grandTotal.toStringAsFixed(2)}'
                            : 'Book • Pay ₹${_grandTotal.toStringAsFixed(2)} at temple',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int minLines = 1,
    int maxLines = 1,
  }) {
    final cs = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      minLines: minLines,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: cs.primary),
      ),
    );
  }
}

