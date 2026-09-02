import 'package:flutter_test/flutter_test.dart';
import 'package:anilunch/services/auth_service.dart';

void main() {
  group('AuthService', () {
    test('initializes cleanly', () {
      expect(AuthService.currentUserId, isNull);
    });
  });
}
