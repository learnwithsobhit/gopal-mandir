import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import 'admin_feedback_detail_screen.dart';

class AdminFeedbackListScreen extends StatefulWidget {
  const AdminFeedbackListScreen({super.key, required this.token});
  final String token;

  @override
  State<AdminFeedbackListScreen> createState() => _AdminFeedbackListScreenState();
}

class _AdminFeedbackListScreenState extends State<AdminFeedbackListScreen> {
  final ApiService _api = ApiService();
  final _searchCtrl = TextEditingController();
  bool _loading = true;
  String? _status;
  String? _priority;
  int? _rating;
  List<AdminFeedbackView> _items = [];

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
    final data = await _api.adminListFeedback(
      widget.token,
      status: _status,
      priority: _priority,
      rating: _rating,
      search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _items = data;
      _loading = false;
    });
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'new':
        return Colors.blue;
      case 'triaged':
        return Colors.teal;
      case 'in_progress':
        return Colors.orange;
      case 'resolved':
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
      appBar: AppBar(
        title: const Text('Feedback Queue'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by name/email/ref/message',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: _load,
                  icon: const Icon(Icons.send),
                ),
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _load(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: _status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All')),
                      DropdownMenuItem(value: 'new', child: Text('New')),
                      DropdownMenuItem(value: 'triaged', child: Text('Triaged')),
                      DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                      DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                      DropdownMenuItem(value: 'closed', child: Text('Closed')),
                    ],
                    onChanged: (v) => setState(() => _status = v),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: _priority,
                    decoration: const InputDecoration(labelText: 'Priority'),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All')),
                      DropdownMenuItem(value: 'low', child: Text('Low')),
                      DropdownMenuItem(value: 'medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'high', child: Text('High')),
                      DropdownMenuItem(value: 'critical', child: Text('Critical')),
                    ],
                    onChanged: (v) => setState(() => _priority = v),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    value: _rating,
                    decoration: const InputDecoration(labelText: 'Rating'),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All')),
                      DropdownMenuItem(value: 5, child: Text('5')),
                      DropdownMenuItem(value: 4, child: Text('4')),
                      DropdownMenuItem(value: 3, child: Text('3')),
                      DropdownMenuItem(value: 2, child: Text('2')),
                      DropdownMenuItem(value: 1, child: Text('1')),
                    ],
                    onChanged: (v) => setState(() => _rating = v),
                  ),
                ),
                IconButton(onPressed: _load, icon: const Icon(Icons.filter_alt)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? const Center(child: Text('No feedback found'))
                    : ListView.builder(
                        itemCount: _items.length,
                        itemBuilder: (_, i) {
                          final f = _items[i];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: ListTile(
                              title: Text(f.name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(f.message, maxLines: 2, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.star, color: AppColors.templeGoldDark, size: 16),
                                      Text(' ${f.rating}'),
                                      const SizedBox(width: 8),
                                      Text('Ref: ${f.referenceId}', style: const TextStyle(fontSize: 12)),
                                      const SizedBox(width: 8),
                                      Text('Replies: ${f.responseCount}', style: const TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: _statusColor(f.status).withAlpha(30),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      f.status,
                                      style: TextStyle(
                                        color: _statusColor(f.status),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(f.priority, style: const TextStyle(fontSize: 11)),
                                ],
                              ),
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AdminFeedbackDetailScreen(
                                      token: widget.token,
                                      feedbackId: f.id,
                                    ),
                                  ),
                                );
                                _load();
                              },
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

