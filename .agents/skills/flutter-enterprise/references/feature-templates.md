# Feature-Based Templates for Flutter Enterprise

## Overview

Feature-based architecture organizes code around business features rather than technical layers. Each feature is self-contained with its own data, domain, and presentation layers.

## Feature Structure Template

```
features/
├── feature_name/
│   ├── data/
│   │   ├── datasources/
│   │   │   ├── feature_remote_data_source.dart
│   │   │   └── feature_local_data_source.dart
│   │   ├── models/
│   │   │   ├── feature_model.dart
│   │   │   └── feature_response_model.dart
│   │   └── repositories/
│   │       └── feature_repository_impl.dart
│   ├── domain/
│   │   ├── entities/
│   │   │   └── feature_entity.dart
│   │   ├── repositories/
│   │   │   └── feature_repository.dart
│   │   └── usecases/
│   │       ├── get_feature_usecase.dart
│   │       ├── create_feature_usecase.dart
│   │       ├── update_feature_usecase.dart
│   │       └── delete_feature_usecase.dart
│   └── presentation/
│       ├── pages/
│       │   ├── feature_list_page.dart
│       │   └── feature_detail_page.dart
│       ├── widgets/
│       │   ├── feature_card_widget.dart
│       │   ├── feature_form_widget.dart
│       │   └── feature_loading_widget.dart
│       └── state_management/
│           ├── providers/  # Provider pattern
│           │   ├── feature_provider.dart
│           │   └── feature_list_provider.dart
│           ├── bloc/      # Bloc pattern
│           │   ├── feature_bloc.dart
│           │   ├── feature_state.dart
│           │   └── feature_event.dart
│           ├── riverpod/  # Riverpod pattern
│           │   ├── feature_provider.dart
│           │   ├── feature_notifier.dart
│           │   └── feature_state.dart
│           └── getx/      # GetX pattern
│               ├── feature_controller.dart
│               └── feature_binding.dart
```

## Template: User Management Feature

### Domain Layer

#### Entity Template
```dart
// lib/features/user/domain/entities/user_entity.dart
class UserEntity {
  final String id;
  final String name;
  final String email;
  final String? avatar;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserEntity &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.avatar == avatar &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        email.hashCode ^
        avatar.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }

  UserEntity copyWith({
    String? id,
    String? name,
    String? email,
    String? avatar,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
```

#### Repository Interface Template
```dart
// lib/features/user/domain/repositories/user_repository.dart
import '../entities/user_entity.dart';

abstract class UserRepository {
  /// Get all users
  Future<List<UserEntity>> getUsers({int page = 1, int limit = 20});

  /// Get user by ID
  Future<UserEntity?> getUserById(String id);

  /// Search users by name or email
  Future<List<UserEntity>> searchUsers(String query);

  /// Create new user
  Future<UserEntity> createUser(UserEntity user);

  /// Update existing user
  Future<UserEntity> updateUser(UserEntity user);

  /// Delete user
  Future<void> deleteUser(String id);

  /// Get user profile
  Future<UserEntity> getUserProfile();

  /// Update user profile
  Future<UserEntity> updateUserProfile(UserEntity user);
}
```

#### Use Case Templates
```dart
// lib/features/user/domain/usecases/get_users_usecase.dart
import '../entities/user_entity.dart';
import '../repositories/user_repository.dart';

class GetUsersUseCase {
  final UserRepository _repository;

  GetUsersUseCase(this._repository);

  Future<List<UserEntity>> call({int page = 1, int limit = 20}) async {
    if (page < 1) {
      throw ArgumentError('Page must be greater than 0');
    }

    if (limit < 1 || limit > 100) {
      throw ArgumentError('Limit must be between 1 and 100');
    }

    return await _repository.getUsers(page: page, limit: limit);
  }
}

// lib/features/user/domain/usecases/create_user_usecase.dart
class CreateUserUseCase {
  final UserRepository _repository;

  CreateUserUseCase(this._repository);

  Future<UserEntity> call(UserEntity user) async {
    if (user.name.isEmpty) {
      throw ArgumentError('User name cannot be empty');
    }

    if (!user.email.contains('@')) {
      throw ArgumentError('Invalid email format');
    }

    return await _repository.createUser(user);
  }
}

// lib/features/user/domain/usecases/search_users_usecase.dart
class SearchUsersUseCase {
  final UserRepository _repository;

  SearchUsersUseCase(this._repository);

  Future<List<UserEntity>> call(String query) async {
    if (query.length < 2) {
      throw ArgumentError('Search query must be at least 2 characters');
    }

    return await _repository.searchUsers(query);
  }
}
```

### Data Layer

#### Model Template
```dart
// lib/features/user/data/models/user_model.dart
import '../../domain/entities/user_entity.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? avatar;
  final String createdAt;
  final String updatedAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      avatar: json['avatar'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      if (avatar != null) 'avatar': avatar,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  UserEntity toEntity() {
    return UserEntity(
      id: id,
      name: name,
      email: email,
      avatar: avatar,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
    );
  }

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      name: entity.name,
      email: entity.email,
      avatar: entity.avatar,
      createdAt: entity.createdAt.toIso8601String(),
      updatedAt: entity.updatedAt.toIso8601String(),
    );
  }
}
```

#### Data Source Template
```dart
// lib/features/user/data/datasources/user_remote_data_source.dart
import '../models/user_model.dart';

abstract class UserRemoteDataSource {
  Future<List<UserModel>> getUsers({int page = 1, int limit = 20});
  Future<UserModel?> getUserById(String id);
  Future<List<UserModel>> searchUsers(String query);
  Future<UserModel> createUser(UserModel user);
  Future<UserModel> updateUser(UserModel user);
  Future<void> deleteUser(String id);
}

// lib/features/user/data/datasources/user_remote_data_source_impl.dart
import 'package:http/http.dart' as http;
import 'package:convert/convert.dart';
import '../../core/network/network_info.dart';
import '../models/user_model.dart';

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final HttpClient httpClient;
  final NetworkInfo networkInfo;

  UserRemoteDataSourceImpl({
    required this.httpClient,
    required this.networkInfo,
  });

  @override
  Future<List<UserModel>> getUsers({int page = 1, int limit = 20}) async {
    final response = await httpClient.get(
      '/users',
      queryParameters: {
        'page': page,
        'limit': limit,
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = response.data['data'];
      return jsonData.map((json) => UserModel.fromJson(json)).toList();
    } else {
      throw ServerException('Failed to load users');
    }
  }

  @override
  Future<UserModel?> getUserById(String id) async {
    final response = await httpClient.get('/users/$id');

    if (response.statusCode == 200) {
      return UserModel.fromJson(response.data['data']);
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw ServerException('Failed to load user');
    }
  }

  @override
  Future<List<UserModel>> searchUsers(String query) async {
    final response = await httpClient.get(
      '/users/search',
      queryParameters: {'q': query},
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = response.data['data'];
      return jsonData.map((json) => UserModel.fromJson(json)).toList();
    } else {
      throw ServerException('Failed to search users');
    }
  }

  @override
  Future<UserModel> createUser(UserModel user) async {
    final response = await httpClient.post(
      '/users',
      data: user.toJson(),
    );

    if (response.statusCode == 201) {
      return UserModel.fromJson(response.data['data']);
    } else {
      throw ServerException('Failed to create user');
    }
  }

  @override
  Future<UserModel> updateUser(UserModel user) async {
    final response = await httpClient.put(
      '/users/${user.id}',
      data: user.toJson(),
    );

    if (response.statusCode == 200) {
      return UserModel.fromJson(response.data['data']);
    } else {
      throw ServerException('Failed to update user');
    }
  }

  @override
  Future<void> deleteUser(String id) async {
    final response = await httpClient.delete('/users/$id');

    if (response.statusCode != 204) {
      throw ServerException('Failed to delete user');
    }
  }
}
```

#### Repository Implementation Template
```dart
// lib/features/user/data/repositories/user_repository_impl.dart
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/user_remote_data_source.dart';
import '../datasources/user_local_data_source.dart';
import '../models/user_model.dart';
import '../../../core/network/network_info.dart';
import '../../../core/exceptions/exceptions.dart';

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
  Future<List<UserEntity>> getUsers({int page = 1, int limit = 20}) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteUsers = await remoteDataSource.getUsers(page: page, limit: limit);

        // Cache the users locally
        await localDataSource.cacheUsers(remoteUsers);

        return remoteUsers.map((model) => model.toEntity()).toList();
      } on ServerException {
        // Fallback to cached data if server fails
        return await _getCachedUsers();
      }
    } else {
      // Use cached data when offline
      return await _getCachedUsers();
    }
  }

  @override
  Future<UserEntity?> getUserById(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteUser = await remoteDataSource.getUserById(id);

        if (remoteUser != null) {
          // Cache the user locally
          await localDataSource.cacheUser(remoteUser);
          return remoteUser.toEntity();
        }

        return null;
      } on ServerException {
        // Fallback to cached data
        return await _getCachedUserById(id);
      }
    } else {
      return await _getCachedUserById(id);
    }
  }

  @override
  Future<List<UserEntity>> searchUsers(String query) async {
    if (await networkInfo.isConnected) {
      try {
        final searchResults = await remoteDataSource.searchUsers(query);
        return searchResults.map((model) => model.toEntity()).toList();
      } on ServerException {
        throw SearchException('Failed to search users');
      }
    } else {
      throw NetworkException('No internet connection');
    }
  }

  @override
  Future<UserEntity> createUser(UserEntity user) async {
    if (await networkInfo.isConnected) {
      try {
        final userModel = UserModel.fromEntity(user);
        final createdUser = await remoteDataSource.createUser(userModel);

        // Update local cache
        await localDataSource.cacheUser(createdUser);

        return createdUser.toEntity();
      } on ServerException {
        throw CreateException('Failed to create user');
      }
    } else {
      throw NetworkException('No internet connection');
    }
  }

  @override
  Future<UserEntity> updateUser(UserEntity user) async {
    if (await networkInfo.isConnected) {
      try {
        final userModel = UserModel.fromEntity(user);
        final updatedUser = await remoteDataSource.updateUser(userModel);

        // Update local cache
        await localDataSource.cacheUser(updatedUser);

        return updatedUser.toEntity();
      } on ServerException {
        throw UpdateException('Failed to update user');
      }
    } else {
      throw NetworkException('No internet connection');
    }
  }

  @override
  Future<void> deleteUser(String id) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteUser(id);

        // Remove from local cache
        await localDataSource.deleteCachedUser(id);
      } on ServerException {
        throw DeleteException('Failed to delete user');
      }
    } else {
      throw NetworkException('No internet connection');
    }
  }

  Future<List<UserEntity>> _getCachedUsers() async {
    final cachedUsers = await localDataSource.getCachedUsers();
    return cachedUsers.map((model) => model.toEntity()).toList();
  }

  Future<UserEntity?> _getCachedUserById(String id) async {
    final cachedUser = await localDataSource.getCachedUserById(id);
    return cachedUser?.toEntity();
  }
}
```

### Presentation Layer

#### Provider Template
```dart
// lib/features/user/presentation/providers/user_provider.dart
import 'package:flutter/foundation.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/get_users_usecase.dart';
import '../../domain/usecases/create_user_usecase.dart';
import '../../domain/usecases/search_users_usecase.dart';

class UserProvider extends ChangeNotifier {
  final GetUsersUseCase _getUsersUseCase;
  final CreateUserUseCase _createUserUseCase;
  final SearchUsersUseCase _searchUsersUseCase;

  UserProvider({
    required GetUsersUseCase getUsersUseCase,
    required CreateUserUseCase createUserUseCase,
    required SearchUsersUseCase searchUsersUseCase,
  })  : _getUsersUseCase = getUsersUseCase,
        _createUserUseCase = createUserUseCase,
        _searchUsersUseCase = searchUsersUseCase;

  // State
  List<UserEntity> _users = [];
  List<UserEntity> _searchResults = [];
  bool _isLoading = false;
  bool _isSearching = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;

  // Getters
  List<UserEntity> get users => _users;
  List<UserEntity> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  String? get error => _error;
  bool get hasMore => _hasMore;

  // Methods
  Future<void> loadUsers({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _users.clear();
    }

    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newUsers = await _getUsersUseCase(page: _currentPage, limit: 20);

      if (refresh) {
        _users = newUsers;
      } else {
        _users.addAll(newUsers);
      }

      _hasMore = newUsers.length == 20;
      _currentPage++;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      _searchResults.clear();
      _isSearching = false;
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    try {
      _searchResults = await _searchUsersUseCase(query);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  Future<void> createUser(UserEntity user) async {
    try {
      await _createUserUseCase(user);
      await loadUsers(refresh: true);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
```

#### Bloc Template
```dart
// lib/features/user/presentation/bloc/user_bloc.dart
import 'package:flutter/material.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/get_users_usecase.dart';
import '../../domain/usecases/create_user_usecase.dart';
import '../../domain/usecases/search_users_usecase.dart';

// Events
abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object> get props => [];
}

class LoadUsers extends UserEvent {
  final bool refresh;
  final int page;

  const LoadUsers({this.refresh = false, this.page = 1});

  @override
  List<Object> get props => [refresh, page];
}

class SearchUsers extends UserEvent {
  final String query;

  const SearchUsers(this.query);

  @override
  List<Object> get props => [query];
}

class CreateUser extends UserEvent {
  final UserEntity user;

  const CreateUser(this.user);

  @override
  List<Object> get props => [user];
}

class ClearError extends UserEvent {}

// States
abstract class UserState extends Equatable {
  const UserState();

  @override
  List<Object> get props => [];
}

class UserInitial extends UserState {}

class UserLoading extends UserState {}

class UserLoaded extends UserState {
  final List<UserEntity> users;
  final bool hasMore;
  final List<UserEntity> searchResults;
  final bool isSearching;

  const UserLoaded({
    required this.users,
    required this.hasMore,
    this.searchResults = const [],
    this.isSearching = false,
  });

  @override
  List<Object> get props => [users, hasMore, searchResults, isSearching];
}

class UserError extends UserState {
  final String message;

  const UserError(this.message);

  @override
  List<Object> get props => [message];
}

// Bloc Implementation
class UserBloc extends Bloc<UserEvent, UserState> {
  final GetUsersUseCase _getUsersUseCase;
  final CreateUserUseCase _createUserUseCase;
  final SearchUsersUseCase _searchUsersUseCase;

  int _currentPage = 1;

  UserBloc({
    required GetUsersUseCase getUsersUseCase,
    required CreateUserUseCase createUserUseCase,
    required SearchUsersUseCase searchUsersUseCase,
  })  : _getUsersUseCase = getUsersUseCase,
        _createUserUseCase = createUserUseCase,
        _searchUsersUseCase = searchUsersUseCase,
        super(UserInitial()) {
    on<LoadUsers>(_onLoadUsers);
    on<SearchUsers>(_onSearchUsers);
    on<CreateUser>(_onCreateUser);
    on<ClearError>(_onClearError);
  }

  Future<void> _onLoadUsers(LoadUsers event, Emitter<UserState> emit) async {
    if (event.refresh) {
      _currentPage = 1;
    }

    final currentState = state;
    List<UserEntity> currentUsers = [];

    if (currentState is UserLoaded && !event.refresh) {
      currentUsers = currentState.users;
    }

    emit(UserLoading());

    try {
      final newUsers = await _getUsersUseCase(page: _currentPage, limit: 20);
      final allUsers = event.refresh ? newUsers : [...currentUsers, ...newUsers];
      final hasMore = newUsers.length == 20;

      _currentPage++;

      emit(UserLoaded(
        users: allUsers,
        hasMore: hasMore,
        searchResults: currentState is UserLoaded ? currentState.searchResults : [],
        isSearching: currentState is UserLoaded ? currentState.isSearching : false,
      ));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  Future<void> _onSearchUsers(SearchUsers event, Emitter<UserState> emit) async {
    if (event.query.isEmpty) {
      final currentState = state;
      if (currentState is UserLoaded) {
        emit(currentState.copyWith(searchResults: [], isSearching: false));
      }
      return;
    }

    final currentState = state;
    if (currentState is UserLoaded) {
      emit(currentState.copyWith(isSearching: true));
    }

    try {
      final searchResults = await _searchUsersUseCase(event.query);

      final updatedState = state is UserLoaded
          ? (state as UserLoaded).copyWith(searchResults: searchResults, isSearching: false)
          : UserLoaded(users: [], hasMore: false, searchResults: searchResults, isSearching: false);

      emit(updatedState);
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  Future<void> _onCreateUser(CreateUser event, Emitter<UserState> emit) async {
    try {
      await _createUserUseCase(event.user);
      add(LoadUsers(refresh: true));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  Future<void> _onClearError(ClearError event, Emitter<UserState> emit) async {
    final currentState = state;
    if (currentState is UserError) {
      emit(UserInitial());
      add(LoadUsers(refresh: true));
    }
  }
}

extension UserStateCopyWith on UserLoaded {
  UserLoaded copyWith({
    List<UserEntity>? users,
    bool? hasMore,
    List<UserEntity>? searchResults,
    bool? isSearching,
  }) {
    return UserLoaded(
      users: users ?? this.users,
      hasMore: hasMore ?? this.hasMore,
      searchResults: searchResults ?? this.searchResults,
      isSearching: isSearching ?? this.isSearching,
    );
  }
}
```

#### Riverpod Template
```dart
// lib/features/user/presentation/providers/user_provider.dart
import 'package:flutter/material.dart';
import 'package:riverpod/riverpod.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/get_users_usecase.dart';
import '../../domain/usecases/create_user_usecase.dart';
import '../../domain/usecases/search_users_usecase.dart';

// State Class
class UserState {
  final List<UserEntity> users;
  final List<UserEntity> searchResults;
  final bool isLoading;
  final bool isSearching;
  final String? error;
  final int currentPage;
  final bool hasMore;

  const UserState({
    this.users = const [],
    this.searchResults = const [],
    this.isLoading = false,
    this.isSearching = false,
    this.error,
    this.currentPage = 1,
    this.hasMore = true,
  });

  UserState copyWith({
    List<UserEntity>? users,
    List<UserEntity>? searchResults,
    bool? isLoading,
    bool? isSearching,
    String? error,
    int? currentPage,
    bool? hasMore,
  }) {
    return UserState(
      users: users ?? this.users,
      searchResults: searchResults ?? this.searchResults,
      isLoading: isLoading ?? this.isLoading,
      isSearching: isSearching ?? this.isSearching,
      error: error ?? this.error,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserState &&
        other.users == users &&
        other.searchResults == searchResults &&
        other.isLoading == isLoading &&
        other.isSearching == isSearching &&
        other.error == error &&
        other.currentPage == currentPage &&
        other.hasMore == hasMore;
  }

  @override
  int get hashCode {
    return users.hashCode ^
        searchResults.hashCode ^
        isLoading.hashCode ^
        isSearching.hashCode ^
        error.hashCode ^
        currentPage.hashCode ^
        hasMore.hashCode;
  }
}

// State Notifier
class UserNotifier extends StateNotifier<UserState> {
  final GetUsersUseCase _getUsersUseCase;
  final CreateUserUseCase _createUserUseCase;
  final SearchUsersUseCase _searchUsersUseCase;

  UserNotifier({
    required GetUsersUseCase getUsersUseCase,
    required CreateUserUseCase createUserUseCase,
    required SearchUsersUseCase searchUsersUseCase,
  })  : _getUsersUseCase = getUsersUseCase,
        _createUserUseCase = createUserUseCase,
        _searchUsersUseCase = searchUsersUseCase,
        super(const UserState());

  Future<void> loadUsers({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(
        currentPage: 1,
        hasMore: true,
        users: [],
      );
    }

    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final newUsers = await _getUsersUseCase(page: state.currentPage, limit: 20);

      state = state.copyWith(
        users: refresh ? newUsers : [...state.users, ...newUsers],
        hasMore: newUsers.length == 20,
        currentPage: state.currentPage + 1,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      state = state.copyWith(searchResults: [], isSearching: false);
      return;
    }

    state = state.copyWith(isSearching: true);

    try {
      final searchResults = await _searchUsersUseCase(query);
      state = state.copyWith(
        searchResults: searchResults,
        isSearching: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isSearching: false,
      );
    }
  }

  Future<void> createUser(UserEntity user) async {
    try {
      await _createUserUseCase(user);
      await loadUsers(refresh: true);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Providers
final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  return UserNotifier(
    getUsersUseCase: ref.watch(getUsersUseCaseProvider),
    createUserUseCase: ref.watch(createUserUseCaseProvider),
    searchUsersUseCase: ref.watch(searchUsersUseCaseProvider),
  );
});

// Use Case Providers
final getUsersUseCaseProvider = Provider<GetUsersUseCase>((ref) {
  return GetUsersUseCase(ref.watch(userRepositoryProvider));
});

final createUserUseCaseProvider = Provider<CreateUserUseCase>((ref) {
  return CreateUserUseCase(ref.watch(userRepositoryProvider));
});

final searchUsersUseCaseProvider = Provider<SearchUsersUseCase>((ref) {
  return SearchUsersUseCase(ref.watch(userRepositoryProvider));
});
```

#### GetX Controller Template
```dart
// lib/features/user/presentation/controllers/user_controller.dart
import 'package:get/get.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/get_users_usecase.dart';
import '../../domain/usecases/create_user_usecase.dart';
import '../../domain/usecases/search_users_usecase.dart';

class UserController extends GetxController {
  final GetUsersUseCase _getUsersUseCase;
  final CreateUserUseCase _createUserUseCase;
  final SearchUsersUseCase _searchUsersUseCase;

  UserController({
    required GetUsersUseCase getUsersUseCase,
    required CreateUserUseCase createUserUseCase,
    required SearchUsersUseCase searchUsersUseCase,
  })  : _getUsersUseCase = getUsersUseCase,
        _createUserUseCase = createUserUseCase,
        _searchUsersUseCase = searchUsersUseCase;

  // Reactive state variables
  final RxList<UserEntity> _users = <UserEntity>[].obs;
  final RxList<UserEntity> _searchResults = <UserEntity>[].obs;
  final RxBool _isLoading = false.obs;
  final RxBool _isSearching = false.obs;
  final RxString _error = ''.obs;
  final RxInt _currentPage = 1.obs;
  final RxBool _hasMore = true.obs;

  // Getters for reactive variables
  List<UserEntity> get users => _users;
  List<UserEntity> get searchResults => _searchResults;
  bool get isLoading => _isLoading.value;
  bool get isSearching => _isSearching.value;
  String? get error => _error.value.isEmpty ? null : _error.value;
  bool get hasMore => _hasMore.value;

  // Methods
  Future<void> loadUsers({bool refresh = false}) async {
    if (refresh) {
      _currentPage.value = 1;
      _hasMore.value = true;
      _users.clear();
    }

    if (_isLoading.value || !_hasMore.value) return;

    _isLoading.value = true;
    _error.value = '';

    try {
      final newUsers = await _getUsersUseCase(page: _currentPage.value, limit: 20);

      if (refresh) {
        _users.assignAll(newUsers);
      } else {
        _users.addAll(newUsers);
      }

      _hasMore.value = newUsers.length == 20;
      _currentPage.value++;
    } catch (e) {
      _error.value = e.toString();
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      _searchResults.clear();
      _isSearching.value = false;
      return;
    }

    _isSearching.value = true;

    try {
      _searchResults.assignAll(await _searchUsersUseCase(query));
    } catch (e) {
      _error.value = e.toString();
    } finally {
      _isSearching.value = false;
    }
  }

  Future<void> createUser(UserEntity user) async {
    try {
      await _createUserUseCase(user);
      await loadUsers(refresh: true);
    } catch (e) {
      _error.value = e.toString();
    }
  }

  void clearError() {
    _error.value = '';
  }
}

// lib/features/user/presentation/bindings/user_binding.dart
import 'package:get/get.dart';
import '../../domain/usecases/get_users_usecase.dart';
import '../../domain/usecases/create_user_usecase.dart';
import '../../domain/usecases/search_users_usecase.dart';
import '../../domain/repositories/user_repository.dart';
import 'user_controller.dart';

class UserBinding extends Bindings {
  @override
  void dependencies() {
    // Repositories
    Get.lazyPut<UserRepository>(
      () => UserRepositoryImpl(
        remoteDataSource: Get.find(),
        localDataSource: Get.find(),
        networkInfo: Get.find(),
      ),
    );

    // Use cases
    Get.lazyPut<GetUsersUseCase>(
      () => GetUsersUseCase(Get.find()),
    );
    Get.lazyPut<CreateUserUseCase>(
      () => CreateUserUseCase(Get.find()),
    );
    Get.lazyPut<SearchUsersUseCase>(
      () => SearchUsersUseCase(Get.find()),
    );

    // Controller
    Get.lazyPut<UserController>(
      () => UserController(
        getUsersUseCase: Get.find(),
        createUserUseCase: Get.find(),
        searchUsersUseCase: Get.find(),
      ),
    );
  }
}
```

## Feature Registration Template

```dart
// lib/core/di/feature_injection.dart
import 'package:get_it/get_it.dart';
import '../../features/user/data/datasources/user_remote_data_source_impl.dart';
import '../../features/user/data/repositories/user_repository_impl.dart';
import '../../features/user/domain/repositories/user_repository.dart';
import '../../features/user/domain/usecases/get_users_usecase.dart';
import '../../features/user/domain/usecases/create_user_usecase.dart';
import '../../features/user/domain/usecases/search_users_usecase.dart';
import '../../features/user/presentation/providers/user_provider.dart';

Future<void> registerUserFeatures(GetIt sl) async {
  // Data sources
  sl.registerLazySingleton<UserRemoteDataSource>(
    () => UserRemoteDataSourceImpl(
      httpClient: sl(),
      networkInfo: sl(),
    ),
  );

  // Repositories
  sl.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Use cases
  sl.registerFactory<GetUsersUseCase>(
    () => GetUsersUseCase(sl()),
  );

  sl.registerFactory<CreateUserUseCase>(
    () => CreateUserUseCase(sl()),
  );

  sl.registerFactory<SearchUsersUseCase>(
    () => SearchUsersUseCase(sl()),
  );

  // Providers
  sl.registerFactory<UserProvider>(
    () => UserProvider(
      getUsersUseCase: sl(),
      createUserUseCase: sl(),
      searchUsersUseCase: sl(),
    ),
  );
}
```

#### GetX Feature Registration Template

```dart
// lib/core/di/feature_injection.dart
import 'package:get/get.dart';
import '../../features/user/data/datasources/user_remote_data_source_impl.dart';
import '../../features/user/data/repositories/user_repository_impl.dart';
import '../../features/user/domain/repositories/user_repository.dart';
import '../../features/user/domain/usecases/get_users_usecase.dart';
import '../../features/user/domain/usecases/create_user_usecase.dart';
import '../../features/user/domain/usecases/search_users_usecase.dart';
import '../../features/user/presentation/controllers/user_controller.dart';

Future<void> registerUserFeatures() async {
  // Data sources
  Get.lazyPut<UserRemoteDataSource>(
    () => UserRemoteDataSourceImpl(
      httpClient: Get.find(),
      networkInfo: Get.find(),
    ),
  );

  // Repositories
  Get.lazyPut<UserRepository>(
    () => UserRepositoryImpl(
      remoteDataSource: Get.find(),
      localDataSource: Get.find(),
      networkInfo: Get.find(),
    ),
  );

  // Use cases
  Get.lazyPut<GetUsersUseCase>(
    () => GetUsersUseCase(Get.find()),
  );

  Get.lazyPut<CreateUserUseCase>(
    () => CreateUserUseCase(Get.find()),
  );

  Get.lazyPut<SearchUsersUseCase>(
    () => SearchUsersUseCase(Get.find()),
  );

  // Controllers
  Get.lazyPut<UserController>(
    () => UserController(
      getUsersUseCase: Get.find(),
      createUserUseCase: Get.find(),
      searchUsersUseCase: Get.find(),
    ),
  );
}

// Initial dependencies setup
Future<void> setupGetItDependencies() async {
  // Core services
  Get.lazyPut<HttpClient>(() => DioClient());
  Get.lazyPut<NetworkInfo>(() => NetworkInfoImpl());
  Get.lazyPut<UserLocalDataSource>(() => UserLocalDataSourceImpl());

  // Register features
  await registerUserFeatures();
}
```

## Best Practices

1. **Feature Independence**: Each feature should be self-contained
2. **Clear Boundaries**: Avoid cross-feature dependencies in domain layer
3. **Consistent Naming**: Use consistent naming conventions across features
4. **Error Handling**: Implement proper error handling in each layer
5. **Testing**: Write tests for each layer independently
6. **Documentation**: Document feature responsibilities and APIs