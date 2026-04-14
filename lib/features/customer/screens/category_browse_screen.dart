import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/database/local_marketplace_service.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/widgets.dart';

class CategoryBrowseScreen extends StatefulWidget {
  final String category;
  const CategoryBrowseScreen({super.key, required this.category});

  @override
  State<CategoryBrowseScreen> createState() => _CategoryBrowseScreenState();
}

class _CategoryBrowseScreenState extends State<CategoryBrowseScreen> {
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
          return const Icon(
            Icons.home_repair_service,
            color: AppColors.primary,
            size: 34,
          );
        }
      }
    }

    if (cover != null &&
        (cover.startsWith('http://') || cover.startsWith('https://'))) {
      return Image.network(
        cover,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.home_repair_service,
          color: AppColors.primary,
          size: 34,
        ),
      );
    }

    return const Icon(
      Icons.home_repair_service,
      color: AppColors.primary,
      size: 34,
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryKey = widget.category.trim().toLowerCase();
    final categoryLabel =
        AppConstants.categoryDisplayNames[categoryKey] ?? 'Services';

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
        title: Text(categoryLabel),
      ),
      body: FutureBuilder<List<MarketplaceServiceItem>>(
        key: ValueKey('category-services-$categoryKey-$_refreshTick'),
        future: LocalMarketplaceService.instance.getServicesByCategory(
          categoryKey,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: AppLoadingIndicator());
          }

          final services = snapshot.data ?? const <MarketplaceServiceItem>[];
          if (services.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refreshServices,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 100),
                  EmptyStateWidget(
                    title: 'No $categoryLabel Services',
                    subtitle: 'Try another category or search for a service.',
                    icon: Icons.category_outlined,
                    buttonText: 'Search Services',
                    onAction: () => context.goToSearch(),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshServices,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
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
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: double.infinity,
                            height: 140,
                            color: AppColors.primary.withValues(alpha: 0.08),
                            child: _buildServiceImage(service),
                          ),
                        ),
                        const SizedBox(height: 10),
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
                                onPressed: () => context
                                    .goToServiceDetail(service.serviceId),
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
            ),
          );
        },
      ),
    );
  }
}
