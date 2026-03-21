import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';

class AdminFeedbackAnalyticsScreen extends StatefulWidget {
  const AdminFeedbackAnalyticsScreen({super.key, required this.token});
  final String token;

  @override
  State<AdminFeedbackAnalyticsScreen> createState() => _AdminFeedbackAnalyticsScreenState();
}

class _AdminFeedbackAnalyticsScreenState extends State<AdminFeedbackAnalyticsScreen> {
  final ApiService _api = ApiService();
  bool _loading = true;
  AdminFeedbackAnalytics? _a;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _api.adminGetFeedbackAnalytics(widget.token);
    if (!mounted) return;
    setState(() {
      _a = data;
      _loading = false;
    });
  }

  Widget _kpi(String label, String value) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = _a;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback Analytics'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : a == null
              ? const Center(child: Text('No analytics available'))
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    Row(
                      children: [
                        _kpi('Total', '${a.total}'),
                        _kpi('New', '${a.newCount}'),
                        _kpi('In Progress', '${a.inProgressCount}'),
                        _kpi('Resolved', '${a.resolvedCount}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: ListTile(
                        title: const Text('Average Rating'),
                        trailing: Text(
                          a.avgRating.toStringAsFixed(2),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Rating Distribution', style: TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            Text('5★: ${a.rating5}'),
                            Text('4★: ${a.rating4}'),
                            Text('3★: ${a.rating3}'),
                            Text('2★: ${a.rating2}'),
                            Text('1★: ${a.rating1}'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Trend', style: TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            ...a.trend.map((t) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Row(
                                    children: [
                                      SizedBox(width: 110, child: Text(t.day)),
                                      Expanded(
                                        child: LinearProgressIndicator(
                                          value: a.total == 0 ? 0 : t.count / a.total,
                                          minHeight: 8,
                                          color: AppColors.krishnaBlue,
                                          backgroundColor: AppColors.krishnaBlue.withAlpha(30),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text('${t.count}'),
                                    ],
                                  ),
                                )),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

