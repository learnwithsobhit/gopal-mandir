import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class DonateScreen extends StatefulWidget {
  const DonateScreen({super.key});

  @override
  State<DonateScreen> createState() => _DonateScreenState();
}

class _DonateScreenState extends State<DonateScreen> {
  final ApiService _api = ApiService();
  final _formKey = GlobalKey<FormState>();

  int _selectedAmount = 501;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  String _purpose = 'General Donation';
  bool _submitting = false;

  final List<int> _amounts = [101, 251, 501, 1001, 2101, 5001];
  final List<String> _purposes = [
    'General Donation',
    'Annadan Seva',
    'Temple Renovation',
    'Festival Sponsorship',
    'Gau Seva',
    'Education Fund',
  ];

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
              // Header
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
                          const Text(
                            'सेवा में दान',
                            style: TextStyle(
                              fontFamily: 'PlayfairDisplay',
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Your contribution supports temple seva and community welfare',
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

              // Amount selection
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

              // Purpose dropdown
              const Text(
                'Purpose',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkBrown,
                ),
              ),
              const SizedBox(height: 8),
              DropdownMenu<String>(
                initialSelection: _purpose,
                enabled: !_submitting,
                width: double.infinity,
                textStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 14, color: AppColors.darkBrown),
                inputDecorationTheme: InputDecorationTheme(
                  filled: true,
                  fillColor: AppColors.softWhite,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.krishnaBlue.withAlpha(30)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.krishnaBlue),
                  ),
                ),
                dropdownMenuEntries: _purposes
                    .map(
                      (p) => DropdownMenuEntry<String>(
                        value: p,
                        label: p,
                        trailingIcon: p == _purpose
                            ? const Icon(Icons.check, size: 18, color: AppColors.krishnaBlue)
                            : null,
                        style: ButtonStyle(
                          textStyle: const WidgetStatePropertyAll(TextStyle(fontFamily: 'Poppins')),
                          foregroundColor: const WidgetStatePropertyAll(AppColors.darkBrown),
                          overlayColor: WidgetStateProperty.resolveWith<Color?>(
                            (states) {
                              if (states.contains(WidgetState.selected)) {
                                return AppColors.krishnaBlue.withAlpha(16);
                              }
                              if (states.contains(WidgetState.pressed)) {
                                return AppColors.krishnaBlue.withAlpha(22);
                              }
                              if (states.contains(WidgetState.hovered) || states.contains(WidgetState.focused)) {
                                return AppColors.krishnaBlue.withAlpha(12);
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onSelected: (v) {
                  if (v == null) return;
                  setState(() => _purpose = v);
                },
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

              const SizedBox(height: 32),

              // Donate button
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
    final resp = await _api.submitDonation(
      DonationRequest(
        name: _nameController.text.trim(),
        amount: _selectedAmount.toDouble(),
        purpose: _purpose,
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
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

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Dhanyavaad!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(resp.message),
              if (resp.referenceId.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Reference ID: ${resp.referenceId}',
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
  }

  Widget _buildField(
    String label,
    TextEditingController ctrl,
    IconData icon, {
    TextInputType? keyboard,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      validator: validator,
      enabled: enabled,
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
    super.dispose();
  }
}
