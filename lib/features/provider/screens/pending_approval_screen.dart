import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/local_auth_service.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';

class PendingApprovalScreen extends ConsumerStatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  ConsumerState<PendingApprovalScreen> createState() =>
      _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends ConsumerState<PendingApprovalScreen> {
  int _refreshTick = 0;

  Future<String> _getStatus(String uid) async {
    return LocalAuthService.instance.getProviderVerificationStatus(uid);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Verification Status')),
      body: user == null
          ? const Center(child: Text('Please sign in again.'))
          : FutureBuilder<String>(
              key: ValueKey<int>(_refreshTick),
              future: _getStatus(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final status = snapshot.data ?? 'pending';
                final isApproved = status == 'approved';
                final isRejected = status == 'rejected';

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isApproved
                              ? AppColors.success.withValues(alpha: 0.1)
                              : isRejected
                                  ? AppColors.error.withValues(alpha: 0.1)
                                  : AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isApproved
                                ? AppColors.success
                                : isRejected
                                    ? AppColors.error
                                    : AppColors.warning,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isApproved
                                  ? Icons.verified
                                  : isRejected
                                      ? Icons.cancel
                                      : Icons.hourglass_bottom,
                              color: isApproved
                                  ? AppColors.success
                                  : isRejected
                                      ? AppColors.error
                                      : AppColors.warning,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Current status: ${status.toUpperCase()}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isApproved
                            ? 'Your account is verified. You can now fully use provider tools.'
                            : isRejected
                                ? 'Your verification was rejected. Please update your profile and resubmit.'
                                : 'Your documents are under review. This usually takes up to 24 hours.',
                        style:
                            const TextStyle(color: AppColors.onSurfaceVariant),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (isApproved) {
                              context.goToProviderDashboard();
                            } else {
                              context.goToProviderOwnProfile();
                            }
                          },
                          child: Text(
                            isApproved ? 'Go to Dashboard' : 'Open Profile',
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _refreshTick++;
                            });
                          },
                          child: const Text('Refresh Status'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
