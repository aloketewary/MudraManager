# Performance Optimization for Flutter Enterprise Apps

## Overview

Performance optimization is crucial for enterprise Flutter applications to ensure smooth user experience, efficient resource usage, and scalability. This guide covers comprehensive performance optimization strategies for Flutter apps using clean architecture.

## Performance Monitoring

### Performance Metrics

```dart
// lib/core/performance/performance_monitor.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class PerformanceMonitor {
  static const Duration _frameTimeThreshold = Duration(milliseconds: 16);
  static const Duration _jankThreshold = Duration(milliseconds: 100);

  static void startMonitoring() {
    if (!kReleaseMode) {
      WidgetsBinding.instance.addPostFrameCallback(_onPostFrame);
    }
  }

  static void _onPostFrame(Duration timestamp) {
    final frameTime = timestamp;
    if (frameTime > _frameTimeThreshold) {
      debugPrint('Frame time exceeded threshold: ${frameTime.inMilliseconds}ms');
    }
  }

  static void trackJank(String operation) {
    final stopwatch = Stopwatch()..start();

    return () {
      stopwatch.stop();
      if (stopwatch.elapsed > _jankThreshold) {
        debugPrint('Jank detected in $operation: ${stopwatch.elapsed.inMilliseconds}ms');
      }
    };
  }

  static void trackMemoryUsage(String operation) {
    if (!kReleaseMode) {
      final info = ProcessInfo.currentRss;
      debugPrint('Memory usage for $operation: ${info / 1024 / 1024}MB');
    }
  }
}
```

### Performance Dashboard

```dart
// lib/core/performance/performance_dashboard.dart
import 'package:flutter/material.dart';

class PerformanceDashboard extends StatefulWidget {
  const PerformanceDashboard({Key? key}) : super(key: key);

  @override
  _PerformanceDashboardState createState() => _PerformanceDashboardState();
}

class _PerformanceDashboardState extends State<PerformanceDashboard> {
  Timer? _timer;
  double _fps = 0.0;
  int _frameCount = 0;
  Duration _lastFrameTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startPerformanceMonitoring();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startPerformanceMonitoring() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _fps = _frameCount.toDouble();
        _frameCount = 0;
      });
    });
  }

  void _onFrame(Duration timestamp) {
    if (_lastFrameTime != Duration.zero) {
      final frameTime = timestamp - _lastFrameTime;
      if (frameTime.inMilliseconds < 100) { // Only count frames under 100ms
        _frameCount++;
      }
    }
    _lastFrameTime = timestamp;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Performance Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('FPS: ${_fps.toStringAsFixed(1)}'),
            Text('Frame Count: $_frameCount'),
            // Add more performance metrics
          ],
        ),
      ),
    );
  }
}
```

## Widget Performance Optimization

### Efficient List Views

```dart
// lib/core/widgets/optimized_list_view.dart
import 'package:flutter/material.dart';

class OptimizedListView<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(BuildContext, int, T) itemBuilder;
  final ScrollController? controller;
  final bool shrinkWrap;
  final double? itemExtent;

  const OptimizedListView({
    Key? key,
    required this.items,
    required this.itemBuilder,
    this.controller,
    this.shrinkWrap = false,
    this.itemExtent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      shrinkWrap: shrinkWrap,
      itemExtent: itemExtent,
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildOptimizedItem(context, index);
      },
    );
  }

  Widget _buildOptimizedItem(BuildContext context, int index) {
    return RepaintBoundary(
      key: ValueKey(items[index]),
      child: itemBuilder(context, index, items[index]),
    );
  }
}
```

### Image Optimization

```dart
// lib/core/widgets/optimized_image.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class OptimizedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BoxFit fit;

  const OptimizedImage({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
    this.fit = BoxFit.cover,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      placeholder: placeholder,
      errorWidget: errorWidget,
      fit: fit,
      memCacheWidth: width?.toInt() ?? 100,
      memCacheHeight: height?.toInt() ?? 100,
      cacheKey: imageUrl,
      imageBuilder: (context, imageProvider) => Image(
        image: imageProvider,
        width: width,
        height: height,
        fit: fit,
        filterQuality: FilterQuality.low,
        isAntiAlias: false,
      ),
    );
  }
}
```

### Lazy Loading

```dart
// lib/core/widgets/lazy_load_list.dart
import 'package:flutter/material.dart';

class LazyLoadList<T> extends StatefulWidget {
  final Future<List<T>> Function(int page) loadMore;
  final Widget Function(BuildContext, int, T) itemBuilder;
  final int pageSize;

  const LazyLoadList({
    Key? key,
    required this.loadMore,
    required this.itemBuilder,
    this.pageSize = 20,
  }) : super(key: key);

  @override
  _LazyLoadListState<T> createState() => _LazyLoadListState<T>();
}

class _LazyLoadListState<T> extends State<LazyLoadList> {
  final ScrollController _scrollController = ScrollController();
  List<T> _items = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitialItems();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialItems() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final newItems = await widget.loadMore(_currentPage);
      setState(() {
        _items.addAll(newItems);
        _isLoading = false;
        _hasMore = newItems.length == widget.pageSize;
        _currentPage++;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Handle error
    }
  }

  Future<void> _loadMoreItems() async {
    if (!_hasMore || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      final newItems = await widget.loadMore(_currentPage);
      setState(() {
        _items.addAll(newItems);
        _isLoading = false;
        _hasMore = newItems.length == widget.pageSize;
        _currentPage++;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Handle error
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: _items.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _items.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        return RepaintBoundary(
          key: ValueKey(_items[index]),
          child: widget.itemBuilder(context, index, _items[index]),
        );
      },
    );
  }
}
```

## Memory Management

### Memory-Efficient Data Models

```dart
// lib/core/models/memory_efficient_model.dart
import 'package:flutter/foundation.dart';

@immutable
class MemoryEfficientModel {
  final String id;
  final String name;
  final String description;

  const MemoryEfficientModel({
    required this.id,
    required this.name,
    required this.description,
  });

  factory MemoryEfficientModel.fromJson(Map<String, dynamic> json) {
    return MemoryEfficientModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MemoryEfficientModel &&
        other.id == id &&
        other.name == name &&
        other.description == description;
  }

  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode ^ description.hashCode;
  }
}
```

### Memory Cache

```dart
// lib/core/cache/memory_cache.dart
import 'dart:collection';

class MemoryCache<K, V> {
  final Map<K, V> _cache = {};
  final Map<K, DateTime> _timestamps = {};
  final Duration _ttl;
  final int _maxSize;

  MemoryCache({
    Duration ttl = const Duration(hours: 1),
    int maxSize = 100,
  }) : _ttl = ttl, _maxSize = maxSize;

  V? get(K key) {
    final timestamp = _timestamps[key];
    if (timestamp != null) {
      if (DateTime.now().difference(timestamp) > _ttl) {
        _remove(key);
        return null;
      }
    }
    return _cache[key];
  }

  void put(K key, V value) {
    if (_cache.length >= _maxSize) {
      _evictOldest();
    }

    _cache[key] = value;
    _timestamps[key] = DateTime.now();
  }

  void remove(K key) {
    _cache.remove(key);
    _timestamps.remove(key);
  }

  void _remove(K key) {
    _cache.remove(key);
    _timestamps.remove(key);
  }

  void _evictOldest() {
    if (_timestamps.isEmpty) return;

    K? oldestKey;
    DateTime?oldestTimestamp;

    for (final entry in _timestamps.entries) {
      if (oldestTimestamp == null || entry.value.isBefore(oldestTimestamp!)) {
        oldestTimestamp = entry.value;
        oldestKey = entry.key;
      }
    }

    if (oldestKey != null) {
      _remove(oldestKey);
    }
  }

  void clear() {
    _cache.clear();
    _timestamps.clear();
  }

  int get size => _cache.length;
}
```

## Network Performance

### Request Optimization

```dart
// lib/core/network/optimized_client.dart
import 'package:dio/dio.dart';

class OptimizedHttpClient {
  final Dio _dio;
  final MemoryCache<String, dynamic> _cache;

  OptimizedHttpClient({
    required String baseUrl,
    Duration timeout = const Duration(seconds: 30),
    Duration cacheTtl = const Duration(minutes: 5),
  }) : _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: timeout,
    receiveTimeout: timeout,
    sendTimeout: timeout,
  )), _cache = MemoryCache(ttl: cacheTtl);

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final cacheKey = _generateCacheKey('GET', path, queryParameters);
    final cachedResponse = _cache.get(cacheKey);

    if (cachedResponse != null) {
      return Response<T>.fromJson(cachedResponse, options ?? Options());
    }

    try {
      final response = await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );

      if (response.statusCode == 200) {
        _cache.put(cacheKey, response.data);
      }

      return response;
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );

      // Clear cache for POST requests
      _clearRelatedCache(path);

      return response;
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  String _generateCacheKey(
    String method,
    String path,
    Map<String, dynamic>? queryParameters,
  ) {
    final queryString = queryParameters?.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&') ?? '';

    return '$method:$path:$queryString';
  }

  void _clearRelatedCache(String path) {
    final keysToRemove = _cache._cache.keys
        .where((key) => key.contains(path))
        .toList();

    for (final key in keysToRemove) {
      _cache.remove(key);
    }
  }

  Exception _handleDioException(DioException exception) {
    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException('Request timeout', 'TIMEOUT');

      case DioExceptionType.connectionError:
        return NetworkException('No internet connection', 'NO_INTERNET');

      case DioExceptionType.badResponse:
        return ServerException('Server error: ${exception.response?.statusCode}');

      case DioExceptionType.cancel:
        return NetworkException('Request cancelled', 'CANCELLED');

      default:
        return UnknownException('Network error: ${exception.message}');
    }
  }
}
```

### Request Batching

```dart
// lib/core/network/request_batcher.dart
import 'dart:async';

class RequestBatcher<T> {
  final Duration _batchDelay;
  final List<Future<T> Function()> _pendingRequests = [];
  Timer? _timer;

  RequestBatcher({Duration batchDelay = const Duration(milliseconds: 100)})
      : _batchDelay = batchDelay;

  Future<T> add(Future<T> Function() request) {
    final completer = Completer<T>();

    _pendingRequests.add(() {
      final future = request();
      future.then((result) => completer.complete(result));
      return future;
    });

    _scheduleBatch();

    return completer.future;
  }

  void _scheduleBatch() {
    _timer?.cancel();
    _timer = Timer(_batchDelay, () {
      _executeBatch();
    });
  }

  Future<void> _executeBatch() async {
    if (_pendingRequests.isEmpty) return;

    final requests = List.from(_pendingRequests);
    _pendingRequests.clear();

    try {
      await Future.wait(requests.map((request) => request()));
    } catch (e) {
      // Handle batch errors
    }
  }
}
```

## State Management Performance

### Efficient State Updates

```dart
// lib/core/state/efficient_notifier.dart
import 'package:flutter/foundation.dart';

class EfficientNotifier<T> extends ChangeNotifier {
  T _value;
  final List<VoidCallback> _listeners = [];

  EfficientNotifier(T initialValue) : _value = initialValue;

  T get value => _value;

  void updateValue(T newValue) {
    if (_value != newValue) {
      _value = newValue;
      notifyListeners();
    }
  }

  void updateValueIf(T condition, T newValue) {
    if (_value != newValue && condition) {
      _value = newValue;
      notifyListeners();
    }
  }

  @override
  void addListener(VoidCallback listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
      super.addListener(listener);
    }
  }

  @override
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
    super.removeListener(listener);
  }
}
```

### Selective Rebuilds

```dart
// lib/core/widgets/selective_rebuild.dart
import 'package:flutter/material.dart';

class SelectiveRebuild<T> extends StatelessWidget {
  final T value;
  final Widget Function(BuildContext, T) builder;
  final bool Function(T, T)? compare;

  const SelectiveRebuild({
    Key? key,
    required this.value,
    required this.builder,
    this.compare,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return builder(context, value);
  }

  bool shouldRebuild(T oldValue, T newValue) {
    if (compare != null) {
      return compare!(oldValue, newValue);
    }
    return oldValue != newValue;
  }
}
```

## Performance Best Practices

### 1. Widget Optimization

- **Use const widgets**: Use const widgets for static content
- **RepaintBoundary**: Wrap expensive widgets in RepaintBoundary
- **Avoid unnecessary rebuilds**: Use const and final variables
- **Optimize list views**: Use itemExtent and shrinkWrap appropriately
- **Lazy loading**: Implement lazy loading for large lists
- **Image optimization**: Use cached images and proper sizing

### 2. Memory Management

- **Dispose resources**: Properly dispose controllers, streams, and animations
- **Use memory cache**: Implement caching with TTL
- **Avoid memory leaks**: Clean up references in dispose methods
- **Use efficient data structures**: Choose appropriate data structures
- **Monitor memory usage**: Track memory consumption

### 3. Network Performance

- **Request caching**: Cache GET requests with appropriate TTL
- **Request batching**: Batch multiple requests when possible
- **Connection pooling**: Reuse connections when appropriate
- **Compression**: Use gzip compression for API requests
- **Timeout handling**: Implement proper timeout strategies

### 4. State Management

- **Selective updates**: Only update state when necessary
- **Debounce operations**: Debounce frequent state changes
- **Use efficient notifiers**: Implement efficient change notification
- **Avoid deep copies**: Use reference equality when possible
- **Minimize state size**: Keep state objects small

### 5. Build Optimization

- **Use release builds**: Always use release builds for production
- **Enable tree shaking**: Remove unused code
- **Optimize assets**: Compress images and other assets
- **Code splitting**: Split code into smaller chunks
- **Use AOT compilation**: Use ahead-of-time compilation

## Performance Testing

### Performance Tests

```dart
// test/performance/list_view_performance_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  testWidgets('ListView performance test', (WidgetTester tester) async {
    final stopwatch = Stopwatch()..start();

    // Build large list
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView.builder(
            itemCount: 1000,
            itemBuilder: (context, index) {
              return ListTile(title: Text('Item $index'));
            },
          ),
        ),
      ),
    );

    // Measure build time
    final buildTime = stopwatch.elapsed;

    // Measure frame rate
    await tester.pumpAndSettle();

    // Assert performance requirements
    expect(buildTime.inMilliseconds, lessThan(100));
  });
}
```

### Memory Profiling

```dart
// test/performance/memory_profiling_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'dart:io';

void main() {
  test('Memory usage test', () async {
    final initialMemory = ProcessInfo.currentRss;

    // Perform memory-intensive operations
    final items = List.generate(10000, (index) => 'Item $index');

    final finalMemory = ProcessInfo.currentRss;
    final memoryIncrease = finalMemory - initialMemory;

    // Assert memory usage is within limits
    expect(memoryIncrease, lessThan(50 * 1024 * 1024)); // 50MB
  });
}
```

## Performance Monitoring Tools

### Flutter Inspector

```dart
// lib/core/performance/inspector_integration.dart
import 'package:flutter/foundation.dart';

class InspectorIntegration {
  static void enablePerformanceOverlay() {
    if (!kReleaseMode) {
      WidgetsApp.debugAllowBannerOverride = true;
    }
  }

  static void logPerformanceMetrics() {
    if (!kReleaseMode) {
      // Log performance metrics for debugging
      WidgetsBinding.instance.addPostFrameCallback((timestamp) {
        // Track frame times
      });
    }
  }
}
```

### Custom Performance Metrics

```dart
// lib/core/performance/custom_metrics.dart
import 'package:flutter/foundation.dart';

class CustomMetrics {
  static final Map<String, List<Duration>> _metrics = {};

  static void trackMetric(String name, Duration duration) {
    if (!kReleaseMode) {
      _metrics[name] ??= [];
      _metrics[name]!.add(duration);

      if (_metrics[name]!.length > 100) {
        _metrics[name]!.removeAt(0);
      }

      _logMetricStats(name);
    }
  }

  static void _logMetricStats(String name) {
    final durations = _metrics[name]!;
    final average = durations.reduce((a, b) => a + b) / durations.length;
    final max = durations.reduce((a, b) => a > b ? a : b);
    final min = durations.reduce((a, b) => a < b ? a : b);

    debugPrint('$name - Average: ${average.inMilliseconds}ms, '
        'Max: ${max.inMilliseconds}ms, '
        'Min: ${min.inMilliseconds}ms');
  }

  static Map<String, double> getMetricStats() {
    final stats = <String, double>{};

    for (final entry in _metrics.entries) {
      final durations = entry.value;
      if (durations.isNotEmpty) {
        stats[entry.key] = durations
            .map((d) => d.inMilliseconds.toDouble())
            .reduce((a, b) => a + b) / durations.length;
      }
    }

    return stats;
  }
}
```

This comprehensive performance optimization guide ensures Flutter enterprise applications run efficiently with optimal resource usage and smooth user experience.