import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/database/local_booking_service.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';

class DisputeScreen extends StatefulWidget {
  final String bookingId;
  const DisputeScreen({super.key, required this.bookingId});

  @override
  State<DisputeScreen> createState() => _DisputeScreenState();
}

class _DisputeScreenState extends State<DisputeScreen> {
  String _reason = AppConstants.disputeReasons.first;
  final TextEditingController _detailsController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Dispute')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Booking: ${widget.bookingId}',
              style: const TextStyle(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _reason,
              decoration: const InputDecoration(labelText: 'Reason'),
              items: AppConstants.disputeReasons
                  .map(
                    (reason) => DropdownMenuItem<String>(
                      value: reason,
                      child: Text(reason),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _reason = value;
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _detailsController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Details',
                hintText: 'Explain what went wrong in at least a few lines...',
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting
                    ? null
                    : () async {
                        if (_detailsController.text.trim().length < 20) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please provide more details.'),
                            ),
                          );
                          return;
                        }

                        setState(() {
                          _submitting = true;
                        });

                        await LocalBookingService.instance.updateBookingStatus(
                          bookingId: widget.bookingId,
                          status: 'disputed',
                        );

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Dispute submitted: $_reason',
                              ),
                              backgroundColor: AppColors.warning,
                            ),
                          );
                          context.goToBookingDetail(widget.bookingId);
                        }
                      },
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit Dispute'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
