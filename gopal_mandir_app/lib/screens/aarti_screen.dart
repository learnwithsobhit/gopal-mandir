import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class AartiScreen extends StatefulWidget {
  const AartiScreen({super.key});

  @override
  State<AartiScreen> createState() => _AartiScreenState();
}

class _AartiScreenState extends State<AartiScreen> {
  final ApiService _api = ApiService();
  List<AartiSchedule> _aartis = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _api.getAartiSchedule();
    if (mounted) setState(() { _aartis = data; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sandalCream,
      appBar: AppBar(
        title: const Text('आरती समय'),
        backgroundColor: AppColors.krishnaBlue,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.krishnaBlue))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _aartis.length,
              itemBuilder: (context, index) {
                final aarti = _aartis[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.softWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: aarti.isSpecial
                        ? Border.all(color: AppColors.templeGold, width: 1.5)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.krishnaBlue.withAlpha(10),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: aarti.isSpecial
                              ? [AppColors.templeGold, AppColors.templeGoldLight]
                              : [AppColors.krishnaBlue, AppColors.krishnaBlueLight],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            aarti.isSpecial ? Icons.local_fire_department : Icons.access_time,
                            color: Colors.white,
                            size: 20,
                          ),
                          Text(
                            aarti.time.split(' ')[0],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(
                          aarti.name,
                          style: const TextStyle(
                            fontFamily: 'PlayfairDisplay',
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        if (aarti.isSpecial) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.templeGold.withAlpha(30),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'विशेष',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.templeGoldDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          aarti.time,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: AppColors.krishnaBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          aarti.description,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: AppColors.warmGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
