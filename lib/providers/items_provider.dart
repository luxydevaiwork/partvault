import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/widget_service.dart';
import '../data/models/item.dart';
import 'database_provider.dart';

class ItemsNotifier extends AsyncNotifier<List<Item>> {
  @override
  Future<List<Item>> build() async {
    final items = await ref.read(itemRepositoryProvider).getAll();
    _updateWidget(items);
    return items;
  }

  Future<void> addItem(Item item) async {
    await ref.read(itemRepositoryProvider).insert(item);
    ref.invalidateSelf();
    final items = await future;
    _updateWidget(items);
  }

  Future<void> updateItem(Item item) async {
    await ref.read(itemRepositoryProvider).update(item);
    ref.invalidateSelf();
    final items = await future;
    _updateWidget(items);
  }

  Future<void> deleteItem(String id) async {
    await ref.read(itemRepositoryProvider).delete(id);
    ref.invalidateSelf();
    final items = await future;
    _updateWidget(items);
  }

  void _updateWidget(List<Item> items) {
    WidgetService.updateWidget(items: items);
  }
}

final itemsProvider =
    AsyncNotifierProvider<ItemsNotifier, List<Item>>(ItemsNotifier.new);

final itemCountPerCategoryProvider =
    FutureProvider<Map<String, int>>((ref) async {
  ref.watch(itemsProvider);
  return ref.read(itemRepositoryProvider).getCountPerCategory();
});
