import 'package:flutter/material.dart';

import '../../../core/database/local_marketplace_service.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/widgets.dart';

class ProviderPublicProfileScreen extends StatelessWidget {
  final String providerId;
  const ProviderPublicProfileScreen({super.key, required this.providerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Provider Profile')),
      body: FutureBuilder<List<MarketplaceServiceItem>>(
        future:
            LocalMarketplaceService.instance.getProviderServices(providerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: AppLoadingIndicator());
          }

          final services = snapshot.data ?? const <MarketplaceServiceItem>[];
          final displayName =
              services.isNotEmpty ? services.first.providerName : 'Provider';
          final rating = services.isEmpty
              ? 0.0
              : services
                      .map((service) => service.rating)
                      .fold<double>(0.0, (a, b) => a + b) /
                  services.length;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Column(
                children: [
                  const UserAvatar(name: 'Provider', size: 84),
                  const SizedBox(height: 12),
                  Text(
                    displayName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    providerId,
                    style: const TextStyle(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star, size: 18, color: Colors.amber.shade700),
                      const SizedBox(width: 6),
                      Text(
                        rating == 0
                            ? 'No ratings yet'
                            : rating.toStringAsFixed(1),
                      ),
                    ],
                  ),
                ],
              ),
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
                      title: Text(service.title),
                      subtitle: Text(
                        'Rs. ${service.minPrice} - ${service.maxPrice}',
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => context.goToServiceDetail(service.serviceId),
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
