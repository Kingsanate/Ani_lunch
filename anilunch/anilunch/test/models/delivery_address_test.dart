// ignore_for_file: prefer_const_constructors

import 'package:flutter_test/flutter_test.dart';
import 'package:anilunch/models/delivery_address.dart';

void main() {
  group('DeliveryAddress', () {
    test('fromMap parses all fields correctly', () {
      final map = {
        'id': 'addr_001',
        'name': 'John Doe',
        'phone_number': '9876543210',
        'house_no': '123',
        'area': 'MG Road',
        'city': 'Mumbai',
        'state': 'Maharashtra',
        'pincode': '400001',
        'landmark': 'Near Station',
        'notes': 'Ring bell twice',
      };

      final address = DeliveryAddress.fromMap(map);

      expect(address.id, 'addr_001');
      expect(address.fullName, 'John Doe');
      expect(address.phoneNumber, '9876543210');
      expect(address.houseNo, '123');
      expect(address.area, 'MG Road');
      expect(address.city, 'Mumbai');
      expect(address.state, 'Maharashtra');
      expect(address.pincode, '400001');
      expect(address.landmark, 'Near Station');
      expect(address.notes, 'Ring bell twice');
    });

    test('fromMap with missing fields returns defaults', () {
      final address = DeliveryAddress.fromMap({});

      expect(address.id, '');
      expect(address.fullName, '');
      expect(address.phoneNumber, '');
      expect(address.houseNo, '');
      expect(address.area, '');
      expect(address.city, '');
      expect(address.state, '');
      expect(address.pincode, '');
      expect(address.landmark, isNull);
      expect(address.notes, isNull);
    });

    test('fromMap falls back to full_name key for name', () {
      final map = {'full_name': 'Jane Doe'};
      final address = DeliveryAddress.fromMap(map);
      expect(address.fullName, 'Jane Doe');
    });

    test('fromMap falls back to address key for house_no', () {
      final map = {'address': '456 Park Avenue'};
      final address = DeliveryAddress.fromMap(map);
      expect(address.houseNo, '456 Park Avenue');
    });

    test('toMap produces correct map', () {
      final address = DeliveryAddress(
        id: 'addr_002',
        fullName: 'Jane Smith',
        phoneNumber: '9123456789',
        houseNo: '456',
        area: 'Bandra West',
        city: 'Mumbai',
        state: 'Maharashtra',
        pincode: '400050',
        landmark: 'Opposite Park',
        notes: 'Leave at gate',
      );

      final map = address.toMap();

      expect(map['id'], 'addr_002');
      expect(map['name'], 'Jane Smith');
      expect(map['phone_number'], '9123456789');
      expect(map['house_no'], '456');
      expect(map['area'], 'Bandra West');
      expect(map['city'], 'Mumbai');
      expect(map['state'], 'Maharashtra');
      expect(map['pincode'], '400050');
      expect(map['landmark'], 'Opposite Park');
      expect(map['notes'], 'Leave at gate');
    });

    test('toMap omits id when empty', () {
      final address = DeliveryAddress(
        id: '',
        fullName: 'Test',
        phoneNumber: '0000000000',
        houseNo: '1',
        area: 'Test Area',
        city: 'Test City',
        state: 'Test State',
        pincode: '000000',
      );

      final map = address.toMap();

      expect(map.containsKey('id'), false);
    });

    test('fullDisplay getter returns formatted address string', () {
      final address = DeliveryAddress(
        id: '1',
        fullName: 'Test',
        phoneNumber: '0000000000',
        houseNo: '7A',
        area: 'Indira Nagar',
        city: 'Bangalore',
        state: 'Karnataka',
        pincode: '560038',
      );

      expect(address.fullDisplay, '7A, Indira Nagar, Bangalore, Karnataka - 560038');
    });
  });
}
