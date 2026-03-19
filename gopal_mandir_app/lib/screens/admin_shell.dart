import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/admin_auth_service.dart';
import '../theme/app_colors.dart';
import '../models/models.dart';
import 'admin_login_screen.dart';
import 'admin_gallery_list_screen.dart';
import 'admin_live_darshan_screen.dart';
import 'admin_prasad_orders_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  final ApiService _api = ApiService();
  String? _token;
  AdminProfile? _admin;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final t = await AdminAuthService.readToken();
    if (t == null || t.isEmpty) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _token = null;
      });
      return;
    }
    final meResult = await _api.adminMeResult(t);
    if (!mounted) return;
    final me = meResult.admin;
    final statusCode = meResult.statusCode;
    final isUnauthorized = statusCode == 401 || statusCode == 403;
    if (me == null && isUnauthorized) {
      await AdminAuthService.deleteToken();
      setState(() {
        _loading = false;
        _token = null;
      });
      return;
    }
    setState(() {
      _token = t;
      _admin = me;
      _loading = false;
    });
  }

  Future<void> _logout() async {
    final t = _token;
    if (t != null) await _api.adminLogout(t);
    await AdminAuthService.deleteToken();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const AdminLoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.krishnaBlue)),
      );
    }
    if (_token == null) {
      return const AdminLoginScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_admin?.name.trim().isNotEmpty == true ? _admin!.name : 'Admin'),
        backgroundColor: AppColors.krishnaBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tile(
            Icons.photo_library,
            'Gallery',
            'Upload & manage images and videos',
            () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => AdminGalleryListScreen(token: _token!),
              ),
            ),
          ),
          _tile(
            Icons.live_tv,
            'Live Darshan',
            'Stream URL and on-air flag',
            () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => AdminLiveDarshanScreen(token: _token!),
              ),
            ),
          ),
          _tile(
            Icons.restaurant_menu,
            'Prasad orders',
            'Filter and update order status',
            () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => AdminPrasadOrdersScreen(token: _token!),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String title, String sub, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.krishnaBlue.withAlpha(24),
          child: Icon(icon, color: AppColors.krishnaBlue),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(sub, style: TextStyle(fontSize: 12, color: AppColors.warmGrey)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
