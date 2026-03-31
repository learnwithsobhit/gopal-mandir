import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../l10n/locale_scope.dart';

class DailyUpasanaScreen extends StatefulWidget {
  const DailyUpasanaScreen({super.key});

  @override
  State<DailyUpasanaScreen> createState() => _DailyUpasanaScreenState();
}

class _DailyUpasanaScreenState extends State<DailyUpasanaScreen> {
  final ApiService _api = ApiService();
  List<DailyUpasanaItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _api.getDailyUpasana();
    if (!mounted) return;
    setState(() {
      _items = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocaleScope.of(context).strings;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(s.dailyUpasanaTitle),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.krishnaBlue))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.krishnaBlue,
              child: _items.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 120),
                        Center(
                          child: Text(
                            s.dailyUpasanaEmpty,
                            style: const TextStyle(color: AppColors.warmGrey),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (item.category.trim().isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    item.category,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.templeGoldDark,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 10),
                                Text(
                                  item.content,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

