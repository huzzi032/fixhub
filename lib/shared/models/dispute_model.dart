import 'model_types.dart';

class DisputeModel {
  final String disputeId;
  final String bookingId;
  final String raisedBy;
  final String againstUserId;
  final String reason;
  final String description;
  final List<String> evidenceUrls;
  final String status;
  final String? resolution;
  final String? resolvedBy;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? bookingTitle;
  final String? raisedByName;
  final String? againstUserName;

  const DisputeModel({
    required this.disputeId,
    required this.bookingId,
    required this.raisedBy,
    required this.againstUserId,
    required this.reason,
    required this.description,
    this.evidenceUrls = const [],
    this.status = 'open',
    this.resolution,
    this.resolvedBy,
    required this.createdAt,
    this.resolvedAt,
    this.bookingTitle,
    this.raisedByName,
    this.againstUserName,
  });

  factory DisputeModel.fromMap(Map<String, dynamic> data, {String? id}) {
    return DisputeModel(
      disputeId:
          (data['disputeId'] ?? data['dispute_id'] ?? id ?? '') as String,
      bookingId: data['bookingId'] ?? '',
      raisedBy: data['raisedBy'] ?? '',
      againstUserId: data['againstUserId'] ?? '',
      reason: data['reason'] ?? '',
      description: data['description'] ?? '',
      evidenceUrls: (data['evidenceUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      status: data['status'] ?? 'open',
      resolution: data['resolution'] as String?,
      resolvedBy: data['resolvedBy'] as String?,
      createdAt: parseDateTime(data['createdAt'] ?? data['created_at']),
      resolvedAt: _parseNullableDate(data['resolvedAt'] ?? data['resolved_at']),
      bookingTitle: data['bookingTitle'] as String?,
      raisedByName: data['raisedByName'] as String?,
      againstUserName: data['againstUserName'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'disputeId': disputeId,
      'bookingId': bookingId,
      'raisedBy': raisedBy,
      'againstUserId': againstUserId,
      'reason': reason,
      'description': description,
      'evidenceUrls': evidenceUrls,
      'status': status,
      'resolution': resolution,
      'resolvedBy': resolvedBy,
      'createdAt': toEpochMillis(createdAt),
      'resolvedAt': resolvedAt != null ? toEpochMillis(resolvedAt!) : null,
      'bookingTitle': bookingTitle,
      'raisedByName': raisedByName,
      'againstUserName': againstUserName,
    };
  }

  DisputeModel copyWith({
    String? disputeId,
    String? bookingId,
    String? raisedBy,
    String? againstUserId,
    String? reason,
    String? description,
    List<String>? evidenceUrls,
    String? status,
    String? resolution,
    String? resolvedBy,
    DateTime? createdAt,
    DateTime? resolvedAt,
    String? bookingTitle,
    String? raisedByName,
    String? againstUserName,
  }) {
    return DisputeModel(
      disputeId: disputeId ?? this.disputeId,
      bookingId: bookingId ?? this.bookingId,
      raisedBy: raisedBy ?? this.raisedBy,
      againstUserId: againstUserId ?? this.againstUserId,
      reason: reason ?? this.reason,
      description: description ?? this.description,
      evidenceUrls: evidenceUrls ?? this.evidenceUrls,
      status: status ?? this.status,
      resolution: resolution ?? this.resolution,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      bookingTitle: bookingTitle ?? this.bookingTitle,
      raisedByName: raisedByName ?? this.raisedByName,
      againstUserName: againstUserName ?? this.againstUserName,
    );
  }

  // Status helpers
  bool get isOpen => status == 'open';
  bool get isUnderReview => status == 'underReview';
  bool get isResolved => status == 'resolved';

  String get statusDisplayName {
    switch (status) {
      case 'open':
        return 'Open';
      case 'underReview':
        return 'Under Review';
      case 'resolved':
        return 'Resolved';
      default:
        return status;
    }
  }

  bool get hasEvidence => evidenceUrls.isNotEmpty;
  bool get hasResolution => resolution != null && resolution!.isNotEmpty;

  Duration get timeSinceCreated {
    return DateTime.now().difference(createdAt);
  }

  String get timeSinceCreatedText {
    final duration = timeSinceCreated;
    if (duration.inDays > 0) {
      return '${duration.inDays}d ago';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ago';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class TopUpRequestModel {
  final String requestId;
  final String providerId;
  final int requestedAmount;
  final String status;
  final String? approvedBy;
  final DateTime createdAt;
  final String? providerName;
  final int? currentWalletBalance;

  const TopUpRequestModel({
    required this.requestId,
    required this.providerId,
    required this.requestedAmount,
    this.status = 'pending',
    this.approvedBy,
    required this.createdAt,
    this.providerName,
    this.currentWalletBalance,
  });

  factory TopUpRequestModel.fromMap(Map<String, dynamic> data, {String? id}) {
    return TopUpRequestModel(
      requestId:
          (data['requestId'] ?? data['request_id'] ?? id ?? '') as String,
      providerId: data['providerId'] ?? '',
      requestedAmount: data['requestedAmount'] ?? 0,
      status: data['status'] ?? 'pending',
      approvedBy: data['approvedBy'] as String?,
      createdAt: parseDateTime(data['createdAt'] ?? data['created_at']),
      providerName: data['providerName'] as String?,
      currentWalletBalance: data['currentWalletBalance'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'requestId': requestId,
      'providerId': providerId,
      'requestedAmount': requestedAmount,
      'status': status,
      'approvedBy': approvedBy,
      'createdAt': toEpochMillis(createdAt),
      'providerName': providerName,
      'currentWalletBalance': currentWalletBalance,
    };
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
}

class WithdrawalRequestModel {
  final String requestId;
  final String providerId;
  final int amount;
  final String bankName;
  final String accountNumber;
  final String accountTitle;
  final String status;
  final String? processedBy;
  final DateTime createdAt;
  final DateTime? processedAt;

  const WithdrawalRequestModel({
    required this.requestId,
    required this.providerId,
    required this.amount,
    required this.bankName,
    required this.accountNumber,
    required this.accountTitle,
    this.status = 'pending',
    this.processedBy,
    required this.createdAt,
    this.processedAt,
  });

  factory WithdrawalRequestModel.fromMap(Map<String, dynamic> data,
      {String? id}) {
    return WithdrawalRequestModel(
      requestId:
          (data['requestId'] ?? data['request_id'] ?? id ?? '') as String,
      providerId: data['providerId'] ?? '',
      amount: data['amount'] ?? 0,
      bankName: data['bankName'] ?? '',
      accountNumber: data['accountNumber'] ?? '',
      accountTitle: data['accountTitle'] ?? '',
      status: data['status'] ?? 'pending',
      processedBy: data['processedBy'] as String?,
      createdAt: parseDateTime(data['createdAt'] ?? data['created_at']),
      processedAt:
          _parseNullableDate(data['processedAt'] ?? data['processed_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'requestId': requestId,
      'providerId': providerId,
      'amount': amount,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'accountTitle': accountTitle,
      'status': status,
      'processedBy': processedBy,
      'createdAt': toEpochMillis(createdAt),
      'processedAt': processedAt != null ? toEpochMillis(processedAt!) : null,
    };
  }

  bool get isPending => status == 'pending';
  bool get isProcessed => status == 'processed';
  bool get isRejected => status == 'rejected';
}

DateTime? _parseNullableDate(dynamic value) {
  if (value == null) {
    return null;
  }

  return parseDateTime(value);
}
