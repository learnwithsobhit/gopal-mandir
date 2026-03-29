import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/locale_scope.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_screen_header.dart';
import '../widgets/app_surface.dart';
import '../widgets/app_text_form_field.dart';
import '../widgets/vrindavan_background.dart';

class PoojaAppointmentScreen extends StatefulWidget {
  const PoojaAppointmentScreen({super.key});

  @override
  State<PoojaAppointmentScreen> createState() => _PoojaAppointmentScreenState();
}

class _PoojaAppointmentScreenState extends State<PoojaAppointmentScreen> {
  final _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  List<PoojaOfferingWithPackages> _offerings = [];
  bool _loadingOfferings = true;
  List<PoojaAvailabilityDay> _availability = [];
  bool _loadingAvail = false;

  PoojaOfferingWithPackages? _offering;
  PoojaOfferingPackage? _package;
  String _officiant = 'guru';
  String? _bookingDate;
  int? _slotId;
  String _venue = 'temple';

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadOfferings() async {
    setState(() => _loadingOfferings = true);
    final list = await _api.getPoojaOfferings();
    if (!mounted) return;
    setState(() {
      _offerings = list;
      _loadingOfferings = false;
      if (list.isNotEmpty) {
        _offering = list.first;
        _package = list.first.packages.isNotEmpty ? list.first.packages.first : null;
      }
    });
    _refreshAvailability();
  }

  Future<void> _refreshAvailability() async {
    setState(() => _loadingAvail = true);
    final now = DateTime.now();
    final from =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final end = now.add(const Duration(days: 60));
    final to =
        '${end.year.toString().padLeft(4, '0')}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';
    final days = await _api.getPoojaAvailability(officiant: _officiant, from: from, to: to);
    if (!mounted) return;
    setState(() {
      _availability = days;
      _loadingAvail = false;
      _bookingDate = null;
      _slotId = null;
    });
  }

  int _pricePaiseForSelection() {
    if (_offering == null) return 0;
    final base = _offering!.basePricePaise;
    if (_package != null) return _package!.totalPaiseWithBase(base);
    return base;
  }

  Future<void> _pickDate() async {
    final s = AppLocaleScope.of(context).strings;
    if (_availability.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.poojaNoSlots)));
      return;
    }
    final items = _availability.where((d) => d.slots.any((sl) => sl.available > 0)).toList();
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.poojaNoSlots)));
      return;
    }
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(s.poojaPickDate, style: Theme.of(ctx).textTheme.titleMedium),
            ),
            for (final d in items)
              ListTile(
                title: Text(d.date),
                subtitle: Text(
                  d.slots.map((sl) => '${sl.label}: ${sl.available} free').join(' · '),
                ),
                onTap: () => Navigator.pop(ctx, d.date),
              ),
          ],
        ),
      ),
    );
    if (picked != null) {
      setState(() {
        _bookingDate = picked;
        _slotId = null;
      });
    }
  }

  Future<void> _submit() async {
    final s = AppLocaleScope.of(context).strings;
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    if (_offering == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.poojaSelectOffering)));
      return;
    }
    if (_bookingDate == null || _slotId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.poojaDateSlotRequired)));
      return;
    }
    if (_venue == 'devotee_home' && _addressCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.poojaAddressRequired)));
      return;
    }

    final req = PoojaBookingCreateRequest(
      offeringId: _offering!.id,
      packageId: _package?.id,
      officiant: _officiant,
      bookingDate: _bookingDate!,
      slotId: _slotId!,
      venue: _venue,
      address: _venue == 'devotee_home' ? _addressCtrl.text.trim() : null,
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    setState(() => _submitting = true);
    final resp = await _api.createPoojaBooking(req);
    if (!mounted) return;
    setState(() => _submitting = false);

    if (!resp.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(resp.message.isEmpty ? s.errorLoadFailed : resp.message)),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.poojaBookedTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(resp.message),
            const SizedBox(height: 12),
            SelectableText('${s.ref}: ${resp.referenceId}'),
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: resp.referenceId));
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(s.poojaRefCopied)));
              },
              icon: const Icon(Icons.copy, size: 18),
              label: Text(s.poojaCopyRef),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s.close)),
        ],
      ),
    );
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocaleScope.of(context).strings;
    PoojaAvailabilityDay? day;
    if (_bookingDate != null) {
      for (final d in _availability) {
        if (d.date == _bookingDate) {
          day = d;
          break;
        }
      }
    }

    return VrindavanBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text(s.poojaAppointmentTitle)),
        body: _loadingOfferings
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: AppSpacing.screenInsets,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppScreenHeader(
                        title: s.poojaAppointmentTitle,
                        subtitle: s.poojaAppointmentSubtitle,
                        icon: Icons.self_improvement,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      if (_offerings.isEmpty)
                        AppSurface(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Text(s.poojaNoOfferings, textAlign: TextAlign.center),
                          ),
                        )
                      else ...[
                        Text(s.poojaOffering, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: AppSpacing.sm),
                        AppSurface(
                          child: Column(
                            children: _offerings
                                .map(
                                  (o) => RadioListTile<PoojaOfferingWithPackages>(
                                    value: o,
                                    groupValue: _offering,
                                    title: Text(o.name),
                                    subtitle: Text(
                                      o.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    onChanged: (v) {
                                      setState(() {
                                        _offering = v;
                                        _package = v!.packages.isNotEmpty ? v.packages.first : null;
                                      });
                                    },
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        if (_offering != null && _offering!.packages.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.md),
                          Text(s.poojaPackage, style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: AppSpacing.sm),
                          AppSurface(
                            child: Column(
                              children: _offering!.packages
                                  .map(
                                    (p) => RadioListTile<PoojaOfferingPackage>(
                                      value: p,
                                      groupValue: _package,
                                      title: Text(p.name),
                                      subtitle: Text(
                                        '₹${((_offering!.basePricePaise + p.additionalPricePaise) / 100).toStringAsFixed(0)}',
                                      ),
                                      onChanged: (v) => setState(() => _package = v),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        Text(s.poojaOfficiant, style: Theme.of(context).textTheme.titleMedium),
                        AppSurface(
                          child: Row(
                            children: [
                              Expanded(
                                child: RadioListTile<String>(
                                  value: 'guru',
                                  groupValue: _officiant,
                                  title: Text(s.poojaGuru),
                                  onChanged: (v) {
                                    if (v == null) return;
                                    setState(() => _officiant = v);
                                    _refreshAvailability();
                                  },
                                ),
                              ),
                              Expanded(
                                child: RadioListTile<String>(
                                  value: 'baba',
                                  groupValue: _officiant,
                                  title: Text(s.poojaBaba),
                                  onChanged: (v) {
                                    if (v == null) return;
                                    setState(() => _officiant = v);
                                    _refreshAvailability();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_loadingAvail)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else ...[
                          const SizedBox(height: AppSpacing.md),
                          Text(s.poojaDateSlot, style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: AppSpacing.sm),
                          OutlinedButton.icon(
                            onPressed: _pickDate,
                            icon: const Icon(Icons.calendar_today),
                            label: Text(_bookingDate ?? s.poojaPickDate),
                          ),
                          if (day != null) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: day.slots.map((sl) {
                                final enabled = sl.available > 0;
                                final selected = _slotId == sl.slotId;
                                return ChoiceChip(
                                  label: Text('${sl.label} (${sl.available})'),
                                  selected: selected,
                                  onSelected: enabled
                                      ? (_) => setState(() => _slotId = sl.slotId)
                                      : null,
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                        const SizedBox(height: AppSpacing.md),
                        Text(s.poojaVenue, style: Theme.of(context).textTheme.titleMedium),
                        AppSurface(
                          child: Column(
                            children: [
                              RadioListTile<String>(
                                value: 'temple',
                                groupValue: _venue,
                                title: Text(s.poojaVenueTemple),
                                onChanged: (v) => setState(() => _venue = v ?? 'temple'),
                              ),
                              RadioListTile<String>(
                                value: 'devotee_home',
                                groupValue: _venue,
                                title: Text(s.poojaVenueHome),
                                onChanged: (v) => setState(() => _venue = v ?? 'temple'),
                              ),
                            ],
                          ),
                        ),
                        if (_venue == 'devotee_home') ...[
                          const SizedBox(height: AppSpacing.sm),
                          AppTextFormField(
                            controller: _addressCtrl,
                            labelText: s.address,
                            maxLines: 3,
                            minLines: 2,
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? s.poojaAddressRequired : null,
                          ),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          '${s.poojaEstimated}: ₹${(_pricePaiseForSelection() / 100).toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextFormField(
                          controller: _nameCtrl,
                          labelText: s.poojaYourName,
                          textInputAction: TextInputAction.next,
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? s.poojaNameRequired : null,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AppTextFormField(
                          controller: _phoneCtrl,
                          labelText: s.phoneNumber,
                          keyboardType: TextInputType.phone,
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? s.errorPhoneRequired : null,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AppTextFormField(
                          controller: _notesCtrl,
                          labelText: s.notesOptional,
                          maxLines: 3,
                          minLines: 1,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        FilledButton(
                          onPressed: _submitting ? null : _submit,
                          child: _submitting
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(s.poojaSubmit),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
