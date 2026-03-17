import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/models.dart';
import '../widgets/vrindavan_background.dart';
import '../services/api_service.dart';

enum PrasadFulfillment { pickup, delivery }

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
  bool _submitting = false;

  double get _total => widget.item.price * _qty;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final form = _formKey.currentState;
    if (form == null) return;
    if (!form.validate()) return;
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
          title: const Text('Booking Confirmed'),
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
        appBar: AppBar(
          title: const Text('Book Prasad'),
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
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.softWhite,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.krishnaBlue.withAlpha(10),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.item.name,
                              style: const TextStyle(
                                fontFamily: 'PlayfairDisplay',
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.item.description,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: AppColors.warmGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '₹${widget.item.price.toInt()}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.peacockGreen,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.softWhite,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.krishnaBlue.withAlpha(8),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quantity',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
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
                            style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
                          ),
                        ),
                        IconButton(
                          onPressed: _submitting ? null : () => setState(() => _qty += 1),
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                        const Spacer(),
                        Text(
                          'Total: ₹${_total.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkBrown,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Fulfillment',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
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
                      onSelectionChanged: _submitting ? null : (value) => setState(() => _fulfillment = value.first),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

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
              const SizedBox(height: 12),
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
              const SizedBox(height: 12),
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
                const SizedBox(height: 12),
              ],
              _field(
                label: 'Notes (optional)',
                icon: Icons.sticky_note_2_outlined,
                controller: _notesController,
                minLines: 2,
                maxLines: 3,
              ),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _confirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.peacockGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : Text(
                          'Confirm Booking • ₹${_total.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
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
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      minLines: minLines,
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
}

