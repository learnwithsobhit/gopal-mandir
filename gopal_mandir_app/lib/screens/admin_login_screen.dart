import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/admin_auth_service.dart';
import '../theme/app_colors.dart';
import 'admin_shell.dart';

/// Phone OTP login for temple staff (admin CRM). Separate from membership.
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final ApiService _api = ApiService();
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  bool _loading = false;
  String? _devOtp;
  String? _error;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    setState(() {
      _loading = true;
      _error = null;
      _devOtp = null;
    });
    final otp = await _api.requestAdminOtp(_phoneCtrl.text.trim());
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (otp != null && otp.isNotEmpty) {
        _devOtp = otp;
      } else {
        _error = 'Could not send OTP. This number may not be registered as admin.';
      }
    });
  }

  Future<void> _verify() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final r = await _api.verifyAdminOtp(
      phone: _phoneCtrl.text.trim(),
      otp: _otpCtrl.text.trim(),
      name: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
    );
    if (!mounted) return;
    if (r.token != null && r.token!.isNotEmpty) {
      await AdminAuthService.writeToken(r.token!);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const AdminShell()),
      );
      return;
    }
    setState(() {
      _loading = false;
      _error = r.error ?? 'Invalid OTP';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softWhite,
      appBar: AppBar(
        title: const Text('Temple staff login'),
        backgroundColor: AppColors.krishnaBlue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Admin access is restricted to registered temple phones. OTP is sent only for authorized numbers.',
              style: TextStyle(fontFamily: 'Poppins', color: AppColors.warmGrey, fontSize: 13),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Display name (optional, first login)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loading ? null : _requestOtp,
              style: FilledButton.styleFrom(backgroundColor: AppColors.krishnaBlue),
              child: _loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Request OTP'),
            ),
            if (_devOtp != null) ...[
              const SizedBox(height: 12),
              SelectableText(
                'Dev OTP: $_devOtp',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkBrown),
              ),
            ],
            const SizedBox(height: 20),
            TextField(
              controller: _otpCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'OTP',
                border: OutlineInputBorder(),
              ),
            ),
            FilledButton(
              onPressed: _loading ? null : _verify,
              style: FilledButton.styleFrom(backgroundColor: AppColors.peacockGreen),
              child: const Text('Verify & sign in'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: AppColors.urgentRed, fontSize: 13)),
            ],
          ],
        ),
      ),
    );
  }
}
