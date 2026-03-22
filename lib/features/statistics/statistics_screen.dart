import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/category_model.dart';
import '../../data/models/item.dart';
import '../../providers/categories_provider.dart';
import '../../providers/items_provider.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final items = ref.watch(itemsProvider).valueOrNull ?? [];
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    final catMap = {for (final c in categories) c.id: c};

    final totalItems = items.length;
    final totalUnits = items.fold(0, (sum, i) => sum + i.quantity);
    final totalValue = items.fold<double>(
        0, (sum, i) => sum + ((i.purchasePrice ?? 0) * i.quantity));
    final hasPrice = items.any((i) => i.purchasePrice != null);

    final maintenanceDue = items.where((i) => i.isMaintenanceDue).toList();

    final expiringSoon = items
        .where((i) =>
            i.expiryDate != null &&
            !i.isExpired &&
            (i.daysUntilExpiry ?? 999) <= 30)
        .toList()
      ..sort((a, b) => a.expiryDate!.compareTo(b.expiryDate!));

    final expired = items.where((i) => i.isExpired).toList();

    final countPerCat = <String, int>{};
    for (final item in items) {
      countPerCat[item.categoryId] = (countPerCat[item.categoryId] ?? 0) + 1;
    }
    final sortedCats = countPerCat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final highQty = items.where((i) => i.quantity > 1).toList()
      ..sort((a, b) => b.quantity.compareTo(a.quantity));

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(title: const Text('Statistiche')),
      body: totalItems == 0
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bar_chart_outlined,
                        size: 56,
                        color: cs.onSurfaceVariant.withAlpha(100)),
                    const SizedBox(height: 16),
                    Text('Nessun dato',
                        style: tt.titleMedium
                            ?.copyWith(color: cs.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Text('Aggiungi oggetti per vedere le statistiche',
                        style: tt.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                // Summary cards
                Row(
                  children: [
                    _StatCard(
                        label: 'Oggetti',
                        value: '$totalItems',
                        icon: Icons.inventory_2_outlined,
                        color: cs.primary),
                    const SizedBox(width: 12),
                    _StatCard(
                        label: 'Unità totali',
                        value: '$totalUnits',
                        icon: Icons.layers_outlined,
                        color: cs.secondary),
                  ],
                ),
                const SizedBox(height: 12),
                if (hasPrice) ...[
                  Row(
                    children: [
                      _StatCard(
                        label: 'Valore totale',
                        value: '€ ${totalValue.toStringAsFixed(0)}',
                        icon: Icons.euro_outlined,
                        color: cs.tertiary,
                        subtitle: 'inventario stimato',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    _StatCard(
                      label: 'Manutenzioni',
                      value: '${maintenanceDue.length}',
                      icon: Icons.warning_amber_outlined,
                      color: maintenanceDue.isEmpty ? cs.primary : cs.error,
                      subtitle: 'scadute',
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      label: 'In scadenza',
                      value: '${expiringSoon.length + expired.length}',
                      icon: Icons.event_busy_outlined,
                      color: expired.isNotEmpty
                          ? cs.error
                          : expiringSoon.isNotEmpty
                              ? Colors.orange
                              : cs.primary,
                      subtitle: '≤30gg o scaduti',
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Maintenance due
                if (maintenanceDue.isNotEmpty) ...[
                  _SectionTitle(
                      icon: Icons.schedule_outlined,
                      title: 'Manutenzione scaduta',
                      color: cs.error),
                  const SizedBox(height: 8),
                  ...maintenanceDue.map((item) => _ItemAlertTile(
                        item: item,
                        cat: catMap[item.categoryId],
                        subtitle:
                            'Prevista il ${_fmt(item.nextMaintenanceDate ?? item.createdAt)}',
                        onTap: () => context.push('/item/${item.id}'),
                      )),
                  const SizedBox(height: 16),
                ],

                // Expired / expiring
                if (expired.isNotEmpty || expiringSoon.isNotEmpty) ...[
                  _SectionTitle(
                      icon: Icons.event_busy_outlined,
                      title: 'Scadenza imminente',
                      color: Colors.orange),
                  const SizedBox(height: 8),
                  ...expired.map((item) => _ItemAlertTile(
                        item: item,
                        cat: catMap[item.categoryId],
                        subtitle: 'Scaduto il ${_fmt(item.expiryDate!)}',
                        subtitleColor: cs.error,
                        onTap: () => context.push('/item/${item.id}'),
                      )),
                  ...expiringSoon.map((item) => _ItemAlertTile(
                        item: item,
                        cat: catMap[item.categoryId],
                        subtitle:
                            'Scade il ${_fmt(item.expiryDate!)} (${item.daysUntilExpiry}gg)',
                        subtitleColor: Colors.orange,
                        onTap: () => context.push('/item/${item.id}'),
                      )),
                  const SizedBox(height: 16),
                ],

                // Category breakdown
                if (sortedCats.isNotEmpty) ...[
                  _SectionTitle(
                      icon: Icons.grid_view_outlined,
                      title: 'Oggetti per categoria',
                      color: cs.primary),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        for (int i = 0; i < sortedCats.length; i++) ...[
                          _CategoryStatRow(
                            cat: catMap[sortedCats[i].key],
                            count: sortedCats[i].value,
                            maxCount: sortedCats.first.value,
                            cs: cs,
                            tt: tt,
                          ),
                          if (i < sortedCats.length - 1)
                            Divider(
                                height: 1,
                                indent: 16,
                                endIndent: 16,
                                color: cs.outlineVariant.withAlpha(60)),
                        ],
                      ],
                    ),
                  ),
                ],

                // High quantity items
                if (highQty.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _SectionTitle(
                      icon: Icons.layers_outlined,
                      title: 'Con più unità',
                      color: cs.secondary),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        for (int i = 0;
                            i < highQty.length && i < 10;
                            i++) ...[
                          ListTile(
                            dense: true,
                            leading: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: cs.secondaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  '×${highQty[i].quantity}',
                                  style: tt.labelMedium?.copyWith(
                                      color: cs.onSecondaryContainer,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            title: Text(highQty[i].name,
                                style: tt.bodyMedium),
                            subtitle: catMap[highQty[i].categoryId] != null
                                ? Text(
                                    catMap[highQty[i].categoryId]!.name,
                                    style: tt.bodySmall?.copyWith(
                                        color: cs.onSurfaceVariant))
                                : null,
                            onTap: () =>
                                context.push('/item/${highQty[i].id}'),
                          ),
                          if (i < highQty.length - 1 && i < 9)
                            Divider(
                                height: 1,
                                indent: 16,
                                endIndent: 16,
                                color: cs.outlineVariant.withAlpha(60)),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(value,
                style: tt.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold, color: color)),
            Text(label,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            if (subtitle != null)
              Text(subtitle!,
                  style:
                      tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SectionTitle(
      {required this.icon, required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(title, style: tt.labelLarge?.copyWith(color: color)),
      ],
    );
  }
}

class _ItemAlertTile extends StatelessWidget {
  final Item item;
  final CategoryModel? cat;
  final String subtitle;
  final Color? subtitleColor;
  final VoidCallback onTap;

  const _ItemAlertTile({
    required this.item,
    required this.cat,
    required this.subtitle,
    required this.onTap,
    this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: (cat?.color ?? cs.primary).withAlpha(20),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(cat?.icon ?? Icons.inventory_2_outlined,
              color: cat?.color ?? cs.primary, size: 20),
        ),
        title: Text(item.name, style: tt.bodyMedium),
        subtitle: Text(
          subtitle,
          style: tt.bodySmall
              ?.copyWith(color: subtitleColor ?? cs.onSurfaceVariant),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _CategoryStatRow extends StatelessWidget {
  final CategoryModel? cat;
  final int count;
  final int maxCount;
  final ColorScheme cs;
  final TextTheme tt;

  const _CategoryStatRow({
    required this.cat,
    required this.count,
    required this.maxCount,
    required this.cs,
    required this.tt,
  });

  @override
  Widget build(BuildContext context) {
    final color = cat?.color ?? cs.primary;
    final fraction = maxCount > 0 ? count / maxCount : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(cat?.icon ?? Icons.category_outlined,
                  size: 14, color: color),
              const SizedBox(width: 6),
              Expanded(
                  child: Text(cat?.name ?? 'Categoria',
                      style: tt.bodyMedium)),
              Text('$count',
                  style: tt.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              backgroundColor: color.withAlpha(20),
              color: color,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
