import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class CommunityNewPostScreen extends StatefulWidget {
  const CommunityNewPostScreen({super.key});

  @override
  State<CommunityNewPostScreen> createState() => _CommunityNewPostScreenState();
}

class _CommunityNewPostScreenState extends State<CommunityNewPostScreen> {
  static const double _bottomButtonHeight = 52;

  final ApiService _api = ApiService();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();

  static const List<_CatOpt> _categories = [
    _CatOpt('general', 'General'),
    _CatOpt('bhajans', 'Bhajans'),
    _CatOpt('scriptures', 'Scriptures'),
    _CatOpt('mantras', 'Mantras'),
    _CatOpt('festivals', 'Festivals'),
    _CatOpt('seva', 'Seva'),
    _CatOpt('other', 'Other'),
  ];
  String _selectedCategory = 'general';

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();
    if (name.isEmpty || phone.isEmpty || title.isEmpty || body.isEmpty) {
      setState(() {
        _error = 'Please fill name, phone, title and question.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _api.submitCommunityPost(
      CommunityPostCreateRequest(
        authorName: name,
        authorPhone: phone,
        category: _selectedCategory,
        title: title,
        body: body,
      ),
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      Navigator.pop(context, true);
    } else {
      setState(() => _error = result.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomSafe = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Ask a question')),
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
              child: const Text('Post question'),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg + bottomSafe + _bottomButtonHeight + 28,
        ),
        children: [
          Text(
            'Share your spiritual question with the community',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Temple team will answer. Keep it respectful and clear.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.urgentRed.withAlpha(18),
                borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
                border: Border.all(color: AppColors.urgentRed.withAlpha(50)),
              ),
              child: Text(
                _error!,
                style: TextStyle(
                  color: AppColors.urgentRed,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Your name *'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Phone *'),
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
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Title *'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _bodyCtrl,
            minLines: 5,
            maxLines: 12,
            decoration: const InputDecoration(
              labelText: 'Your question *',
            ),
          ),
        ],
      ),
    );
  }
}

class _CatOpt {
  final String id;
  final String label;
  const _CatOpt(this.id, this.label);
}
