import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/db/isar_service.dart' show IsarService;

final isarServiceProvider = Provider<IsarService>((ref) => IsarService());
