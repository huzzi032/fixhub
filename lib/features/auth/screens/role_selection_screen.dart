import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../providers/auth_provider.dart';

class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() =>
      _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  bool _isLoading = false;

  Future<void> _selectRole(String role) async {
    setState(() {
      _isLoading = true;
    });

    try {
      var user = ref.read(currentUserProvider);
      user ??= await ref.read(authStateProvider.future);

      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get user details
      final phone = user.phoneNumber ?? '';
      final email = user.email ?? '';
      final name = user.displayName ?? '';

      // Create user document
      await ref.read(authNotifierProvider.notifier).createUserDocument(
            uid: user.uid,
            name: name.isNotEmpty ? name : 'User',
            phone: phone.isNotEmpty ? phone : '',
            email: email.isNotEmpty ? email : null,
            role: role,
          );

      if (mounted) {
        if (role == UserRoles.customer) {
          context.goToCustomerHome();
        } else if (role == UserRoles.provider) {
          context.goToProviderRegistration();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),

              // Title
              Text(
                'How would you like\nto use FixHub?',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select your role to continue',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 48),

              // Customer Option
              _RoleCard(
                icon: Icons.person_outline,
                title: 'I need services',
                subtitle:
                    'Find and book trusted professionals for your home and vehicle needs',
                onTap:
                    _isLoading ? null : () => _selectRole(UserRoles.customer),
                isLoading: _isLoading,
              ),
              const SizedBox(height: 16),

              // Provider Option
              _RoleCard(
                icon: Icons.handyman_outlined,
                title: 'I offer services',
                subtitle:
                    'Join as a service provider and grow your business with FixHub',
                onTap:
                    _isLoading ? null : () => _selectRole(UserRoles.provider),
                isLoading: _isLoading,
                isSecondary: true,
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool isSecondary;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.isLoading = false,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isSecondary ? Colors.white : AppColors.primary,
          borderRadius: BorderRadius.circular(16),
          border: isSecondary ? Border.all(color: AppColors.outline) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isSecondary
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: isLoading
                  ? Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isSecondary ? AppColors.primary : Colors.white,
                          ),
                        ),
                      ),
                    )
                  : Icon(
                      icon,
                      size: 32,
                      color: isSecondary ? AppColors.primary : Colors.white,
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSecondary ? AppColors.onSurface : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: isSecondary
                          ? AppColors.onSurfaceVariant
                          : Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            if (!isLoading)
              Icon(
                Icons.arrow_forward_ios,
                size: 20,
                color: isSecondary
                    ? AppColors.onSurfaceVariant
                    : Colors.white.withValues(alpha: 0.8),
              ),
          ],
        ),
      ),
    );
  }
}
