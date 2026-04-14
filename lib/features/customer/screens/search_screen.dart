import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/local_marketplace_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/widgets.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final List<String> _recentSearches = [
    'Plumber',
    'AC Repair',
    'Electrician near me',
  ];

  // Filter states
  final Set<String> _selectedCategories = {};
  RangeValues _priceRange = const RangeValues(0, 5000);
  double _minRating = 0;
  String _sortBy = 'nearest';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _FilterSheet(
        selectedCategories: _selectedCategories,
        priceRange: _priceRange,
        minRating: _minRating,
        sortBy: _sortBy,
        onApply: (categories, priceRange, rating, sortBy) {
          setState(() {
            _selectedCategories.clear();
            _selectedCategories.addAll(categories);
            _priceRange = priceRange;
            _minRating = rating;
            _sortBy = sortBy;
          });
          Navigator.pop(context);
        },
      ),
    );
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
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search services...',
            border: InputBorder.none,
            hintStyle: const TextStyle(
              color: AppColors.onSurfaceVariant,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  )
                : null,
          ),
          onChanged: (value) {
            setState(() {});
          },
          onSubmitted: (value) {
            // Perform search
          },
        ),
        actions: [
          IconButton(
            onPressed: _showFilterSheet,
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: _searchController.text.isEmpty
          ? _buildRecentSearches()
          : _buildSearchResults(),
    );
  }

  Widget _buildRecentSearches() {
    return ListView(
      padding: const EdgeInsets.only(bottom: 20),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Searches',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _recentSearches.clear();
                  });
                },
                child: const Text('Clear'),
              ),
            ],
          ),
        ),
        ..._recentSearches.map((search) {
          return ListTile(
            leading: const Icon(Icons.history),
            title: Text(search),
            trailing: const Icon(Icons.north_west),
            onTap: () {
              _searchController.text = search;
              setState(() {});
            },
          );
        }),
        const Divider(),
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Popular Services',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'Plumber',
              'Electrician',
              'AC Repair',
              'Car Mechanic',
              'Carpenter',
              'Painter',
              'Cleaning',
            ].map((service) {
              return ActionChip(
                label: Text(service),
                onPressed: () {
                  _searchController.text = service;
                  setState(() {});
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    return FutureBuilder<List<MarketplaceServiceItem>>(
      future: LocalMarketplaceService.instance.searchServices(
        query: _searchController.text,
        categories: _selectedCategories,
        minPrice: _priceRange.start.round(),
        maxPrice: _priceRange.end.round(),
        minRating: _minRating,
        sortBy: _sortBy,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: AppLoadingIndicator());
        }

        final results = snapshot.data ?? const <MarketplaceServiceItem>[];

        if (results.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: EmptyStateWidget(
              title: 'No Services Found',
              subtitle: 'Try changing your search or filters.',
              icon: Icons.search_off,
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final service = results[index];
            return _ServiceResultCard(
              service: service,
              onTap: () => context.goToServiceDetail(service.serviceId),
            );
          },
        );
      },
    );
  }
}

class _ServiceResultCard extends StatelessWidget {
  final MarketplaceServiceItem service;
  final VoidCallback? onTap;

  const _ServiceResultCard({required this.service, this.onTap});

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    final cover = service.coverImageUrl;
    if (cover != null && cover.startsWith('data:image')) {
      final commaIndex = cover.indexOf(',');
      if (commaIndex > 0 && commaIndex < cover.length - 1) {
        try {
          imageWidget = Image.memory(
            base64Decode(cover.substring(commaIndex + 1)),
            fit: BoxFit.cover,
          );
        } catch (_) {
          imageWidget =
              const Icon(Icons.home_repair_service, color: AppColors.primary);
        }
      } else {
        imageWidget =
            const Icon(Icons.home_repair_service, color: AppColors.primary);
      }
    } else if (cover != null &&
        (cover.startsWith('http://') || cover.startsWith('https://'))) {
      imageWidget = Image.network(
        cover,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.home_repair_service, color: AppColors.primary),
      );
    } else {
      imageWidget =
          const Icon(Icons.home_repair_service, color: AppColors.primary);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Service Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 80,
                  height: 80,
                  color: AppColors.primary.withValues(alpha: 0.1),
                  child: imageWidget,
                ),
              ),
              const SizedBox(width: 12),

              // Service Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Provider Row
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () =>
                                context.goToProviderProfile(service.providerId),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  UserAvatar(
                                    name: service.providerName,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      service.providerName,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              context.goToProviderProfile(service.providerId),
                          child: const Text('Profile'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Title
                    Text(
                      service.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Rating and Price
                    Row(
                      children: [
                        RatingStars(rating: service.rating),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            service.categoryLabel,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Price
                    Text(
                      'Rs. ${service.minPrice} - ${service.maxPrice}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final Set<String> selectedCategories;
  final RangeValues priceRange;
  final double minRating;
  final String sortBy;
  final Function(Set<String>, RangeValues, double, String) onApply;

  const _FilterSheet({
    required this.selectedCategories,
    required this.priceRange,
    required this.minRating,
    required this.sortBy,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late Set<String> _categories;
  late RangeValues _priceRange;
  late double _minRating;
  late String _sortBy;

  final List<String> _allCategories = AppConstants.serviceCategories
      .where((category) => category != 'other')
      .toList();

  @override
  void initState() {
    super.initState();
    _categories = Set.from(widget.selectedCategories);
    _priceRange = widget.priceRange;
    _minRating = widget.minRating;
    _sortBy = widget.sortBy;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filters',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _categories.clear();
                        _priceRange = const RangeValues(0, 5000);
                        _minRating = 0;
                        _sortBy = 'nearest';
                      });
                    },
                    child: const Text('Reset'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    // Categories
                    const Text(
                      'Categories',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _allCategories.map((category) {
                        final isSelected = _categories.contains(category);
                        return FilterChip(
                          label: Text(
                            AppConstants.categoryDisplayNames[category] ??
                                category,
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _categories.add(category);
                              } else {
                                _categories.remove(category);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Price Range
                    const Text(
                      'Price Range',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    RangeSlider(
                      values: _priceRange,
                      min: 0,
                      max: 5000,
                      divisions: 10,
                      labels: RangeLabels(
                        'Rs. ${_priceRange.start.round()}',
                        'Rs. ${_priceRange.end.round()}',
                      ),
                      onChanged: (values) {
                        setState(() {
                          _priceRange = values;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Rating Filter
                    const Text(
                      'Minimum Rating',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [0, 3, 4, 5].map((rating) {
                        return ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (rating > 0) ...[
                                const Icon(
                                  Icons.star,
                                  size: 16,
                                  color: AppColors.warning,
                                ),
                                const SizedBox(width: 4),
                              ],
                              Text(rating > 0 ? '$rating+' : 'Any'),
                            ],
                          ),
                          selected: _minRating == rating.toDouble(),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _minRating = rating.toDouble();
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Sort By
                    const Text(
                      'Sort By',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    RadioGroup<String>(
                      groupValue: _sortBy,
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _sortBy = value;
                        });
                      },
                      child: Column(
                        children: [
                          {'value': 'nearest', 'label': 'Nearest'},
                          {'value': 'rating', 'label': 'Highest Rated'},
                          {'value': 'price_low', 'label': 'Lowest Price'},
                        ].map((option) {
                          return RadioListTile<String>(
                            title: Text(option['label']!),
                            value: option['value']!,
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              // Apply Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(
                        _categories, _priceRange, _minRating, _sortBy);
                  },
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
