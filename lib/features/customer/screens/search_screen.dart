import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final List<_SearchService> _allServices = const [
    _SearchService(
      id: 'service_plumber_1',
      providerName: 'Ali Khan',
      title: 'Professional Plumbing Services',
      category: 'Plumber',
      minPrice: 500,
      maxPrice: 2000,
      rating: 4.5,
    ),
    _SearchService(
      id: 'service_electrician_1',
      providerName: 'Usman Raza',
      title: 'Home Electrical Repair',
      category: 'Electrician',
      minPrice: 700,
      maxPrice: 3000,
      rating: 4.7,
    ),
    _SearchService(
      id: 'service_ac_1',
      providerName: 'Hamza Arif',
      title: 'AC Repair and Gas Refill',
      category: 'AC Repair',
      minPrice: 1200,
      maxPrice: 4500,
      rating: 4.3,
    ),
    _SearchService(
      id: 'service_cleaning_1',
      providerName: 'Sara Services',
      title: 'Deep Cleaning for Home',
      category: 'Cleaning',
      minPrice: 1500,
      maxPrice: 5000,
      rating: 4.8,
    ),
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

  List<_SearchService> get _filteredServices {
    final query = _searchController.text.trim().toLowerCase();

    final filtered = _allServices.where((service) {
      final queryMatches = query.isEmpty ||
          service.title.toLowerCase().contains(query) ||
          service.providerName.toLowerCase().contains(query) ||
          service.category.toLowerCase().contains(query);

      final categoryMatches = _selectedCategories.isEmpty ||
          _selectedCategories.contains(service.category);

      final priceMatches = service.minPrice <= _priceRange.end &&
          service.maxPrice >= _priceRange.start;

      final ratingMatches = service.rating >= _minRating;

      return queryMatches && categoryMatches && priceMatches && ratingMatches;
    }).toList();

    switch (_sortBy) {
      case 'rating':
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'price_low':
        filtered.sort((a, b) => a.minPrice.compareTo(b.minPrice));
        break;
      case 'price_high':
        filtered.sort((a, b) => b.maxPrice.compareTo(a.maxPrice));
        break;
      case 'nearest':
      default:
        break;
    }

    return filtered;
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
    final results = _filteredServices;

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
          onTap: () {
            context.goToServiceDetail(service.id);
          },
        );
      },
    );
  }
}

class _ServiceResultCard extends StatelessWidget {
  final _SearchService service;
  final VoidCallback? onTap;

  const _ServiceResultCard({required this.service, this.onTap});

  @override
  Widget build(BuildContext context) {
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
                  child: const Icon(
                    Icons.plumbing,
                    color: AppColors.primary,
                  ),
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
                        UserAvatar(
                          name: service.providerName,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          service.providerName,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
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
                            service.category,
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

class _SearchService {
  final String id;
  final String providerName;
  final String title;
  final String category;
  final int minPrice;
  final int maxPrice;
  final double rating;

  const _SearchService({
    required this.id,
    required this.providerName,
    required this.title,
    required this.category,
    required this.minPrice,
    required this.maxPrice,
    required this.rating,
  });
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

  final List<String> _allCategories = [
    'Plumber',
    'Electrician',
    'Carpenter',
    'Painter',
    'Car Mechanic',
    'AC Repair',
    'Cleaning',
  ];

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
                          label: Text(category),
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
