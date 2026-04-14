import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/auth_landing_screen.dart';
import '../../features/auth/screens/email_signin_screen.dart';
import '../../features/auth/screens/email_signup_screen.dart';
import '../../features/auth/screens/role_selection_screen.dart';
import '../../features/customer/screens/home_dashboard_screen.dart';
import '../../features/customer/screens/search_screen.dart';
import '../../features/customer/screens/category_browse_screen.dart';
import '../../features/customer/screens/service_detail_screen.dart';
import '../../features/customer/screens/provider_public_profile_screen.dart';
import '../../features/customer/screens/booking_form_screen.dart';
import '../../features/customer/screens/booking_submitted_screen.dart';
import '../../features/customer/screens/provider_accepted_view_screen.dart';
import '../../features/customer/screens/active_job_tracking_screen.dart';
import '../../features/customer/screens/payment_confirmation_screen.dart';
import '../../features/customer/screens/review_rating_screen.dart';
import '../../features/customer/screens/my_orders_screen.dart';
import '../../features/customer/screens/booking_detail_screen.dart';
import '../../features/customer/screens/sos_emergency_screen.dart';
import '../../features/customer/screens/neighborhood_deals_screen.dart';
import '../../features/customer/screens/create_deal_screen.dart';
import '../../features/customer/screens/dispute_screen.dart';
import '../../features/customer/screens/customer_profile_screen.dart';
import '../../features/provider/screens/provider_registration_screen.dart';
import '../../features/provider/screens/pending_approval_screen.dart';
import '../../features/provider/screens/provider_dashboard_screen.dart';
import '../../features/provider/screens/provider_sos_requests_screen.dart';
import '../../features/provider/screens/my_services_screen.dart';
import '../../features/provider/screens/add_edit_service_screen.dart';
import '../../features/provider/screens/service_analytics_screen.dart';
import '../../features/provider/screens/lead_detail_screen.dart';
import '../../features/provider/screens/quote_submission_screen.dart';
import '../../features/provider/screens/active_job_screen.dart';
import '../../features/provider/screens/payment_received_screen.dart';
import '../../features/provider/screens/my_jobs_screen.dart';
import '../../features/provider/screens/job_detail_screen.dart';
import '../../features/provider/screens/lead_wallet_screen.dart';
import '../../features/provider/screens/earnings_screen.dart';
import '../../features/provider/screens/provider_profile_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/admin/screens/provider_verification_queue_screen.dart';
import '../../features/admin/screens/dispute_management_screen.dart';
import '../../features/admin/screens/topup_approval_screen.dart';
import '../../features/admin/screens/platform_overview_screen.dart';
import '../../features/common/screens/notifications_screen.dart';
import '../../features/common/screens/support_screen.dart';
import '../../features/common/screens/privacy_policy_screen.dart';
import '../../features/common/screens/terms_of_service_screen.dart';
import '../../features/common/screens/booking_chat_screen.dart';
import '../constants/app_constants.dart';

String? _queryParam(GoRouterState state, String key) {
  final value = state.uri.queryParameters[key]?.trim();
  if (value == null || value.isEmpty) {
    return null;
  }
  return value;
}

Widget _invalidRoutePage(String message) {
  return Scaffold(
    appBar: AppBar(title: const Text('Invalid Link')),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.onSurfaceVariant),
        ),
      ),
    ),
  );
}

// Router Provider
final routerProvider = Provider<GoRouter>((ref) {
  final authStateAsync = ref.watch(authStateProvider);
  final currentUserDataAsync = ref.watch(currentUserDataProvider);

  final isAuthenticated = authStateAsync.asData?.value != null;
  final userRole = currentUserDataAsync.asData?.value?.role;
  final isLoadingAuth = authStateAsync.isLoading ||
      (isAuthenticated && currentUserDataAsync.isLoading);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      if (isLoadingAuth) {
        return null;
      }

      final isLoggingIn = state.matchedLocation.startsWith('/auth') ||
          state.matchedLocation == '/onboarding' ||
          state.matchedLocation == '/';

      // Not authenticated, allow access to auth screens
      if (!isAuthenticated) {
        if (isLoggingIn) return null;
        return '/';
      }

      // Authenticated but no role selected
      if (userRole == null) {
        if (state.matchedLocation == '/role-selection') return null;
        return '/role-selection';
      }

      if (state.matchedLocation == '/customer/deals/create') {
        if (userRole == UserRoles.provider) {
          return '/provider/deals/create';
        }
        return '/customer/deals';
      }

      if (state.matchedLocation.startsWith('/customer') &&
          userRole != UserRoles.customer) {
        if (userRole == UserRoles.provider) {
          return '/provider/dashboard';
        }
        if (userRole == UserRoles.admin) {
          return '/admin/dashboard';
        }
      }

      if (state.matchedLocation.startsWith('/provider') &&
          userRole != UserRoles.provider) {
        if (userRole == UserRoles.customer) {
          return '/customer/home';
        }
        if (userRole == UserRoles.admin) {
          return '/admin/dashboard';
        }
      }

      if (state.matchedLocation.startsWith('/admin') &&
          userRole != UserRoles.admin) {
        if (userRole == UserRoles.customer) {
          return '/customer/home';
        }
        if (userRole == UserRoles.provider) {
          return '/provider/dashboard';
        }
      }

      // Authenticated with role, redirect to appropriate dashboard
      if (isLoggingIn) {
        switch (userRole) {
          case UserRoles.customer:
            return '/customer/home';
          case UserRoles.provider:
            return '/provider/dashboard';
          case UserRoles.admin:
            return '/admin/dashboard';
          default:
            return '/role-selection';
        }
      }

      return null;
    },
    routes: [
      // Splash & Onboarding
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Auth Routes
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthLandingScreen(),
      ),
      GoRoute(
        path: '/auth/email-signin',
        builder: (context, state) => const EmailSignInScreen(),
      ),
      GoRoute(
        path: '/auth/email-signup',
        builder: (context, state) => const EmailSignUpScreen(),
      ),
      GoRoute(
        path: '/role-selection',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/support',
        builder: (context, state) => const SupportScreen(),
      ),
      GoRoute(
        path: '/privacy-policy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/terms-of-service',
        builder: (context, state) => const TermsOfServiceScreen(),
      ),

      // Provider Registration
      GoRoute(
        path: '/provider/registration',
        builder: (context, state) => const ProviderRegistrationScreen(),
      ),
      GoRoute(
        path: '/provider/pending',
        builder: (context, state) => const PendingApprovalScreen(),
      ),

      // Customer Routes
      GoRoute(
        path: '/customer/home',
        builder: (context, state) => const HomeDashboardScreen(),
      ),
      GoRoute(
        path: '/customer/search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/customer/category/:category',
        builder: (context, state) {
          final category = state.pathParameters['category']!;
          return CategoryBrowseScreen(category: category);
        },
      ),
      GoRoute(
        path: '/customer/service/:serviceId',
        builder: (context, state) {
          final serviceId = state.pathParameters['serviceId']!;
          return ServiceDetailScreen(serviceId: serviceId);
        },
      ),
      GoRoute(
        path: '/customer/provider/:providerId',
        builder: (context, state) {
          final providerId = state.pathParameters['providerId']!;
          return ProviderPublicProfileScreen(providerId: providerId);
        },
      ),
      GoRoute(
        path: '/customer/booking/form',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return BookingFormScreen(
            serviceId: extra?['serviceId'],
            category: extra?['category'],
          );
        },
      ),
      GoRoute(
        path: '/customer/booking/submitted',
        builder: (context, state) {
          final bookingId = _queryParam(state, 'bookingId');
          if (bookingId == null) {
            return _invalidRoutePage(
              'Booking link is incomplete. Please open this booking from My Orders.',
            );
          }
          return BookingSubmittedScreen(bookingId: bookingId);
        },
      ),
      GoRoute(
        path: '/customer/booking/accepted',
        builder: (context, state) {
          final bookingId = _queryParam(state, 'bookingId');
          if (bookingId == null) {
            return _invalidRoutePage(
              'Accepted booking link is missing booking details.',
            );
          }
          return ProviderAcceptedViewScreen(bookingId: bookingId);
        },
      ),
      GoRoute(
        path: '/customer/booking/track',
        builder: (context, state) {
          final bookingId = _queryParam(state, 'bookingId');
          if (bookingId == null) {
            return _invalidRoutePage(
              'Tracking link is invalid. Please retry from your booking details.',
            );
          }
          return ActiveJobTrackingScreen(bookingId: bookingId);
        },
      ),
      GoRoute(
        path: '/customer/booking/payment',
        builder: (context, state) {
          final bookingId = _queryParam(state, 'bookingId');
          if (bookingId == null) {
            return _invalidRoutePage(
              'Payment link is invalid. Please open payment from booking details.',
            );
          }
          return PaymentConfirmationScreen(bookingId: bookingId);
        },
      ),
      GoRoute(
        path: '/customer/booking/review',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is! Map<String, dynamic>) {
            return _invalidRoutePage(
              'Review link is invalid. Please open review from your completed booking.',
            );
          }
          final bookingId = extra['bookingId'] as String?;
          final providerId = extra['providerId'] as String?;
          final providerName = extra['providerName'] as String?;
          if (bookingId == null || providerId == null || providerName == null) {
            return _invalidRoutePage(
              'Review details are missing. Please reopen this action from booking details.',
            );
          }
          return ReviewRatingScreen(
            bookingId: bookingId,
            providerId: providerId,
            providerName: providerName,
            providerPhoto: extra['providerPhoto'],
          );
        },
      ),
      GoRoute(
        path: '/customer/orders',
        builder: (context, state) => const MyOrdersScreen(),
      ),
      GoRoute(
        path: '/customer/booking/:bookingId',
        builder: (context, state) {
          final bookingId = state.pathParameters['bookingId']!;
          return BookingDetailScreen(bookingId: bookingId);
        },
      ),
      GoRoute(
        path: '/customer/sos',
        builder: (context, state) => const SosEmergencyScreen(),
      ),
      GoRoute(
        path: '/customer/deals',
        builder: (context, state) => const NeighborhoodDealsScreen(),
      ),
      GoRoute(
        path: '/customer/deals/create',
        builder: (context, state) => const CreateDealScreen(),
      ),
      GoRoute(
        path: '/customer/dispute',
        builder: (context, state) {
          final bookingId = _queryParam(state, 'bookingId');
          if (bookingId == null) {
            return _invalidRoutePage(
              'Dispute link is missing booking details.',
            );
          }
          return DisputeScreen(bookingId: bookingId);
        },
      ),
      GoRoute(
        path: '/chat/:bookingId',
        builder: (context, state) {
          final bookingId = state.pathParameters['bookingId'];
          if (bookingId == null || bookingId.isEmpty) {
            return _invalidRoutePage('Chat link is invalid.');
          }
          return BookingChatScreen(bookingId: bookingId);
        },
      ),
      GoRoute(
        path: '/customer/profile',
        builder: (context, state) => const CustomerProfileScreen(),
      ),

      // Provider Routes
      GoRoute(
        path: '/provider/dashboard',
        builder: (context, state) => const ProviderDashboardScreen(),
      ),
      GoRoute(
        path: '/provider/sos',
        builder: (context, state) => const ProviderSosRequestsScreen(),
      ),
      GoRoute(
        path: '/provider/services',
        builder: (context, state) => const MyServicesScreen(),
      ),
      GoRoute(
        path: '/provider/services/add',
        builder: (context, state) => const AddEditServiceScreen(),
      ),
      GoRoute(
        path: '/provider/services/edit',
        builder: (context, state) {
          final serviceId = _queryParam(state, 'serviceId');
          if (serviceId == null) {
            return _invalidRoutePage(
              'Service edit link is invalid. Please open edit from your services list.',
            );
          }
          return AddEditServiceScreen(serviceId: serviceId);
        },
      ),
      GoRoute(
        path: '/provider/services/analytics',
        builder: (context, state) {
          final serviceId = _queryParam(state, 'serviceId');
          if (serviceId == null) {
            return _invalidRoutePage(
              'Service analytics link is invalid. Please open analytics from your services list.',
            );
          }
          return ServiceAnalyticsScreen(serviceId: serviceId);
        },
      ),
      GoRoute(
        path: '/provider/lead/:bookingId',
        builder: (context, state) {
          final bookingId = state.pathParameters['bookingId']!;
          return LeadDetailScreen(bookingId: bookingId);
        },
      ),
      GoRoute(
        path: '/provider/quote',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is! Map<String, dynamic>) {
            return _invalidRoutePage(
              'Quote link is invalid. Please open this from lead details.',
            );
          }
          final bookingId = extra['bookingId'] as String?;
          final customerName = extra['customerName'] as String?;
          final issueTitle = extra['issueTitle'] as String?;
          if (bookingId == null || customerName == null || issueTitle == null) {
            return _invalidRoutePage(
              'Quote details are incomplete. Please retry from lead details.',
            );
          }
          return QuoteSubmissionScreen(
            bookingId: bookingId,
            customerName: customerName,
            issueTitle: issueTitle,
          );
        },
      ),
      GoRoute(
        path: '/provider/job/active',
        builder: (context, state) {
          final bookingId = _queryParam(state, 'bookingId');
          if (bookingId == null) {
            return _invalidRoutePage(
              'Active job link is invalid. Please open from your jobs list.',
            );
          }
          return ActiveJobScreen(bookingId: bookingId);
        },
      ),
      GoRoute(
        path: '/provider/job/payment-received',
        builder: (context, state) {
          final bookingId = _queryParam(state, 'bookingId');
          if (bookingId == null) {
            return _invalidRoutePage(
              'Payment update link is invalid. Please retry from job details.',
            );
          }
          return PaymentReceivedScreen(bookingId: bookingId);
        },
      ),
      GoRoute(
        path: '/provider/deals/create',
        builder: (context, state) => const CreateDealScreen(),
      ),
      GoRoute(
        path: '/provider/jobs',
        builder: (context, state) => const MyJobsScreen(),
      ),
      GoRoute(
        path: '/provider/job/:bookingId',
        builder: (context, state) {
          final bookingId = state.pathParameters['bookingId']!;
          return ProviderJobDetailScreen(bookingId: bookingId);
        },
      ),
      GoRoute(
        path: '/provider/wallet',
        builder: (context, state) => const LeadWalletScreen(),
      ),
      GoRoute(
        path: '/provider/earnings',
        builder: (context, state) => const EarningsScreen(),
      ),
      GoRoute(
        path: '/provider/profile',
        builder: (context, state) => const ProviderProfileScreen(),
      ),

      // Admin Routes
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/verifications',
        builder: (context, state) => const ProviderVerificationQueueScreen(),
      ),
      GoRoute(
        path: '/admin/disputes',
        builder: (context, state) => const DisputeManagementScreen(),
      ),
      GoRoute(
        path: '/admin/topups',
        builder: (context, state) => const TopUpApprovalScreen(),
      ),
      GoRoute(
        path: '/admin/overview',
        builder: (context, state) => const PlatformOverviewScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Page Not Found',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'The page you\'re looking for doesn\'t exist.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});

// Navigation Helpers
extension GoRouterExtension on BuildContext {
  void goToCustomerHome() => go('/customer/home');
  void goToProviderDashboard() => go('/provider/dashboard');
  void goToAdminDashboard() => go('/admin/dashboard');
  void goToAuth() => go('/auth');
  void goToNotifications() => push('/notifications');
  void goToSupport() => push('/support');
  void goToPrivacyPolicy() => push('/privacy-policy');
  void goToTermsOfService() => push('/terms-of-service');
  void goToRoleSelection() => go('/role-selection');
  void goToSearch() => go('/customer/search');
  void goToCategory(String category) => push('/customer/category/$category');
  void goToServiceDetail(String serviceId) =>
      push('/customer/service/$serviceId');
  void goToProviderProfile(String providerId) =>
      push('/customer/provider/$providerId');
  void goToBookingForm({String? serviceId, String? category}) =>
      push('/customer/booking/form', extra: {
        'serviceId': serviceId,
        'category': category,
      });
  void goToBookingSubmitted(String bookingId) => push(
      '/customer/booking/submitted?bookingId=${Uri.encodeQueryComponent(bookingId)}');
  void goToBookingTracking(String bookingId) => push(
      '/customer/booking/track?bookingId=${Uri.encodeQueryComponent(bookingId)}');
  void goToPaymentConfirmation(String bookingId) => push(
      '/customer/booking/payment?bookingId=${Uri.encodeQueryComponent(bookingId)}');
  void goToReview(Map<String, dynamic> data) =>
      push('/customer/booking/review', extra: data);
  void goToOrders() => go('/customer/orders');
  void goToBookingDetail(String bookingId) =>
      push('/customer/booking/$bookingId');
  void goToBookingChat(String bookingId) =>
      push('/chat/${Uri.encodeComponent(bookingId)}');
  void goToSOS() => push('/customer/sos');
  void goToDeals() => go('/customer/deals');
  void goToCreateDeal() => push('/provider/deals/create');
  void goToDispute(String bookingId) => push(
      '/customer/dispute?bookingId=${Uri.encodeQueryComponent(bookingId)}');
  void goToCustomerProfile() => go('/customer/profile');
  void goToProviderRegistration() => push('/provider/registration');
  void goToPendingApproval() => push('/provider/pending');
  void goToProviderSOSRequests() => push('/provider/sos');
  void goToMyServices() => go('/provider/services');
  void goToAddService() => push('/provider/services/add');
  void goToEditService(String serviceId) => push(
      '/provider/services/edit?serviceId=${Uri.encodeQueryComponent(serviceId)}');
  void goToServiceAnalytics(String serviceId) => push(
      '/provider/services/analytics?serviceId=${Uri.encodeQueryComponent(serviceId)}');
  void goToLeadDetail(String bookingId) => push('/provider/lead/$bookingId');
  void goToQuoteSubmission(Map<String, dynamic> data) =>
      push('/provider/quote', extra: data);
  void goToActiveJob(String bookingId) => push(
      '/provider/job/active?bookingId=${Uri.encodeQueryComponent(bookingId)}');
  void goToPaymentReceived(String bookingId) => push(
      '/provider/job/payment-received?bookingId=${Uri.encodeQueryComponent(bookingId)}');
  void goToMyJobs() => go('/provider/jobs');
  void goToProviderJobDetail(String bookingId) =>
      push('/provider/job/$bookingId');
  void goToWallet() => push('/provider/wallet');
  void goToEarnings() => go('/provider/earnings');
  void goToProviderOwnProfile() => go('/provider/profile');
  void goToVerifications() => push('/admin/verifications');
  void goToDisputeManagement() => push('/admin/disputes');
  void goToTopUps() => push('/admin/topups');
  void goToPlatformOverview() => push('/admin/overview');
}
