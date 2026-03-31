import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';

class DailyUpasanaScreen extends StatefulWidget {
  const DailyUpasanaScreen({super.key});

  @override
  State<DailyUpasanaScreen> createState() => _DailyUpasanaScreenState();
}

class _DailyUpasanaScreenState extends State<DailyUpasanaScreen> {
  final ApiService _api = ApiService();
  DateTime _selectedDate = DateTime.now();
  List<DailyUpasanaItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _api.getDailyUpasanaForDate(_selectedDate);
    if (!mounted) return;
    setState(() {
      _items = data;
      _loading = false;
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
    );
    if (picked == null) return;
    setState(() => _selectedDate = picked);
    _load();
  }

  String get _dateLabel {
    final y = _selectedDate.year.toString().padLeft(4, '0');
    final m = _selectedDate.month.toString().padLeft(2, '0');
    final d = _selectedDate.day.toString().padLeft(2, '0');
    return '$d-$m-$y';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Daily Upasana'),
        actions: [
          IconButton(icon: const Icon(Icons.calendar_month), onPressed: _pickDate),
        ],
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
                            'No upasana items found for $_dateLabel',
                            style: const TextStyle(color: AppColors.warmGrey),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _items.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              'Date: $_dateLabel',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.krishnaBlue,
                              ),
                            ),
                          );
                        }
                        final item = _items[index - 1];
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
                                    height: 1.5,
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

