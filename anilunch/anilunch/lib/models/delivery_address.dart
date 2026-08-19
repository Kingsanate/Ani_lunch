class DeliveryAddress {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String houseNo;
  final String area;
  final String city;
  final String state;
  final String pincode;
  final String? landmark;
  final String? notes;

  DeliveryAddress({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.houseNo,
    required this.area,
    required this.city,
    required this.state,
    required this.pincode,
    this.landmark,
    this.notes,
  });

  String get fullDisplay => '$houseNo, $area, $city, $state - $pincode';

  Map<String, dynamic> toMap() {
    return {
      if (id.isNotEmpty) 'id': id,
      'name': fullName,
      'phone_number': phoneNumber,
      'house_no': houseNo,
      'area': area,
      'city': city,
      'state': state,
      'pincode': pincode,
      'landmark': landmark,
      'notes': notes,
    };
  }

  factory DeliveryAddress.fromMap(Map<String, dynamic> map) {
    return DeliveryAddress(
      id: map['id']?.toString() ?? '',
      fullName: map['name'] ?? map['full_name'] ?? '',
      phoneNumber: map['phone_number'] ?? '',
      houseNo: map['house_no'] ?? map['address'] ?? '',
      area: map['area'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      pincode: map['pincode'] ?? '',
      landmark: map['landmark'],
      notes: map['notes'],
    );
  }
}
