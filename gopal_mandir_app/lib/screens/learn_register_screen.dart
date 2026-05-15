import 'package:flutter/material.dart';

import '../l10n/locale_scope.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class LearnRegisterScreen extends StatefulWidget {
  const LearnRegisterScreen({
    super.key,
    required this.topicId,
    required this.topicTitle,
  });

  final int topicId;
  final String topicTitle;

  @override
  State<LearnRegisterScreen> createState() => _LearnRegisterScreenState();
}

class _LearnRegisterScreenState extends State<LearnRegisterScreen> {
  final ApiService _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final s = AppLocaleScope.of(context).strings;
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.learnNamePhoneRequired)),
      );
      return;
    }

    setState(() => _loading = true);
    final payload = LearnRegistrationPayload(
      topicId: widget.topicId,
      name: name,
      phone: phone,
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );
    final result = await _api.submitLearnRegistration(payload);
    if (!mounted) return;
    setState(() => _loading = false);

    final messenger = ScaffoldMessenger.of(context);
    if (result.success) {
      messenger.showSnackBar(SnackBar(content: Text(result.message)));
      Navigator.pop(context);
      return;
    }
    messenger.showSnackBar(SnackBar(content: Text(result.message)));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocaleScope.of(context).strings;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(s.learnRegisterTitle),
        backgroundColor: AppColors.krishnaBlue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.topicTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkBrown,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: s.learnFormName,
                  border: const OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneCtrl,
                decoration: InputDecoration(
                  labelText: s.learnFormPhone,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                decoration: InputDecoration(
                  labelText: s.learnFormEmailOptional,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesCtrl,
                decoration: InputDecoration(
                  labelText: s.learnFormNotesOptional,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 24),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.krishnaBlue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(s.learnSubmit),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
