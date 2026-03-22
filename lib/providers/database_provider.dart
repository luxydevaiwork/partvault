import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/database_service.dart';
import '../data/repositories/item_repository.dart';
import '../data/repositories/category_repository.dart';

final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  return ItemRepository(DatabaseService.database);
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(DatabaseService.database);
});
