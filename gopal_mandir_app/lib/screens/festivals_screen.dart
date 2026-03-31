import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';

class FestivalsScreen extends StatefulWidget {
  const FestivalsScreen({super.key});

  @override
  State<FestivalsScreen> createState() => _FestivalsScreenState();
}

class _FestivalsScreenState extends State<FestivalsScreen> {
  final ApiService _api = ApiService();
  DateTime _selectedDate = DateTime.now();
  late Future<List<FestivalEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.getFestivalsForDate(_selectedDate);
  }

  String get _dateLabel {
    final y = _selectedDate.year.toString().padLeft(4, '0');
    final m = _selectedDate.month.toString().padLeft(2, '0');
    final d = _selectedDate.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      _selectedDate = picked;
      _future = _api.getFestivalsForDate(_selectedDate);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Festivals & Events')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Date-wise festivals',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkBrown,
                  ),
                ),
                TextButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_month, size: 18),
                  label: Text(
                    _dateLabel,
                    style: GoogleFonts.poppins(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<List<FestivalEntry>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Could not load festivals'));
                }
                final list = snapshot.data ?? const [];
                if (list.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No festivals/events found for this date'),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final item = list[i];
                    return Card(
                      color: AppColors.sandalCream.withAlpha(230),
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.krishnaBlue,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item.description,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppColors.darkBrown,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
