import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/database/local_marketplace_service.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/widgets.dart';

class CategoryBrowseScreen extends StatelessWidget {
  final String category;
  const CategoryBrowseScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final categoryKey = category.trim().toLowerCase();
    final categoryLabel =
        AppConstants.categoryDisplayNames[categoryKey] ?? 'Services';

    return Scaffold(
      appBar: AppBar(title: Text(categoryLabel)),
      body: FutureBuilder<List<MarketplaceServiceItem>>(
        future: LocalMarketplaceService.instance.getServicesByCategory(
          categoryKey,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: AppLoadingIndicator());
          }

          final services = snapshot.data ?? const <MarketplaceServiceItem>[];
          if (services.isEmpty) {
            return EmptyStateWidget(
              title: 'No $categoryLabel Services',
              subtitle: 'Try another category or search for a service.',
              icon: Icons.category_outlined,
              buttonText: 'Search Services',
              onAction: () => context.goToSearch(),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'By ${service.providerName}',
                        style: const TextStyle(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.amber.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${service.rating.toStringAsFixed(1)} (${service.reviewCount})',
                            style: const TextStyle(fontSize: 13),
                          ),
                          const Spacer(),
                          Text(
                            'Rs. ${service.minPrice} - ${service.maxPrice}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  context.goToServiceDetail(service.serviceId),
                              child: const Text('View Details'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => context.goToBookingForm(
                                serviceId: service.serviceId,
                                category: service.category,
                              ),
                              child: const Text('Book Now'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
