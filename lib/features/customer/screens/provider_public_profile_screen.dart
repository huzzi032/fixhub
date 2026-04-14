import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/database/local_marketplace_service.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/widgets.dart';

class ProviderPublicProfileScreen extends StatefulWidget {
  final String providerId;
  const ProviderPublicProfileScreen({super.key, required this.providerId});

  @override
  State<ProviderPublicProfileScreen> createState() =>
      _ProviderPublicProfileScreenState();
}

class _ProviderPublicProfileScreenState
    extends State<ProviderPublicProfileScreen> {
  int _refreshTick = 0;

  Future<void> _refreshServices() async {
    if (!mounted) return;
    setState(() {
      _refreshTick++;
    });
  }

  Widget _buildServiceImage(MarketplaceServiceItem service) {
    final cover = service.coverImageUrl;
    if (cover != null && cover.startsWith('data:image')) {
      final commaIndex = cover.indexOf(',');
      if (commaIndex > 0 && commaIndex < cover.length - 1) {
        try {
          return Image.memory(
            base64Decode(cover.substring(commaIndex + 1)),
            fit: BoxFit.cover,
          );
        } catch (_) {
          return const Icon(Icons.home_repair_service,
              color: AppColors.primary, size: 30);
        }
      }
    }

    if (cover != null &&
        (cover.startsWith('http://') || cover.startsWith('https://'))) {
      return Image.network(
        cover,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.home_repair_service,
            color: AppColors.primary, size: 30),
      );
    }

    return const Icon(Icons.home_repair_service,
        color: AppColors.primary, size: 30);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
              return;
            }
            context.goToCustomerHome();
          },
        ),
        title: const Text('Provider Profile'),
      ),
      body: FutureBuilder<ProviderPublicProfile?>(
        key: ValueKey('provider-profile-${widget.providerId}-$_refreshTick'),
        future: LocalMarketplaceService.instance
            .getProviderPublicProfile(widget.providerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: AppLoadingIndicator());
          }

          if (snapshot.hasError) {
            return ErrorStateWidget(
              message: 'Unable to load provider profile.',
              onRetry: () {
                _refreshServices();
              },
            );
          }

          final profile = snapshot.data;
          if (profile == null) {
            return const EmptyStateWidget(
              title: 'Profile Not Found',
              subtitle: 'This provider profile is unavailable right now.',
              icon: Icons.person_search_outlined,
            );
          }

          final services = profile.services;

          final headerRating =
              profile.totalReviews > 0 ? profile.averageRating : 0.0;

          String? hourlyRateText;
          if (profile.hourlyRateMin != null && profile.hourlyRateMax != null) {
            hourlyRateText =
                'Rs. ${profile.hourlyRateMin} - ${profile.hourlyRateMax} / hour';
          } else if (profile.hourlyRateMin != null) {
            hourlyRateText =
                'Starting from Rs. ${profile.hourlyRateMin} / hour';
          }

          return RefreshIndicator(
            onRefresh: _refreshServices,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Column(
                  children: [
                    UserAvatar(
                      imageUrl: profile.profilePhotoUrl,
                      name: profile.displayName,
                      size: 84,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      profile.displayName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (profile.isVerified) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Verified Provider',
                          style: TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      widget.providerId,
                      style: const TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.star,
                            size: 18, color: Colors.amber.shade700),
                        const SizedBox(width: 6),
                        Text(
                          headerRating == 0
                              ? 'No ratings yet'
                              : '${headerRating.toStringAsFixed(1)} (${profile.totalReviews})',
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _StatChip(
                          icon: Icons.assignment_turned_in_outlined,
                          text: '${profile.completedJobs} jobs done',
                        ),
                        _StatChip(
                          icon: Icons.handyman_outlined,
                          text: '${profile.activeServices} active services',
                        ),
                        if (hourlyRateText != null)
                          _StatChip(
                            icon: Icons.payments_outlined,
                            text: hourlyRateText,
                          ),
                      ],
                    ),
                  ],
                ),
                if (profile.bio.trim().isNotEmpty) ...[
                  const SizedBox(height: 22),
                  const Text(
                    'About',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    profile.bio,
                    style: const TextStyle(
                      color: AppColors.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
                if (profile.skills.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'Skills',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: profile.skills
                        .map(
                          (skill) => Chip(
                            label: Text(skill),
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.08),
                            side: BorderSide.none,
                          ),
                        )
                        .toList(),
                  ),
                ],
                if (profile.serviceCities.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  const Text(
                    'Service Cities',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    profile.serviceCities.join(', '),
                    style: const TextStyle(color: AppColors.onSurfaceVariant),
                  ),
                ],
                const SizedBox(height: 24),
                const Text(
                  'Services Offered',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                if (services.isEmpty)
                  const EmptyStateWidget(
                    title: 'No Services Yet',
                    subtitle: 'This provider has not published any services.',
                    icon: Icons.handyman_outlined,
                  )
                else
                  ...services.map(
                    (service) => Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 54,
                            height: 54,
                            color: AppColors.primary.withValues(alpha: 0.08),
                            child: _buildServiceImage(service),
                          ),
                        ),
                        title: Text(service.title),
                        subtitle: Text(
                          'Rs. ${service.minPrice} - ${service.maxPrice}',
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () =>
                            context.goToServiceDetail(service.serviceId),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                const Text(
                  'Customer Reviews',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                if (profile.reviews.isEmpty)
                  const EmptyStateWidget(
                    title: 'No Reviews Yet',
                    subtitle:
                        'Reviews will appear once customers submit feedback.',
                    icon: Icons.reviews_outlined,
                  )
                else
                  ...profile.reviews.map(
                    (review) => Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                UserAvatar(
                                  imageUrl: review.customerPhotoUrl,
                                  name: review.customerName,
                                  size: 34,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    review.customerName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: List.generate(
                                5,
                                (index) => Icon(
                                  index < review.rating
                                      ? Icons.star
                                      : Icons.star_border,
                                  size: 16,
                                  color: Colors.amber.shade700,
                                ),
                              ),
                            ),
                            if (review.comment.trim().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(review.comment),
                            ],
                          ],
                        ),
                      ),
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

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _StatChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
