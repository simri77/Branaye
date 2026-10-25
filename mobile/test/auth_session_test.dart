import 'package:branaye/data/api/auth_repository.dart';
import 'package:branaye/data/api/fcm_service.dart';
import 'package:branaye/data/api/notes_repository.dart';
import 'package:branaye/data/api/token_store.dart';
import 'package:branaye/data/providers.dart';
import 'package:branaye/core/models/note.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'registration waits for email verification and does not save a session',
    () async {
      final tokenStore = _MemoryTokenStore();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
          tokenStoreProvider.overrideWithValue(tokenStore),
          fcmServiceProvider.overrideWith((ref) => _NoopFcmService(ref)),
        ],
      );
      addTearDown(container.dispose);

      final success = await container
          .read(authProvider.notifier)
          .register('Ada', 'ada@example.com', 'correct-horse');

      expect(success, isTrue);
      expect(container.read(authProvider).isLoggedIn, isFalse);
      expect(
        container.read(authProvider).errorMessage,
        contains('Check your email'),
      );
      expect(tokenStore.token, isNull);
    },
  );

  test(
    'logout clears the session before a subsequent login is saved',
    () async {
      final tokenStore = _MemoryTokenStore();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
          notesRepositoryProvider.overrideWithValue(_FakeNotesRepository()),
          tokenStoreProvider.overrideWithValue(tokenStore),
          fcmServiceProvider.overrideWith((ref) => _NoopFcmService(ref)),
        ],
      );
      addTearDown(container.dispose);
      final notesSubscription = container.listen(notesProvider, (_, _) {});
      addTearDown(notesSubscription.close);

      final auth = container.read(authProvider.notifier);
      expect(await auth.login('first@example.com', 'password'), isTrue);
      expect(tokenStore.token, 'first@example.com-token');
      await container.read(notesProvider.future);

      final signingOut = auth.logout();
      final signingIn = auth.login('second@example.com', 'password');
      await Future.wait([signingOut, signingIn]);
      await container.read(notesProvider.future);

      expect(container.read(authProvider).isLoggedIn, isTrue);
      expect(container.read(authProvider).user?.email, 'second@example.com');
      expect(tokenStore.token, 'second@example.com-token');
      expect(container.read(notesProvider).value, isEmpty);
    },
  );
}

class _MemoryTokenStore extends TokenStore {
  String? token;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String value) async {
    token = value;
  }

  @override
  Future<void> clear() async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    token = null;
  }
}

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository() : super(Dio());

  @override
  Future<String> register({
    required String name,
    required String email,
    required String password,
  }) async => 'Check your email to verify your account.';

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    return AuthSession(
      accessToken: '$email-token',
      user: AuthUser(id: email, email: email, name: email),
    );
  }
}

class _FakeNotesRepository implements NotesRepository {
  @override
  Future<List<Note>> listAllForBackup() async => [];

  @override
  Future<List<Note>> list({
    String? q,
    String? category,
    List<String>? tags,
    bool includeArchived = false,
    String sort = 'createdAt:desc',
  }) async => [];

  @override
  Future<Note> create(Note note) => throw UnimplementedError();

  @override
  Future<Note> update(Note note) => throw UnimplementedError();

  @override
  Future<void> delete(String id) => throw UnimplementedError();

  @override
  Future<Note?> getById(String id) => throw UnimplementedError();
}

class _NoopFcmService extends FcmService {
  _NoopFcmService(super.ref);

  @override
  Future<void> init() async {}
}
