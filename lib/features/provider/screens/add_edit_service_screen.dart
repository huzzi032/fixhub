import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/database/local_marketplace_service.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../auth/providers/auth_provider.dart';

class AddEditServiceScreen extends ConsumerStatefulWidget {
  final String? serviceId;
  const AddEditServiceScreen({super.key, this.serviceId});

  @override
  ConsumerState<AddEditServiceScreen> createState() =>
      _AddEditServiceScreenState();
}

class _AddEditServiceScreenState extends ConsumerState<AddEditServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();

  String _category = AppConstants.serviceCategories.first;
  bool _isActive = true;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    if (widget.serviceId == null) {
      setState(() {
        _loading = false;
      });
      return;
    }

    final service = await LocalMarketplaceService.instance
        .getServiceById(widget.serviceId!);
    if (!mounted) return;

    if (service != null) {
      _titleController.text = service.title;
      _descriptionController.text = service.description;
      _minPriceController.text = service.minPrice.toString();
      _maxPriceController.text = service.maxPrice.toString();
      _category = service.category;
      _isActive = service.isActive;
    }

    setState(() {
      _loading = false;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final userData = ref.watch(currentUserDataProvider).asData?.value;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.serviceId == null ? 'Add Service' : 'Edit Service'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : user == null || userData == null
              ? const Center(
                  child: Text('Please sign in to manage services.'),
                )
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration:
                            const InputDecoration(labelText: 'Service Title'),
                        validator: (value) =>
                            Validators.validateServiceTitle(value ?? '')
                                .errorMessage,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        decoration:
                            const InputDecoration(labelText: 'Description'),
                        validator: (value) =>
                            Validators.validateDescription(value ?? '')
                                .errorMessage,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _category,
                        decoration:
                            const InputDecoration(labelText: 'Category'),
                        items: AppConstants.serviceCategories
                            .where((value) => value != 'other')
                            .map(
                              (category) => DropdownMenuItem<String>(
                                value: category,
                                child: Text(
                                  AppConstants.categoryDisplayNames[category] ??
                                      category,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _category = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _minPriceController,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Minimum Price'),
                        validator: (value) {
                          final number = int.tryParse(value ?? '');
                          if (number == null || number < 100) {
                            return 'Enter a valid minimum price';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _maxPriceController,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Maximum Price'),
                        validator: (value) {
                          final max = int.tryParse(value ?? '');
                          final min = int.tryParse(_minPriceController.text);

                          if (max == null || max < 100) {
                            return 'Enter a valid maximum price';
                          }

                          if (min != null && max < min) {
                            return 'Maximum price must be >= minimum price';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        value: _isActive,
                        title: const Text('Service Active'),
                        subtitle: const Text('Visible to customers in search.'),
                        onChanged: (value) {
                          setState(() {
                            _isActive = value;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _saving
                              ? null
                              : () async {
                                  if (!_formKey.currentState!.validate()) {
                                    return;
                                  }

                                  setState(() {
                                    _saving = true;
                                  });

                                  await LocalMarketplaceService.instance
                                      .saveProviderService(
                                    serviceId: widget.serviceId,
                                    providerId: user.uid,
                                    providerName: userData.name,
                                    title: _titleController.text.trim(),
                                    description:
                                        _descriptionController.text.trim(),
                                    category: _category,
                                    minPrice:
                                        int.parse(_minPriceController.text),
                                    maxPrice:
                                        int.parse(_maxPriceController.text),
                                    isActive: _isActive,
                                  );

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(widget.serviceId == null
                                            ? 'Service added successfully.'
                                            : 'Service updated successfully.'),
                                        backgroundColor: AppColors.success,
                                      ),
                                    );
                                    context.goToMyServices();
                                  }
                                },
                          child: _saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(widget.serviceId == null
                                  ? 'Create Service'
                                  : 'Update Service'),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
