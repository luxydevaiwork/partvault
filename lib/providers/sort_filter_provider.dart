import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/item.dart';
import 'items_provider.dart';

enum SortOption {
  dateNewest,
  dateOldest,
  nameAsc,
  nameDesc,
  expiryDate,
  maintenanceDue,
  quantity,
}

extension SortOptionLabel on SortOption {
  String get label {
    switch (this) {
      case SortOption.dateNewest:
        return 'Più recenti';
      case SortOption.dateOldest:
        return 'Meno recenti';
      case SortOption.nameAsc:
        return 'Nome A→Z';
      case SortOption.nameDesc:
        return 'Nome Z→A';
      case SortOption.expiryDate:
        return 'Scadenza';
      case SortOption.maintenanceDue:
        return 'Manutenzione';
      case SortOption.quantity:
        return 'Quantità';
    }
  }
}

final sortOptionProvider =
    StateProvider<SortOption>((ref) => SortOption.dateNewest);

/// Sorted+filtered view of all items (used in search results and all-items list).
final sortedItemsProvider = Provider<List<Item>>((ref) {
  final items = ref.watch(itemsProvider).valueOrNull ?? [];
  final sort = ref.watch(sortOptionProvider);
  final list = List<Item>.from(items);
  switch (sort) {
    case SortOption.dateNewest:
      list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    case SortOption.dateOldest:
      list.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
    case SortOption.nameAsc:
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    case SortOption.nameDesc:
      list.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
    case SortOption.expiryDate:
      list.sort((a, b) {
        if (a.expiryDate == null && b.expiryDate == null) return 0;
        if (a.expiryDate == null) return 1;
        if (b.expiryDate == null) return -1;
        return a.expiryDate!.compareTo(b.expiryDate!);
      });
    case SortOption.maintenanceDue:
      list.sort((a, b) {
        if (a.isMaintenanceDue && !b.isMaintenanceDue) return -1;
        if (!a.isMaintenanceDue && b.isMaintenanceDue) return 1;
        final aNext = a.nextMaintenanceDate;
        final bNext = b.nextMaintenanceDate;
        if (aNext == null && bNext == null) return 0;
        if (aNext == null) return 1;
        if (bNext == null) return -1;
        return aNext.compareTo(bNext);
      });
    case SortOption.quantity:
      list.sort((a, b) => b.quantity.compareTo(a.quantity));
  }
  return list;
});
