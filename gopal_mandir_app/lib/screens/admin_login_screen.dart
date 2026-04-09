import 'package:flutter/material.dart';
import '../data/country_dial_codes.dart';
import '../services/api_service.dart';
import '../services/admin_auth_service.dart';
import '../theme/app_colors.dart';
import '../utils/e164_phone.dart';
import '../widgets/admin_phone_country_row.dart';
import 'admin_shell.dart';

/// Phone OTP login for temple staff (admin CRM). Separate from membership.
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final ApiService _api = ApiService();
  /// National mobile digits only (country code from [_selectedCountry]).
  final _phoneCtrl = TextEditingController();
  CountryDialCode _selectedCountry = CountryDialCodes.defaultCountry;
  final _otpCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _secretCodeCtrl = TextEditingController();

  bool _loading = false;
  String? _devOtp;
  String? _error;
  bool _secretMode = true;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _nameCtrl.dispose();
    _secretCodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    final composed = tryComposeE164(
      dialDigits: _selectedCountry.dialDigits,
      nationalRaw: _phoneCtrl.text,
    );
    if (composed.error != null) {
      setState(() => _error = composed.error);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _devOtp = null;
    });
    final r = await _api.requestAdminOtp(composed.e164!);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (r.otp != null && r.otp!.isNotEmpty) {
        _devOtp = r.otp;
      } else {
        if (r.retryAfterSec != null && r.retryAfterSec! > 0) {
          final mins = r.retryAfterSec! ~/ 60;
          final secs = r.retryAfterSec! % 60;
          final waitText = mins > 0 ? '${mins}m ${secs}s' : '${secs}s';
          final attemptsText =
              (r.attemptsUsed != null && r.attemptsLimit != null)
                  ? ' (${r.attemptsUsed}/${r.attemptsLimit} attempts used)'
                  : '';
          _error =
              '${r.error ?? 'Too many OTP requests.'} Try again in $waitText.$attemptsText';
        } else {
          _error =
              r.error ??
              'Could not send OTP. This number may not be registered as admin.';
        }
      }
    });
  }

  Future<void> _verify() async {
    final composed = tryComposeE164(
      dialDigits: _selectedCountry.dialDigits,
      nationalRaw: _phoneCtrl.text,
    );
    if (composed.error != null) {
      setState(() => _error = composed.error);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final r = await _api.verifyAdminOtp(
      phone: composed.e164!,
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

  Future<void> _loginWithSecret() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final r = await _api.adminLoginWithSecret(
      code: _secretCodeCtrl.text.trim(),
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
      _error = r.error ?? 'Invalid secret code';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softWhite,
      appBar: AppBar(
        title: const Text('Temple staff login'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment<bool>(value: true, label: Text('Secret code')),
                ButtonSegment<bool>(value: false, label: Text('Phone OTP')),
              ],
              selected: {_secretMode},
              onSelectionChanged: _loading
                  ? null
                  : (set) {
                      setState(() {
                        _secretMode = set.first;
                        _error = null;
                        _devOtp = null;
                      });
                    },
            ),
            const SizedBox(height: 20),
            Text(
              _secretMode
                  ? 'Owner-generated secret code login. Code is single-use and expires.'
                  : 'Admin access is restricted to registered temple phones. OTP is sent only for authorized numbers.',
              style: const TextStyle(fontFamily: 'Poppins', color: AppColors.warmGrey, fontSize: 13),
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
            if (_secretMode) ...[
              TextField(
                controller: _secretCodeCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Secret code',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _loading ? null : _loginWithSecret,
                style: FilledButton.styleFrom(backgroundColor: AppColors.peacockGreen),
                child: _loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Login with secret code'),
              ),
            ] else ...[
              AdminPhoneCountryRow(
                selected: _selectedCountry,
                onCountryChanged: (c) => setState(() => _selectedCountry = c),
                nationalController: _phoneCtrl,
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
            ],
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
