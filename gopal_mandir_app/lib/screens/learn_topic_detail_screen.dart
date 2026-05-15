import 'package:flutter/material.dart';

import '../l10n/app_language.dart';
import '../l10n/locale_scope.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/skeleton.dart';
import 'learn_register_screen.dart';

class LearnTopicDetailScreen extends StatefulWidget {
  const LearnTopicDetailScreen({
    super.key,
    this.topic,
    this.topicId,
  }) : assert(topic != null || topicId != null);

  /// When opening from the hub, pass the cached row to avoid an extra round-trip.
  final LearnTopic? topic;

  /// When opening by id only (e.g. deep link later), pass [topicId] and leave [topic] null.
  final int? topicId;

  @override
  State<LearnTopicDetailScreen> createState() => _LearnTopicDetailScreenState();
}

class _LearnTopicDetailScreenState extends State<LearnTopicDetailScreen> {
  final ApiService _api = ApiService();
  LearnTopic? _topic;
  bool _loading = false;
  String? _error;

  int get _resolvedId => widget.topic?.id ?? widget.topicId!;

  @override
  void initState() {
    super.initState();
    _topic = widget.topic;
    if (_topic == null) {
      _loading = true;
      _fetch();
    }
  }

  Future<void> _fetch() async {
    final t = await _api.getLearnTopic(_resolvedId);
    if (!mounted) return;
    setState(() {
      _topic = t;
      _loading = false;
      _error = t == null ? 'Not found' : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocaleScope.of(context).strings;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(_topic?.title ?? s.learnHubTitle),
        backgroundColor: AppColors.krishnaBlue,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: SkeletonCard(height: 280, radius: 16),
            )
          : _error != null || _topic == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _error ?? s.learnEmpty,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () {
                            setState(() {
                              _loading = true;
                              _error = null;
                            });
                            _fetch();
                          },
                          child: Text(s.retryLabel),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildBody(context, s, _topic!),
    );
  }

  Widget _buildBody(BuildContext context, AppStrings s, LearnTopic t) {
    final delivery = s.learnDeliveryLabel(t.deliveryMode);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  t.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkBrown,
                  ),
                ),
              ),
              Chip(
                label: Text(
                  delivery,
                  style: const TextStyle(fontSize: 11, color: Colors.white),
                ),
                backgroundColor: AppColors.peacockGreen,
              ),
            ],
          ),
          if (t.categoryKey.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              t.categoryKey,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.templeGoldDark,
              ),
            ),
          ],
          const SizedBox(height: 16),
          _detailRow(Icons.person_outline, '${s.learnTeacher}: ${t.teacherName}'),
          if (t.scheduleSummary.isNotEmpty)
            _detailRow(Icons.schedule, '${s.learnSchedule}: ${t.scheduleSummary}'),
          if (t.durationSummary.isNotEmpty)
            _detailRow(Icons.timelapse_outlined, '${s.learnDuration}: ${t.durationSummary}'),
          if (t.locationNote != null && t.locationNote!.trim().isNotEmpty)
            _detailRow(Icons.place_outlined, '${s.learnLocation}: ${t.locationNote}'),
          if (t.maxParticipants != null)
            _detailRow(
              Icons.groups_outlined,
              '${s.learnCapacity}: ${t.maxParticipants}',
            ),
          const SizedBox(height: 20),
          Text(
            t.description,
            style: const TextStyle(
              fontSize: 15,
              height: 1.55,
              color: AppColors.darkBrown,
            ),
          ),
          const SizedBox(height: 28),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.krishnaBlue,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => LearnRegisterScreen(
                    topicId: t.id,
                    topicTitle: t.title,
                  ),
                ),
              );
            },
            child: Text(s.learnRegister),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.krishnaBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: AppColors.warmGrey),
            ),
          ),
        ],
      ),
    );
  }
}
