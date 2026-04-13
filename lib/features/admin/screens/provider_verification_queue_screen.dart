import 'package:flutter/material.dart';

class ProviderVerificationQueueScreen extends StatelessWidget {
  const ProviderVerificationQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Provider Verification')),
      body: const Center(child: Text('Verification Queue')),
    );
  }
}
