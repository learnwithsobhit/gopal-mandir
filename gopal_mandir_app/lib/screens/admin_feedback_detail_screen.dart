import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class AdminFeedbackDetailScreen extends StatefulWidget {
  const AdminFeedbackDetailScreen({
    super.key,
    required this.token,
    required this.feedbackId,
  });

  final String token;
  final int feedbackId;

  @override
  State<AdminFeedbackDetailScreen> createState() => _AdminFeedbackDetailScreenState();
}

class _AdminFeedbackDetailScreenState extends State<AdminFeedbackDetailScreen> {
  final ApiService _api = ApiService();
  final _responseCtrl = TextEditingController();

  bool _loading = true;
  AdminFeedbackView? _feedback;
  List<FeedbackThreadItem> _thread = [];
  String? _status;
  String? _priority;
  bool _isPublic = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _responseCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final detail = await _api.adminGetFeedbackDetail(widget.token, widget.feedbackId);
    final thread = await _api.adminListFeedbackResponses(widget.token, widget.feedbackId);
    if (!mounted) return;
    setState(() {
      _feedback = detail;
      _thread = thread;
      _status = detail?.status;
      _priority = detail?.priority;
      _loading = false;
    });
  }

  Future<void> _saveMeta() async {
    final ok = await _api.adminPatchFeedback(
      widget.token,
      widget.feedbackId,
      {
        if (_status != null) 'status': _status,
        if (_priority != null) 'priority': _priority,
      },
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Saved' : 'Failed to save')),
    );
    if (ok) _load();
  }

  Future<void> _sendResponse() async {
    final msg = _responseCtrl.text.trim();
    if (msg.isEmpty) return;
    final ok = await _api.adminAddFeedbackResponse(
      widget.token,
      widget.feedbackId,
      message: msg,
      isPublic: _isPublic,
    );
    if (!mounted) return;
    if (ok) {
      _responseCtrl.clear();
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add response')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = _feedback;
    return Scaffold(
      appBar: AppBar(title: const Text('Feedback Detail')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : f == null
              ? const Center(child: Text('Feedback not found'))
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(12),
                        children: [
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(f.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 4),
                                  Text('Ref: ${f.referenceId}'),
                                  Text('Rating: ${f.rating}/5'),
                                  if ((f.email ?? '').isNotEmpty) Text('Email: ${f.email}'),
                                  if ((f.phone ?? '').isNotEmpty) Text('Phone: ${f.phone}'),
                                  const SizedBox(height: 8),
                                  Text(f.message),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: _status,
                                      decoration: const InputDecoration(labelText: 'Status'),
                                      items: const [
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
                                    child: DropdownButtonFormField<String>(
                                      value: _priority,
                                      decoration: const InputDecoration(labelText: 'Priority'),
                                      items: const [
                                        DropdownMenuItem(value: 'low', child: Text('Low')),
                                        DropdownMenuItem(value: 'medium', child: Text('Medium')),
                                        DropdownMenuItem(value: 'high', child: Text('High')),
                                        DropdownMenuItem(value: 'critical', child: Text('Critical')),
                                      ],
                                      onChanged: (v) => setState(() => _priority = v),
                                    ),
                                  ),
                                  IconButton(onPressed: _saveMeta, icon: const Icon(Icons.save)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text('Responses', style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          ..._thread.map((r) => Card(
                                child: ListTile(
                                  title: Text(r.authorName ?? r.authorType),
                                  subtitle: Text(r.message),
                                  trailing: Text(
                                    r.isPublic ? 'Public' : 'Internal',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                              )),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                        child: Column(
                          children: [
                            TextField(
                              controller: _responseCtrl,
                              minLines: 1,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                hintText: 'Write response...',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            Row(
                              children: [
                                Checkbox(
                                  value: _isPublic,
                                  onChanged: (v) => setState(() => _isPublic = v ?? false),
                                ),
                                const Text('Public response'),
                                const Spacer(),
                                ElevatedButton.icon(
                                  onPressed: _sendResponse,
                                  icon: const Icon(Icons.send),
                                  label: const Text('Post'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

