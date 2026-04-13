import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms of Service')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Text(
            'FixHub Terms of Service\n\n'
            '1. Account Responsibility\n'
            'Users must provide accurate details and are responsible for all account activity.\n\n'
            '2. Booking Conduct\n'
            'Customers and providers must communicate honestly, respect schedules, and avoid abusive behavior.\n\n'
            '3. Payments\n'
            'Payment confirmation should be completed only after job completion and customer verification.\n\n'
            '4. Service Quality\n'
            'Providers are expected to deliver work consistent with their listing and quote commitments.\n\n'
            '5. Disputes\n'
            'Disputes may be opened from booking details and are reviewed according to platform policy.\n\n'
            '6. Platform Rights\n'
            'FixHub may suspend accounts involved in fraud, abuse, or repeated policy violations.\n\n'
            '7. Contact\n'
            'Terms administration is handled by ${AppConstants.supportManagerName}. Contact ${AppConstants.supportEmail} or ${AppConstants.supportPhone} for legal and policy queries.',
            style: TextStyle(height: 1.5),
          ),
        ),
      ),
    );
  }
}
