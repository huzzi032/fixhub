import 'package:flutter/material.dart';

class PlatformOverviewScreen extends StatelessWidget {
  const PlatformOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Platform Overview')),
      body: const Center(child: Text('Platform Statistics')),
    );
  }
}
