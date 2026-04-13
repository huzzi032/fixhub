import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Text(
            'FixHub Privacy Policy\n\n'
            '1. Data We Collect\n'
            'We collect account details, booking information, and service history needed to operate the platform.\n\n'
            '2. How We Use Data\n'
            'Your data is used to match customers with providers, manage bookings, and improve platform reliability.\n\n'
            '3. Data Sharing\n'
            'We only share the minimum information required to complete a booking between customer and provider.\n\n'
            '4. Security\n'
            'We apply technical safeguards to protect user information and prevent unauthorized access.\n\n'
            '5. Your Controls\n'
            'You can request profile updates and account deletion through support.\n\n'
            '6. Contact\n'
            'This policy is managed by ${AppConstants.supportManagerName}. For privacy concerns, contact ${AppConstants.supportEmail} or call ${AppConstants.supportPhone}.',
            style: TextStyle(height: 1.5),
          ),
        ),
      ),
    );
  }
}
