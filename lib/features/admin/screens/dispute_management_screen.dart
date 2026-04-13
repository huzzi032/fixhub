import 'package:flutter/material.dart';

class DisputeManagementScreen extends StatelessWidget {
  const DisputeManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dispute Management')),
      body: const Center(child: Text('Disputes List')),
    );
  }
}
