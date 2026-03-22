import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/category_model.dart';
import 'database_provider.dart';

class CategoriesNotifier extends AsyncNotifier<List<CategoryModel>> {
  @override
  Future<List<CategoryModel>> build() async {
    return ref.read(categoryRepositoryProvider).getAll();
  }

  Future<void> addCategory(CategoryModel category) async {
    await ref.read(categoryRepositoryProvider).insert(category);
    ref.invalidateSelf();
    await future;
  }

  Future<void> updateCategory(CategoryModel category) async {
    await ref.read(categoryRepositoryProvider).update(category);
    ref.invalidateSelf();
    await future;
  }

  Future<void> deleteCategory(String id) async {
    await ref.read(categoryRepositoryProvider).delete(id);
    ref.invalidateSelf();
    await future;
  }
}

final categoriesProvider =
    AsyncNotifierProvider<CategoriesNotifier, List<CategoryModel>>(
        CategoriesNotifier.new);
