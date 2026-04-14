import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

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
  final ImagePicker _imagePicker = ImagePicker();

  String _category = AppConstants.serviceCategories.first;
  List<String> _imageUrls = <String>[];
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
      _imageUrls = List<String>.from(service.imageUrls);
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

  Future<void> _pickImages() async {
    final picked = await _imagePicker.pickMultiImage(
      imageQuality: 70,
      maxHeight: 1280,
      maxWidth: 1280,
    );

    if (picked.isEmpty) {
      return;
    }

    final next = List<String>.from(_imageUrls);
    var overflowed = false;

    for (final file in picked) {
      if (next.length >= 3) {
        overflowed = true;
        break;
      }

      final bytes = await file.readAsBytes();
      final dataUrl = _toDataUrl(bytes);
      next.add(dataUrl);
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _imageUrls = next;
    });

    if (overflowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 3 service images are allowed.'),
        ),
      );
    }
  }

  String _toDataUrl(Uint8List bytes) {
    final base64 = base64Encode(bytes);
    return 'data:image/jpeg;base64,$base64';
  }

  Widget _buildImagePreview(String imageUrl) {
    if (imageUrl.startsWith('data:image')) {
      final commaIndex = imageUrl.indexOf(',');
      if (commaIndex > 0 && commaIndex < imageUrl.length - 1) {
        try {
          final raw = imageUrl.substring(commaIndex + 1);
          return Image.memory(
            base64Decode(raw),
            fit: BoxFit.cover,
          );
        } catch (_) {
          // Fall back to placeholder below.
        }
      }
    }

    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
      );
    }

    return const Icon(Icons.image_not_supported);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final userData = ref.watch(currentUserDataProvider).asData?.value;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
              return;
            }
            context.goToMyServices();
          },
        ),
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
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Service Images',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _pickImages,
                            icon:
                                const Icon(Icons.add_photo_alternate_outlined),
                            label: const Text('Add'),
                          ),
                        ],
                      ),
                      if (_imageUrls.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.outline),
                          ),
                          child: const Text(
                            'No images selected. Adding images improves conversion in search results.',
                            style: TextStyle(color: AppColors.onSurfaceVariant),
                          ),
                        )
                      else
                        SizedBox(
                          height: 96,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _imageUrls.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 10),
                            itemBuilder: (context, index) {
                              final image = _imageUrls[index];
                              return Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: SizedBox(
                                      width: 120,
                                      height: 96,
                                      child: _buildImagePreview(image),
                                    ),
                                  ),
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          _imageUrls.removeAt(index);
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.black
                                              .withValues(alpha: 0.6),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
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
                                    imageUrls: _imageUrls,
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
