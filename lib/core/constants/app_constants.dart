class AppConstants {
  // App Info
  static const String appName = 'FixHub';
  static const String appTagline = 'Pakistan\'s Trusted Service Marketplace';
  static const String supportManagerName = 'Huzaifa Chaudhary';
  static const String supportEmail = 'huzaifachaduhary@gmail.com';
  static const String supportPhone = '03044487024';
  static const String supportDialPhone = '+923044487024';

  // Country
  static const String countryCode = 'PK';
  static const String currencySymbol = 'Rs.';
  static const String currencyCode = 'PKR';
  static const String phonePrefix = '+92';

  // Validation
  static const String phoneRegex = r'^(\+92|0)?3[0-9]{9}$';
  static const String emailRegex =
      r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$';
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 32;

  // Limits
  static const int maxServiceImages = 5;
  static const int maxBookingImages = 3;
  static const int maxCertificates = 3;
  static const int maxImageSizeKB = 500;
  static const int maxBioLength = 300;
  static const int maxDescriptionLength = 600;
  static const int maxIssueTitleLength = 80;
  static const int maxIssueDescriptionLength = 400;
  static const int maxCommentLength = 250;
  static const int maxProviderNoteLength = 200;
  static const int maxQuoteMessageLength = 150;
  static const int maxServiceTitleLength = 80;
  static const int maxTags = 10;

  // Pricing
  static const int leadDeductionAmount = 50;
  static const int minWalletBalanceForBidding = 50;
  static const int minTopUpAmount = 100;
  static const int maxTopUpAmount = 10000;
  static const int minHourlyRate = 100;
  static const int maxHourlyRate = 5000;
  static const int minFixedPrice = 100;
  static const int maxFixedPrice = 50000;
  static const int maxPriceFilter = 5000;

  // Location
  static const double defaultServiceRadiusKm = 10;
  static const double minServiceRadiusKm = 5;
  static const double maxServiceRadiusKm = 50;
  static const double sosSearchRadiusKm = 5;
  static const int locationUpdateIntervalSeconds = 30;
  static const double defaultLatitude = 24.8607; // Karachi
  static const double defaultLongitude = 67.0011;

  // Time
  static const int minBookingAdvanceHours = 2;
  static const int maxBookingAdvanceDays = 30;
  static const int splashDelaySeconds = 2;
  static const int sosBidTimeoutMinutes = 30;
  static const int dealExpiryOptionsDays = 3;
  static const List<int> dealExpiryChoices = [3, 7, 14];
  static const int disputeReviewHours = 48;

  // Pagination
  static const int reviewsPerPage = 10;
  static const int bookingsPerPage = 15;
  static const int servicesPerPage = 20;
  static const int leadsPerPage = 20;
  static const int notificationsPerPage = 25;

  // Trust Levels
  static const Map<int, String> trustLevelNames = {
    1: 'New',
    2: 'Reliable',
    3: 'Trusted',
    4: 'Expert',
    5: 'Elite',
  };

  // Categories
  static const List<String> serviceCategories = [
    'plumber',
    'electrician',
    'carpenter',
    'painter',
    'car_mechanic',
    'ac_repair',
    'cleaning',
    'other',
  ];

  static const Map<String, String> categoryDisplayNames = {
    'plumber': 'Plumber',
    'electrician': 'Electrician',
    'carpenter': 'Carpenter',
    'painter': 'Painter',
    'car_mechanic': 'Car Mechanic',
    'ac_repair': 'AC Repair',
    'cleaning': 'Cleaning',
    'other': 'Other',
  };

  static const Map<String, String> categoryIcons = {
    'plumber': 'plumbing',
    'electrician': 'electrical_services',
    'carpenter': 'carpenter',
    'painter': 'format_paint',
    'car_mechanic': 'car_repair',
    'ac_repair': 'ac_unit',
    'cleaning': 'cleaning_services',
    'other': 'handyman',
  };

  // Pakistani Cities
  static const List<String> pakistaniCities = [
    'Karachi',
    'Lahore',
    'Islamabad',
    'Rawalpindi',
    'Faisalabad',
    'Gujranwala',
    'Sialkot',
    'Multan',
    'Peshawar',
    'Quetta',
    'Hyderabad',
    'Bahawalpur',
    'Sargodha',
    'Sukkur',
    'Larkana',
    'Sheikhupura',
    'Mirpur Khas',
    'Rahim Yar Khan',
    'Gujrat',
    'Jhang',
    'Mardan',
    'Kasur',
    'Dera Ghazi Khan',
    'Sahiwal',
    'Nawabshah',
    'Mingora',
    'Okara',
    'Mandi Bahauddin',
    'Chiniot',
    'Kamoke',
    'Hafizabad',
    'Kohat',
    'Jacobabad',
    'Shikarpur',
    'Muzaffargarh',
    'Khanewal',
    'Gojra',
    'Bahawalnagar',
    'Abbottabad',
    'Muridke',
    'Pakpattan',
    'Khuzdar',
    'Jaranwala',
    'Chishtian',
    'Daska',
    'Mandi',
    'Ahmadpur East',
    'Kamalia',
    'Tando Adam',
    'Khairpur',
    'Dera Ismail Khan',
  ];

  // Time Slots
  static const List<String> timeSlots = [
    '08:00 AM',
    '08:30 AM',
    '09:00 AM',
    '09:30 AM',
    '10:00 AM',
    '10:30 AM',
    '11:00 AM',
    '11:30 AM',
    '12:00 PM',
    '12:30 PM',
    '01:00 PM',
    '01:30 PM',
    '02:00 PM',
    '02:30 PM',
    '03:00 PM',
    '03:30 PM',
    '04:00 PM',
    '04:30 PM',
    '05:00 PM',
    '05:30 PM',
    '06:00 PM',
    '06:30 PM',
    '07:00 PM',
    '07:30 PM',
    '08:00 PM',
  ];

  // Dispute Reasons
  static const List<String> disputeReasons = [
    'Provider didn\'t show up',
    'Poor quality of work',
    'Wrong amount charged',
    'Provider was rude',
    'Other',
  ];

  // SOS Issue Types
  static const List<String> sosIssueTypes = [
    'Plumbing Emergency',
    'Electrical Emergency',
    'AC Not Working',
    'Car Breakdown',
    'Locksmith Needed',
    'Other Emergency',
  ];

  // Quote Time Estimates
  static const List<String> quoteTimeEstimates = [
    '1 hour',
    '2 hours',
    '3 hours',
    'Half day',
    'Full day',
  ];

  // Onboarding
  static const List<Map<String, String>> onboardingSlides = [
    {
      'title': 'Find Trusted Professionals',
      'description':
          'Connect with verified service providers for all your home and vehicle needs in Pakistan.',
      'image': 'onboarding_1',
    },
    {
      'title': 'Book in Seconds',
      'description':
          'Schedule services at your convenience. Track your provider in real-time.',
      'image': 'onboarding_2',
    },
    {
      'title': 'Pay with Confidence',
      'description':
          'Cash on delivery. No upfront payments. Rate and review after service completion.',
      'image': 'onboarding_3',
    },
  ];
}

class FirestoreCollections {
  static const String users = 'users';
  static const String customers = 'customers';
  static const String providers = 'providers';
  static const String services = 'services';
  static const String bookings = 'bookings';
  static const String bids = 'bids';
  static const String reviews = 'reviews';
  static const String neighborhoodDeals = 'neighborhoodDeals';
  static const String disputes = 'disputes';
  static const String topupRequests = 'topupRequests';
  static const String withdrawalRequests = 'withdrawalRequests';
  static const String notifications = 'notifications';
  static const String notificationMessages = 'messages';
}

class UserRoles {
  static const String customer = 'customer';
  static const String provider = 'provider';
  static const String admin = 'admin';
}

class VerificationStatus {
  static const String pending = 'pending';
  static const String approved = 'approved';
  static const String rejected = 'rejected';
  static const String suspended = 'suspended';
}

class BookingStatus {
  static const String pending = 'pending';
  static const String accepted = 'accepted';
  static const String rejected = 'rejected';
  static const String enRoute = 'enRoute';
  static const String inProgress = 'inProgress';
  static const String completed = 'completed';
  static const String paid = 'paid';
  static const String cancelled = 'cancelled';
  static const String disputed = 'disputed';
}

class PaymentStatus {
  static const String pending = 'pending';
  static const String collected = 'collected';
}

class PaymentMethod {
  static const String cash = 'cash';
}

class PriceType {
  static const String fixed = 'fixed';
  static const String hourly = 'hourly';
  static const String quote = 'quote';
}

class BidStatus {
  static const String pending = 'pending';
  static const String accepted = 'accepted';
  static const String rejected = 'rejected';
}

class DealStatus {
  static const String open = 'open';
  static const String filled = 'filled';
  static const String expired = 'expired';
  static const String cancelled = 'cancelled';
}

class DisputeStatus {
  static const String open = 'open';
  static const String underReview = 'underReview';
  static const String resolved = 'resolved';
}

class RequestStatus {
  static const String pending = 'pending';
  static const String approved = 'approved';
  static const String rejected = 'rejected';
  static const String processed = 'processed';
}

class NotificationType {
  static const String bookingUpdate = 'booking_update';
  static const String bidAccepted = 'bid_accepted';
  static const String newLead = 'new_lead';
  static const String verificationUpdate = 'verification_update';
  static const String dealUpdate = 'deal_update';
  static const String disputeUpdate = 'dispute_update';
  static const String walletUpdate = 'wallet_update';
  static const String general = 'general';
}

class SharedPrefKeys {
  static const String isFirstLaunch = 'is_first_launch';
  static const String recentSearches = 'recent_searches';
  static const String lastLocation = 'last_location';
  static const String fcmToken = 'fcm_token';
  static const String notificationsEnabled = 'notifications_enabled';
  static const String promotionsEnabled = 'promotions_enabled';
  static const String dealsEnabled = 'deals_enabled';
}
