import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class VolunteerScreen extends StatefulWidget {
  const VolunteerScreen({super.key});

  @override
  State<VolunteerScreen> createState() => _VolunteerScreenState();
}

class _VolunteerScreenState extends State<VolunteerScreen> {
  final ApiService _api = ApiService();
  final ScrollController _scrollController = ScrollController();
  static const double _bottomButtonHeight = 48;

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _availabilityCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();

  final List<String> _areas = const ['Seva', 'Events', 'Kitchen', 'Cleaning', 'Other'];
  String _selectedArea = 'Seva';

  final Map<String, bool> _availabilityChips = {
    'Weekdays': false,
    'Weekends': false,
    'Morning': false,
    'Evening': false,
  };

  bool _loading = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _scrollController.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _availabilityCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  String _buildAvailability() {
    final selected = _availabilityChips.entries.where((e) => e.value).map((e) => e.key).toList();
    final extra = _availabilityCtrl.text.trim();
    final parts = <String>[];
    if (selected.isNotEmpty) parts.add(selected.join(', '));
    if (extra.isNotEmpty) parts.add(extra);
    return parts.join(' | ');
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      setState(() {
        _error = 'Please enter name and phone number';
        _success = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });

    final req = VolunteerRequest(
      name: name,
      phone: phone,
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      area: _selectedArea,
      availability: _buildAvailability().isEmpty ? null : _buildAvailability(),
      message: _messageCtrl.text.trim().isEmpty ? null : _messageCtrl.text.trim(),
    );

    final result = await _api.submitVolunteerRequest(req);
    if (!mounted) return;

    setState(() {
      _loading = false;
      if (result.success) {
        _success = result.message;
        _error = null;
        _nameCtrl.clear();
        _phoneCtrl.clear();
        _emailCtrl.clear();
        _availabilityCtrl.clear();
        _messageCtrl.clear();
        for (final k in _availabilityChips.keys) {
          _availabilityChips[k] = false;
        }
        _selectedArea = _areas.first;
      } else {
        _error = result.message;
      }
    });

    if (result.success) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Volunteer'),
        backgroundColor: AppColors.krishnaBlue,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: SizedBox(
            height: _bottomButtonHeight,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.krishnaBlue,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Submit'),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.krishnaBlue))
          : ListView(
              controller: _scrollController,
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomSafe + _bottomButtonHeight + 28),
              children: [
                const Text(
                  'Join our sevak team',
                  style: TextStyle(
                    fontFamily: 'PlayfairDisplay',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkBrown,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Share your availability and interests. We will contact you soon.',
                  style: TextStyle(fontFamily: 'Poppins', color: AppColors.warmGrey),
                ),
                const SizedBox(height: 12),
                if (_error != null) _banner(_error!, isError: true),
                if (_success != null) _banner(_success!, isError: false),
                const SizedBox(height: 12),
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Name *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedArea,
                  decoration: const InputDecoration(
                    labelText: 'Area of interest',
                    border: OutlineInputBorder(),
                  ),
                  items: _areas.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _selectedArea = v);
                  },
                ),
                const SizedBox(height: 12),
                const Text(
                  'Availability',
                  style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availabilityChips.entries.map((e) {
                    return FilterChip(
                      label: Text(e.key),
                      selected: e.value,
                      onSelected: (v) => setState(() => _availabilityChips[e.key] = v),
                      selectedColor: AppColors.krishnaBlue.withAlpha(20),
                      checkmarkColor: AppColors.krishnaBlue,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _availabilityCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Other availability (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _messageCtrl,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Message (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _banner(String text, {required bool isError}) {
    final color = isError ? AppColors.urgentRed : AppColors.krishnaBlue;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Text(
        text,
        style: TextStyle(fontFamily: 'Poppins', color: color),
      ),
    );
  }
}

