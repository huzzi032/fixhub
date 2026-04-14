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

class CustomerProfileScreen extends ConsumerStatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  ConsumerState<CustomerProfileScreen> createState() =>
      _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends ConsumerState<CustomerProfileScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  UserNotificationSettings _notificationSettings =
      const UserNotificationSettings(
    bookingUpdates: true,
    promotions: true,
    neighborhoodDeals: true,
  );
  List<SavedAddress> _savedAddresses = <SavedAddress>[];
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
    final addresses =
        await LocalAuthService.instance.getSavedAddresses(user.uid);

    if (!mounted) return;
    setState(() {
      _notificationSettings = settings;
      _savedAddresses = addresses;
      _loadingExtras = false;
    });
  }

  Future<void> _addAddress() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final labelController = TextEditingController();
    final addressController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add Address'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelController,
                decoration: const InputDecoration(labelText: 'Label'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final label = labelController.text.trim();
                final address = addressController.text.trim();
                if (label.isEmpty || address.isEmpty) {
                  return;
                }

                await LocalAuthService.instance.addSavedAddress(
                  uid: user.uid,
                  label: label,
                  address: address,
                );

                if (!mounted || !dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();
                _loadExtras();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
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
            context.goToCustomerHome();
          },
        ),
        title: const Text('Profile'),
        actions: [
          IconButton(
            onPressed: () => context.goToNotifications(),
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
      ),
      body: userDataAsync.when(
        data: (userData) {
          if (userData == null) {
            return const ErrorStateWidget(message: 'User data not found');
          }

          return ListView(
            children: [
              _buildProfileHeader(context, userData),
              const Divider(),
              _buildSectionTitle(context, 'Saved Addresses'),
              if (_loadingExtras)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: AppLoadingIndicator(),
                )
              else ...[
                ..._savedAddresses.map(
                  (address) => ListTile(
                    leading: const Icon(Icons.location_on_outlined),
                    title: Text(address.label),
                    subtitle: Text(address.address),
                    trailing: IconButton(
                      onPressed: () async {
                        final user = ref.read(currentUserProvider);
                        if (user == null) return;
                        await LocalAuthService.instance.removeSavedAddress(
                          uid: user.uid,
                          addressId: address.id,
                        );
                        _loadExtras();
                      },
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.add_location_alt_outlined),
                  title: const Text('Add New Address'),
                  trailing: const Icon(Icons.add),
                  onTap: _addAddress,
                ),
              ],
              const Divider(),
              _buildSectionTitle(context, 'Notifications'),
              SwitchListTile(
                secondary: const Icon(Icons.notifications_outlined),
                title: const Text('Booking Updates'),
                subtitle: const Text('Get notified about your bookings'),
                value: _notificationSettings.bookingUpdates,
                onChanged: (value) async {
                  final user = ref.read(currentUserProvider);
                  if (user == null) return;
                  await LocalSettingsService.instance
                      .setBookingUpdates(user.uid, value);
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
                subtitle: const Text('Receive offers and discounts'),
                value: _notificationSettings.promotions,
                onChanged: (value) async {
                  final user = ref.read(currentUserProvider);
                  if (user == null) return;
                  await LocalSettingsService.instance
                      .setPromotions(user.uid, value);
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
              SwitchListTile(
                secondary: const Icon(Icons.people_outline),
                title: const Text('Neighborhood Deals'),
                subtitle: const Text('Updates about deals in your area'),
                value: _notificationSettings.neighborhoodDeals,
                onChanged: (value) async {
                  final user = ref.read(currentUserProvider);
                  if (user == null) return;
                  await LocalSettingsService.instance
                      .setNeighborhoodDeals(user.uid, value);
                  setState(() {
                    _notificationSettings = UserNotificationSettings(
                      bookingUpdates: _notificationSettings.bookingUpdates,
                      promotions: _notificationSettings.promotions,
                      neighborhoodDeals: value,
                    );
                  });
                },
              ),
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
              const SizedBox(height: 28),
              const Center(
                child: Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        },
        loading: () => const Center(child: AppLoadingIndicator()),
        error: (error, _) => ErrorStateWidget(
          message: 'Failed to load profile',
          onRetry: () => ref.refresh(currentUserDataProvider),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context, 3),
    );
  }

  Widget _buildProfileHeader(BuildContext context, UserModel userData) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Stack(
            children: [
              UserAvatar(
                imageUrl: userData.profilePhotoUrl,
                name: userData.name,
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
                    icon: const Icon(Icons.camera_alt,
                        size: 18, color: Colors.white),
                    onPressed: () => _updateProfilePhoto(userData),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            userData.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            userData.phone.isEmpty ? 'Phone not set' : userData.phone,
            style: const TextStyle(color: AppColors.onSurfaceVariant),
          ),
          if (userData.email != null && userData.email!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              userData.email!,
              style: const TextStyle(color: AppColors.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 16),
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
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
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

  Widget _buildBottomNav(BuildContext context, int currentIndex) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        switch (index) {
          case 0:
            context.goToCustomerHome();
            break;
          case 1:
            context.goToOrders();
            break;
          case 2:
            context.goToDeals();
            break;
          case 3:
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.assignment_outlined),
          activeIcon: Icon(Icons.assignment),
          label: 'My Orders',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.local_offer_outlined),
          activeIcon: Icon(Icons.local_offer),
          label: 'Deals',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
