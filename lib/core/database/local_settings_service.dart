import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

class LocalSettingsService {
  LocalSettingsService._();

  static final LocalSettingsService instance = LocalSettingsService._();

  Future<String> getLocationLabel(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_locationKey(uid)) ?? 'Karachi, Sindh';
  }

  Future<void> setLocationLabel(String uid, String location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_locationKey(uid), location.trim());
  }

  Future<UserNotificationSettings> getNotificationSettings(String uid) async {
    final prefs = await SharedPreferences.getInstance();

    return UserNotificationSettings(
      bookingUpdates: prefs.getBool(_bookingUpdatesKey(uid)) ?? true,
      promotions: prefs.getBool(_promotionsKey(uid)) ?? true,
      neighborhoodDeals: prefs.getBool(_dealsKey(uid)) ?? true,
    );
  }

  Future<void> setBookingUpdates(String uid, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_bookingUpdatesKey(uid), value);
  }

  Future<void> setPromotions(String uid, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_promotionsKey(uid), value);
  }

  Future<void> setNeighborhoodDeals(String uid, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dealsKey(uid), value);
  }

  Future<bool> getProviderOnline(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_providerOnlineKey(uid)) ?? true;
  }

  Future<void> setProviderOnline(String uid, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_providerOnlineKey(uid), value);
  }

  String _locationKey(String uid) => '${SharedPrefKeys.lastLocation}.$uid';

  String _bookingUpdatesKey(String uid) =>
      '${SharedPrefKeys.notificationsEnabled}.$uid';

  String _promotionsKey(String uid) =>
      '${SharedPrefKeys.promotionsEnabled}.$uid';

  String _dealsKey(String uid) => '${SharedPrefKeys.dealsEnabled}.$uid';

  String _providerOnlineKey(String uid) => 'provider_online.$uid';
}

class UserNotificationSettings {
  final bool bookingUpdates;
  final bool promotions;
  final bool neighborhoodDeals;

  const UserNotificationSettings({
    required this.bookingUpdates,
    required this.promotions,
    required this.neighborhoodDeals,
  });
}
