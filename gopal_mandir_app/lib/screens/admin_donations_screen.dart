import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../models/models.dart';
import '../widgets/admin_payment_status_dialog.dart';

class AdminDonationsScreen extends StatefulWidget {
  const AdminDonationsScreen({super.key, required this.token});

  final String token;

  @override
  State<AdminDonationsScreen> createState() => _AdminDonationsScreenState();
}

class _AdminDonationsScreenState extends State<AdminDonationsScreen> {
  final ApiService _api = ApiService();
  final _searchController = TextEditingController();
  List<AdminDonationView> _items = [];
  bool _loading = true;
  String? _paymentStatusFilter;

  static const _statusChoices = ['pending', 'paid', 'failed', 'refunded'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _api.adminListDonations(
      widget.token,
      paymentStatus: _paymentStatusFilter,
      search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
      limit: 100,
    );
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  String _fmtAmount(double amount) {
    if (amount == amount.truncateToDouble()) {
      return '₹${amount.toInt()}';
    }
    return '₹${amount.toStringAsFixed(2)}';
  }

  String _paymentLine(AdminDonationView d) {
    final buf = StringBuffer('Pay: ${d.paymentStatus}');
    if (d.gateway != null && d.gateway!.isNotEmpty) {
      buf.write(' • ${d.gateway}');
    }
    if (d.gatewayOrderId != null && d.gatewayOrderId!.isNotEmpty) {
      buf.write('\nOrder: ${d.gatewayOrderId}');
    }
    if (d.gatewayPaymentId != null && d.gatewayPaymentId!.isNotEmpty) {
      buf.write('\nPayment id: ${d.gatewayPaymentId}');
    }
    if (d.paymentFailureReason != null && d.paymentFailureReason!.isNotEmpty) {
      buf.write('\nFailure: ${d.paymentFailureReason}');
    }
    if (d.paymentAdminNote != null && d.paymentAdminNote!.isNotEmpty) {
      buf.write('\nAdmin note: ${d.paymentAdminNote}');
    }
    return buf.toString();
  }

  Future<void> _patchPayment(AdminDonationView d) async {
    if (!adminCanPatchPaymentStatus(d.paymentStatus)) return;
    final result = await showAdminPaymentResolveDialog(
      context,
      title: 'Update payment — ${d.referenceId}',
      currentPaymentStatus: d.paymentStatus,
    );
    if (result == null || !mounted) return;
    final resp = await _api.adminPatchDonationPayment(
      widget.token,
      d.id,
      paymentStatus: result.paymentStatus,
      gatewayPaymentId: result.gatewayPaymentId,
      adminNote: result.adminNote,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resp.message)));
    if (resp.success) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('General Donations'),
        backgroundColor: AppColors.krishnaBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search name, phone, ref, purpose…',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _load,
                ),
              ),
              onSubmitted: (_) => _load(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: DropdownButtonFormField<String?>(
              value: _paymentStatusFilter,
              decoration: const InputDecoration(
                labelText: 'Payment status',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              isExpanded: true,
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('All')),
                for (final s in _statusChoices)
                  DropdownMenuItem<String?>(value: s, child: Text(s)),
              ],
              onChanged: (v) {
                setState(() => _paymentStatusFilter = v);
                _load();
              },
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.krishnaBlue))
                : _items.isEmpty
                    ? const Center(child: Text('No donations'))
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: AppColors.krishnaBlue,
                        child: ListView.builder(
                          itemCount: _items.length,
                          itemBuilder: (context, i) {
                            final d = _items[i];
                            final highlight = d.paymentStatus == 'failed' || d.paymentStatus == 'pending';
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              color: highlight ? AppColors.urgentRed.withAlpha(14) : null,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.templeGold.withAlpha(40),
                                  child: const Icon(Icons.favorite, color: AppColors.krishnaBlue),
                                ),
                                title: Text(
                                  '${d.name}  •  ${_fmtAmount(d.amount)}',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  'Purpose: ${d.purpose}'
                                  '\nPhone: ${d.phone ?? "—"} · Email: ${d.email ?? "—"}'
                                  '\nRef: ${d.referenceId}'
                                  '\n${_paymentLine(d)}',
                                ),
                                isThreeLine: true,
                                trailing: adminCanPatchPaymentStatus(d.paymentStatus)
                                    ? IconButton(
                                        icon: const Icon(Icons.payments_outlined),
                                        tooltip: 'Update payment',
                                        onPressed: () => _patchPayment(d),
                                      )
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
