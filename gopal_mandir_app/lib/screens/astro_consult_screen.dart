import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class AstroConsultScreen extends StatefulWidget {
  const AstroConsultScreen({super.key});

  @override
  State<AstroConsultScreen> createState() => _AstroConsultScreenState();
}

class _AstroConsultScreenState extends State<AstroConsultScreen> {
  static const double _bottomButtonHeight = 52;

  final ApiService _api = ApiService();
  final ScrollController _scrollController = ScrollController();

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _questionCtrl = TextEditingController();
  final _birthPlaceCtrl = TextEditingController();

  DateTime? _dob;
  TimeOfDay? _dobTime;

  // Keep values in sync with ASTRO_ALLOWED_CATEGORIES in the backend.
  static const List<_Category> _categories = [
    _Category('astrology', 'Astrology'),
    _Category('palmistry', 'Palmistry'),
    _Category('grahdosh', 'Grah Dosh'),
    _Category('kundali_matching', 'Kundali Matching'),
    _Category('muhurat', 'Shubh Muhurat'),
    _Category('other', 'Other'),
  ];
  String _selectedCategory = 'astrology';

  bool _loading = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _scrollController.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _subjectCtrl.dispose();
    _questionCtrl.dispose();
    _birthPlaceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final result = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (result != null) setState(() => _dob = result);
  }

  Future<void> _pickTime() async {
    final result = await showTimePicker(
      context: context,
      initialTime: _dobTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (result != null) setState(() => _dobTime = result);
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  String? _formatDob() {
    final d = _dob;
    if (d == null) return null;
    return '${d.year}-${_twoDigits(d.month)}-${_twoDigits(d.day)}';
  }

  String? _formatTime() {
    final t = _dobTime;
    if (t == null) return null;
    return '${_twoDigits(t.hour)}:${_twoDigits(t.minute)}:00';
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final question = _questionCtrl.text.trim();
    if (name.isEmpty || phone.isEmpty || question.isEmpty) {
      setState(() {
        _error = 'Please enter name, phone number and your question';
        _success = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });

    final req = AstroConsultSubmitRequest(
      name: name,
      phone: phone,
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      category: _selectedCategory,
      subject: _subjectCtrl.text.trim().isEmpty ? null : _subjectCtrl.text.trim(),
      question: question,
      dobDate: _formatDob(),
      dobTime: _formatTime(),
      birthPlace:
          _birthPlaceCtrl.text.trim().isEmpty ? null : _birthPlaceCtrl.text.trim(),
    );

    final result = await _api.submitAstroConsult(req);
    if (!mounted) return;

    setState(() {
      _loading = false;
      if (result.success) {
        _success = result.message;
        _error = null;
        _nameCtrl.clear();
        _phoneCtrl.clear();
        _emailCtrl.clear();
        _subjectCtrl.clear();
        _questionCtrl.clear();
        _birthPlaceCtrl.clear();
        _dob = null;
        _dobTime = null;
        _selectedCategory = 'astrology';
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
      appBar: AppBar(title: const Text('Ask an Astrologer')),
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
              child: const Text('Submit Question'),
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
                  'Astrology, Muhurat & Spiritual guidance',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Share your question along with contact details. Our team will reach out on your phone to guide you.',
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
                  // ignore: deprecated_member_use
                  value: _selectedCategory,
                  decoration: const InputDecoration(labelText: 'Topic'),
                  items: _categories
                      .map((c) => DropdownMenuItem(value: c.id, child: Text(c.label)))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _selectedCategory = v);
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _subjectCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Subject (optional)',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _questionCtrl,
                  minLines: 4,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: 'Your question *',
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Birth details (optional, helps with kundali / muhurat)',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(_formatDob() ?? 'DOB date'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickTime,
                        icon: const Icon(Icons.access_time, size: 18),
                        label: Text(
                          _dobTime == null
                              ? 'DOB time'
                              : '${_twoDigits(_dobTime!.hour)}:${_twoDigits(_dobTime!.minute)}',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _birthPlaceCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Birth place (optional)',
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

class _Category {
  final String id;
  final String label;
  const _Category(this.id, this.label);
}
