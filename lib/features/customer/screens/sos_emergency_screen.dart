import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/database/local_booking_service.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';

class SosEmergencyScreen extends ConsumerStatefulWidget {
  const SosEmergencyScreen({super.key});

  @override
  ConsumerState<SosEmergencyScreen> createState() => _SosEmergencyScreenState();
}

class _SosEmergencyScreenState extends ConsumerState<SosEmergencyScreen> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  String _selectedIssue = AppConstants.sosIssueTypes.first;
  bool _submitting = false;

  @override
  void dispose() {
    _addressController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SOS Emergency')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.sosRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.sosRed),
              ),
              child: const Text(
                'Use SOS only for urgent repair situations. Nearby providers will be alerted first.',
                style: TextStyle(color: AppColors.sosRed),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedIssue,
              decoration: const InputDecoration(labelText: 'Emergency Type'),
              items: AppConstants.sosIssueTypes
                  .map(
                    (issue) => DropdownMenuItem<String>(
                      value: issue,
                      child: Text(issue),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _selectedIssue = value;
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Current Address',
                hintText: 'House / Street / Area',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _detailsController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Emergency Details',
                hintText: 'Briefly explain the issue and urgency',
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submitting
                    ? null
                    : () async {
                        final user = ref.read(currentUserProvider);
                        if (user == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Please sign in first.')),
                          );
                          return;
                        }

                        if (_addressController.text.trim().isEmpty ||
                            _detailsController.text.trim().length < 10) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please provide complete address and details.',
                              ),
                            ),
                          );
                          return;
                        }

                        setState(() {
                          _submitting = true;
                        });

                        final userData =
                            await ref.read(userDataProvider(user.uid).future);
                        final bookingId =
                            await LocalBookingService.instance.createBooking(
                          customerId: user.uid,
                          serviceCategory: 'other',
                          issueTitle: _selectedIssue,
                          issueDescription: _detailsController.text.trim(),
                          address: _addressController.text.trim(),
                          scheduledAt: DateTime.now(),
                          customerName: userData?.name,
                          isSOS: true,
                        );

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('SOS request sent to providers.'),
                              backgroundColor: AppColors.sosRed,
                            ),
                          );
                          context.goToBookingTracking(bookingId);
                        }
                      },
                icon: const Icon(Icons.emergency),
                label: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Send SOS Request'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.sosRed,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
