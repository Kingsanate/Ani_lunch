import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:anilunch/services/auth_service.dart';
import 'auth_service_test.mocks.dart';

class FakePostgrestFilterBuilder extends Fake
    implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  @override
  Future<S> then<S>(
      FutureOr<S> Function(List<Map<String, dynamic>> value) onValue,
      {Function? onError}) {
    return Future.value(<Map<String, dynamic>>[]).then(onValue, onError: onError);
  }
}

class FakeSupabaseQueryBuilder extends Fake implements SupabaseQueryBuilder {
  Map<String, dynamic>? lastInserted;
  int insertCallCount = 0;

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> insert(dynamic values,
      {bool defaultToNull = true}) {
    insertCallCount++;
    if (values is Map<String, dynamic>) {
      lastInserted = values;
    }
    return FakePostgrestFilterBuilder();
  }
}

class FakeSupabaseClient extends Fake implements SupabaseClient {
  final GoTrueClient _auth;
  final SupabaseQueryBuilder _queryBuilder;
  FakeSupabaseClient(this._auth, this._queryBuilder);

  @override
  GoTrueClient get auth => _auth;

  @override
  SupabaseQueryBuilder from(String table) => _queryBuilder;
}

// Generate mocks for SupabaseClient and related classes
@GenerateMocks([SupabaseClient, GoTrueClient, User])
void main() {
  group('AuthService', () {
    late AuthService authService;
    late MockGoTrueClient mockGoTrue;
    late FakeSupabaseQueryBuilder fakeQueryBuilder;

    setUp(() {
      mockGoTrue = MockGoTrueClient();
      fakeQueryBuilder = FakeSupabaseQueryBuilder();
      final fakeClient = FakeSupabaseClient(mockGoTrue, fakeQueryBuilder);

      authService = AuthService(client: fakeClient);
    });

    group('signIn', () {
      test('calls supabase auth.signInWithPassword', () async {
        when(mockGoTrue.signInWithPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenAnswer((_) async => AuthResponse(session: null, user: null));

        await authService.signIn(
          email: 'test@example.com',
          password: 'password123',
        );

        verify(mockGoTrue.signInWithPassword(
          email: 'test@example.com',
          password: 'password123',
        )).called(1);
      });

      test('throws on invalid credentials', () async {
        when(mockGoTrue.signInWithPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(AuthException('Invalid credentials'));

        expect(
          () => authService.signIn(
            email: 'wrong@example.com',
            password: 'badpassword',
          ),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('signUp', () {
      test('calls supabase auth.signUp and inserts user', () async {
        final mockUser = User(
          id: 'user_001',
          appMetadata: {},
          userMetadata: null,
          aud: 'authenticated',
          createdAt: DateTime.now().toIso8601String(),
        );

        when(mockGoTrue.signUp(
          email: anyNamed('email'),
          password: anyNamed('password'),
          data: anyNamed('data'),
        )).thenAnswer((_) async {
          return AuthResponse(
            user: mockUser,
            session: null,
          );
        });

        await authService.signUp(
          email: 'new@example.com',
          password: 'securepass',
          name: 'New User',
          phone: '9999999999',
          address: '123 Main St',
          pinCode: '400001',
        );

        verify(mockGoTrue.signUp(
          email: 'new@example.com',
          password: 'securepass',
          data: {
            'full_name': 'New User',
            'phone_number': '9999999999',
            'address': '123 Main St',
          },
        )).called(1);

        expect(fakeQueryBuilder.insertCallCount, 1);
        expect(fakeQueryBuilder.lastInserted?['id'], 'user_001');
        expect(fakeQueryBuilder.lastInserted?['name'], 'New User');
        expect(fakeQueryBuilder.lastInserted?['email'], 'new@example.com');
      });

      test('does not insert user when signUp returns null user', () async {
        when(mockGoTrue.signUp(
          email: anyNamed('email'),
          password: anyNamed('password'),
          data: anyNamed('data'),
        )).thenAnswer((_) async {
          return AuthResponse(user: null, session: null);
        });

        await authService.signUp(
          email: 'fail@example.com',
          password: 'password',
          name: 'Fail',
          phone: '0000000000',
          address: 'Nowhere',
          pinCode: '000000',
        );

        expect(fakeQueryBuilder.insertCallCount, 0);
      });
    });

    group('signOut', () {
      test('calls supabase auth.signOut', () async {
        when(mockGoTrue.signOut()).thenAnswer((_) async {});

        await authService.signOut();

        verify(mockGoTrue.signOut()).called(1);
      });
    });

    group('authStateChanges', () {
      test('returns auth state changes stream', () {
        final streamController = StreamController<AuthState>();
        final expectedStream = streamController.stream;
        when(mockGoTrue.onAuthStateChange).thenAnswer((_) => expectedStream);

        final stream = authService.authStateChanges;

        expect(stream, same(expectedStream));
        streamController.close();
      });
    });

    group('currentUser', () {
      test('returns current user from supabase', () {
        final mockUser = User(
          id: 'user_001',
          appMetadata: {},
          userMetadata: null,
          aud: 'authenticated',
          createdAt: DateTime.now().toIso8601String(),
        );
        when(mockGoTrue.currentUser).thenReturn(mockUser);

        final user = authService.currentUser;

        expect(user, same(mockUser));
      });

      test('returns null when no user is logged in', () {
        when(mockGoTrue.currentUser).thenReturn(null);

        final user = authService.currentUser;

        expect(user, isNull);
      });
    });
  });
}
