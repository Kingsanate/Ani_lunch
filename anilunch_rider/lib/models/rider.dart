class RiderModel {
  final String id;
  final String name;
  final String phone;
  final String email;
  final bool isOnline;
  final bool isApproved;
  final String approvalStatus; // 'pending' | 'approved' | 'rejected'
  final String? rejectionReason;
  final DateTime? createdAt;
  final double? latitude;
  final double? longitude;

  RiderModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.isOnline,
    this.isApproved = false,
    this.approvalStatus = 'pending',
    this.rejectionReason,
    this.createdAt,
    this.latitude,
    this.longitude,
  });

  factory RiderModel.fromJson(Map<String, dynamic> json) {
    return RiderModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      isOnline: json['is_online'] as bool? ?? false,
      isApproved: json['is_approved'] as bool? ?? false,
      approvalStatus: json['approval_status'] as String? ?? 'pending',
      rejectionReason: json['rejection_reason'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'is_online': isOnline,
      'is_approved': isApproved,
      'approval_status': approvalStatus,
      if (rejectionReason != null) 'rejection_reason': rejectionReason,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }

  RiderModel copyWith({
    bool? isOnline,
    bool? isApproved,
    String? approvalStatus,
    String? rejectionReason,
    double? latitude,
    double? longitude,
  }) {
    return RiderModel(
      id: id,
      name: name,
      phone: phone,
      email: email,
      isOnline: isOnline ?? this.isOnline,
      isApproved: isApproved ?? this.isApproved,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
