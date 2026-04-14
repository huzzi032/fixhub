import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/database/local_booking_service.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../auth/providers/auth_provider.dart';

class QuoteSubmissionScreen extends ConsumerStatefulWidget {
  final String bookingId;
  final String customerName;
  final String issueTitle;

  const QuoteSubmissionScreen({
    super.key,
    required this.bookingId,
    required this.customerName,
    required this.issueTitle,
  });

  @override
  ConsumerState<QuoteSubmissionScreen> createState() =>
      _QuoteSubmissionScreenState();
}

class _QuoteSubmissionScreenState extends ConsumerState<QuoteSubmissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _arrivalEstimate = AppConstants.quoteTimeEstimates.first;
  bool _submitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Submit Quote')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Customer: ${widget.customerName}',
              style: const TextStyle(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.issueTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quote Amount (Rs.)',
              ),
              validator: (value) =>
                  Validators.validateQuoteAmount(value ?? '').errorMessage,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _arrivalEstimate,
              decoration: const InputDecoration(labelText: 'Estimated Time'),
              items: AppConstants.quoteTimeEstimates
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item,
                      child: Text(item),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _arrivalEstimate = value;
                });
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Message to Customer',
                hintText: 'What is included in your quote?',
              ),
              validator: (value) =>
                  Validators.validateQuoteMessage(value ?? '').errorMessage,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _submitting
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) {
                          return;
                        }

                        final user = ref.read(currentUserProvider);
                        final userData =
                            ref.read(currentUserDataProvider).asData?.value;
                        if (user == null || userData == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Please sign in first.')),
                          );
                          return;
                        }

                        setState(() {
                          _submitting = true;
                        });

                        await LocalBookingService.instance.acceptLead(
                          bookingId: widget.bookingId,
                          providerId: user.uid,
                          providerName: userData.name,
                          quoteAmount: int.parse(_amountController.text),
                          providerNote:
                              '${_noteController.text.trim()} ETA: $_arrivalEstimate',
                        );

                        if (context.mounted) {
                          final action = await showDialog<String>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('Lead Accepted'),
                              content: const Text(
                                'You can now chat with the customer or open the active job view.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop('job'),
                                  child: const Text('Active Job'),
                                ),
                                FilledButton.icon(
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop('chat'),
                                  icon: const Icon(Icons.chat_bubble_outline),
                                  label: const Text('Open Chat'),
                                ),
                              ],
                            ),
                          );

                          if (!context.mounted) {
                            return;
                          }

                          if (action == 'chat') {
                            context.goToBookingChat(widget.bookingId);
                            return;
                          }

                          context.goToActiveJob(widget.bookingId);
                        }
                      },
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit Quote'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
