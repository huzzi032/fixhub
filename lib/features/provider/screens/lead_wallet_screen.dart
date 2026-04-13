import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/local_booking_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/providers/auth_provider.dart';

class LeadWalletScreen extends ConsumerStatefulWidget {
  const LeadWalletScreen({super.key});

  @override
  ConsumerState<LeadWalletScreen> createState() => _LeadWalletScreenState();
}

class _LeadWalletScreenState extends ConsumerState<LeadWalletScreen> {
  final _topUpController = TextEditingController(text: '500');
  int _refreshTick = 0;
  bool _processing = false;

  @override
  void dispose() {
    _topUpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Lead Wallet')),
      body: user == null
          ? const EmptyStateWidget(
              title: 'Sign In Required',
              subtitle: 'Please sign in as provider to access wallet.',
              icon: Icons.lock_outline,
            )
          : FutureBuilder<int>(
              key: ValueKey<int>(_refreshTick),
              future: LocalBookingService.instance
                  .getProviderWalletBalance(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: AppLoadingIndicator());
                }

                final balance = snapshot.data ?? 0;

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryLight],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Available Balance',
                            style: TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Rs. $balance',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: _topUpController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Top-up Amount',
                        hintText: 'Enter amount in PKR',
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _processing
                            ? null
                            : () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final amount =
                                    int.tryParse(_topUpController.text);
                                if (amount == null || amount < 100) {
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Minimum top-up is Rs. 100'),
                                    ),
                                  );
                                  return;
                                }

                                setState(() {
                                  _processing = true;
                                });

                                await LocalBookingService.instance.topUpWallet(
                                  providerId: user.uid,
                                  amount: amount,
                                );

                                if (!mounted) return;
                                setState(() {
                                  _processing = false;
                                  _refreshTick++;
                                });

                                messenger.showSnackBar(
                                  SnackBar(
                                    content:
                                        Text('Wallet topped up by Rs. $amount'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              },
                        child: _processing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Top Up Wallet'),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Lead Rules',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                '• You need a positive balance to accept more jobs.'),
                            SizedBox(height: 6),
                            Text(
                                '• Keep wallet funded for uninterrupted lead access.'),
                            SizedBox(height: 6),
                            Text(
                                '• Earnings are automatically added on payment collection.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
