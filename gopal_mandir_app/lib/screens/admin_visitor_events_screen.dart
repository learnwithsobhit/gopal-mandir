import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/locale_scope.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';

class AdminVisitorEventsScreen extends StatefulWidget {
  const AdminVisitorEventsScreen({super.key, required this.token});

  final String token;

  @override
  State<AdminVisitorEventsScreen> createState() => _AdminVisitorEventsScreenState();
}

class _AdminVisitorEventsScreenState extends State<AdminVisitorEventsScreen> {
  final ApiService _api = ApiService();
  final List<VisitorEvent> _items = [];
  static const int _pageSize = 50;
  int _offset = 0;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  Future<void> _load({required bool reset}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _offset = 0;
        _hasMore = true;
      });
    } else {
      setState(() => _loadingMore = true);
    }
    final off = reset ? 0 : _offset;
    final page = await _api.adminListVisitorEvents(
      widget.token,
      limit: _pageSize,
      offset: off,
    );
    if (!mounted) return;
    setState(() {
      if (reset) {
        _items
          ..clear()
          ..addAll(page);
      } else {
        _items.addAll(page);
      }
      _offset = off + page.length;
      _hasMore = page.length >= _pageSize;
      _loading = false;
      _loadingMore = false;
    });
  }

  String _uaShort(String? ua) {
    if (ua == null || ua.isEmpty) return '—';
    if (ua.length <= 72) return ua;
    return '${ua.substring(0, 72)}…';
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocaleScope.of(context).strings;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.adminVisitorAnalytics),
        backgroundColor: AppColors.krishnaBlue,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        color: AppColors.krishnaBlue,
        onRefresh: () => _load(reset: true),
        child: _loading && _items.isEmpty
            ? const Center(child: CircularProgressIndicator(color: AppColors.krishnaBlue))
            : _items.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.sizeOf(context).height * 0.35,
                        child: Center(child: Text(s.adminVisitorEventsEmpty)),
                      ),
                    ],
                  )
                : ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                itemCount: _items.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, i) {
                  if (i >= _items.length) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: _loadingMore
                            ? const CircularProgressIndicator(color: AppColors.krishnaBlue)
                            : TextButton(
                                onPressed: _loadingMore ? null : () => _load(reset: false),
                                child: Text(s.adminVisitorEventsLoadMore),
                              ),
                      ),
                    );
                  }
                  final e = _items[i];
                  final local = e.occurredAt.toLocal();
                  final timeStr = DateFormat.yMMMd().add_jm().format(local);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            timeStr,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            e.screen,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('Platform: ${e.platform}', style: const TextStyle(fontSize: 13)),
                          if (e.appVersion != null && e.appVersion!.isNotEmpty)
                            Text('App: ${e.appVersion}', style: const TextStyle(fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(
                            'IP: ${e.ipSeen ?? "—"}',
                            style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade700),
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            e.sessionId ?? '—',
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _uaShort(e.userAgent),
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
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
