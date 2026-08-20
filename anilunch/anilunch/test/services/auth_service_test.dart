import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:anilunch/services/auth_service.dart';
import 'auth_service_test.mocks.dart';

// Generate mocks for SupabaseClient and related classes
@GenerateMocks([SupabaseClient, GoTrueClient, User, PostgrestClient, PostgrestQueryBuilder])
void main() {
  group('AuthService', () {
    late AuthService authService;
    late MockSupabaseClient mockClient;
    late MockGoTrueClient mockGoTrue;
    late MockPostgrestClient mockPostgrest;
    late MockPostgrestQueryBuilder mockQueryBuilder;

    setUp(() {
      mockClient = MockSupabaseClient();
      mockGoTrue = MockGoTrueClient();
      mockPostgrest = MockPostgrestClient();
      mockQueryBuilder = MockPostgrestQueryBuilder();

      // Wire up mocks
      when(mockClient.auth).thenReturn(mockGoTrue);
      when((mockClient as dynamic).from(any)).thenReturn(mockQueryBuilder);

      authService = AuthService(client: mockClient);
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

        when((mockQueryBuilder as dynamic).insert(any)).thenAnswer((_) async => []);

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

        verify(mockQueryBuilder.insert({
          'id': 'user_001',
          'user_id': 'user_001',
          'name': 'New User',
          'email': 'new@example.com',
          'phone_number': '9999999999',
          'address': '123 Main St',
          'pin_code': '400001',
        })).called(1);
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

        verifyNever(mockQueryBuilder.insert(any));
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
        when(mockGoTrue.onAuthStateChange).thenAnswer((_) => streamController.stream);

        final stream = authService.authStateChanges;

        expect(stream, same(streamController.stream));
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
