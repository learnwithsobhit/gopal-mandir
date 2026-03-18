import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../models/models.dart';

class MembershipScreen extends StatefulWidget {
  const MembershipScreen({super.key});

  @override
  State<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends State<MembershipScreen> {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'membership_token';
  static const _defaultError = 'Could not load membership session. Please try again.';

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
          _error = 'Session expired. Please request OTP again.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        final msg = e.toString();
        _error = msg.isNotEmpty ? 'Could not load membership session: $msg' : _defaultError;
      });
    }
  }

  Future<void> _sendOtp() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) {
      setState(() => _error = 'Please enter phone number');
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
        _error = 'Failed to send OTP';
      } else {
        _devOtp = res;
        _otpCtrl.text = res; // Dev-mode convenience
      }
    });
  }

  Future<void> _verifyOtp() async {
    final phone = _phoneCtrl.text.trim();
    final otp = _otpCtrl.text.trim();
    if (phone.isEmpty || otp.isEmpty) {
      setState(() => _error = 'Please enter phone and OTP');
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
        _error = res.error ?? 'OTP verification failed';
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
    final member = _member;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Membership'),
        backgroundColor: AppColors.krishnaBlue,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.krishnaBlue))
          : (member != null ? _buildLoggedIn(member) : _buildJoinFlow()),
    );
  }

  Widget _buildLoggedIn(MemberProfile member) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_error != null) _errorBanner(_error!),
        _profileCard(member),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _logout,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.krishnaBlue,
              foregroundColor: Colors.white,
              textStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Logout'),
          ),
        ),
      ],
    );
  }

  Widget _buildJoinFlow() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_error != null) _errorBanner(_error!),
        _sectionTitle('Join as a member'),
        const SizedBox(height: 8),
        TextField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Phone number',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _sendOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.krishnaBlue,
              foregroundColor: Colors.white,
              textStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Send OTP'),
          ),
        ),
        if (_devOtp != null) ...[
          const SizedBox(height: 8),
          Text(
            'Dev OTP: $_devOtp',
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.warmGrey),
          ),
        ],
        const SizedBox(height: 14),
        TextField(
          controller: _otpCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Enter OTP',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _nameCtrl,
          decoration: const InputDecoration(
            labelText: 'Name (optional)',
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
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _verifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.templeGold,
              foregroundColor: Colors.black87,
              textStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Verify & Join'),
          ),
        ),
      ],
    );
  }

  Widget _errorBanner(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.urgentRed.withAlpha(18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.urgentRed.withAlpha(50)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontFamily: 'Poppins', color: AppColors.urgentRed),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'PlayfairDisplay',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.darkBrown,
      ),
    );
  }

  Widget _profileCard(MemberProfile member) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your membership',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 10),
          _kv('Phone', member.phone),
          _kv('Name', member.name.isEmpty ? '—' : member.name),
          _kv('Email', member.email.isEmpty ? '—' : member.email),
          _kv('Status', member.status),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              k,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.warmGrey),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

