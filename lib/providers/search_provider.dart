import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/item.dart';
import 'database_provider.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<Item>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty) return [];
  return ref.read(itemRepositoryProvider).search(query);
});
