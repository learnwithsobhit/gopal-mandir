import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import 'admin_astro_consult_detail_screen.dart';

class AdminAstroConsultListScreen extends StatefulWidget {
  const AdminAstroConsultListScreen({super.key, required this.token});

  final String token;

  @override
  State<AdminAstroConsultListScreen> createState() =>
      _AdminAstroConsultListScreenState();
}

class _AdminAstroConsultListScreenState
    extends State<AdminAstroConsultListScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _searchCtrl = TextEditingController();

  List<AstroConsultView> _items = [];
  bool _loading = true;
  String? _statusFilter;
  String? _categoryFilter;
  String? _search;

  static const _statuses = ['new', 'contacted', 'answered', 'closed'];
  static const _categories = [
    'astrology',
    'palmistry',
    'grahdosh',
    'kundali_matching',
    'muhurat',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _api.adminListAstroConsults(
      widget.token,
      status: _statusFilter,
      category: _categoryFilter,
      search: _search,
    );
    if (mounted) {
      setState(() {
        _items = data;
        _loading = false;
      });
    }
  }

  Future<void> _openDetail(AstroConsultView item) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AdminAstroConsultDetailScreen(
          token: widget.token,
          initial: item,
        ),
      ),
    );
    if (changed == true) _load();
  }

  String _fmtDate(String iso) {
    if (iso.isEmpty) return '-';
    try {
      return DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'new':
        return Colors.blue;
      case 'contacted':
        return Colors.orange;
      case 'answered':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Astro Consultations')),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchCtrl,
              textInputAction: TextInputAction.search,
              onSubmitted: (v) {
                _search = v.trim().isEmpty ? null : v.trim();
                _load();
              },
              decoration: InputDecoration(
                hintText: 'Search name / phone / question',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchCtrl.clear();
                          _search = null;
                          _load();
                        },
                      ),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text('Status: '),
                DropdownButton<String?>(
                  value: _statusFilter,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All')),
                    ..._statuses.map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Text(s[0].toUpperCase() + s.substring(1)),
                      ),
                    ),
                  ],
                  onChanged: (v) {
                    _statusFilter = v;
                    _load();
                  },
                ),
                const SizedBox(width: 16),
                const Text('Topic: '),
                DropdownButton<String?>(
                  value: _categoryFilter,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All')),
                    ..._categories.map(
                      (c) => DropdownMenuItem(value: c, child: Text(c)),
                    ),
                  ],
                  onChanged: (v) {
                    _categoryFilter = v;
                    _load();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? const Center(child: Text('No consultations found'))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) => _card(_items[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _card(AstroConsultView v) {
    return Card(
      child: InkWell(
        onTap: () => _openDetail(v),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      v.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Chip(
                    label: Text(
                      v.status[0].toUpperCase() + v.status.substring(1),
                      style:
                          const TextStyle(fontSize: 11, color: Colors.white),
                    ),
                    backgroundColor: _statusColor(v.status),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              _row(Icons.phone, v.phone),
              if (v.email != null && v.email!.isNotEmpty)
                _row(Icons.email_outlined, v.email!),
              _row(Icons.category_outlined, 'Topic: ${v.category}'),
              if (v.subject.isNotEmpty) _row(Icons.title, v.subject),
              const SizedBox(height: 4),
              Text(
                v.question,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: AppColors.warmGrey),
              ),
              const SizedBox(height: 4),
              Text(
                'Submitted ${_fmtDate(v.createdAt)}',
                style: TextStyle(fontSize: 11, color: AppColors.warmGrey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.warmGrey),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
