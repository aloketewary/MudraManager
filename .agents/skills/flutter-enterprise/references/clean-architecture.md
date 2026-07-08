# Clean Architecture Patterns for Flutter

## Overview

Clean Architecture is a software design philosophy that separates concerns into distinct layers, making the system more maintainable, testable, and independent of external frameworks.

## Layer Structure

### 1. Domain Layer (Core Business Logic)

**Purpose**: Contains the core business logic and rules of the application. This layer should be completely independent of any external frameworks or UI.

**Components**:
- **Entities**: Core business objects with no dependencies
- **Repository Interfaces**: Abstract contracts for data access
- **Use Cases**: Application-specific business rules

```dart
// Entity Example
class User {
  final String id;
  final String name;
  final String email;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
  });

  // Business logic methods
  bool isValidEmail() {
    return email.contains('@');
  }
}

// Repository Interface Example
abstract class UserRepository {
  Future<List<User>> getUsers();
  Future<User> getUserById(String id);
  Future<void> createUser(User user);
  Future<void> updateUser(User user);
  Future<void> deleteUser(String id);
}

// Use Case Example
class GetUserByIdUseCase {
  final UserRepository _repository;

  GetUserByIdUseCase(this._repository);

  Future<User?> call(String userId) async {
    if (userId.isEmpty) {
      throw ArgumentError('User ID cannot be empty');
    }

    return await _repository.getUserById(userId);
  }
}
```

### 2. Data Layer (Data Implementation)

**Purpose**: Implements the repository interfaces defined in the domain layer. Handles data sources, caching, and data transformation.

**Components**:
- **Data Sources**: Remote and local data access
- **Models**: Data transfer objects
- **Repository Implementations**: Concrete implementations of domain repositories

```dart
// Data Source Example
abstract class UserRemoteDataSource {
  Future<List<UserModel>> getUsers();
  Future<UserModel?> getUserById(String id);
  Future<void> createUser(UserModel user);
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final HttpClient httpClient;

  UserRemoteDataSourceImpl(this.httpClient);

  @override
  Future<List<UserModel>> getUsers() async {
    final response = await httpClient.get('/users');
    return (response.data as List)
        .map((json) => UserModel.fromJson(json))
        .toList();
  }

  @override
  Future<UserModel?> getUserById(String id) async {
    final response = await httpClient.get('/users/$id');
    return UserModel.fromJson(response.data);
  }
}

// Model Example
class UserModel {
  final String id;
  final String name;
  final String email;
  final String createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'created_at': createdAt,
    };
  }

  // Convert to domain entity
  User toEntity() {
    return User(
      id: id,
      name: name,
      email: email,
      createdAt: DateTime.parse(createdAt),
    );
  }

  // Convert from domain entity
  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      name: user.name,
      email: user.email,
      createdAt: user.createdAt.toIso8601String(),
    );
  }
}

// Repository Implementation Example
class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource remoteDataSource;
  final UserLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  UserRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<List<User>> getUsers() async {
    if (await networkInfo.isConnected) {
      try {
        final remoteUsers = await remoteDataSource.getUsers();
        await localDataSource.cacheUsers(remoteUsers);
        return remoteUsers.map((model) => model.toEntity()).toList();
      } on ServerException {
        // Fallback to local cache if server fails
        return await _getCachedUsers();
      }
    } else {
      return await _getCachedUsers();
    }
  }

  Future<List<User>> _getCachedUsers() async {
    final cachedUsers = await localDataSource.getCachedUsers();
    return cachedUsers.map((model) => model.toEntity()).toList();
  }
}
```

### 3. Presentation Layer (UI and State Management)

**Purpose**: Handles UI presentation and user interaction. Depends on the domain layer through use cases.

**Components**:
- **Pages**: Full-screen UI components
- **Widgets**: Reusable UI components
- **State Management**: Provider/Bloc/Riverpod/GetX (choose based on preference)

#### Provider Implementation Example

```dart
// Provider Example
class UserProvider extends ChangeNotifier {
  final GetUserByIdUseCase getUserById;
  final GetUsersUseCase getUsers;

  User? _currentUser;
  List<User> _users = [];
  bool _isLoading = false;
  String? _error;

  UserProvider({
    required this.getUserById,
    required this.getUsers,
  });

  // Getters
  User? get currentUser => _currentUser;
  List<User> get users => _users;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Methods
  Future<void> loadUser(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await getUserById(userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUsers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _users = await getUsers();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

// Page Example with Provider
class UserListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => UserProvider(
        getUserById: context.read<GetUserByIdUseCase>(),
        getUsers: context.read<GetUsersUseCase>(),
      ),
      child: UserListView(),
    );
  }
}

class UserListView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Users')),
      body: Consumer<UserProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Text('Error: ${provider.error}'),
            );
          }

          return ListView.builder(
            itemCount: provider.users.length,
            itemBuilder: (context, index) {
              final user = provider.users[index];
              return UserTile(user: user);
            },
          );
        },
      ),
    );
  }
}
```

#### Bloc Implementation Example

```dart
// Bloc Events
abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object> get props => [];
}

class LoadUsers extends UserEvent {}

class LoadUserById extends UserEvent {
  final String userId;

  const LoadUserById(this.userId);

  @override
  List<Object> get props => [userId];
}

// Bloc States
abstract class UserState extends Equatable {
  const UserState();

  @override
  List<Object> get props => [];
}

class UserInitial extends UserState {}

class UserLoading extends UserState {}

class UserLoaded extends UserState {
  final List<User> users;

  const UserLoaded(this.users);

  @override
  List<Object> get props => [users];
}

class UserError extends UserState {
  final String message;

  const UserError(this.message);

  @override
  List<Object> get props => [message];
}

// Bloc Implementation
class UserBloc extends Bloc<UserEvent, UserState> {
  final GetUsersUseCase getUsers;
  final GetUserByIdUseCase getUserById;

  UserBloc({
    required this.getUsers,
    required this.getUserById,
  }) : super(UserInitial()) {
    on<LoadUsers>(_onLoadUsers);
    on<LoadUserById>(_onLoadUserById);
  }

  Future<void> _onLoadUsers(LoadUsers event, Emitter<UserState> emit) async {
    emit(UserLoading());
    try {
      final users = await getUsers();
      emit(UserLoaded(users));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  Future<void> _onLoadUserById(LoadUserById event, Emitter<UserState> emit) async {
    emit(UserLoading());
    try {
      final user = await getUserById(event.userId);
      emit(UserLoaded([user]));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }
}

// Page Example with Bloc
class UserListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UserBloc(
        getUsers: context.read<GetUsersUseCase>(),
        getUserById: context.read<GetUserByIdUseCase>(),
      ),
      child: UserListView(),
    );
  }
}

class UserListView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Users')),
      body: BlocBuilder<UserBloc, UserState>(
        builder: (context, state) {
          if (state is UserLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (state is UserError) {
            return Center(
              child: Text('Error: ${state.message}'),
            );
          }

          if (state is UserLoaded) {
            return ListView.builder(
              itemCount: state.users.length,
              itemBuilder: (context, index) {
                final user = state.users[index];
                return UserTile(user: user);
              },
            );
          }

          return Container();
        },
      ),
    );
  }
}
```

#### Riverpod Implementation Example

```dart
// State Notifier with Riverpod
class UserNotifier extends StateNotifier<AsyncValue<List<User>>> {
  final GetUsersUseCase getUsers;
  final GetUserByIdUseCase getUserById;

  UserNotifier({
    required this.getUsers,
    required this.getUserById,
  }) : super(const AsyncValue.loading());

  Future<void> loadUsers() async {
    state = const AsyncValue.loading();
    try {
      final users = await getUsers();
      state = AsyncValue.data(users);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> loadUserById(String userId) async {
    state = const AsyncValue.loading();
    try {
      final user = await getUserById(userId);
      state = AsyncValue.data([user]);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

// Providers
final userProvider = StateNotifierProvider<UserNotifier, AsyncValue<List<User>>>(
  (ref) => UserNotifier(
    getUsers: ref.watch(getUsersUseCaseProvider),
    getUserById: ref.watch(getUserByIdUseCaseProvider),
  ),
);

// Use Case Providers
final getUsersUseCaseProvider = Provider<GetUsersUseCase>(
  (ref) => GetUsersUseCase(ref.watch(userRepositoryProvider)),
);

final getUserByIdUseCaseProvider = Provider<GetUserByIdUseCase>(
  (ref) => GetUserByIdUseCase(ref.watch(userRepositoryProvider)),
);

// Page Example with Riverpod
class UserListPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Users')),
      body: userState.when(
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: ${error.toString()}'),
        ),
        data: (users) => ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return UserTile(user: user);
          },
        ),
      ),
    );
  }
}
```

#### GetX Implementation Example

```dart
// GetX Controller Example
class UserController extends GetxController {
  final GetUserByIdUseCase getUserById;
  final GetUsersUseCase getUsers;

  UserController({
    required this.getUserById,
    required this.getUsers,
  });

  // Reactive state variables
  final Rx<User?> _currentUser = Rx<User?>(null);
  final RxList<User> _users = <User>[].obs;
  final RxBool _isLoading = false.obs;
  final RxString _error = ''.obs;

  // Getters for reactive variables
  User? get currentUser => _currentUser.value;
  List<User> get users => _users;
  bool get isLoading => _isLoading.value;
  String? get error => _error.value.isEmpty ? null : _error.value;

  // Methods
  Future<void> loadUser(String userId) async {
    _isLoading.value = true;
    _error.value = '';

    try {
      _currentUser.value = await getUserById(userId);
    } catch (e) {
      _error.value = e.toString();
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> loadUsers() async {
    _isLoading.value = true;
    _error.value = '';

    try {
      final userList = await getUsers();
      _users.assignAll(userList);
    } catch (e) {
      _error.value = e.toString();
    } finally {
      _isLoading.value = false;
    }
  }
}

// Page Example with GetX
class UserListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Initialize controller with dependencies
    final UserController controller = Get.put(
      UserController(
        getUserById: Get.find(),
        getUsers: Get.find(),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text('Users')),
      body: Obx(() {
        if (controller.isLoading) {
          return Center(child: CircularProgressIndicator());
        }

        if (controller.error != null) {
          return Center(
            child: Text('Error: ${controller.error}'),
          );
        }

        return ListView.builder(
          itemCount: controller.users.length,
          itemBuilder: (context, index) {
            final user = controller.users[index];
            return UserTile(user: user);
          },
        );
      }),
    );
  }
}

// Dependency Injection with GetX
class UserBinding extends Bindings {
  @override
  void dependencies() {
    // Use cases
    Get.lazyPut<GetUserByIdUseCase>(
      () => GetUserByIdUseCase(Get.find()),
    );
    Get.lazyPut<GetUsersUseCase>(
      () => GetUsersUseCase(Get.find()),
    );

    // Controller
    Get.lazyPut<UserController>(
      () => UserController(
        getUserById: Get.find(),
        getUsers: Get.find(),
      ),
    );
  }
}
```

## Dependency Rules

1. **Inner layers cannot depend on outer layers**
2. **Dependencies point inward**
3. **Outer layers can depend on inner layers**
4. **Domain layer has no dependencies**

```
Presentation → Domain ← Data
```

## Benefits

1. **Testability**: Business logic is isolated from UI and frameworks
2. **Maintainability**: Clear separation of concerns
3. **Flexibility**: Easy to swap implementations (e.g., change database)
4. **Scalability**: Features can be developed independently
5. **Reusability**: Domain logic can be reused across different platforms

## Common Pitfalls to Avoid

1. **Don't pass UI models to domain layer**
2. **Don't import Flutter framework in domain layer**
3. **Don't put business logic in presentation layer**
4. **Don't make repositories depend on concrete implementations**
5. **Don't skip error handling in use cases**

## Testing Strategy

### Domain Layer Testing
```dart
class GetUserByIdUseCaseTest {
  late GetUserByIdUseCase useCase;
  late MockUserRepository mockRepository;

  setUp() {
    mockRepository = MockUserRepository();
    useCase = GetUserByIdUseCase(mockRepository);
  }

  test('should get user from repository', () async {
    // Arrange
    const userId = '1';
    final testUser = User(
      id: userId,
      name: 'Test User',
      email: 'test@example.com',
      createdAt: DateTime.now(),
    );

    when(mockRepository.getUserById(userId))
        .thenAnswer((_) async => testUser);

    // Act
    final result = await useCase(userId);

    // Assert
    expect(result, testUser);
    verify(mockRepository.getUserById(userId));
  });
}
```

### Data Layer Testing
```dart
class UserRepositoryImplTest {
  late UserRepositoryImpl repository;
  late MockUserRemoteDataSource mockRemoteDataSource;
  late MockUserLocalDataSource mockLocalDataSource;
  late MockNetworkInfo mockNetworkInfo;

  setUp() {
    mockRemoteDataSource = MockUserRemoteDataSource();
    mockLocalDataSource = MockUserLocalDataSource();
    mockNetworkInfo = MockNetworkInfo();

    repository = UserRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
      networkInfo: mockNetworkInfo,
    );
  }

  test('should return remote data when device is online', () async {
    // Arrange
    when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
    final testModels = [UserModel(id: '1', name: 'Test', email: 'test@test.com', createdAt: '2023-01-01')];
    when(mockRemoteDataSource.getUsers()).thenAnswer((_) async => testModels);

    // Act
    final result = await repository.getUsers();

    // Assert
    expect(result, isA<List<User>>());
    verify(mockRemoteDataSource.getUsers());
    verify(mockLocalDataSource.cacheUsers(testModels));
  });
}