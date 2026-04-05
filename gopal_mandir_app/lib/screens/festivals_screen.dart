import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import 'festival_detail_screen.dart';

class FestivalsScreen extends StatefulWidget {
  const FestivalsScreen({super.key});

  @override
  State<FestivalsScreen> createState() => _FestivalsScreenState();
}

class _FestivalsScreenState extends State<FestivalsScreen> {
  final ApiService _api = ApiService();
  bool _loading = true;
  List<FestivalMonthBucket> _months = [];
  List<FestivalEntry> _items = [];
  FestivalMonthBucket? _selectedMonth;

  @override
  void initState() {
    super.initState();
    _loadMonths();
  }

  Future<void> _loadMonths() async {
    setState(() => _loading = true);
    final boot = await _api.getFestivalsBootstrap();

    late List<FestivalMonthBucket> months;
    late FestivalMonthBucket selected;
    late List<FestivalEntry> items;

    if (boot != null && boot.months.isNotEmpty) {
      months = boot.months;
      selected = _selectedMonth == null
          ? months.first
          : months.firstWhere(
              (m) => m.year == _selectedMonth!.year && m.month == _selectedMonth!.month,
              orElse: () => months.first,
            );
      final isFirstMonth =
          selected.year == months.first.year && selected.month == months.first.month;
      items = isFirstMonth ? boot.festivals : await _api.getFestivalsForMonth(year: selected.year, month: selected.month);
    } else {
      months = await _api.getFestivalMonths();
      if (!mounted) return;
      if (months.isEmpty) {
        setState(() {
          _months = [];
          _items = [];
          _selectedMonth = null;
          _loading = false;
        });
        return;
      }
      selected = _selectedMonth == null
          ? months.first
          : months.firstWhere(
              (m) => m.year == _selectedMonth!.year && m.month == _selectedMonth!.month,
              orElse: () => months.first,
            );
      items = await _api.getFestivalsForMonth(year: selected.year, month: selected.month);
    }

    if (!mounted) return;
    setState(() {
      _months = months;
      _selectedMonth = selected;
      _items = items;
      _loading = false;
    });
  }

  Future<void> _selectMonth(FestivalMonthBucket bucket) async {
    setState(() {
      _selectedMonth = bucket;
      _loading = true;
    });
    final items = await _api.getFestivalsForMonth(year: bucket.year, month: bucket.month);
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Festivals & Events')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 8),
                SizedBox(
                  height: 46,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: _months.map((m) {
                      final selected = _selectedMonth?.year == m.year && _selectedMonth?.month == m.month;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text('${m.monthLabel} (${m.itemCount})'),
                          selected: selected,
                          onSelected: (_) => _selectMonth(m),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: _items.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('No festivals/events in this month'),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _items.length,
                          itemBuilder: (context, i) {
                            final item = _items[i];
                            return Card(
                              color: AppColors.sandalCream.withAlpha(230),
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) => FestivalDetailScreen(festivalId: item.id),
                                  ),
                                ),
                                title: Text(
                                  item.title,
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.krishnaBlue,
                                  ),
                                ),
                                subtitle: Text(
                                  item.forDate,
                                  style: GoogleFonts.poppins(fontSize: 12, color: AppColors.warmGrey),
                                ),
                                trailing: const Icon(Icons.chevron_right),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
