import 'package:flutter/material.dart';

import '../l10n/locale_scope.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';

class AboutTempleScreen extends StatefulWidget {
  const AboutTempleScreen({super.key});

  @override
  State<AboutTempleScreen> createState() => _AboutTempleScreenState();
}

class _AboutTempleScreenState extends State<AboutTempleScreen> {
  final ApiService _api = ApiService();
  TempleInfo? _info;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _api.getTempleInfo();
    if (!mounted) return;
    setState(() {
      _info = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocaleScope.of(context).strings;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(s.aboutTemple),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.krishnaBlue))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.krishnaBlue,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  Text(
                    _info?.name ?? '',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkBrown,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_info?.address ?? ''}, ${_info?.city ?? ''}',
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: AppColors.warmGrey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_info != null && _info!.aboutContent.trim().isNotEmpty)
                    Text(
                      _info!.aboutContent,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.65,
                        color: AppColors.darkBrown,
                      ),
                    )
                  else
                    Text(
                      s.aboutTempleEmpty,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.55,
                        color: AppColors.warmGrey,
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
