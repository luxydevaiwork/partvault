import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/category_model.dart';
import '../../providers/categories_provider.dart';
import '../../providers/items_provider.dart';
import '../home/widgets/category_grid_card.dart';
import 'add_category_sheet.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final categoriesAsync = ref.watch(categoriesProvider);
    final countsAsync = ref.watch(itemCountPerCategoryProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Categorie'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Nuova categoria',
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => const AddCategorySheet(),
            ),
          ),
        ],
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Errore: $e')),
        data: (categories) {
          if (categories.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.grid_view_outlined,
                        size: 56,
                        color: cs.onSurfaceVariant.withAlpha(100)),
                    const SizedBox(height: 16),
                    Text('Nessuna categoria',
                        style: tt.titleMedium
                            ?.copyWith(color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
            );
          }
          final counts = countsAsync.valueOrNull ?? {};
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: categories.length,
            itemBuilder: (context, i) {
              final cat = categories[i];
              return CategoryGridCard(
                category: cat,
                itemCount: counts[cat.id] ?? 0,
                onTap: () => context.push('/categories/${cat.id}'),
                onLongPress: () =>
                    _showCategoryOptions(context, ref, cat,
                        counts[cat.id] ?? 0),
              );
            },
          );
        },
      ),
    );
  }

  void _showCategoryOptions(BuildContext context, WidgetRef ref,
      CategoryModel cat, int itemCount) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(cat.icon, color: cat.color),
              title: Text(cat.name,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('$itemCount oggetti'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Modifica categoria'),
              onTap: () {
                Navigator.pop(ctx);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => AddCategorySheet(editCategory: cat),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Elimina categoria',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDeleteCategory(context, ref, cat, itemCount);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteCategory(BuildContext context, WidgetRef ref,
      CategoryModel cat, int itemCount) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elimina categoria'),
        content: Text(itemCount > 0
            ? 'Eliminare "${cat.name}"? I $itemCount oggetti perderanno la categoria.'
            : 'Eliminare "${cat.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(categoriesProvider.notifier).deleteCategory(cat.id);
            },
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
  }
}
