# Flutter Enterprise Project Structure Template

## Complete Directory Structure

```
my_enterprise_app/
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_constants.dart
│   │   │   ├── api_constants.dart
│   │   │   └── route_constants.dart
│   │   ├── errors/
│   │   │   ├── exceptions.dart
│   │   │   ├── failures.dart
│   │   │   └── error_handler.dart
│   │   ├── network/
│   │   │   ├── api_client.dart
│   │   │   ├── network_info.dart
│   │   │   ├── interceptors/
│   │   │   │   ├── auth_interceptor.dart
│   │   │   │   ├── logging_interceptor.dart
│   │   │   │   └── error_interceptor.dart
│   │   │   └── adapters/
│   │   │       └── dio_adapter.dart
│   │   ├── utils/
│   │   │   ├── date_utils.dart
│   │   │   ├── validation_utils.dart
│   │   │   ├── format_utils.dart
│   │   │   └── extensions/
│   │   │       ├── string_extension.dart
│   │   │       └── datetime_extension.dart
│   │   ├── widgets/
│   │   │   ├── common/
│   │   │   │   ├── loading_widget.dart
│   │   │   │   ├── error_widget.dart
│   │   │   │   ├── empty_state_widget.dart
│   │   │   │   └── custom_button.dart
│   │   │   └── forms/
│   │   │       ├── text_field_widget.dart
│   │   │       ├── dropdown_widget.dart
│   │   │       └── date_picker_widget.dart
│   │   ├── theme/
│   │   │   ├── app_theme.dart
│   │   │   ├── light_theme.dart
│   │   │   ├── dark_theme.dart
│   │   │   └── colors.dart
│   │   └── di/
│   │       ├── injection_container.dart
│   │       └── feature_injection.dart
│   ├── features/
│   │   ├── authentication/
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   ├── auth_remote_data_source.dart
│   │   │   │   │   └── auth_local_data_source.dart
│   │   │   │   ├── models/
│   │   │   │   │   ├── auth_model.dart
│   │   │   │   │   ├── user_model.dart
│   │   │   │   │   └── token_model.dart
│   │   │   │   └── repositories/
│   │   │   │       └── auth_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   ├── auth_entity.dart
│   │   │   │   │   ├── user_entity.dart
│   │   │   │   │   └── token_entity.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── auth_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       ├── login_usecase.dart
│   │   │   │       ├── logout_usecase.dart
│   │   │   │       ├── register_usecase.dart
│   │   │   │       └── get_current_user_usecase.dart
│   │   │   └── presentation/
│   │   │       ├── pages/
│   │   │       │   ├── login_page.dart
│   │   │       │   ├── register_page.dart
│   │   │       │   └── forgot_password_page.dart
│   │   │       ├── widgets/
│   │   │       │   ├── login_form_widget.dart
│   │   │       │   ├── register_form_widget.dart
│   │   │       │   └── social_login_widget.dart
│   │   │       └── state_management/
│   │   │           ├── providers/  # Provider pattern
│   │   │           │   ├── auth_provider.dart
│   │   │           │   └── login_provider.dart
│   │   │           ├── bloc/      # Bloc pattern
│   │   │           │   ├── auth_bloc.dart
│   │   │           │   ├── auth_state.dart
│   │   │           │   ├── auth_event.dart
│   │   │           │   └── login_bloc.dart
│   │   │           └── riverpod/  # Riverpod pattern
│   │   │               ├── auth_provider.dart
│   │   │               ├── auth_notifier.dart
│           └── getx/      # GetX pattern
│               ├── auth_controller.dart
│               └── auth_binding.dart
│   │   │               └── auth_state.dart
│   │   ├── user_management/
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   ├── user_remote_data_source.dart
│   │   │   │   └── user_local_data_source.dart
│   │   │   ├── models/
│   │   │   │   └── user_model.dart
│   │   │   └── repositories/
│   │   │       └── user_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── user_entity.dart
│   │   │   ├── repositories/
│   │   │   │   └── user_repository.dart
│   │   │   └── usecases/
│   │   │       ├── get_users_usecase.dart
│   │   │       ├── get_user_by_id_usecase.dart
│   │   │       ├── create_user_usecase.dart
│   │   │       ├── update_user_usecase.dart
│   │   │       └── delete_user_usecase.dart
│   │   └── presentation/
│   │       ├── pages/
│   │       │   ├── user_list_page.dart
│   │       │   ├── user_detail_page.dart
│   │       │   └── user_form_page.dart
│   │       ├── widgets/
│   │       │   ├── user_card_widget.dart
│   │       │   ├── user_form_widget.dart
│   │       │   └── user_avatar_widget.dart
│   │       └── state_management/
│   │           ├── providers/  # Provider pattern
│   │           │   ├── user_provider.dart
│   │           │   └── user_form_provider.dart
│   │           ├── bloc/      # Bloc pattern
│   │           │   ├── user_bloc.dart
│   │           │   ├── user_state.dart
│   │           │   ├── user_event.dart
│   │           │   └── user_form_bloc.dart
│   │           └── riverpod/  # Riverpod pattern
│   │               ├── user_provider.dart
│   │               ├── user_notifier.dart
│           └── getx/      # GetX pattern
│               ├── user_controller.dart
│               └── user_binding.dart
│   │               └── user_state.dart
│   │   └── [other_features...]
│   ├── main.dart
│   └── app.dart
├── test/
│   ├── fixtures/
│   ├── helpers/
│   ├── mocks/
│   └── unit/
│       ├── core/
│       └── features/
├── integration_test/
├── assets/
│   ├── images/
│   ├── fonts/
│   └── data/
├── pubspec.yaml
├── analysis_options.yaml
└── README.md
```

## Core Files Templates

### main.dart
```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'core/di/injection_container.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize dependencies
  await configureDependencies();

  runApp(MyApp());
}
```

### app.dart

#### Provider Implementation
```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/route_constants.dart';
import 'features/authentication/presentation/providers/auth_provider.dart';
import 'features/user_management/presentation/providers/user_provider.dart';
import 'features/authentication/presentation/pages/login_page.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => sl<AuthProvider>()),
        ChangeNotifierProvider(create: (_) => sl<UserProvider>()),
      ],
      child: MaterialApp(
        title: 'Enterprise App',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        initialRoute: RouteConstants.login,
        routes: {
          RouteConstants.login: (context) => LoginPage(),
          // Add other routes
        },
        onGenerateRoute: _generateRoute,
      ),
    );
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    // Handle dynamic routes
    return null;
  }
}
```

#### Bloc Implementation
```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/route_constants.dart';
import 'features/authentication/presentation/bloc/auth_bloc.dart';
import 'features/user_management/presentation/bloc/user_bloc.dart';
import 'features/authentication/presentation/pages/login_page.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<AuthBloc>()),
        BlocProvider(create: (_) => sl<UserBloc>()),
      ],
      child: MaterialApp(
        title: 'Enterprise App',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        initialRoute: RouteConstants.login,
        routes: {
          RouteConstants.login: (context) => LoginPage(),
          // Add other routes
        },
        onGenerateRoute: _generateRoute,
      ),
    );
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    // Handle dynamic routes
    return null;
  }
}
```

#### Riverpod Implementation
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/route_constants.dart';
import 'features/authentication/presentation/riverpod/auth_provider.dart';
import 'features/user_management/presentation/riverpod/user_provider.dart';
import 'features/authentication/presentation/pages/login_page.dart';

class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Enterprise App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: RouteConstants.login,
      routes: {
        RouteConstants.login: (context) => LoginPage(),
        // Add other routes
      },
      onGenerateRoute: _generateRoute,
    );
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    // Handle dynamic routes
    return null;
  }
}
#### GetX Implementation
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/route_constants.dart';
import 'features/authentication/presentation/controllers/auth_controller.dart';
import 'features/user_management/presentation/controllers/user_controller.dart';
import 'features/authentication/presentation/pages/login_page.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Enterprise App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: RouteConstants.login,
      getPages: [
        GetPage(
          name: RouteConstants.login,
          page: () => LoginPage(),
          binding: AuthBinding(),
        ),
        // Add other routes
      ],
    );
  }
}
```
```

### app.dart (Bloc Implementation)
```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/route_constants.dart';
import 'features/authentication/presentation/bloc/auth_bloc.dart';
import 'features/user_management/presentation/bloc/user_bloc.dart';
import 'features/authentication/presentation/pages/login_page.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<AuthBloc>()),
        BlocProvider(create: (_) => sl<UserBloc>()),
      ],
      child: MaterialApp(
        title: 'Enterprise App',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        initialRoute: RouteConstants.login,
        routes: {
          RouteConstants.login: (context) => LoginPage(),
          // Add other routes
        },
        onGenerateRoute: _generateRoute,
      ),
    );
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    // Handle dynamic routes
    return null;
  }
}
```

### app.dart (Riverpod Implementation)
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/route_constants.dart';
import 'features/authentication/presentation/pages/login_page.dart';

class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Enterprise App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: RouteConstants.login,
      routes: {
        RouteConstants.login: (context) => LoginPage(),
        // Add other routes
      },
      onGenerateRoute: _generateRoute,
    );
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    // Handle dynamic routes
    return null;
  }
}
```

### Constants Templates

#### app_constants.dart
```dart
class AppConstants {
  // App info
  static const String appName = 'Enterprise App';
  static const String appVersion = '1.0.0';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Cache
  static const Duration cacheTimeout = Duration(hours: 1);
  static const Duration userCacheTimeout = Duration(minutes: 30);

  // Validation
  static const int minPasswordLength = 8;
  static const int maxUsernameLength = 50;
  static const int maxEmailLength = 100;

  // UI
  static const double defaultBorderRadius = 8.0;
  static const double largeBorderRadius = 12.0;
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
}
```

#### api_constants.dart
```dart
class ApiConstants {
  static const String baseUrl = 'https://api.example.com/v1';

  // Endpoints
  static const String auth = '/auth';
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';

  static const String users = '/users';
  static const String userProfile = '/users/profile';

  // Headers
  static const String contentType = 'application/json';
  static const String accept = 'application/json';
  static const String authorization = 'Authorization';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);
}
```

#### route_constants.dart
```dart
class RouteConstants {
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String userList = '/users';
  static const String userDetail = '/users/:id';
  static const String userForm = '/users/form';
}
```

### Error Handling Templates

#### exceptions.dart
```dart
abstract class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, [this.code]);

  @override
  String toString() => 'AppException: $message';
}

class ServerException extends AppException {
  const ServerException(String message, [String? code]) : super(message, code);
}

class NetworkException extends AppException {
  const NetworkException(String message, [String? code]) : super(message, code);
}

class ValidationException extends AppException {
  const ValidationException(String message, [String? code]) : super(message, code);
}

class CacheException extends AppException {
  const CacheException(String message, [String? code]) : super(message, code);
}

class AuthenticationException extends AppException {
  const AuthenticationException(String message, [String? code]) : super(message, code);
}

class AuthorizationException extends AppException {
  const AuthorizationException(String message, [String? code]) : super(message, code);
}
```

#### failures.dart
```dart
abstract class Failure {
  final String message;
  final String? code;

  const Failure(this.message, [this.code]);
}

class ServerFailure extends Failure {
  const ServerFailure(String message, [String? code]) : super(message, code);
}

class NetworkFailure extends Failure {
  const NetworkFailure(String message, [String? code]) : super(message, code);
}

class ValidationFailure extends Failure {
  const ValidationFailure(String message, [String? code]) : super(message, code);
}

class CacheFailure extends Failure {
  const CacheFailure(String message, [String? code]) : super(message, code);
}

class AuthenticationFailure extends Failure {
  const AuthenticationFailure(String message, [String? code]) : super(message, code);
}

class AuthorizationFailure extends Failure {
  const AuthorizationFailure(String message, [String? code]) : super(message, code);
}
```

### Dependency Injection Template

#### injection_container.dart
```dart
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

final GetIt sl = GetIt.instance;

@InjectableInit()
Future<void> configureDependencies() async {
  await sl.init();
}
```

### pubspec.yaml Template
```yaml
name: enterprise_app
description: Flutter Enterprise Application

version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: ">=3.10.0"

dependencies:
  flutter:
    sdk: flutter

  # State Management (Choose based on preference)
  provider: ^6.1.1              # For Provider pattern
  flutter_bloc: ^8.1.3           # For Bloc pattern
  flutter_riverpod: ^2.4.9        # For Riverpod pattern
  get: ^4.6.6                   # For GetX pattern

  # Dependency Injection
  get_it: ^7.6.4
  injectable: ^2.3.2

  # Network
  dio: ^5.3.2
  retrofit: ^4.0.3

  # Local Storage
  shared_preferences: ^2.2.2
  hive: ^2.2.3
  hive_flutter: ^1.1.0

  # JSON Serialization
  json_annotation: ^4.8.1

  # Code Generation
  freezed_annotation: ^2.4.1
  equatable: ^2.0.5

  # UI
  cupertino_icons: ^1.0.2

  # Utils
  intl: ^0.18.1
  uuid: ^4.2.1

  # Navigation
  go_router: ^12.1.3

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

  # Code Generation
  build_runner: ^2.4.6
  json_serializable: ^6.7.1
  freezed: ^2.4.6
  injectable_generator: ^2.4.1
  retrofit_generator: ^8.0.4

  # Testing
  mockito: ^5.4.2
  bloc_test: ^9.1.4           # For Bloc testing
  flutter_riverpod: ^2.4.9        # For Riverpod testing
  get_test: ^3.0.0             # For GetX testing
  integration_test:
    sdk: flutter

flutter:
  uses-material-design: true

  assets:
    - assets/images/
    - assets/data/

  fonts:
    - family: Roboto
      fonts:
        - asset: assets/fonts/Roboto-Regular.ttf
        - asset: assets/fonts/Roboto-Bold.ttf
          weight: 700
```

### analysis_options.yaml Template
```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"

  errors:
    invalid_annotation_target: ignore

linter:
  rules:
    # Enable additional lint rules
    prefer_single_quotes: true
    sort_constructors_first: true
    sort_unnamed_constructors_first: true
    always_declare_return_types: true
    avoid_print: true
    avoid_unnecessary_containers: true
    sized_box_for_whitespace: true
    use_key_in_widget_constructors: true
    prefer_const_constructors: true
    prefer_const_literals_to_create_immutables: true
    prefer_const_declarations: true
    prefer_final_fields: true
    prefer_final_locals: true
    avoid_redundant_argument_values: true
    avoid_types_on_closure_parameters: true
    avoid_function_literals_in_foreach_calls: true
    avoid_returning_null_for_void: true
    prefer_is_empty: true
    prefer_is_not_empty: true
    unnecessary_const: true
    unnecessary_new: true
    prefer_if_null_operators: true
    prefer_null_aware_operators: true
```

## Setup Commands

### Initial Setup
```bash
# Create new Flutter project
flutter create enterprise_app --org com.example

# Navigate to project
cd enterprise_app

# Add dependencies
flutter pub add provider flutter_bloc flutter_riverpod get_it injectable dio retrofit shared_preferences hive hive_flutter json_annotation freezed_annotation equatable cupertino_icons intl uuid go_router

# Add dev dependencies
flutter pub add --dev flutter_test flutter_lints build_runner json_serializable freezed injectable_generator retrofit_generator mockito bloc_test integration_test

# Create directory structure
mkdir -p lib/core/{constants,errors,network,utils,widgets,theme,di}
mkdir -p lib/features/authentication/{data/{datasources,models,repositories},domain/{entities,repositories,usecases},presentation/{pages,widgets,state_management/{providers,bloc,riverpod}}}
mkdir -p lib/features/user_management/{data/{datasources,models,repositories},domain/{entities,repositories,usecases},presentation/{pages,widgets,state_management/{providers,bloc,riverpod}}}
mkdir -p test/{fixtures,helpers,mocks,unit/{core,features}}
mkdir -p integration_test
mkdir -p assets/{images,fonts,data}
```

### Code Generation
```bash
# Generate code
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode for development
flutter pub run build_runner watch --delete-conflicting-outputs
```

## State Management Selection Guide

### Choosing Your State Management Solution

#### Provider Pattern
- **When to use**: Simple to medium complexity apps, teams familiar with Provider
- **Pros**: Lightweight, easy to learn, good performance
- **Cons**: Manual boilerplate for state comparison
- **Dependencies**: `provider: ^6.1.1`

#### Bloc Pattern
- **When to use**: Complex apps with strict state management requirements
- **Pros**: Predictable state, excellent tooling, strong separation of concerns
- **Cons**: More boilerplate, steeper learning curve
- **Dependencies**: `flutter_bloc: ^8.1.3`, `equatable: ^2.0.5`

#### Riverpod Pattern
- **When to use**: Modern apps needing compile-time safety and flexibility
- **Pros**: Compile-time safety, great testing support, flexible providers
- **Cons**: Newer ecosystem, requires mindset shift
- **Dependencies**: `flutter_riverpod: ^2.4.9`

#### GetX Pattern
- **When to use**: Apps requiring minimal boilerplate and high performance
- **Pros**: Minimal boilerplate, excellent performance, simple syntax, built-in dependency injection
- **Cons**: Less conventional, magic-based approach can hide complexity
- **Dependencies**: `get: ^4.6.6`

### Migration Paths

All four patterns can be easily migrated between since they share the same clean architecture foundation:

1. **Keep Domain Layer**: Entities, repositories, and use cases remain unchanged
2. **Adapt Presentation Layer**: Only state management implementation changes
3. **Update Dependency Injection**: Register appropriate providers/blocs/notifiers
4. **Update Testing**: Use corresponding testing libraries and patterns

### Implementation Notes

- Choose **one** state management solution per project
- All examples in documentation are functionally equivalent
- Testing patterns are provided for each approach
- Directory structure supports all four patterns simultaneously

This template provides a comprehensive foundation for enterprise Flutter applications with clean architecture and feature-based structure, supporting all major state management approaches.