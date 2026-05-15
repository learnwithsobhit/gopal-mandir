import 'package:flutter/material.dart';

import '../l10n/locale_scope.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/skeleton.dart';
import 'learn_topic_detail_screen.dart';

class LearnHubScreen extends StatefulWidget {
  const LearnHubScreen({super.key});

  @override
  State<LearnHubScreen> createState() => _LearnHubScreenState();
}

class _LearnHubScreenState extends State<LearnHubScreen> {
  final ApiService _api = ApiService();
  List<LearnTopic> _topics = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _api.getLearnTopics();
    if (!mounted) return;
    setState(() {
      _topics = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocaleScope.of(context).strings;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(s.learnHubTitle),
        backgroundColor: AppColors.krishnaBlue,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: 5,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, __) => const SkeletonCard(height: 120, radius: 16),
            )
          : RefreshIndicator(
              color: AppColors.krishnaBlue,
              onRefresh: _load,
              child: _topics.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        const SizedBox(height: 48),
                        Icon(Icons.school_outlined,
                            size: 56, color: AppColors.warmGrey.withAlpha(180)),
                        const SizedBox(height: 16),
                        Text(
                          s.learnEmpty,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.warmGrey,
                            height: 1.4,
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _topics.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => _TopicCard(
                        topic: _topics[i],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => LearnTopicDetailScreen(
                                topic: _topics[i],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({required this.topic, required this.onTap});

  final LearnTopic topic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = AppLocaleScope.of(context).strings;
    final delivery = s.learnDeliveryLabel(topic.deliveryMode);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      topic.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.darkBrown,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(
                      delivery,
                      style: const TextStyle(fontSize: 11, color: Colors.white),
                    ),
                    backgroundColor: AppColors.krishnaBlue,
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
              if (topic.categoryKey.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  topic.categoryKey,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.templeGoldDark,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                '${s.learnTeacher}: ${topic.teacherName}',
                style: TextStyle(fontSize: 13, color: AppColors.warmGrey),
              ),
              if (topic.scheduleSummary.isNotEmpty)
                Text(
                  '${s.learnSchedule}: ${topic.scheduleSummary}',
                  style: TextStyle(fontSize: 13, color: AppColors.warmGrey),
                ),
              if (topic.durationSummary.isNotEmpty)
                Text(
                  '${s.learnDuration}: ${topic.durationSummary}',
                  style: TextStyle(fontSize: 13, color: AppColors.warmGrey),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
