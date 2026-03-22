import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/category_model.dart';
import '../../data/models/item.dart';
import '../../providers/categories_provider.dart';
import '../../providers/database_provider.dart';
import '../../providers/items_provider.dart';
import '../../providers/sort_filter_provider.dart';
import '../home/widgets/item_card.dart';

final _categoryItemsProvider =
    FutureProvider.family<List<Item>, String>((ref, categoryId) async {
  ref.watch(itemsProvider);
  return ref.read(itemRepositoryProvider).getByCategory(categoryId);
});

class CategoryDetailScreen extends ConsumerStatefulWidget {
  final String categoryId;
  const CategoryDetailScreen({super.key, required this.categoryId});

  @override
  ConsumerState<CategoryDetailScreen> createState() =>
      _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends ConsumerState<CategoryDetailScreen> {
  final Set<String> _selected = {};
  bool get _isSelecting => _selected.isNotEmpty;

  void _toggleSelect(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  void _clearSelection() => setState(() => _selected.clear());

  void _selectAll(List<Item> items) =>
      setState(() => _selected.addAll(items.map((i) => i.id)));

  Future<void> _deleteSelected(List<Item> items) async {
    final toDelete = items.where((i) => _selected.contains(i.id)).toList();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elimina oggetti'),
        content: Text(
            'Eliminare ${toDelete.length} oggetti? L\'azione non è reversibile.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    for (final item in toDelete) {
      await ref.read(itemsProvider.notifier).deleteItem(item.id);
    }
    _clearSelection();
  }

  Future<void> _moveSelected(
      List<Item> items, List<CategoryModel> categories) async {
    final toMove = items.where((i) => _selected.contains(i.id)).toList();
    String? targetId;

    await showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('Sposta in categoria',
                  style: Theme.of(ctx).textTheme.titleMedium),
            ),
            ...categories
                .where((c) => c.id != widget.categoryId)
                .map((cat) => ListTile(
                      leading: Icon(cat.icon, color: cat.color),
                      title: Text(cat.name),
                      onTap: () {
                        targetId = cat.id;
                        Navigator.pop(ctx);
                      },
                    )),
          ],
        ),
      ),
    );

    if (targetId == null || !mounted) return;
    for (final item in toMove) {
      await ref
          .read(itemsProvider.notifier)
          .updateItem(item.copyWith(categoryId: targetId));
    }
    _clearSelection();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final itemsAsync = ref.watch(_categoryItemsProvider(widget.categoryId));
    final cs = Theme.of(context).colorScheme;

    final category = categoriesAsync.valueOrNull?.firstWhere(
      (c) => c.id == widget.categoryId,
      orElse: () => CategoryModel(
        id: widget.categoryId,
        name: '',
        iconCodePoint: Icons.category.codePoint,
        colorValue: 0xFF546E7A,
        isDefault: false,
        createdAt: DateTime.now(),
      ),
    );

    final catColor = category?.color ?? cs.primary;

    return Scaffold(
      appBar: _isSelecting
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: _clearSelection,
              ),
              title: Text('${_selected.length} selezionati'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.select_all),
                  tooltip: 'Seleziona tutti',
                  onPressed: () => itemsAsync.whenData(_selectAll),
                ),
                IconButton(
                  icon: const Icon(Icons.drive_file_move_outline),
                  tooltip: 'Sposta',
                  onPressed: () => itemsAsync.whenData((items) =>
                      _moveSelected(
                          items, categoriesAsync.valueOrNull ?? [])),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: cs.error),
                  tooltip: 'Elimina',
                  onPressed: () => itemsAsync
                      .whenData((items) => _deleteSelected(items)),
                ),
              ],
            )
          : AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
              title: category != null
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(category.icon, color: catColor, size: 22),
                        const SizedBox(width: 8),
                        Text(category.name),
                      ],
                    )
                  : const Text('Categoria'),
              actions: [_CategorySortButton()],
            ),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Errore: $e')),
        data: (rawItems) {
          if (rawItems.isEmpty) {
            return _EmptyCategory(category: category);
          }
          final sort = ref.watch(sortOptionProvider);
          final items = List<Item>.from(rawItems);
          switch (sort) {
            case SortOption.nameAsc:
              items.sort((a, b) =>
                  a.name.toLowerCase().compareTo(b.name.toLowerCase()));
            case SortOption.nameDesc:
              items.sort((a, b) =>
                  b.name.toLowerCase().compareTo(a.name.toLowerCase()));
            case SortOption.dateOldest:
              items.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
            case SortOption.expiryDate:
              items.sort((a, b) {
                if (a.expiryDate == null && b.expiryDate == null) return 0;
                if (a.expiryDate == null) return 1;
                if (b.expiryDate == null) return -1;
                return a.expiryDate!.compareTo(b.expiryDate!);
              });
            case SortOption.maintenanceDue:
              items.sort((a, b) {
                if (a.isMaintenanceDue && !b.isMaintenanceDue) return -1;
                if (!a.isMaintenanceDue && b.isMaintenanceDue) return 1;
                return 0;
              });
            case SortOption.quantity:
              items.sort((a, b) => b.quantity.compareTo(a.quantity));
            default:
              break;
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 96),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final item = items[i];
              final isSelected = _selected.contains(item.id);
              return GestureDetector(
                onLongPress: () => _toggleSelect(item.id),
                child: Stack(
                  children: [
                    ItemCard(
                      item: item,
                      category: category,
                      onTap: _isSelecting
                          ? () => _toggleSelect(item.id)
                          : () => context.push('/item/${item.id}'),
                    ),
                    if (_isSelecting)
                      Positioned(
                        top: 8,
                        right: 24,
                        child: IgnorePointer(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color:
                                  isSelected ? cs.primary : cs.surface,
                              border: Border.all(
                                color: isSelected
                                    ? cs.primary
                                    : cs.outlineVariant,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: isSelected
                                ? Icon(Icons.check,
                                    size: 16, color: cs.onPrimary)
                                : null,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _CategorySortButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(sortOptionProvider);
    return IconButton(
      icon: const Icon(Icons.sort),
      tooltip: 'Ordina',
      onPressed: () => showModalBottomSheet(
        context: context,
        builder: (ctx) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Text('Ordina per',
                    style: Theme.of(ctx).textTheme.titleMedium),
              ),
              ...SortOption.values.map((opt) => ListTile(
                    leading: Icon(
                      opt == current
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: opt == current
                          ? Theme.of(ctx).colorScheme.primary
                          : null,
                    ),
                    title: Text(opt.label),
                    onTap: () {
                      ref.read(sortOptionProvider.notifier).state = opt;
                      Navigator.pop(ctx);
                    },
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCategory extends StatelessWidget {
  final CategoryModel? category;
  const _EmptyCategory({this.category});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final catColor = category?.color ?? cs.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: catColor.withAlpha(25),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                category?.icon ?? Icons.category_outlined,
                size: 36,
                color: catColor,
              ),
            ),
            const SizedBox(height: 20),
            Text('Nessun oggetto',
                style: tt.titleMedium?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text(
              'Usa il + per aggiungere il primo oggetto in questa categoria',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
