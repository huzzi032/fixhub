import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/local_marketplace_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/providers/auth_provider.dart';

class NeighborhoodDealsScreen extends ConsumerStatefulWidget {
  const NeighborhoodDealsScreen({super.key});

  @override
  ConsumerState<NeighborhoodDealsScreen> createState() =>
      _NeighborhoodDealsScreenState();
}

class _NeighborhoodDealsScreenState
    extends ConsumerState<NeighborhoodDealsScreen> {
  Future<void> _toggleJoin(
    NeighborhoodDealItem deal,
    String userId,
  ) async {
    try {
      if (deal.hasJoined) {
        await LocalMarketplaceService.instance.leaveDeal(
          dealId: deal.dealId,
          userId: userId,
        );
      } else {
        await LocalMarketplaceService.instance.joinDeal(
          dealId: deal.dealId,
          userId: userId,
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
      return;
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Neighborhood Deals')),
      body: user == null
          ? const EmptyStateWidget(
              title: 'Sign In Required',
              subtitle: 'Please sign in to view and join neighborhood deals.',
              icon: Icons.lock_outline,
            )
          : FutureBuilder<List<NeighborhoodDealItem>>(
              future:
                  LocalMarketplaceService.instance.getDeals(userId: user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: AppLoadingIndicator());
                }

                final deals = snapshot.data ?? const <NeighborhoodDealItem>[];
                if (deals.isEmpty) {
                  return const EmptyStateWidget(
                    title: 'No Deals Nearby',
                    subtitle:
                        'Providers will publish deals for your area soon.',
                    icon: Icons.local_offer_outlined,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {});
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: deals.length,
                    itemBuilder: (context, index) {
                      final deal = deals[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondary,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${deal.discountPercent}% OFF',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    deal.participantsLabel,
                                    style: const TextStyle(
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                deal.categoryLabel,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text('${deal.area}, ${deal.city}'),
                              const SizedBox(height: 8),
                              Text(
                                deal.description,
                                style: const TextStyle(
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Organized by: ${deal.organizerLabel}',
                                style: const TextStyle(
                                  color: AppColors.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () => _toggleJoin(deal, user.uid),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: deal.hasJoined
                                        ? AppColors.background
                                        : AppColors.primary,
                                    foregroundColor: deal.hasJoined
                                        ? AppColors.onSurface
                                        : Colors.white,
                                  ),
                                  child: Text(
                                    deal.hasJoined ? 'Leave Deal' : 'Join Deal',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
