# Testing Patterns for Flutter Enterprise Apps

## Overview

Comprehensive testing strategy for Flutter enterprise applications using clean architecture and feature-based structure.

## Testing Pyramid

```
    E2E Tests (10%)
   ─────────────────
  Integration Tests (20%)
 ─────────────────────────
Unit Tests (70%)
```

## Unit Testing

### Domain Layer Testing

#### Entity Testing
```dart
// test/features/user/domain/entities/user_entity_test.dart
import 'package:flutter_test/flutter_test.dart';
import '../../../../../lib/features/user/domain/entities/user_entity.dart';

void main() {
  group('UserEntity', () {
    const testUser = UserEntity(
      id: '1',
      name: 'Test User',
      email: 'test@example.com',
      avatar: 'avatar.jpg',
      createdAt: '2023-01-01T00:00:00.000Z',
      updatedAt: '2023-01-01T00:00:00.000Z',
    );

    test('should create UserEntity with valid data', () {
      expect(testUser.id, '1');
      expect(testUser.name, 'Test User');
      expect(testUser.email, 'test@example.com');
      expect(testUser.avatar, 'avatar.jpg');
    });

    test('should support equality', () {
      const user1 = UserEntity(
        id: '1',
        name: 'Test User',
        email: 'test@example.com',
        createdAt: '2023-01-01T00:00:00.000Z',
        updatedAt: '2023-01-01T00:00:00.000Z',
      );

      const user2 = UserEntity(
        id: '1',
        name: 'Test User',
        email: 'test@example.com',
        createdAt: '2023-01-01T00:00:00.000Z',
        updatedAt: '2023-01-01T00:00:00.000Z',
      );

      expect(user1, equals(user2));
    });

    test('should copyWith correctly', () {
      final updatedUser = testUser.copyWith(name: 'Updated User');

      expect(updatedUser.id, testUser.id);
      expect(updatedUser.name, 'Updated User');
      expect(updatedUser.email, testUser.email);
    });

    test('should validate email format', () {
      expect(testUser.isValidEmail(), isTrue);

      const invalidUser = UserEntity(
        id: '2',
        name: 'Invalid User',
        email: 'invalid-email',
        createdAt: '2023-01-01T00:00:00.000Z',
        updatedAt: '2023-01-01T00:00:00.000Z',
      );

      expect(invalidUser.isValidEmail(), isFalse);
    });
  });
}
```

#### Use Case Testing
```dart
// test/features/user/domain/usecases/get_users_usecase_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import '../../../../../lib/features/user/domain/entities/user_entity.dart';
import '../../../../../lib/features/user/domain/repositories/user_repository.dart';
import '../../../../../lib/features/user/domain/usecases/get_users_usecase.dart';

import 'get_users_usecase_test.mocks.dart';

@GenerateMocks([UserRepository])
void main() {
  late GetUsersUseCase useCase;
  late MockUserRepository mockRepository;

  setUp(() {
    mockRepository = MockUserRepository();
    useCase = GetUsersUseCase(mockRepository);
  });

  const testUsers = [
    UserEntity(
      id: '1',
      name: 'User 1',
      email: 'user1@example.com',
      createdAt: '2023-01-01T00:00:00.000Z',
      updatedAt: '2023-01-01T00:00:00.000Z',
    ),
    UserEntity(
      id: '2',
      name: 'User 2',
      email: 'user2@example.com',
      createdAt: '2023-01-01T00:00:00.000Z',
      updatedAt: '2023-01-01T00:00:00.000Z',
    ),
  ];

  test('should get users from repository', () async {
    // Arrange
    when(mockRepository.getUsers(page: 1, limit: 20))
        .thenAnswer((_) async => testUsers);

    // Act
    final result = await useCase(page: 1, limit: 20);

    // Assert
    expect(result, testUsers);
    verify(mockRepository.getUsers(page: 1, limit: 20));
  });

  test('should throw ArgumentError when page is less than 1', () async {
    // Act & Assert
    expect(
      () => useCase(page: 0, limit: 20),
      throwsA(isA<ArgumentException>()),
    );
  });

  test('should throw ArgumentError when limit is out of range', () async {
    // Act & Assert
    expect(
      () => useCase(page: 1, limit: 0),
      throwsA(isA<ArgumentException>()),
    );

    expect(
      () => useCase(page: 1, limit: 101),
      throwsA(isA<ArgumentException>()),
    );
  });

  test('should propagate repository exceptions', () async {
    // Arrange
    when(mockRepository.getUsers(page: 1, limit: 20))
        .thenThrow(ServerException('Network error'));

    // Act & Assert
    expect(
      () => useCase(page: 1, limit: 20),
      throwsA(isA<ServerException>()),
    );
  });
}
```

### Data Layer Testing

#### Model Testing
```dart
// test/features/user/data/models/user_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import '../../../../../lib/features/user/data/models/user_model.dart';
import '../../../../../lib/features/user/domain/entities/user_entity.dart';

void main() {
  group('UserModel', () {
    const testJson = {
      'id': '1',
      'name': 'Test User',
      'email': 'test@example.com',
      'avatar': 'avatar.jpg',
      'created_at': '2023-01-01T00:00:00.000Z',
      'updated_at': '2023-01-01T00:00:00.000Z',
    };

    test('should create UserModel from JSON', () {
      final result = UserModel.fromJson(testJson);

      expect(result.id, '1');
      expect(result.name, 'Test User');
      expect(result.email, 'test@example.com');
      expect(result.avatar, 'avatar.jpg');
    });

    test('should convert to JSON', () {
      const model = UserModel(
        id: '1',
        name: 'Test User',
        email: 'test@example.com',
        avatar: 'avatar.jpg',
        createdAt: '2023-01-01T00:00:00.000Z',
        updatedAt: '2023-01-01T00:00:00.000Z',
      );

      final result = model.toJson();

      expect(result, testJson);
    });

    test('should convert to entity', () {
      const model = UserModel(
        id: '1',
        name: 'Test User',
        email: 'test@example.com',
        createdAt: '2023-01-01T00:00:00.000Z',
        updatedAt: '2023-01-01T00:00:00.000Z',
      );

      final entity = model.toEntity();

      expect(entity.id, model.id);
      expect(entity.name, model.name);
      expect(entity.email, model.email);
      expect(entity.avatar, model.avatar);
    });

    test('should create from entity', () {
      const entity = UserEntity(
        id: '1',
        name: 'Test User',
        email: 'test@example.com',
        avatar: 'avatar.jpg',
        createdAt: '2023-01-01T00:00:00.000Z',
        updatedAt: '2023-01-01T00:00:00.000Z',
      );

      final model = UserModel.fromEntity(entity);

      expect(model.id, entity.id);
      expect(model.name, entity.name);
      expect(model.email, entity.email);
      expect(model.avatar, entity.avatar);
    });
  });
}
```

#### Repository Implementation Testing
```dart
// test/features/user/data/repositories/user_repository_impl_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import '../../../../../lib/features/user/data/repositories/user_repository_impl.dart';
import '../../../../../lib/features/user/data/datasources/user_remote_data_source.dart';
import '../../../../../lib/features/user/data/datasources/user_local_data_source.dart';
import '../../../../../lib/features/user/domain/entities/user_entity.dart';
import '../../../../../lib/core/network/network_info.dart';
import '../../../../../lib/core/exceptions/exceptions.dart';

import 'user_repository_impl_test.mocks.dart';

@GenerateMocks([
  UserRemoteDataSource,
  UserLocalDataSource,
  NetworkInfo,
])
void main() {
  late UserRepositoryImpl repository;
  late MockUserRemoteDataSource mockRemoteDataSource;
  late MockUserLocalDataSource mockLocalDataSource;
  late MockNetworkInfo mockNetworkInfo;

  setUp(() {
    mockRemoteDataSource = MockUserRemoteDataSource();
    mockLocalDataSource = MockUserLocalDataSource();
    mockNetworkInfo = MockNetworkInfo();

    repository = UserRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
      networkInfo: mockNetworkInfo,
    );
  });

  group('getUsers', () {
    const testUserModels = [
      UserModel(
        id: '1',
        name: 'User 1',
        email: 'user1@example.com',
        createdAt: '2023-01-01T00:00:00.000Z',
        updatedAt: '2023-01-01T00:00:00.000Z',
      ),
    ];

    test('should return remote data when device is online', () async {
      // Arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemoteDataSource.getUsers(page: 1, limit: 20))
          .thenAnswer((_) async => testUserModels);

      // Act
      final result = await repository.getUsers();

      // Assert
      expect(result, isA<List<UserEntity>>());
      verify(mockRemoteDataSource.getUsers(page: 1, limit: 20));
      verify(mockLocalDataSource.cacheUsers(testUserModels));
    });

    test('should return cached data when device is offline', () async {
      // Arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      when(mockLocalDataSource.getCachedUsers())
          .thenAnswer((_) async => testUserModels);

      // Act
      final result = await repository.getUsers();

      // Assert
      expect(result, isA<List<UserEntity>>());
      verify(mockLocalDataSource.getCachedUsers());
      verifyNever(mockRemoteDataSource.getUsers());
    });

    test('should return cached data when server fails', () async {
      // Arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemoteDataSource.getUsers(page: 1, limit: 20))
          .thenThrow(ServerException('Server error'));
      when(mockLocalDataSource.getCachedUsers())
          .thenAnswer((_) async => testUserModels);

      // Act
      final result = await repository.getUsers();

      // Assert
      expect(result, isA<List<UserEntity>>());
      verify(mockRemoteDataSource.getUsers(page: 1, limit: 20));
      verify(mockLocalDataSource.getCachedUsers());
    });
  });
}
```

### Presentation Layer Testing

#### Provider Testing
```dart
// test/features/user/presentation/providers/user_provider_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import '../../../../../lib/features/user/presentation/providers/user_provider.dart';
import '../../../../../lib/features/user/domain/entities/user_entity.dart';
import '../../../../../lib/features/user/domain/usecases/get_users_usecase.dart';
import '../../../../../lib/features/user/domain/usecases/create_user_usecase.dart';
import '../../../../../lib/features/user/domain/usecases/search_users_usecase.dart';

import 'user_provider_test.mocks.dart';

@GenerateMocks([
  GetUsersUseCase,
  CreateUserUseCase,
  SearchUsersUseCase,
])
void main() {
  late UserProvider provider;
  late MockGetUsersUseCase mockGetUsersUseCase;
  late MockCreateUserUseCase mockCreateUserUseCase;
  late MockSearchUsersUseCase mockSearchUsersUseCase;

  setUp(() {
    mockGetUsersUseCase = MockGetUsersUseCase();
    mockCreateUserUseCase = MockCreateUserUseCase();
    mockSearchUsersUseCase = MockSearchUsersUseCase();

    provider = UserProvider(
      getUsersUseCase: mockGetUsersUseCase,
      createUserUseCase: mockCreateUserUseCase,
      searchUsersUseCase: mockSearchUsersUseCase,
    );
  });

  const testUsers = [
    UserEntity(
      id: '1',
      name: 'User 1',
      email: 'user1@example.com',
      createdAt: '2023-01-01T00:00:00.000Z',
      updatedAt: '2023-01-01T00:00:00.000Z',
    ),
  ];

  test('should initialize with empty state', () {
    expect(provider.users, isEmpty);
    expect(provider.searchResults, isEmpty);
    expect(provider.isLoading, isFalse);
    expect(provider.isSearching, isFalse);
    expect(provider.error, isNull);
  });

  test('should load users successfully', () async {
    // Arrange
    when(mockGetUsersUseCase(page: 1, limit: 20))
        .thenAnswer((_) async => testUsers);

    // Act
    await provider.loadUsers();

    // Assert
    expect(provider.users, testUsers);
    expect(provider.isLoading, isFalse);
    expect(provider.error, isNull);
    verify(mockGetUsersUseCase(page: 1, limit: 20));
  });

  test('should handle loading state', () async {
    // Arrange
    when(mockGetUsersUseCase(page: 1, limit: 20))
        .thenAnswer((_) async {
      await Future.delayed(Duration(milliseconds: 100));
      return testUsers;
    });

    // Act
    final future = provider.loadUsers();

    // Assert loading state
    expect(provider.isLoading, isTrue);

    await future;

    // Assert completion state
    expect(provider.isLoading, isFalse);
  });

  test('should handle error state', () async {
    // Arrange
    when(mockGetUsersUseCase(page: 1, limit: 20))
        .thenThrow(Exception('Network error'));

    // Act
    await provider.loadUsers();

    // Assert
    expect(provider.users, isEmpty);
    expect(provider.isLoading, isFalse);
    expect(provider.error, 'Exception: Network error');
  });

  test('should search users', () async {
    // Arrange
    when(mockSearchUsersUseCase('test'))
        .thenAnswer((_) async => testUsers);

    // Act
    await provider.searchUsers('test');

    // Assert
    expect(provider.searchResults, testUsers);
    expect(provider.isSearching, isFalse);
    verify(mockSearchUsersUseCase('test'));
  });

  test('should clear search results when query is empty', () async {
    // Act
    await provider.searchUsers('');

    // Assert
    expect(provider.searchResults, isEmpty);
    expect(provider.isSearching, isFalse);
    verifyNever(mockSearchUsersUseCase(any));
  });
});
```

#### Bloc Testing
```dart
// test/features/user/presentation/bloc/user_bloc_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import '../../../../../lib/features/user/presentation/bloc/user_bloc.dart';
import '../../../../../lib/features/user/domain/entities/user_entity.dart';
import '../../../../../lib/features/user/domain/usecases/get_users_usecase.dart';
import '../../../../../lib/features/user/domain/usecases/create_user_usecase.dart';
import '../../../../../lib/features/user/domain/usecases/search_users_usecase.dart';

import 'user_bloc_test.mocks.dart';

@GenerateMocks([
  GetUsersUseCase,
  CreateUserUseCase,
  SearchUsersUseCase,
])
void main() {
  late UserBloc bloc;
  late MockGetUsersUseCase mockGetUsersUseCase;
  late MockCreateUserUseCase mockCreateUserUseCase;
  late MockSearchUsersUseCase mockSearchUsersUseCase;

  setUp(() {
    mockGetUsersUseCase = MockGetUsersUseCase();
    mockCreateUserUseCase = MockCreateUserUseCase();
    mockSearchUsersUseCase = MockSearchUsersUseCase();

    bloc = UserBloc(
      getUsersUseCase: mockGetUsersUseCase,
      createUserUseCase: mockCreateUserUseCase,
      searchUsersUseCase: mockSearchUsersUseCase,
    );
  });

  const testUsers = [
    UserEntity(
      id: '1',
      name: 'User 1',
      email: 'user1@example.com',
      createdAt: '2023-01-01T00:00:00.000Z',
      updatedAt: '2023-01-01T00:00:00.000Z',
    ),
  ];

  blocTest<UserBloc, UserState>(
    'should emit loading and loaded states when loading users',
    build: () {
      when(mockGetUsersUseCase(page: 1, limit: 20))
          .thenAnswer((_) async => testUsers);
      return bloc;
    },
    act: (bloc) => bloc.add(LoadUsers()),
    expect: () => [
      UserLoading(),
      UserLoaded(users: testUsers, hasMore: false),
    ],
    verify: (_) => verify(mockGetUsersUseCase(page: 1, limit: 20)).called(1),
  );

  blocTest<UserBloc, UserState>(
    'should emit error state when loading users fails',
    build: () {
      when(mockGetUsersUseCase(page: 1, limit: 20))
          .thenThrow(Exception('Network error'));
      return bloc;
    },
    act: (bloc) => bloc.add(LoadUsers()),
    expect: () => [
      UserLoading(),
      UserError('Exception: Network error'),
    ],
    verify: (_) => verify(mockGetUsersUseCase(page: 1, limit: 20)).called(1),
  );

  blocTest<UserBloc, UserState>(
    'should emit search results when searching users',
    build: () {
      when(mockSearchUsersUseCase('test'))
          .thenAnswer((_) async => testUsers);
      return bloc;
    },
    act: (bloc) => bloc.add(SearchUsers('test')),
    expect: () => [
      UserLoaded(users: [], hasMore: true, isSearching: true),
      UserLoaded(users: [], hasMore: true, searchResults: testUsers, isSearching: false),
    ],
    verify: (_) => verify(mockSearchUsersUseCase('test')).called(1),
  );

  blocTest<UserBloc, UserState>(
    'should clear search results when query is empty',
    build: () => bloc,
    act: (bloc) => bloc.add(SearchUsers('')),
    expect: () => [
      UserLoaded(users: [], hasMore: true, searchResults: [], isSearching: false),
    ],
    verify: (_) => verifyNever(mockSearchUsersUseCase(any)),
  );

  blocTest<UserBloc, UserState>(
    'should create user and refresh list',
    build: () {
      when(mockCreateUserUseCase(testUsers.first))
          .thenAnswer((_) async => testUsers.first);
      when(mockGetUsersUseCase(page: 1, limit: 20))
          .thenAnswer((_) async => testUsers);
      return bloc;
    },
    act: (bloc) => bloc.add(CreateUser(testUsers.first)),
    expect: () => [
      UserLoading(),
      UserLoaded(users: testUsers, hasMore: false),
    ],
    verify: (_) {
      verify(mockCreateUserUseCase(testUsers.first)).called(1);
      verify(mockGetUsersUseCase(page: 1, limit: 20)).called(1);
    },
  );
}
```

#### Riverpod Testing
```dart
// test/features/user/presentation/providers/user_provider_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import '../../../../../lib/features/user/presentation/providers/user_provider.dart';
import '../../../../../lib/features/user/domain/entities/user_entity.dart';
import '../../../../../lib/features/user/domain/usecases/get_users_usecase.dart';
import '../../../../../lib/features/user/domain/usecases/create_user_usecase.dart';
import '../../../../../lib/features/user/domain/usecases/search_users_usecase.dart';

import 'user_provider_test.mocks.dart';

@GenerateMocks([
  GetUsersUseCase,
  CreateUserUseCase,
  SearchUsersUseCase,
])
void main() {
  late UserNotifier notifier;
  late MockGetUsersUseCase mockGetUsersUseCase;
  late MockCreateUserUseCase mockCreateUserUseCase;
  late MockSearchUsersUseCase mockSearchUsersUseCase;

  setUp(() {
    mockGetUsersUseCase = MockGetUsersUseCase();
    mockCreateUserUseCase = MockCreateUserUseCase();
    mockSearchUsersUseCase = MockSearchUsersUseCase();

    notifier = UserNotifier(
      getUsersUseCase: mockGetUsersUseCase,
      createUserUseCase: mockCreateUserUseCase,
      searchUsersUseCase: mockSearchUsersUseCase,
    );
  });

  const testUsers = [
    UserEntity(
      id: '1',
      name: 'User 1',
      email: 'user1@example.com',
      createdAt: '2023-01-01T00:00:00.000Z',
      updatedAt: '2023-01-01T00:00:00.000Z',
    ),
  ];

  test('should initialize with empty state', () {
    expect(notifier.state.users, isEmpty);
    expect(notifier.state.searchResults, isEmpty);
    expect(notifier.state.isLoading, isFalse);
    expect(notifier.state.isSearching, isFalse);
    expect(notifier.state.error, isNull);
  });

  test('should load users successfully', () async {
    // Arrange
    when(mockGetUsersUseCase(page: 1, limit: 20))
        .thenAnswer((_) async => testUsers);

    // Act
    await notifier.loadUsers();

    // Assert
    expect(notifier.state.users, testUsers);
    expect(notifier.state.isLoading, isFalse);
    expect(notifier.state.error, isNull);
    verify(mockGetUsersUseCase(page: 1, limit: 20));
  });

  test('should handle loading state', () async {
    // Arrange
    when(mockGetUsersUseCase(page: 1, limit: 20))
        .thenAnswer((_) async {
      await Future.delayed(Duration(milliseconds: 100));
      return testUsers;
    });

    // Act
    final future = notifier.loadUsers();

    // Assert loading state
    expect(notifier.state.isLoading, isTrue);

    await future;

    // Assert completion state
    expect(notifier.state.isLoading, isFalse);
  });

  test('should handle error state', () async {
    // Arrange
    when(mockGetUsersUseCase(page: 1, limit: 20))
        .thenThrow(Exception('Network error'));

    // Act
    await notifier.loadUsers();

    // Assert
    expect(notifier.state.users, isEmpty);
    expect(notifier.state.isLoading, isFalse);
    expect(notifier.state.error, 'Exception: Network error');
  });

  test('should search users', () async {
    // Arrange
    when(mockSearchUsersUseCase('test'))
        .thenAnswer((_) async => testUsers);

    // Act
    await notifier.searchUsers('test');

    // Assert
    expect(notifier.state.searchResults, testUsers);
    expect(notifier.state.isSearching, isFalse);
    verify(mockSearchUsersUseCase('test'));
  });

  test('should clear search results when query is empty', () async {
    // Act
    await notifier.searchUsers('');

    // Assert
    expect(notifier.state.searchResults, isEmpty);
    expect(notifier.state.isSearching, isFalse);
    verifyNever(mockSearchUsersUseCase(any));
  });

  test('should clear error', () {
    // Arrange
    notifier.state = notifier.state.copyWith(error: 'Test error');

    // Act
    notifier.clearError();

    // Assert
    expect(notifier.state.error, isNull);
  });

  test('should work with Riverpod provider', () async {
    // Arrange
    final container = ProviderContainer();
    when(mockGetUsersUseCase(page: 1, limit: 20))
        .thenAnswer((_) async => testUsers);

    // Override providers for testing
    container.overrideProvider(getUsersUseCaseProvider, (_) => mockGetUsersUseCase);
    container.overrideProvider(createUserUseCaseProvider, (_) => mockCreateUserUseCase);
    container.overrideProvider(searchUsersUseCaseProvider, (_) => mockSearchUsersUseCase);

    // Act
    final userNotifier = container.read(userProvider.notifier);
    await userNotifier.loadUsers();

    // Assert
    final state = container.read(userProvider);
    expect(state.users, testUsers);
    expect(state.isLoading, isFalse);
    expect(state.error, isNull);
  });
});
```

#### GetX Controller Testing
```dart
// test/features/user/presentation/controllers/user_controller_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import '../../../../../lib/features/user/presentation/controllers/user_controller.dart';
import '../../../../../lib/features/user/domain/entities/user_entity.dart';
import '../../../../../lib/features/user/domain/usecases/get_users_usecase.dart';
import '../../../../../lib/features/user/domain/usecases/create_user_usecase.dart';
import '../../../../../lib/features/user/domain/usecases/search_users_usecase.dart';

import 'user_controller_test.mocks.dart';

@GenerateMocks([
  GetUsersUseCase,
  CreateUserUseCase,
  SearchUsersUseCase,
])
void main() {
  late UserController controller;
  late MockGetUsersUseCase mockGetUsersUseCase;
  late MockCreateUserUseCase mockCreateUserUseCase;
  late MockSearchUsersUseCase mockSearchUsersUseCase;

  setUp(() {
    // Initialize GetX testing
    Get.testMode = true;

    mockGetUsersUseCase = MockGetUsersUseCase();
    mockCreateUserUseCase = MockCreateUserUseCase();
    mockSearchUsersUseCase = MockSearchUsersUseCase();

    controller = UserController(
      getUsersUseCase: mockGetUsersUseCase,
      createUserUseCase: mockCreateUserUseCase,
      searchUsersUseCase: mockSearchUsersUseCase,
    );
  });

  tearDown(() {
    Get.reset();
  });

  const testUsers = [
    UserEntity(
      id: '1',
      name: 'User 1',
      email: 'user1@example.com',
      createdAt: '2023-01-01T00:00:00.000Z',
      updatedAt: '2023-01-01T00:00:00.000Z',
    ),
  ];

  test('should initialize with empty state', () {
    expect(controller.users, isEmpty);
    expect(controller.searchResults, isEmpty);
    expect(controller.isLoading, isFalse);
    expect(controller.isSearching, isFalse);
    expect(controller.error, isNull);
  });

  test('should load users successfully', () async {
    // Arrange
    when(mockGetUsersUseCase(page: 1, limit: 20))
        .thenAnswer((_) async => testUsers);

    // Act
    await controller.loadUsers();

    // Assert
    expect(controller.users, testUsers);
    expect(controller.isLoading, isFalse);
    expect(controller.error, isNull);
    verify(mockGetUsersUseCase(page: 1, limit: 20));
  });

  test('should handle loading state', () async {
    // Arrange
    when(mockGetUsersUseCase(page: 1, limit: 20))
        .thenAnswer((_) async {
      await Future.delayed(Duration(milliseconds: 100));
      return testUsers;
    });

    // Act
    final future = controller.loadUsers();

    // Assert loading state
    expect(controller.isLoading, isTrue);

    await future;

    // Assert completion state
    expect(controller.isLoading, isFalse);
  });

  test('should handle error state', () async {
    // Arrange
    when(mockGetUsersUseCase(page: 1, limit: 20))
        .thenThrow(Exception('Network error'));

    // Act
    await controller.loadUsers();

    // Assert
    expect(controller.users, isEmpty);
    expect(controller.isLoading, isFalse);
    expect(controller.error, 'Exception: Network error');
  });

  test('should search users', () async {
    // Arrange
    when(mockSearchUsersUseCase('test'))
        .thenAnswer((_) async => testUsers);

    // Act
    await controller.searchUsers('test');

    // Assert
    expect(controller.searchResults, testUsers);
    expect(controller.isSearching, isFalse);
    verify(mockSearchUsersUseCase('test'));
  });

  test('should clear search results when query is empty', () async {
    // Act
    await controller.searchUsers('');

    // Assert
    expect(controller.searchResults, isEmpty);
    expect(controller.isSearching, isFalse);
    verifyNever(mockSearchUsersUseCase(any));
  });

  test('should clear error', () {
    // Arrange
    controller._error.value = 'Test error';

    // Act
    controller.clearError();

    // Assert
    expect(controller.error, isNull);
  });

  test('should work with GetX binding', () async {
    // Arrange
    final binding = UserBinding();
    when(mockGetUsersUseCase(page: 1, limit: 20))
        .thenAnswer((_) async => testUsers);

    // Act
    binding.dependencies();
    final userController = Get.find<UserController>();
    await userController.loadUsers();

    // Assert
    expect(userController.users, testUsers);
    expect(userController.isLoading, isFalse);
    expect(userController.error, isNull);
  });
}
```

## Widget Testing

### Page Testing
```dart
// test/features/user/presentation/pages/user_list_page_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import '../../../../../lib/features/user/presentation/pages/user_list_page.dart';
import '../../../../../lib/features/user/presentation/providers/user_provider.dart';
import '../../../../../lib/features/user/domain/entities/user_entity.dart';

import '../../mocks/user_provider_mock.dart';

void main() {
  group('UserListPage', () {
    late MockUserProvider mockProvider;

    setUp(() {
      mockProvider = MockUserProvider();
    });

    testWidgets('should show loading indicator', (WidgetTester tester) async {
      // Arrange
      when(mockProvider.isLoading).thenReturn(true);
      when(mockProvider.users).thenReturn([]);
      when(mockProvider.error).thenReturn(null);

      // Act
      await tester.pumpWidget(
        ChangeNotifierProvider<UserProvider>.value(
          value: mockProvider,
          child: MaterialApp(home: UserListPage()),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display user list', (WidgetTester tester) async {
      // Arrange
      const testUsers = [
        UserEntity(
          id: '1',
          name: 'User 1',
          email: 'user1@example.com',
          createdAt: '2023-01-01T00:00:00.000Z',
          updatedAt: '2023-01-01T00:00:00.000Z',
        ),
      ];

      when(mockProvider.isLoading).thenReturn(false);
      when(mockProvider.users).thenReturn(testUsers);
      when(mockProvider.error).thenReturn(null);

      // Act
      await tester.pumpWidget(
        ChangeNotifierProvider<UserProvider>.value(
          value: mockProvider,
          child: MaterialApp(home: UserListPage()),
        ),
      );

      // Assert
      expect(find.text('User 1'), findsOneWidget);
      expect(find.text('user1@example.com'), findsOneWidget);
    });

    testWidgets('should show error message', (WidgetTester tester) async {
      // Arrange
      when(mockProvider.isLoading).thenReturn(false);
      when(mockProvider.users).thenReturn([]);
      when(mockProvider.error).thenReturn('Network error');

      // Act
      await tester.pumpWidget(
        ChangeNotifierProvider<UserProvider>.value(
          value: mockProvider,
          child: MaterialApp(home: UserListPage()),
        ),
      );

      // Assert
      expect(find.text('Error: Network error'), findsOneWidget);
    });
  });
}
```

#### GetX Widget Testing
```dart
// test/features/user/presentation/pages/user_list_page_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_test/get_test.dart';
import '../../../../../lib/features/user/presentation/pages/user_list_page.dart';
import '../../../../../lib/features/user/presentation/controllers/user_controller.dart';
import '../../../../../lib/features/user/domain/entities/user_entity.dart';

import '../../mocks/user_controller_mock.dart';

void main() {
  group('UserListPage with GetX', () {
    setUp(() {
      Get.testMode = true;
    });

    tearDown(() {
      Get.reset();
    });

    testWidgets('should show loading indicator', (WidgetTester tester) async {
      // Arrange
      final controller = MockUserController();
      when(controller.isLoading).thenReturn(true);
      when(controller.users).thenReturn([]);
      when(controller.error).thenReturn(null);

      // Act
      await tester.pumpWidget(
        GetMaterialApp(
          home: UserListPage(),
          bindings: BindingsBuilder(() {
            Get.lazyPut<UserController>(() => controller);
          }),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display user list', (WidgetTester tester) async {
      // Arrange
      const testUsers = [
        UserEntity(
          id: '1',
          name: 'User 1',
          email: 'user1@example.com',
          createdAt: '2023-01-01T00:00:00.000Z',
          updatedAt: '2023-01-01T00:00:00.000Z',
        ),
      ];

      final controller = MockUserController();
      when(controller.isLoading).thenReturn(false);
      when(controller.users).thenReturn(testUsers);
      when(controller.error).thenReturn(null);

      // Act
      await tester.pumpWidget(
        GetMaterialApp(
          home: UserListPage(),
          bindings: BindingsBuilder(() {
            Get.lazyPut<UserController>(() => controller);
          }),
        ),
      );

      // Assert
      expect(find.text('User 1'), findsOneWidget);
      expect(find.text('user1@example.com'), findsOneWidget);
    });

    testWidgets('should show error message', (WidgetTester tester) async {
      // Arrange
      final controller = MockUserController();
      when(controller.isLoading).thenReturn(false);
      when(controller.users).thenReturn([]);
      when(controller.error).thenReturn('Network error');

      // Act
      await tester.pumpWidget(
        GetMaterialApp(
          home: UserListPage(),
          bindings: BindingsBuilder(() {
            Get.lazyPut<UserController>(() => controller);
          }),
        ),
      );

      // Assert
      expect(find.text('Error: Network error'), findsOneWidget);
    });
  });
}
```

## Integration Testing

### Feature Integration Testing
```dart
// integration_test/user_feature_integration_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:my_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('User Feature Integration Tests', () {
    testWidgets('should create and display user', (WidgetTester tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();

      // Navigate to user creation
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Fill user form
      await tester.enterText(find.byKey(Key('name_field')), 'Test User');
      await tester.enterText(find.byKey(Key('email_field')), 'test@example.com');

      // Submit form
      await tester.tap(find.byKey(Key('submit_button')));
      await tester.pumpAndSettle();

      // Assert user is created and displayed
      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('should search users', (WidgetTester tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();

      // Search for user
      await tester.enterText(find.byType(TextField), 'Test');
      await tester.pumpAndSettle();

      // Assert search results
      expect(find.text('Test User'), findsOneWidget);
    });
  });
}
```

## Testing Utilities

### Test Helpers
```dart
// test/helpers/test_helpers.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class TestHelpers {
  static Widget createWidgetUnderTest(Widget child) {
    return MaterialApp(
      home: Scaffold(body: child),
    );
  }

  static Future<void> pumpAndSettleWithDelay(
    WidgetTester tester, {
    Duration duration = const Duration(milliseconds: 100),
  }) async {
    await tester.pump();
    await Future.delayed(duration);
    await tester.pumpAndSettle();
  }

  static void expectNoOverflow() {
    expect(find.byType(Overflow), findsNothing);
  }

  static void expectVisible(Key key) {
    expect(find.byKey(key), findsOneWidget);
  }

  static void expectHidden(Key key) {
    expect(find.byKey(key), findsNothing);
  }
}
```

### Mock Factories
```dart
// test/mocks/mock_factories.dart
import '../../../lib/features/user/domain/entities/user_entity.dart';
import '../../../lib/features/user/data/models/user_model.dart';

class MockFactories {
  static UserEntity createTestUser({
    String id = '1',
    String name = 'Test User',
    String email = 'test@example.com',
  }) {
    return const UserEntity(
      id: '1',
      name: 'Test User',
      email: 'test@example.com',
      createdAt: '2023-01-01T00:00:00.000Z',
      updatedAt: '2023-01-01T00:00:00.000Z',
    );
  }

  static List<UserEntity> createTestUserList({int count = 3}) {
    return List.generate(count, (index) => createTestUser(
      id: index.toString(),
      name: 'User $index',
      email: 'user$index@example.com',
    ));
  }

  static UserModel createTestUserModel({
    String id = '1',
    String name = 'Test User',
    String email = 'test@example.com',
  }) {
    return const UserModel(
      id: '1',
      name: 'Test User',
      email: 'test@example.com',
      createdAt: '2023-01-01T00:00:00.000Z',
      updatedAt: '2023-01-01T00:00:00.000Z',
    );
  }
}
```

## Test Configuration

### pubspec.yaml Test Dependencies
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  mockito: ^5.4.2
  build_runner: ^2.4.6
  mockito_generator: ^5.4.2
  fake_async: ^1.3.1
  network_image_mock: ^2.1.1
  golden_toolkit: ^0.15.0
  get_test: ^3.0.0  # For GetX testing
```

### Test Runner Configuration
```dart
// test/test_config.dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Global test setup
  setUpAll(() {
    // Initialize test dependencies
  });

  tearDownAll(() {
    // Clean up test dependencies
  });
}
```

## Best Practices

1. **Test Pyramid**: Focus on unit tests (70%), integration tests (20%), and E2E tests (10%)
2. **Descriptive Tests**: Use clear, descriptive test names that explain what is being tested
3. **AAA Pattern**: Arrange, Act, Assert structure for tests
4. **Mock External Dependencies**: Mock all external dependencies in unit tests
5. **Test Coverage**: Aim for 80%+ coverage on domain and data layers
6. **Independent Tests**: Tests should not depend on each other
7. **Fast Tests**: Unit tests should run in milliseconds
8. **CI Integration**: Run tests automatically on every commit