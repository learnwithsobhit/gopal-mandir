import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';

class RateUsScreen extends StatefulWidget {
  const RateUsScreen({super.key});

  @override
  State<RateUsScreen> createState() => _RateUsScreenState();
}

class _RateUsScreenState extends State<RateUsScreen> {
  final ApiService _api = ApiService();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  int _rating = 5;
  bool _submitting = false;

  static const _storeUrl = 'https://gopal-mandir-app.web.app';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final msg = _messageCtrl.text.trim();
    if (msg.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please share your feedback message.')),
      );
      return;
    }
    setState(() => _submitting = true);
    final res = await _api.submitFeedback(
      FeedbackRequestModel(
        name: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        rating: _rating,
        message: msg,
        source: 'web',
      ),
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (!res.success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thank you!'),
        content: Text('Feedback submitted successfully.\nReference: ${res.referenceId}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
    _messageCtrl.clear();
  }

  Future<void> _openStore() async {
    final uri = Uri.parse(_storeUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rate Us')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('How was your experience?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Row(
            children: List.generate(5, (i) {
              final star = i + 1;
              return IconButton(
                onPressed: () => setState(() => _rating = star),
                icon: Icon(
                  _rating >= star ? Icons.star : Icons.star_border,
                  color: AppColors.templeGoldDark,
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Name (optional)'),
          ),
          TextField(
            controller: _emailCtrl,
            decoration: const InputDecoration(labelText: 'Email (optional)'),
            keyboardType: TextInputType.emailAddress,
          ),
          TextField(
            controller: _phoneCtrl,
            decoration: const InputDecoration(labelText: 'Phone (optional)'),
            keyboardType: TextInputType.phone,
          ),
          TextField(
            controller: _messageCtrl,
            decoration: const InputDecoration(labelText: 'Your feedback'),
            maxLines: 5,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Submit Feedback'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _openStore,
            icon: const Icon(Icons.open_in_new),
            label: const Text('Rate on Store'),
          ),
        ],
      ),
    );
  }
}

