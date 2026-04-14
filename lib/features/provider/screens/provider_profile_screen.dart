import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/auth/local_auth_service.dart';
import '../../../core/database/local_settings_service.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/providers/auth_provider.dart';

class ProviderProfileScreen extends ConsumerStatefulWidget {
  const ProviderProfileScreen({super.key});

  @override
  ConsumerState<ProviderProfileScreen> createState() =>
      _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends ConsumerState<ProviderProfileScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  UserNotificationSettings _notificationSettings =
      const UserNotificationSettings(
    bookingUpdates: true,
    promotions: true,
    neighborhoodDeals: true,
  );
  bool _isOnline = true;
  bool _loadingExtras = true;

  @override
  void initState() {
    super.initState();
    _loadExtras();
  }

  Future<void> _loadExtras() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      if (mounted) {
        setState(() {
          _loadingExtras = false;
        });
      }
      return;
    }

    final settings =
        await LocalSettingsService.instance.getNotificationSettings(user.uid);
    final online =
        await LocalSettingsService.instance.getProviderOnline(user.uid);

    if (!mounted) return;
    setState(() {
      _notificationSettings = settings;
      _isOnline = online;
      _loadingExtras = false;
    });
  }

  Future<void> _editProfile(UserModel userData) async {
    final nameController = TextEditingController(text: userData.name);
    final phoneController = TextEditingController(text: userData.phone);
    final emailController = TextEditingController(text: userData.email ?? '');

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final user = ref.read(currentUserProvider);
                if (user == null) return;

                await LocalAuthService.instance.updateUserProfile(
                  uid: user.uid,
                  name: nameController.text,
                  phone: phoneController.text,
                  email: emailController.text,
                );

                if (!mounted || !dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();
                ref.invalidate(currentUserDataProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile updated.')),
                );
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateProfilePhoto(UserModel userData) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      return;
    }

    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 1200,
      maxHeight: 1200,
    );

    if (picked == null) {
      return;
    }

    try {
      final bytes = await picked.readAsBytes();
      final dataUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      await LocalAuthService.instance.updateUserProfile(
        uid: user.uid,
        name: userData.name,
        phone: userData.phone,
        email: userData.email,
        profilePhotoUrl: dataUrl,
      );

      if (!mounted) return;
      ref.invalidate(currentUserDataProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo updated.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile photo: $error'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final userDataAsync = ref.watch(currentUserDataProvider);

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
        title: const Text('Provider Profile'),
        actions: [
          IconButton(
            onPressed: () => context.goToNotifications(),
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
      ),
      body: userDataAsync.when(
        data: (userData) {
          if (userData == null || user == null) {
            return const EmptyStateWidget(
              title: 'Profile Not Available',
              subtitle: 'Please sign in again.',
              icon: Icons.person_off_outlined,
            );
          }

          return ListView(
            children: [
              _buildHeader(context, userData),
              const Divider(),
              _buildSectionTitle(context, 'Availability'),
              SwitchListTile(
                secondary: const Icon(Icons.power_settings_new),
                title: Text(_isOnline ? 'Online' : 'Offline'),
                subtitle: Text(
                  _isOnline
                      ? 'You can receive and accept leads.'
                      : 'You are hidden from new lead assignments.',
                ),
                value: _isOnline,
                onChanged: (value) async {
                  await LocalSettingsService.instance
                      .setProviderOnline(user.uid, value);
                  if (!mounted) return;
                  setState(() {
                    _isOnline = value;
                  });
                },
              ),
              const Divider(),
              _buildSectionTitle(context, 'Notifications'),
              if (_loadingExtras)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: AppLoadingIndicator(),
                )
              else ...[
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_outlined),
                  title: const Text('Lead and Job Updates'),
                  value: _notificationSettings.bookingUpdates,
                  onChanged: (value) async {
                    await LocalSettingsService.instance
                        .setBookingUpdates(user.uid, value);
                    if (!mounted) return;
                    setState(() {
                      _notificationSettings = UserNotificationSettings(
                        bookingUpdates: value,
                        promotions: _notificationSettings.promotions,
                        neighborhoodDeals:
                            _notificationSettings.neighborhoodDeals,
                      );
                    });
                  },
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.local_offer_outlined),
                  title: const Text('Promotions'),
                  value: _notificationSettings.promotions,
                  onChanged: (value) async {
                    await LocalSettingsService.instance
                        .setPromotions(user.uid, value);
                    if (!mounted) return;
                    setState(() {
                      _notificationSettings = UserNotificationSettings(
                        bookingUpdates: _notificationSettings.bookingUpdates,
                        promotions: value,
                        neighborhoodDeals:
                            _notificationSettings.neighborhoodDeals,
                      );
                    });
                  },
                ),
              ],
              const Divider(),
              _buildSectionTitle(context, 'Support'),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Help & Support'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.goToSupport(),
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Privacy Policy'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.goToPrivacyPolicy(),
              ),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Terms of Service'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.goToTermsOfService(),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.error),
                title: const Text(
                  'Logout',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () => _showLogoutDialog(context, ref),
              ),
              const SizedBox(height: 20),
            ],
          );
        },
        loading: () => const Center(child: AppLoadingIndicator()),
        error: (error, _) => const ErrorStateWidget(
          message: 'Failed to load provider profile.',
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserModel userData) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Stack(
            children: [
              UserAvatar(
                name: userData.name,
                imageUrl: userData.profilePhotoUrl,
                size: 100,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.camera_alt,
                      size: 18,
                      color: Colors.white,
                    ),
                    onPressed: () => _updateProfilePhoto(userData),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            userData.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            userData.email ?? 'Email not set',
            style: const TextStyle(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _editProfile(userData),
            icon: const Icon(Icons.edit),
            label: const Text('Edit Profile'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await ref.read(authNotifierProvider.notifier).signOut();
              if (context.mounted) {
                context.goToAuth();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
