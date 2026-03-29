import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
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
  static const double _bottomButtonHeight = 52;

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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bottomSafe = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Volunteer')),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: SizedBox(
            height: _bottomButtonHeight,
            width: double.infinity,
            child: FilledButton(
              onPressed: _loading ? null : _submit,
              child: const Text('Submit'),
            ),
          ),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: cs.primary))
          : ListView(
              controller: _scrollController,
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg + bottomSafe + _bottomButtonHeight + 28,
              ),
              children: [
                Text(
                  'Join our sevak team',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Share your availability and interests. We will contact you soon.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                if (_error != null) _banner(_error!, isError: true),
                if (_success != null) _banner(_success!, isError: false),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _nameCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Name *'),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Phone *'),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Email (optional)'),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use — value tracks controlled selection
                  value: _selectedArea,
                  decoration: const InputDecoration(labelText: 'Area of interest'),
                  items: _areas.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _selectedArea = v);
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Availability',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: _availabilityChips.entries.map((e) {
                    return FilterChip(
                      label: Text(e.key),
                      selected: e.value,
                      onSelected: (v) => setState(() => _availabilityChips[e.key] = v),
                      selectedColor: cs.primary.withAlpha(48),
                      checkmarkColor: cs.primary,
                      side: BorderSide(color: cs.outline.withAlpha(100)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _availabilityCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Other availability (optional)',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _messageCtrl,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Message (optional)',
                  ),
                ),
              ],
            ),
    );
  }

  Widget _banner(String text, {required bool isError}) {
    final color = isError ? AppColors.urgentRed : Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w500),
      ),
    );
  }
}
