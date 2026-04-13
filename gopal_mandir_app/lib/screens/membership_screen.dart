import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';
import '../l10n/locale_scope.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../models/models.dart';
import '../widgets/app_surface.dart';

class MembershipScreen extends StatefulWidget {
  const MembershipScreen({super.key});

  @override
  State<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends State<MembershipScreen> {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'membership_token';

  final ApiService _api = ApiService();
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  bool _loading = false;
  String? _devOtp;
  String? _token;
  MemberProfile? _member;
  String? _error;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<String?> _readToken() async {
    // First try secure storage (works on mobile). If it throws on web, fall back to SharedPreferences.
    try {
      final token = await _storage.read(key: _tokenKey);
      if (token != null && token.trim().isNotEmpty) return token;
    } catch (_) {
      // ignore and fall back
    }
    if (!kIsWeb) return null;
    try {
      final prefs = await SharedPreferences.getInstance().timeout(const Duration(seconds: 3));
      final token = prefs.getString(_tokenKey);
      if (token != null && token.trim().isNotEmpty) return token;
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeToken(String token) async {
    try {
      await _storage.write(key: _tokenKey, value: token);
      return;
    } catch (_) {
      // ignore and fall back
    }
    if (!kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance().timeout(const Duration(seconds: 3));
      await prefs.setString(_tokenKey, token).timeout(const Duration(seconds: 3));
    } catch (_) {
      // ignore
    }
  }

  Future<void> _deleteToken() async {
    try {
      await _storage.delete(key: _tokenKey);
      return;
    } catch (_) {
      // ignore and fall back
    }
    if (!kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance().timeout(const Duration(seconds: 3));
      await prefs.remove(_tokenKey).timeout(const Duration(seconds: 3));
    } catch (_) {
      // ignore
    }
  }

  Future<void> _restoreSession() async {
    final s = AppLocaleScope.of(context).strings;
    try {
      if (!mounted) return;
      setState(() {
        _loading = true;
        _error = null;
      });

      final token = await _readToken().timeout(const Duration(seconds: 5));
      if (token == null || token.trim().isEmpty) {
        if (!mounted) return;
        setState(() => _loading = false);
        return;
      }

      final me = await _api.getMembershipMe(token).timeout(const Duration(seconds: 8));
      if (!mounted) return;

      if (me != null) {
        setState(() {
          _token = token;
          _member = me;
          _loading = false;
        });
      } else {
        await _deleteToken().timeout(const Duration(seconds: 3));
        setState(() {
          _token = null;
          _member = null;
          _loading = false;
          _error = s.sessionExpiredRequestOtp;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        final msg = e.toString();
        _error = msg.isNotEmpty ? s.membershipLoadError(msg) : s.membershipSessionLoadError;
      });
    }
  }

  Future<void> _sendOtp() async {
    final s = AppLocaleScope.of(context).strings;
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) {
      setState(() => _error = s.pleaseEnterPhone);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _devOtp = null;
    });
    final res = await _api.requestMembershipOtp(phone);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res == null) {
        _error = s.failedToSendOtp;
      } else {
        _devOtp = res;
        _otpCtrl.text = res; // Dev-mode convenience
      }
    });
  }

  Future<void> _verifyOtp() async {
    final s = AppLocaleScope.of(context).strings;
    final phone = _phoneCtrl.text.trim();
    final otp = _otpCtrl.text.trim();
    if (phone.isEmpty || otp.isEmpty) {
      setState(() => _error = s.enterPhoneAndOtp);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await _api.verifyMembershipOtp(
      phone: phone,
      otp: otp,
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
    );
    if (!mounted) return;
    if (res.token == null || res.member == null) {
      setState(() {
        _loading = false;
        _error = res.error ?? s.otpVerificationFailed;
      });
      return;
    }
    final token = res.token!;
    final member = res.member!;
    await _writeToken(token);
    setState(() {
      _token = token;
      _member = member;
      _loading = false;
    });
  }

  Future<void> _logout() async {
    final token = _token;
    if (token == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    await _api.logoutMembership(token);
    await _deleteToken();
    if (!mounted) return;
    setState(() {
      _token = null;
      _member = null;
      _devOtp = null;
      _otpCtrl.clear();
      _nameCtrl.clear();
      _emailCtrl.clear();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocaleScope.of(context).strings;
    final member = _member;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(s.membershipTitle)),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
          : (member != null ? _buildLoggedIn(member) : _buildJoinFlow()),
    );
  }

  Widget _buildLoggedIn(MemberProfile member) {
    final s = AppLocaleScope.of(context).strings;
    return ListView(
      padding: AppSpacing.screenInsets,
      children: [
        if (_error != null) _errorBanner(_error!),
        _profileCard(member),
        const SizedBox(height: AppSpacing.md),
        FilledButton(
          onPressed: _logout,
          child: Text(s.logoutLabel),
        ),
      ],
    );
  }

  Widget _buildJoinFlow() {
    final s = AppLocaleScope.of(context).strings;
    final theme = Theme.of(context);
    return ListView(
      padding: AppSpacing.screenInsets,
      children: [
        if (_error != null) _errorBanner(_error!),
        _sectionTitle(s.membershipJoin),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(labelText: s.phoneNumberLabel),
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton(
          onPressed: _sendOtp,
          child: Text(s.sendOtp),
        ),
        if (_devOtp != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            s.devOtpValue(_devOtp!),
            style: theme.textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _otpCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: s.enterOtp),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _nameCtrl,
          decoration: InputDecoration(labelText: s.nameOptional),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(labelText: s.emailOptionalLabel),
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed: _verifyOtp,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.templeGold,
            foregroundColor: Colors.black87,
          ),
          child: Text(s.verifyJoin),
        ),
      ],
    );
  }

  Widget _errorBanner(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.urgentRed.withAlpha(18),
        borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
        border: Border.all(color: AppColors.urgentRed.withAlpha(50)),
      ),
      child: Text(
        text,
        style: TextStyle(color: AppColors.urgentRed, fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.headlineSmall,
    );
  }

  Widget _profileCard(MemberProfile member) {
    final s = AppLocaleScope.of(context).strings;
    return AppSurface(
      level: AppSurfaceLevel.low,
      padding: AppSpacing.screenInsets,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.yourMembership,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          _kv(s.phoneLabel, member.phone),
          _kv(s.nameLabel, member.name.isEmpty ? '—' : member.name),
          _kv(s.emailLabel, member.email.isEmpty ? '—' : member.email),
          _kv(s.statusLabel, member.status),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              k,
              style: theme.textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

