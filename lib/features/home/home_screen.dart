import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/category_model.dart';
import '../../data/models/item.dart';
import '../../providers/categories_provider.dart';
import '../../providers/items_provider.dart';
import '../../providers/search_provider.dart';
import '../../providers/sort_filter_provider.dart';
import '../barcode_scanner/barcode_scanner_screen.dart';
import '../qr_share/qr_share_sheet.dart';
import '../shop_mode/shop_mode_screen.dart';
import 'widgets/category_grid_card.dart';
import 'widgets/item_card.dart';

/// Provider listing items that have maintenance due.
final _maintenanceDueProvider = Provider<List<Item>>((ref) {
  final items = ref.watch(itemsProvider).valueOrNull ?? [];
  return items.where((i) => i.isMaintenanceDue).toList();
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = SearchController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        ref.read(searchQueryProvider.notifier).state = value;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final query = ref.watch(searchQueryProvider);
    final dueMaintenance = ref.watch(_maintenanceDueProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top bar: search + actions
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: SearchBar(
                      controller: _searchController,
                      hintText: 'Cerca modello, misura, oggetto...',
                      leading: const Icon(Icons.search),
                      trailing: [
                        if (query.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(searchQueryProvider.notifier).state = '';
                            },
                          ),
                        // Barcode scan shortcut
                        IconButton(
                          icon: const Icon(Icons.qr_code_scanner_outlined),
                          tooltip: 'Scansiona barcode',
                          onPressed: () async {
                            final item = await scanBarcodeForItem(context);
                            if (item != null && context.mounted) {
                              context.push('/item/${item.id}');
                            }
                          },
                        ),
                      ],
                      onChanged: _onSearchChanged,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Shop mode button
                  FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      minimumSize: Size.zero,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ShopModeScreen()),
                      );
                    },
                    child: const Icon(Icons.shopping_cart_outlined),
                  ),
                ],
              ),
            ),

            // Maintenance due banner
            if (dueMaintenance.isNotEmpty)
              _MaintenanceBanner(items: dueMaintenance),

            // Quick action row: QR import + sort
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Row(
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.qr_code_outlined, size: 16),
                    label: const Text('Importa QR'),
                    style: TextButton.styleFrom(
                      textStyle: const TextStyle(fontSize: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                    ),
                    onPressed: () => importItemFromQr(context, ref),
                  ),
                  const Spacer(),
                  if (query.isNotEmpty) _SortButton(),
                ],
              ),
            ),

            Expanded(
              child: query.isEmpty
                  ? const _CategoryGrid(key: ValueKey('grid'))
                  : const _SearchResults(key: ValueKey('search')),
            ),
          ],
        ),
      ),
    );
  }
}

class _SortButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(sortOptionProvider);
    return TextButton.icon(
      icon: const Icon(Icons.sort, size: 16),
      label: Text(current.label,
          style: const TextStyle(fontSize: 12)),
      style: TextButton.styleFrom(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      onPressed: () => _showSortSheet(context, ref, current),
    );
  }

  void _showSortSheet(
      BuildContext context, WidgetRef ref, SortOption current) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 4, vertical: 8),
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
    );
  }
}

class _MaintenanceBanner extends StatelessWidget {
  final List<Item> items;
  const _MaintenanceBanner({required this.items});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: cs.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_outlined,
                color: cs.onErrorContainer, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                items.length == 1
                    ? '"${items.first.name}" richiede manutenzione'
                    : '${items.length} oggetti richiedono manutenzione',
                style: tt.bodySmall?.copyWith(color: cs.onErrorContainer),
              ),
            ),
            if (items.length == 1)
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: cs.onErrorContainer,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 30),
                ),
                onPressed: () {
                  final ctx = context;
                  GoRouter.of(ctx).push('/item/${items.first.id}');
                },
                child: const Text('Vedi'),
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryGrid extends ConsumerWidget {
  const _CategoryGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final countsAsync = ref.watch(itemCountPerCategoryProvider);

    return categoriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Errore: $e')),
      data: (categories) {
        if (categories.isEmpty) {
          return const _EmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'Nessuna categoria',
            subtitle: 'Le categorie appariranno qui',
          );
        }
        final counts = countsAsync.valueOrNull ?? {};
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
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
            );
          },
        );
      },
    );
  }
}

class _SearchResults extends ConsumerWidget {
  const _SearchResults({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(searchResultsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return resultsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Errore: $e')),
      data: (rawItems) {
        if (rawItems.isEmpty) {
          return const _EmptyState(
            icon: Icons.search_off,
            title: 'Nessun risultato',
            subtitle: 'Prova con un termine diverso',
          );
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
            break; // dateNewest is already default from DB
        }
        final catMap = {
          for (final c in (categoriesAsync.valueOrNull ?? <CategoryModel>[]))
            c.id: c,
        };
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 96),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final item = items[i];
            return ItemCard(
              item: item,
              category: catMap[item.categoryId],
              onTap: () => context.push('/item/${item.id}'),
            );
          },
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: cs.onSurfaceVariant.withAlpha(100)),
            const SizedBox(height: 16),
            Text(title,
                style: tt.titleMedium?.copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(subtitle,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
