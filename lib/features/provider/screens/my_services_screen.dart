import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/local_marketplace_service.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/providers/auth_provider.dart';

class MyServicesScreen extends ConsumerStatefulWidget {
  const MyServicesScreen({super.key});

  @override
  ConsumerState<MyServicesScreen> createState() => _MyServicesScreenState();
}

class _MyServicesScreenState extends ConsumerState<MyServicesScreen> {
  int _refreshTick = 0;

  Future<void> _refreshServices() async {
    if (!mounted) return;
    setState(() {
      _refreshTick++;
    });
  }

  Widget _buildServiceThumb(MarketplaceServiceItem service) {
    final cover = service.coverImageUrl;
    if (cover == null) {
      return Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.home_repair_service, color: AppColors.primary),
      );
    }

    if (cover.startsWith('data:image')) {
      final commaIndex = cover.indexOf(',');
      if (commaIndex > 0 && commaIndex < cover.length - 1) {
        try {
          final bytes = base64Decode(cover.substring(commaIndex + 1));
          return ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 64,
              height: 64,
              child: Image.memory(bytes, fit: BoxFit.cover),
            ),
          );
        } catch (_) {}
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 64,
        height: 64,
        child: Image.network(
          cover,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: AppColors.primary.withValues(alpha: 0.1),
            child:
                const Icon(Icons.home_repair_service, color: AppColors.primary),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteService(MarketplaceServiceItem service) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Service'),
        content: Text('Delete "${service.title}" permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) {
      return;
    }

    await LocalMarketplaceService.instance.deleteService(service.serviceId);
    if (!mounted) return;

    setState(() {
      _refreshTick++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
              return;
            }
            context.goToProviderDashboard();
          },
        ),
        title: const Text('My Services'),
        actions: [
          IconButton(
            onPressed: () => context.goToAddService(),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: user == null
          ? const EmptyStateWidget(
              title: 'Sign In Required',
              subtitle: 'Please sign in as provider to manage services.',
              icon: Icons.lock_outline,
            )
          : FutureBuilder<List<MarketplaceServiceItem>>(
              key: ValueKey<int>(_refreshTick),
              future: LocalMarketplaceService.instance
                  .getProviderServices(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: AppLoadingIndicator());
                }

                final services =
                    snapshot.data ?? const <MarketplaceServiceItem>[];
                if (services.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _refreshServices,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 90),
                        EmptyStateWidget(
                          title: 'No Services Added',
                          subtitle:
                              'Create your first service to start receiving leads.',
                          icon: Icons.handyman_outlined,
                          buttonText: 'Add Service',
                          onAction: () => context.goToAddService(),
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
                              Row(
                                children: [
                                  _buildServiceThumb(service),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      service.title,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Switch(
                                    value: service.isActive,
                                    onChanged: (value) async {
                                      await LocalMarketplaceService.instance
                                          .setServiceActive(
                                              service.serviceId, value);
                                      if (!mounted) return;
                                      setState(() {
                                        _refreshTick++;
                                      });
                                    },
                                  ),
                                ],
                              ),
                              Text(
                                service.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      service.categoryLabel,
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
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
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () => context
                                        .goToEditService(service.serviceId),
                                    icon: const Icon(Icons.edit_outlined),
                                    label: const Text('Edit'),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      final id = service.serviceId.trim();
                                      if (id.isEmpty) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Service analytics is unavailable for this item.',
                                            ),
                                          ),
                                        );
                                        return;
                                      }
                                      context.goToServiceAnalytics(id);
                                    },
                                    icon: const Icon(Icons.analytics_outlined),
                                    label: const Text('Analytics'),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () => _deleteService(service),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.error,
                                      foregroundColor: Colors.white,
                                    ),
                                    icon: const Icon(Icons.delete_outline),
                                    label: const Text('Delete'),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.goToAddService(),
        icon: const Icon(Icons.add),
        label: const Text('Add Service'),
      ),
    );
  }
}
