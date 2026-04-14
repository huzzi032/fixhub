import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/database/local_marketplace_service.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/widgets.dart';

class ServiceDetailScreen extends StatelessWidget {
  final String serviceId;
  const ServiceDetailScreen({super.key, required this.serviceId});

  Widget _buildHeroImage(MarketplaceServiceItem service) {
    final cover = service.coverImageUrl;

    if (cover == null) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.primary.withValues(alpha: 0.1),
        ),
        child: const Icon(
          Icons.home_repair_service,
          size: 64,
          color: AppColors.primary,
        ),
      );
    }

    if (cover.startsWith('data:image')) {
      final commaIndex = cover.indexOf(',');
      if (commaIndex > 0 && commaIndex < cover.length - 1) {
        try {
          final raw = cover.substring(commaIndex + 1);
          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 220,
              width: double.infinity,
              child: Image.memory(base64Decode(raw), fit: BoxFit.cover),
            ),
          );
        } catch (_) {}
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 220,
        width: double.infinity,
        child: Image.network(
          cover,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: AppColors.primary.withValues(alpha: 0.1),
            child: const Icon(
              Icons.home_repair_service,
              size: 64,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Service Details')),
      body: FutureBuilder<MarketplaceServiceItem?>(
        future: LocalMarketplaceService.instance.getServiceById(serviceId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: AppLoadingIndicator());
          }

          final service = snapshot.data;
          if (service == null) {
            return EmptyStateWidget(
              title: 'Service Not Found',
              subtitle: 'This service may have been removed.',
              icon: Icons.error_outline,
              buttonText: 'Back to Search',
              onAction: () => context.goToSearch(),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHeroImage(service),
              const SizedBox(height: 16),
              Text(
                service.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 18),
                  const SizedBox(width: 6),
                  Text(service.providerName),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber.shade700, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    '${service.rating.toStringAsFixed(1)} (${service.reviewCount} reviews)',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                service.description,
                style: const TextStyle(
                  color: AppColors.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Price Range',
                      style: TextStyle(fontWeight: FontWeight.w600),
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
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          context.goToProviderProfile(service.providerId),
                      icon: const Icon(Icons.person),
                      label: const Text('Provider'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context.goToBookingForm(
                        serviceId: service.serviceId,
                        category: service.category,
                      ),
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: const Text('Book Now'),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
