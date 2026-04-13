import 'package:flutter/material.dart';

class TopUpApprovalScreen extends StatelessWidget {
  const TopUpApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Top-up Approvals')),
      body: const Center(child: Text('Top-up Requests')),
    );
  }
}
