import 'package:flutter/material.dart';

/// Minimum length for reason text (must match API `required_admin_payment_note`).
const int kAdminPaymentReasonMinLength = 3;

/// Result of admin "resolve payment" dialog (offline follow-up with donor).
class AdminPaymentResolveResult {
  AdminPaymentResolveResult({
    required this.paymentStatus,
    this.gatewayPaymentId,
    required this.adminNote,
  });

  final String paymentStatus;
  final String? gatewayPaymentId;
  final String adminNote;
}

/// Shows dialog to set payment to paid/refunded with optional UTR and required reason.
Future<AdminPaymentResolveResult?> showAdminPaymentResolveDialog(
  BuildContext context, {
  required String title,
  required String currentPaymentStatus,
}) async {
  final formKey = GlobalKey<FormState>();
  final cs = currentPaymentStatus.toLowerCase().trim();
  final onlyRefunded = cs == 'paid';
  var selected = onlyRefunded ? 'refunded' : 'paid';
  final utrCtrl = TextEditingController();
  final noteCtrl = TextEditingController();

  return showDialog<AdminPaymentResolveResult>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setLocal) {
          return AlertDialog(
            title: Text(title),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      onlyRefunded
                          ? 'Mark as refunded (was paid).'
                          : 'Current status: $cs',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    if (onlyRefunded)
                      const Text('New status: refunded')
                    else
                      DropdownButtonFormField<String>(
                        value: selected,
                        decoration: const InputDecoration(
                          labelText: 'New payment status',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'paid', child: Text('paid')),
                          DropdownMenuItem(value: 'refunded', child: Text('refunded')),
                        ],
                        onChanged: (v) {
                          if (v != null) setLocal(() => selected = v);
                        },
                      ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: utrCtrl,
                      decoration: const InputDecoration(
                        labelText: 'UTR / payment id (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: noteCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Reason for change *',
                        hintText: 'At least $kAdminPaymentReasonMinLength characters',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                      validator: (v) {
                        final t = v?.trim() ?? '';
                        if (t.length < kAdminPaymentReasonMinLength) {
                          return 'Reason is required (min $kAdminPaymentReasonMinLength characters)';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState?.validate() != true) return;
                  final utr = utrCtrl.text.trim();
                  final note = noteCtrl.text.trim();
                  Navigator.pop(
                    ctx,
                    AdminPaymentResolveResult(
                      paymentStatus: onlyRefunded ? 'refunded' : selected,
                      gatewayPaymentId: utr.isEmpty ? null : utr,
                      adminNote: note,
                    ),
                  );
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    },
  );
}

bool adminCanPatchPaymentStatus(String paymentStatus) {
  final s = paymentStatus.toLowerCase().trim();
  return s == 'failed' || s == 'pending' || s == 'paid';
}
