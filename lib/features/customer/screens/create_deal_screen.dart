import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/database/local_marketplace_service.dart';
import '../../../core/router/app_router.dart';
import '../../auth/providers/auth_provider.dart';

class CreateDealScreen extends ConsumerStatefulWidget {
  const CreateDealScreen({super.key});

  @override
  ConsumerState<CreateDealScreen> createState() => _CreateDealScreenState();
}

class _CreateDealScreenState extends ConsumerState<CreateDealScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _cityController =
      TextEditingController(text: 'Karachi');
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _minParticipantsController =
      TextEditingController(text: '8');
  final TextEditingController _discountController =
      TextEditingController(text: '15');

  String _category = 'plumber';
  int _expiryDays = 7;
  bool _submitting = false;

  @override
  void dispose() {
    _areaController.dispose();
    _cityController.dispose();
    _descriptionController.dispose();
    _minParticipantsController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final currentUserData = ref.watch(currentUserDataProvider).asData?.value;
    final isProvider = currentUserData?.role == 'provider';

    return Scaffold(
      appBar: AppBar(title: const Text('Create Neighborhood Deal')),
      body: currentUser == null
          ? const Center(child: Text('Please sign in first.'))
          : !isProvider
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Only providers can create neighborhood deals. Customers can join available deals from the deals portal.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _category,
                        decoration: const InputDecoration(
                            labelText: 'Service Category'),
                        items: AppConstants.serviceCategories
                            .where((category) => category != 'other')
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
                        controller: _areaController,
                        decoration: const InputDecoration(labelText: 'Area'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Area is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _cityController,
                        decoration: const InputDecoration(labelText: 'City'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'City is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Deal Description',
                          hintText:
                              'Example: Group AC servicing discount for our street',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().length < 10) {
                            return 'Please enter a meaningful description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _minParticipantsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Minimum Participants'),
                        validator: (value) {
                          final number = int.tryParse(value ?? '');
                          if (number == null || number < 2) {
                            return 'Minimum 2 participants required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _discountController,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Discount %'),
                        validator: (value) {
                          final number = int.tryParse(value ?? '');
                          if (number == null || number < 5 || number > 80) {
                            return 'Discount must be between 5 and 80';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        initialValue: _expiryDays,
                        decoration:
                            const InputDecoration(labelText: 'Expires In'),
                        items: AppConstants.dealExpiryChoices
                            .map(
                              (days) => DropdownMenuItem<int>(
                                value: days,
                                child: Text('$days days'),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _expiryDays = value;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _submitting
                              ? null
                              : () async {
                                  if (!_formKey.currentState!.validate()) {
                                    return;
                                  }

                                  final user = ref.read(currentUserProvider);
                                  final userData = ref
                                      .read(currentUserDataProvider)
                                      .asData
                                      ?.value;
                                  if (user == null || userData == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content:
                                              Text('Please sign in first.')),
                                    );
                                    return;
                                  }

                                  if (userData.role != 'provider') {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Only providers can create deals.'),
                                      ),
                                    );
                                    return;
                                  }

                                  setState(() {
                                    _submitting = true;
                                  });

                                  await LocalMarketplaceService.instance
                                      .createDeal(
                                    createdBy: user.uid,
                                    serviceCategory: _category,
                                    area: _areaController.text.trim(),
                                    city: _cityController.text.trim(),
                                    description:
                                        _descriptionController.text.trim(),
                                    minParticipants: int.parse(
                                        _minParticipantsController.text),
                                    discountPercent:
                                        int.parse(_discountController.text),
                                    expiryDays: _expiryDays,
                                  );

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text('Deal created successfully.'),
                                      ),
                                    );
                                    context.goToProviderDashboard();
                                  }
                                },
                          child: _submitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Publish Deal'),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
