import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../payments/razorpay_donation.dart';

class EventDonateScreen extends StatefulWidget {
  final Event event;

  const EventDonateScreen({super.key, required this.event});

  @override
  State<EventDonateScreen> createState() => _EventDonateScreenState();
}

class _EventDonateScreenState extends State<EventDonateScreen> {
  final ApiService _api = ApiService();
  final _formKey = GlobalKey<FormState>();

  int _selectedAmount = 501;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  bool _submitting = false;

  final List<int> _amounts = [101, 251, 501, 1001, 2101, 5001];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('दान'),
        backgroundColor: AppColors.krishnaBlue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.peacockGreen,
                      AppColors.peacockGreenLight,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.favorite, color: Colors.white, size: 40),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.event.title,
                            style: const TextStyle(
                              fontFamily: 'PlayfairDisplay',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Donate for this event',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: Colors.white.withAlpha(200),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Select Amount (₹)',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkBrown,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _amounts.map((amount) {
                  final selected = _selectedAmount == amount;
                  return GestureDetector(
                    onTap: _submitting ? null : () => setState(() => _selectedAmount = amount),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.krishnaBlue : AppColors.softWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? AppColors.krishnaBlue : AppColors.krishnaBlue.withAlpha(30),
                        ),
                        boxShadow: selected
                            ? [BoxShadow(color: AppColors.krishnaBlue.withAlpha(30), blurRadius: 8)]
                            : null,
                      ),
                      child: Text(
                        '₹$amount',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : AppColors.darkBrown,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              _buildField(
                'Your Name',
                _nameController,
                Icons.person,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Please enter your name';
                  if (v.trim().length < 2) return 'Name is too short';
                  return null;
                },
                enabled: !_submitting,
              ),
              const SizedBox(height: 16),
              _buildField(
                'Phone Number',
                _phoneController,
                Icons.phone,
                keyboard: TextInputType.phone,
                validator: (v) {
                  final raw = (v ?? '').trim();
                  if (raw.isEmpty) return 'Please enter phone number';
                  final digits = raw.replaceAll(RegExp(r'\D'), '');
                  if (digits.length < 10) return 'Enter a valid phone number';
                  return null;
                },
                enabled: !_submitting,
              ),
              const SizedBox(height: 16),
              _buildField(
                'Email (optional)',
                _emailController,
                Icons.email,
                keyboard: TextInputType.emailAddress,
                validator: (v) {
                  final raw = (v ?? '').trim();
                  if (raw.isEmpty) return null;
                  final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(raw);
                  return ok ? null : 'Enter a valid email';
                },
                enabled: !_submitting,
              ),
              const SizedBox(height: 16),
              _buildField(
                'Message (optional)',
                _messageController,
                Icons.message,
                enabled: !_submitting,
                maxLines: 3,
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.templeGold,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : Text(
                          'Donate ₹$_selectedAmount',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Secure & Trusted',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.warmGrey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null) return;
    if (!form.validate()) return;

    setState(() => _submitting = true);
    try {
      final checkout = await _api.createEventDonationCheckout(
        widget.event.id,
        EventDonationRequest(
          eventId: widget.event.id,
          name: _nameController.text.trim(),
          amount: _selectedAmount.toDouble(),
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          message: _messageController.text.trim().isEmpty ? null : _messageController.text.trim(),
        ),
      );

      if (!mounted) return;

      if (!checkout.success || checkout.orderId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(checkout.error ?? 'Could not start payment. Try again later.'),
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
          ? 'Dhanyavaad! Your donation of ₹$_selectedAmount for this event was received. Jai Gopal!'
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

  Widget _buildField(
    String label,
    TextEditingController ctrl,
    IconData icon, {
    TextInputType? keyboard,
    String? Function(String?)? validator,
    bool enabled = true,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      validator: validator,
      enabled: enabled,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontFamily: 'Poppins', color: AppColors.warmGrey),
        prefixIcon: Icon(icon, color: AppColors.krishnaBlue),
        filled: true,
        fillColor: AppColors.softWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.krishnaBlue.withAlpha(30)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.krishnaBlue.withAlpha(30)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.krishnaBlue),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}
