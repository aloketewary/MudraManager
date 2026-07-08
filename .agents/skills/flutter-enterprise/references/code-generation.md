# Code Generation for Flutter Enterprise Apps

## Overview

Code generation reduces boilerplate and ensures consistency across enterprise Flutter applications. This guide covers essential code generation tools and patterns for clean architecture.

## Essential Code Generation Tools

### 1. JSON Serialization

#### Setup
```yaml
# pubspec.yaml
dependencies:
  json_annotation: ^4.8.1

dev_dependencies:
  build_runner: ^2.4.6
  json_serializable: ^6.7.1
```

#### Model Template with Code Generation
```dart
// lib/features/user/data/models/user_model.dart
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/user_entity.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  final String id;
  final String name;
  final String email;
  final String? avatar;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String updatedAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

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

#### Build Command
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 2. Freezed for Immutable Classes

#### Setup
```yaml
# pubspec.yaml
dependencies:
  freezed_annotation: ^2.4.1

dev_dependencies:
  build_runner: ^2.4.6
  freezed: ^2.4.6
```

#### Entity Template with Freezed
```dart
// lib/features/user/domain/entities/user_entity.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_entity.freezed.dart';

@freezed
class UserEntity with _$UserEntity {
  const factory UserEntity({
    required String id,
    required String name,
    required String email,
    String? avatar,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _UserEntity;

  const UserEntity._();

  bool get isValidEmail => email.contains('@');
}
```

#### Response Model Template
```dart
// lib/core/models/api_response_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_response_model.freezed.dart';
part 'api_response_model.g.dart';

@freezed
class ApiResponse<T> with _$ApiResponse<T> {
  const factory ApiResponse({
    required bool success,
    required T data,
    String? message,
    @JsonKey(name: 'error_code') int? errorCode,
  }) = _ApiResponse<T>;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) =>
      _$ApiResponseFromJson(json, fromJsonT);
}

@freezed
class PaginatedResponse<T> with _$PaginatedResponse<T> {
  const factory PaginatedResponse({
    required List<T> data,
    required int page,
    required int limit,
    required int total,
    @JsonKey(name: 'total_pages') required int totalPages,
  }) = _PaginatedResponse<T>;

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) =>
      _$PaginatedResponseFromJson(json, fromJsonT);
}
```

### 3. Injectable for Dependency Injection

#### Setup
```yaml
# pubspec.yaml
dependencies:
  get_it: ^7.6.4
  injectable: ^2.3.2

dev_dependencies:
  build_runner: ^2.4.6
  injectable_generator: ^2.4.1
```

#### Dependency Injection Setup
```dart
// lib/core/di/injection_container.dart
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

final GetIt sl = GetIt.instance;

@InjectableInit()
Future<void> configureDependencies() async {
  sl.init();
}
```

#### Repository with Injectable
```dart
// lib/features/user/data/repositories/user_repository_impl.dart
import 'package:injectable/injectable.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/user_remote_data_source.dart';
import '../datasources/user_local_data_source.dart';
import '../../../core/network/network_info.dart';

@LazySingleton(as: UserRepository)
class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource remoteDataSource;
  final UserLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  UserRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  // Implementation...
}
```

#### Use Case with Injectable
```dart
// lib/features/user/domain/usecases/get_users_usecase.dart
import 'package:injectable/injectable.dart';
import '../repositories/user_repository.dart';

@LazySingleton()
class GetUsersUseCase {
  final UserRepository _repository;

  GetUsersUseCase(this._repository);

  Future<List<UserEntity>> call({int page = 1, int limit = 20}) async {
    return await _repository.getUsers(page: page, limit: limit);
  }
}
```

#### Provider with Injectable
```dart
// lib/features/user/presentation/providers/user_provider.dart
import 'package:injectable/injectable.dart';
import '../../domain/usecases/get_users_usecase.dart';
import '../../domain/usecases/create_user_usecase.dart';
import '../../domain/usecases/search_users_usecase.dart';

@LazySingleton()
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

  // Implementation...
}
```

### 4. Retrofit for API Clients

#### Setup
```yaml
# pubspec.yaml
dependencies:
  retrofit: ^4.0.3
  dio: ^5.3.2
  json_annotation: ^4.8.1

dev_dependencies:
  build_runner: ^2.4.6
  retrofit_generator: ^8.0.4
  json_serializable: ^6.7.1
```

#### API Client Template
```dart
// lib/core/network/api_client.dart
import 'package:retrofit/retrofit.dart';
import 'package:dio/dio.dart';
import '../models/api_response_model.dart';
import '../models/paginated_response_model.dart';
import '../../features/user/data/models/user_model.dart';

part 'api_client.g.dart';

@RestApi(baseUrl: 'https://api.example.com/v1/')
abstract class ApiClient {
  factory ApiClient(Dio dio, {String baseUrl}) = _ApiClient;

  @GET('/users')
  Future<ApiResponse<PaginatedResponse<UserModel>>> getUsers(
    @Query('page') int page,
    @Query('limit') int limit,
  );

  @GET('/users/{id}')
  Future<ApiResponse<UserModel>> getUserById(@Path('id') String id);

  @POST('/users')
  Future<ApiResponse<UserModel>> createUser(@Body() UserModel user);

  @PUT('/users/{id}')
  Future<ApiResponse<UserModel>> updateUser(
    @Path('id') String id,
    @Body() UserModel user,
  );

  @DELETE('/users/{id}')
  Future<ApiResponse<void>> deleteUser(@Path('id') String id);

  @GET('/users/search')
  Future<ApiResponse<List<UserModel>>> searchUsers(@Query('q') String query);
}
```

### 5. Equatable for Value Equality

#### Setup
```yaml
# pubspec.yaml
dependencies:
  equatable: ^2.0.5
```

#### Entity with Equatable
```dart
// lib/features/user/domain/entities/user_entity.dart
import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
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
  List<Object?> get props => [
        id,
        name,
        email,
        avatar,
        createdAt,
        updatedAt,
      ];

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

  bool get isValidEmail => email.contains('@');
}
```

### 6. Mock Generation for Testing

#### Setup
```yaml
# pubspec.yaml
dev_dependencies:
  mockito: ^5.4.2
  build_runner: ^2.4.6
  mockito_generator: ^5.4.2
```

#### Mock Classes
```dart
// test/features/user/domain/repositories/user_repository_test.dart
import 'package:mockito/annotations.dart';
import '../../../../../lib/features/user/domain/repositories/user_repository.dart';

@GenerateMocks([UserRepository])
void main() {}
```

## Build Scripts

### Development Build Script
```yaml
# build.yaml
targets:
  $default:
    builders:
      json_serializable:
        options:
          explicit_to_json: true
          include_if_null: false
      retrofit_generator:
        options:
          null_safety: true
      injectable_generator:
        options:
          auto_register: true
          as_extension: true
```

### Watch Command for Development
```bash
flutter pub run build_runner watch --delete-conflicting-outputs
```

### Build Commands for CI/CD
```bash
# Generate code
flutter pub run build_runner build --delete-conflicting-outputs

# Clean generated files
flutter pub run build_runner clean

# Generate and validate
flutter pub run build_runner build --delete-conflicting-outputs && flutter analyze
```

## Code Generation Workflow

### 1. Initial Setup
```bash
# Add dependencies
flutter pub add json_annotation freezed_annotation injectable retrofit dio equatable
flutter pub add --dev build_runner json_serializable freezed injectable_generator retrofit_generator mockito

# Generate initial code
flutter pub run build_runner build --delete-conflicting-outputs
```

### 2. Development Workflow
```bash
# Start watch mode
flutter pub run build_runner watch --delete-conflicting-outputs

# Make changes to files
# Code will be generated automatically
```

### 3. Before Commit
```bash
# Clean and regenerate
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs

# Run analysis
flutter analyze

# Run tests
flutter test
```

## Custom Code Generation Templates

### Feature Generator Script
```dart
// scripts/generate_feature.dart
import 'dart:io';

void main() {
  if (args.length != 2) {
    print('Usage: dart scripts/generate_feature.dart <feature_name> <entity_name>');
    exit(1);
  }

  final featureName = args[0];
  final entityName = args[1];

  generateFeature(featureName, entityName);
}

void generateFeature(String featureName, String entityName) {
  final featureDir = Directory('lib/features/$featureName');
  featureDir.createSync(recursive: true);

  // Create directory structure
  final directories = [
    'data/datasources',
    'data/models',
    'data/repositories',
    'domain/entities',
    'domain/repositories',
    'domain/usecases',
    'presentation/pages',
    'presentation/widgets',
    'presentation/providers',
  ];

  for (final dir in directories) {
    Directory('${featureDir.path}/$dir').createSync(recursive: true);
  }

  // Generate entity
  generateEntity(featureDir, entityName);

  // Generate repository interface
  generateRepositoryInterface(featureDir, entityName);

  // Generate use cases
  generateUseCases(featureDir, entityName);

  // Generate model
  generateModel(featureDir, entityName);

  // Generate repository implementation
  generateRepositoryImpl(featureDir, entityName);

  // Generate provider
  generateProvider(featureDir, entityName);

  print('Feature "$featureName" generated successfully!');
}
```

### Entity Template Generator
```dart
void generateEntity(Directory featureDir, String entityName) {
  final entityFile = File('${featureDir.path}/domain/entities/${entityName.toLowerCase()}_entity.dart');

  final entityContent = '''
import 'package:freezed_annotation/freezed_annotation.dart';

part '${entityName.toLowerCase()}_entity.freezed.dart';

@freezed
class ${entityName}Entity with _\$${entityName}Entity {
  const factory ${entityName}Entity({
    required String id,
    required String name,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _\$${entityName}Entity;

  const ${entityName}Entity._();
}
''';

  entityFile.writeAsStringSync(entityContent);
}
```

## Best Practices

1. **Consistent Naming**: Use consistent naming conventions across generated files
2. **Version Control**: Add generated files to .gitignore but keep templates
3. **CI/CD Integration**: Include code generation in build pipeline
4. **Documentation**: Document code generation setup and commands
5. **Performance**: Use watch mode during development, build mode for production
6. **Validation**: Validate generated code with analysis and tests
7. **Clean Builds**: Clean and regenerate when switching branches
8. **Team Coordination**: Ensure team uses same code generation versions

## Troubleshooting

### Common Issues
1. **Conflicting Classes**: Use `--delete-conflicting-outputs` flag
2. **Import Errors**: Check pubspec.yaml dependencies
3. **Generation Failures**: Clean with `flutter pub run build_runner clean`
4. **Version Conflicts**: Ensure compatible package versions
5. **Cache Issues**: Clear pub cache with `flutter pub cache repair`

### Debug Commands
```bash
# Check what's being generated
flutter pub run build_runner build --verbose

# Clean everything
flutter pub run build_runner clean
flutter pub get

# Force regeneration
flutter pub run build_runner build --delete-conflicting-outputs