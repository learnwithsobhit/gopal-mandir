import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class DonateScreen extends StatefulWidget {
  const DonateScreen({super.key});

  @override
  State<DonateScreen> createState() => _DonateScreenState();
}

class _DonateScreenState extends State<DonateScreen> {
  int _selectedAmount = 501;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _purpose = 'General Donation';

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
                  Icon(Icons.favorite, color: Colors.white, size: 40),
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
                  onTap: () => setState(() => _selectedAmount = amount),
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
              style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.darkBrown),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.softWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.krishnaBlue.withAlpha(30)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _purpose,
                  isExpanded: true,
                  items: _purposes.map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontFamily: 'Poppins')))).toList(),
                  onChanged: (v) => setState(() => _purpose = v!),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Name field
            _buildField('Your Name', _nameController, Icons.person),
            const SizedBox(height: 16),
            _buildField('Phone Number', _phoneController, Icons.phone, keyboard: TextInputType.phone),

            const SizedBox(height: 32),

            // Donate button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('🙏 धन्यवाद! ₹$_selectedAmount donation recorded. Jai Gopal!'),
                      backgroundColor: AppColors.peacockGreen,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.templeGold,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
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
                '🔒 Secure & Trusted',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.warmGrey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, IconData icon, {TextInputType? keyboard}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
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
}
