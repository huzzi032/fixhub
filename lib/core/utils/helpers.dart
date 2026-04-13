import 'dart:math';
import 'package:latlong2/latlong.dart';
import '../constants/app_constants.dart';
import '../theme/app_theme.dart';

class Helpers {
  // Haversine Distance Calculation
  static double calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371; // km
    
    final double lat1Rad = point1.latitude * pi / 180;
    final double lat2Rad = point2.latitude * pi / 180;
    final double deltaLat = (point2.latitude - point1.latitude) * pi / 180;
    final double deltaLon = (point2.longitude - point1.longitude) * pi / 180;
    
    final double a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(deltaLon / 2) * sin(deltaLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  static int estimateTravelTimeMinutes(double distanceKm) {
    // Assuming average speed of 30 km/h in urban Pakistan
    final minutes = (distanceKm / 30 * 60).round();
    return minutes.clamp(5, 120);
  }
  
  // Status Color Helper
  static dynamic getStatusColor(String status) {
    switch (status) {
      case BookingStatus.pending:
        return AppColors.pending;
      case BookingStatus.accepted:
        return AppColors.accepted;
      case BookingStatus.enRoute:
        return AppColors.enRoute;
      case BookingStatus.inProgress:
        return AppColors.inProgress;
      case BookingStatus.completed:
        return AppColors.completed;
      case BookingStatus.paid:
        return AppColors.paid;
      case BookingStatus.cancelled:
        return AppColors.cancelled;
      case BookingStatus.disputed:
        return AppColors.disputed;
      case BookingStatus.rejected:
        return AppColors.error;
      default:
        return AppColors.onSurfaceVariant;
    }
  }
  
  // Status Display Name
  static String getStatusDisplayName(String status) {
    switch (status) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.accepted:
        return 'Accepted';
      case BookingStatus.enRoute:
        return 'En Route';
      case BookingStatus.inProgress:
        return 'In Progress';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.paid:
        return 'Paid';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.disputed:
        return 'Disputed';
      case BookingStatus.rejected:
        return 'Rejected';
      default:
        return status;
    }
  }
  
  // Verification Status Color
  static dynamic getVerificationStatusColor(String status) {
    switch (status) {
      case VerificationStatus.pending:
        return AppColors.pending;
      case VerificationStatus.approved:
        return AppColors.success;
      case VerificationStatus.rejected:
        return AppColors.error;
      case VerificationStatus.suspended:
        return AppColors.error;
      default:
        return AppColors.onSurfaceVariant;
    }
  }
  
  // Trust Level Helper
  static String getTrustLevelName(int level) {
    return AppConstants.trustLevelNames[level] ?? 'New';
  }
  
  static dynamic getTrustLevelColor(int level) {
    switch (level) {
      case 1:
        return AppColors.onSurfaceVariant;
      case 2:
        return AppColors.info;
      case 3:
        return AppColors.success;
      case 4:
        return AppColors.secondary;
      case 5:
        return AppColors.primary;
      default:
        return AppColors.onSurfaceVariant;
    }
  }
  
  // Category Helper
  static String getCategoryDisplayName(String category) {
    return AppConstants.categoryDisplayNames[category] ?? category;
  }
  
  static String getCategoryIcon(String category) {
    return AppConstants.categoryIcons[category] ?? 'handyman';
  }
  
  // Price Type Display
  static String getPriceTypeDisplay(String priceType, {int? amount}) {
    switch (priceType) {
      case PriceType.fixed:
        return amount != null ? 'Fixed: Rs. $amount' : 'Fixed Price';
      case PriceType.hourly:
        return amount != null ? 'Rs. $amount/hr' : 'Hourly Rate';
      case PriceType.quote:
        return 'Get a Quote';
      default:
        return 'Contact for Price';
    }
  }
  
  // Generate Unique ID
  static String generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
  }
  
  // Generate Booking ID
  static String generateBookingId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(9999).toString().padLeft(4, '0');
    return 'BK$timestamp$random';
  }
  
  // Slug Generator
  static String generateSlug(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'[\s]+'), '-')
        .trim();
  }
  
  // Truncate Text
  static String truncateText(String text, int maxLength, {String suffix = '...'}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - suffix.length)}$suffix';
  }
  
  // Mask Phone Number
  static String maskPhoneNumber(String phone) {
    if (phone.length < 7) return phone;
    return '${phone.substring(0, 4)}****${phone.substring(phone.length - 3)}';
  }
  
  // Mask Email
  static String maskEmail(String email) {
    if (!email.contains('@')) return email;
    final parts = email.split('@');
    final local = parts[0];
    final domain = parts[1];
    
    if (local.length <= 2) return email;
    
    final maskedLocal = '${local.substring(0, 2)}${'*' * (local.length - 2)}';
    return '$maskedLocal@$domain';
  }
  
  // Get Initials
  static String getInitials(String name) {
    if (name.isEmpty) return '?';
    
    final parts = name.trim().split(' ');
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    
    return '${parts[0].substring(0, 1)}${parts[parts.length - 1].substring(0, 1)}'.toUpperCase();
  }
  
  // Get Random Avatar Color
  static dynamic getAvatarColor(String name) {
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.info,
      AppColors.success,
      AppColors.warning,
    ];
    
    final index = name.hashCode.abs() % colors.length;
    return colors[index];
  }
  
  // Parse Tags from String
  static List<String> parseTags(String tagsString) {
    if (tagsString.isEmpty) return [];
    
    return tagsString
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();
  }
  
  // Format Tags to String
  static String formatTags(List<String> tags) {
    return tags.join(', ');
  }
  
  // Check if Booking is Active
  static bool isBookingActive(String status) {
    return [
      BookingStatus.pending,
      BookingStatus.accepted,
      BookingStatus.enRoute,
      BookingStatus.inProgress,
    ].contains(status);
  }
  
  // Check if Booking is Completed
  static bool isBookingCompleted(String status) {
    return [
      BookingStatus.completed,
      BookingStatus.paid,
    ].contains(status);
  }
  
  // Check if Booking is Cancelled
  static bool isBookingCancelled(String status) {
    return [
      BookingStatus.cancelled,
      BookingStatus.disputed,
    ].contains(status);
  }
  
  // Can Cancel Booking
  static bool canCancelBooking(String status) {
    return [
      BookingStatus.pending,
      BookingStatus.accepted,
    ].contains(status);
  }
  
  // Can Review Booking
  static bool canReviewBooking(String status, bool hasReview) {
    return status == BookingStatus.paid && !hasReview;
  }
  
  // Get Next Status
  static String? getNextStatus(String currentStatus) {
    switch (currentStatus) {
      case BookingStatus.accepted:
        return BookingStatus.enRoute;
      case BookingStatus.enRoute:
        return BookingStatus.inProgress;
      case BookingStatus.inProgress:
        return BookingStatus.completed;
      default:
        return null;
    }
  }
  
  // Get Status Action Label
  static String getStatusActionLabel(String status) {
    switch (status) {
      case BookingStatus.accepted:
        return 'I\'m On My Way';
      case BookingStatus.enRoute:
        return 'I\'ve Arrived — Start Job';
      case BookingStatus.inProgress:
        return 'Mark Job as Completed';
      default:
        return 'Update Status';
    }
  }
  
  // Calculate Average Rating
  static double calculateAverageRating(List<int> ratings) {
    if (ratings.isEmpty) return 0.0;
    return ratings.reduce((a, b) => a + b) / ratings.length;
  }
  
  // Calculate New Average Rating
  static double calculateNewAverage(double currentAvg, int totalRatings, int newRating) {
    return ((currentAvg * totalRatings) + newRating) / (totalRatings + 1);
  }
  
  // Get Star Color
  static dynamic getStarColor(double rating) {
    if (rating >= 4.5) return AppColors.success;
    if (rating >= 3.5) return AppColors.warning;
    if (rating >= 2.5) return AppColors.pending;
    return AppColors.error;
  }
  
  // Format Rating Count
  static String formatRatingCount(int count) {
    if (count == 0) return 'No reviews';
    if (count == 1) return '1 review';
    return '$count reviews';
  }
  
  // Get Deal Status Color
  static dynamic getDealStatusColor(String status) {
    switch (status) {
      case DealStatus.open:
        return AppColors.success;
      case DealStatus.filled:
        return AppColors.primary;
      case DealStatus.expired:
        return AppColors.onSurfaceVariant;
      case DealStatus.cancelled:
        return AppColors.error;
      default:
        return AppColors.onSurfaceVariant;
    }
  }
  
  // Get Notification Icon
  static String getNotificationIcon(String type) {
    switch (type) {
      case NotificationType.bookingUpdate:
        return 'assignment';
      case NotificationType.bidAccepted:
        return 'check_circle';
      case NotificationType.newLead:
        return 'notifications_active';
      case NotificationType.verificationUpdate:
        return 'verified_user';
      case NotificationType.dealUpdate:
        return 'local_offer';
      case NotificationType.disputeUpdate:
        return 'gavel';
      case NotificationType.walletUpdate:
        return 'account_balance_wallet';
      default:
        return 'notifications';
    }
  }
  
  // Deep Link Parser
  static Map<String, String>? parseDeepLink(String link) {
    final uri = Uri.tryParse(link);
    if (uri == null) return null;
    
    return {
      'path': uri.path,
      ...uri.queryParameters,
    };
  }
  
  // Build Deep Link
  static String buildDeepLink(String path, {Map<String, String>? params}) {
    final uri = Uri(
      scheme: 'fixhub',
      host: 'app',
      path: path,
      queryParameters: params,
    );
    return uri.toString();
  }
}
