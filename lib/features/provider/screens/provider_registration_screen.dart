import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/database/app_database.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';

class ProviderRegistrationScreen extends ConsumerStatefulWidget {
  const ProviderRegistrationScreen({super.key});

  @override
  ConsumerState<ProviderRegistrationScreen> createState() =>
      _ProviderRegistrationScreenState();
}

class _ProviderRegistrationScreenState
    extends ConsumerState<ProviderRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bioController = TextEditingController();
  final _skillsController = TextEditingController();
  final _hourlyRateController = TextEditingController();

  String _city = AppConstants.pakistaniCities.first;
  bool _submitting = false;

  @override
  void dispose() {
    _bioController.dispose();
    _skillsController.dispose();
    _hourlyRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Provider Registration')),
      body: user == null
          ? const Center(child: Text('Please sign in first.'))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Complete your provider profile to start receiving leads.',
                    style: TextStyle(color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _city,
                    decoration:
                        const InputDecoration(labelText: 'Primary City'),
                    items: AppConstants.pakistaniCities
                        .take(15)
                        .map(
                          (city) => DropdownMenuItem<String>(
                            value: city,
                            child: Text(city),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _city = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _skillsController,
                    decoration: const InputDecoration(
                      labelText: 'Skills',
                      hintText: 'Example: Plumbing, Leak repair, Fittings',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().length < 5) {
                        return 'Please enter your core skills';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _hourlyRateController,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Hourly Rate (Rs.)'),
                    validator: (value) {
                      final amount = int.tryParse(value ?? '');
                      if (amount == null || amount < 100) {
                        return 'Enter a valid hourly rate';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _bioController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Bio',
                      hintText: 'Tell customers about your experience',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().length < 20) {
                        return 'Bio should be at least 20 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _submitting
                          ? null
                          : () async {
                              if (!_formKey.currentState!.validate()) {
                                return;
                              }

                              setState(() {
                                _submitting = true;
                              });

                              final db = await AppDatabase.instance.database;
                              final now = DateTime.now().millisecondsSinceEpoch;

                              await db.insert(
                                'providers',
                                <String, Object?>{
                                  'user_id': user.uid,
                                  'verification_status': 'pending',
                                  'wallet_balance': 0,
                                  'earnings_total': 0,
                                  'joined_at': now,
                                },
                                conflictAlgorithm: ConflictAlgorithm.ignore,
                              );

                              await db.update(
                                'providers',
                                <String, Object?>{
                                  'verification_status': 'pending',
                                },
                                where: 'user_id = ?',
                                whereArgs: <Object>[user.uid],
                              );

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Registration submitted.'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                                context.goToPendingApproval();
                              }
                            },
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Submit for Verification'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
