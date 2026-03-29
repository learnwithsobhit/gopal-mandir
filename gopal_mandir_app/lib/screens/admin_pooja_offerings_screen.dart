import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import 'admin_pooja_availability_screen.dart';

class AdminPoojaOfferingsScreen extends StatefulWidget {
  const AdminPoojaOfferingsScreen({super.key, required this.token});

  final String token;

  @override
  State<AdminPoojaOfferingsScreen> createState() => _AdminPoojaOfferingsScreenState();
}

class _AdminPoojaOfferingsScreenState extends State<AdminPoojaOfferingsScreen> {
  final _api = ApiService();
  List<AdminPoojaCatalogItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _api.adminListPoojaOfferings(widget.token);
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  Future<void> _addOffering() async {
    final name = TextEditingController();
    final desc = TextEditingController();
    final rupees = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New offering'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: desc, decoration: const InputDecoration(labelText: 'Description')),
            TextField(
              controller: rupees,
              decoration: const InputDecoration(labelText: 'Base price (₹)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Create')),
        ],
      ),
    );
    if (ok != true) return;
    final r = int.tryParse(rupees.text.trim()) ?? 0;
    final resp = await _api.adminCreatePoojaOffering(
      widget.token,
      name: name.text.trim(),
      description: desc.text.trim(),
      basePricePaise: r * 100,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resp.message)));
    _load();
  }

  Future<void> _toggleActive(AdminPoojaCatalogItem o) async {
    final resp = await _api.adminPatchPoojaOffering(widget.token, o.id, active: !o.active);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resp.message)));
    if (resp.success) _load();
  }

  Future<void> _addPackage(AdminPoojaCatalogItem o) async {
    final name = TextEditingController();
    final addRupees = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Package for ${o.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
            TextField(
              controller: addRupees,
              decoration: const InputDecoration(labelText: 'Extra on base (₹)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add')),
        ],
      ),
    );
    if (ok != true) return;
    final add = int.tryParse(addRupees.text.trim()) ?? 0;
    final resp = await _api.adminCreatePoojaPackage(
      widget.token,
      o.id,
      name: name.text.trim(),
      additionalPricePaise: add * 100,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resp.message)));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pooja offerings'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addOffering,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.krishnaBlue))
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.schedule, color: AppColors.krishnaBlue),
                    title: const Text('Slot schedule & capacity'),
                    subtitle: const Text('Guru Ji & Baba Ji — daily time bands and limits'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => AdminPoojaAvailabilityScreen(token: widget.token),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                for (final o in _items)
                  Card(
                    child: ExpansionTile(
                      title: Text(o.name),
                      subtitle: Text(
                        '₹${o.basePricePaise / 100} · ${o.packages.length} packages · ${o.active ? "active" : "inactive"}',
                      ),
                      children: [
                        SwitchListTile(
                          title: const Text('Active'),
                          value: o.active,
                          onChanged: (_) => _toggleActive(o),
                        ),
                        ListTile(
                          leading: const Icon(Icons.add_box_outlined),
                          title: const Text('Add package'),
                          onTap: () => _addPackage(o),
                        ),
                        for (final p in o.packages)
                          ListTile(
                            dense: true,
                            title: Text(p.name),
                            subtitle: Text('+₹${p.additionalPricePaise / 100} · ${p.active ? "on" : "off"}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.toggle_on_outlined),
                              onPressed: () async {
                                final r = await _api.adminPatchPoojaPackage(
                                  widget.token,
                                  p.id,
                                  active: !p.active,
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r.message)));
                                  _load();
                                }
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
