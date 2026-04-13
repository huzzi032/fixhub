class AppGeoPoint {
  final double latitude;
  final double longitude;

  const AppGeoPoint({
    required this.latitude,
    required this.longitude,
  });

  factory AppGeoPoint.fromMap(Map<String, dynamic> map) {
    return AppGeoPoint(
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

DateTime parseDateTime(dynamic value, {DateTime? fallback}) {
  if (value is DateTime) {
    return value;
  }

  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }

  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) {
      return parsed;
    }
  }

  return fallback ?? DateTime.now();
}

int toEpochMillis(DateTime value) {
  return value.millisecondsSinceEpoch;
}
