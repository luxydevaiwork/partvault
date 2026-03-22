import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/image_service.dart';
import '../../core/services/nfc_service.dart';
import '../../core/services/notification_service.dart';
import '../../data/models/category_model.dart';
import '../../data/models/item.dart';
import '../../providers/categories_provider.dart';
import '../../providers/database_provider.dart';
import '../../providers/items_provider.dart';
import '../qr_share/qr_share_sheet.dart';

final _itemDetailProvider =
    FutureProvider.family<Item?, String>((ref, id) async {
  return ref.read(itemRepositoryProvider).getById(id);
});

class ItemDetailScreen extends ConsumerWidget {
  final String itemId;
  const ItemDetailScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = ref.watch(_itemDetailProvider(itemId));
    final categoriesAsync = ref.watch(categoriesProvider);

    return itemAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Errore: $e')),
      ),
      data: (item) {
        if (item == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Oggetto non trovato')),
          );
        }
        final catMap = {
          for (final c in (categoriesAsync.valueOrNull ?? <CategoryModel>[]))
            c.id: c,
        };
        final category = catMap[item.categoryId];
        return _ItemDetailView(item: item, category: category);
      },
    );
  }
}

class _ItemDetailView extends ConsumerStatefulWidget {
  final Item item;
  final CategoryModel? category;

  const _ItemDetailView({required this.item, required this.category});

  @override
  ConsumerState<_ItemDetailView> createState() => _ItemDetailViewState();
}

class _ItemDetailViewState extends ConsumerState<_ItemDetailView> {
  bool _nfcWriting = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final item = widget.item;
    final category = widget.category;
    final catColor = category?.color ?? cs.primary;

    return Scaffold(
      backgroundColor: cs.surface,
      body: CustomScrollView(
        slivers: [
          // App Bar with hero image
          SliverAppBar(
            expandedHeight: item.imagePath != null ? 260 : 0,
            pinned: true,
            backgroundColor: cs.surface,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.qr_code_outlined),
                tooltip: 'Condividi QR',
                onPressed: () => showQrShare(context, item),
              ),
              IconButton(
                icon: const Icon(Icons.copy_all_outlined),
                tooltip: 'Duplica',
                onPressed: () => _duplicateItem(context),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => context.push('/item/${item.id}/edit'),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _confirmDelete(context),
              ),
            ],
            flexibleSpace: item.imagePath != null
                ? FlexibleSpaceBar(
                    background: Hero(
                      tag: 'item_image_${item.id}',
                      child: _buildImage(),
                    ),
                  )
                : null,
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Category chip
                if (category != null)
                  Wrap(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: catColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(category.icon, color: catColor, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              category.name,
                              style: tt.labelMedium?.copyWith(
                                  color: catColor,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),

                // Title + quantity badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                        child: Text(item.name, style: tt.headlineMedium)),
                    if (item.quantity > 1) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: cs.secondaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '×${item.quantity}',
                          style: tt.labelLarge?.copyWith(
                              color: cs.onSecondaryContainer,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 20),

                // Model code
                if (item.modelCode != null &&
                    item.modelCode!.isNotEmpty) ...[
                  _SectionCard(
                    icon: Icons.qr_code_outlined,
                    label: 'Codice / Modello',
                    content: item.modelCode!,
                    onCopy: () => _copy(item.modelCode!),
                    isMonospace: true,
                  ),
                  const SizedBox(height: 12),
                ],

                // Measures
                if (item.measures != null && item.measures!.isNotEmpty) ...[
                  _SectionCard(
                    icon: Icons.straighten_outlined,
                    label: 'Misure',
                    content: item.measures!,
                    onCopy: () => _copy(item.measures!),
                  ),
                  const SizedBox(height: 12),
                ],

                // Location
                if (item.location != null && item.location!.isNotEmpty) ...[
                  _SectionCard(
                    icon: Icons.place_outlined,
                    label: 'Posizione',
                    content: item.location!,
                  ),
                  const SizedBox(height: 12),
                ],

                // Expiry date
                if (item.expiryDate != null) ...[
                  _ExpiryCard(item: item),
                  const SizedBox(height: 12),
                ],

                // Warranty
                if (item.warrantyDate != null) ...[
                  _WarrantyCard(item: item),
                  const SizedBox(height: 12),
                ],

                // Purchase price
                if (item.purchasePrice != null) ...[
                  _SectionCard(
                    icon: Icons.euro_outlined,
                    label: 'Prezzo di acquisto',
                    content: '€ ${item.purchasePrice!.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 12),
                ],

                // Notes
                if (item.notes != null && item.notes!.isNotEmpty) ...[
                  _SectionCard(
                    icon: Icons.notes_outlined,
                    label: 'Note',
                    content: item.notes!,
                  ),
                  const SizedBox(height: 12),
                ],

                // Maintenance section
                if (item.maintenanceIntervalDays != null) ...[
                  _MaintenanceCard(item: item, onMarkDone: _markMaintenanceDone),
                  const SizedBox(height: 12),
                ] else ...[
                  OutlinedButton.icon(
                    icon: const Icon(Icons.schedule_outlined),
                    label: const Text('Aggiungi promemoria manutenzione'),
                    onPressed: () => _showMaintenanceDialog(),
                  ),
                  const SizedBox(height: 12),
                ],

                // NFC actions
                _NfcCard(
                  item: item,
                  isWriting: _nfcWriting,
                  onWrite: _writeNfc,
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (widget.item.imagePath == null) return const SizedBox.shrink();
    final file = File(widget.item.imagePath!);
    if (!file.existsSync()) return const SizedBox.shrink();
    return Image.file(file, fit: BoxFit.cover, width: double.infinity);
  }

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copiato negli appunti')),
    );
  }

  Future<void> _duplicateItem(BuildContext context) async {
    final copy = Item.create(
      name: '${widget.item.name} (copia)',
      categoryId: widget.item.categoryId,
      modelCode: widget.item.modelCode,
      measures: widget.item.measures,
      notes: widget.item.notes,
      quantity: widget.item.quantity,
      location: widget.item.location,
      expiryDate: widget.item.expiryDate,
    );
    await ref.read(itemsProvider.notifier).addItem(copy);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${copy.name}" creato')),
      );
      context.push('/item/${copy.id}');
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elimina oggetto'),
        content: Text(
            'Vuoi eliminare "${widget.item.name}"? L\'azione non è reversibile.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              ImageService.deleteImage(widget.item.imagePath);
              await ref
                  .read(itemsProvider.notifier)
                  .deleteItem(widget.item.id);
              if (context.mounted) context.pop();
            },
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
  }

  Future<void> _markMaintenanceDone() async {
    final updated = widget.item.copyWith(lastMaintainedAt: DateTime.now());
    await ref.read(itemsProvider.notifier).updateItem(updated);
    // Refresh detail
    ref.invalidate(_itemDetailProvider(widget.item.id));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Manutenzione registrata!')),
      );
    }
  }

  Future<void> _showMaintenanceDialog() async {
    int? days;
    await showDialog(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Promemoria manutenzione'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Intervallo in giorni',
              hintText: 'es. 30, 90, 365',
              suffixText: 'giorni',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () {
                days = int.tryParse(controller.text.trim());
                Navigator.pop(ctx);
              },
              child: const Text('Salva'),
            ),
          ],
        );
      },
    );
    if (days == null || days! <= 0) return;
    final updated = widget.item.copyWith(maintenanceIntervalDays: days);
    await ref.read(itemsProvider.notifier).updateItem(updated);
    await NotificationService.scheduleMaintenanceReminder(updated);
    ref.invalidate(_itemDetailProvider(widget.item.id));
  }

  Future<void> _writeNfc() async {
    final available = await NfcService.isAvailable();
    if (!available) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('NFC non disponibile su questo dispositivo')),
        );
      }
      return;
    }

    if (!mounted) return;
    setState(() => _nfcWriting = true);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Avvicina il tag NFC...'),
          duration: Duration(seconds: 10),
        ),
      );
    }

    NfcService.writeTag(
      payload: widget.item.toShareString(),
      onSuccess: () {
        if (mounted) {
          setState(() => _nfcWriting = false);
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tag NFC scritto con successo!')),
          );
        }
      },
      onError: (e) {
        if (mounted) {
          setState(() => _nfcWriting = false);
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Errore NFC: $e')),
          );
        }
      },
    );
  }
}

class _MaintenanceCard extends StatelessWidget {
  final Item item;
  final VoidCallback onMarkDone;

  const _MaintenanceCard({required this.item, required this.onMarkDone});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDue = item.isMaintenanceDue;
    final nextDate = item.nextMaintenanceDate;
    final color = isDue ? cs.error : cs.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isDue ? Icons.warning_amber_outlined : Icons.schedule_outlined,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 6),
              Text(
                'Manutenzione',
                style: tt.labelSmall?.copyWith(color: color),
              ),
              const Spacer(),
              if (isDue)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: cs.error,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'SCADUTA',
                    style: tt.labelSmall
                        ?.copyWith(color: cs.onError, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Ogni ${item.maintenanceIntervalDays} giorni',
            style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          if (nextDate != null) ...[
            const SizedBox(height: 2),
            Text(
              isDue
                  ? 'Prevista il ${_fmt(nextDate)} — in ritardo!'
                  : 'Prossima: ${_fmt(nextDate)}',
              style: tt.bodySmall?.copyWith(color: color),
            ),
          ],
          if (item.lastMaintainedAt != null) ...[
            const SizedBox(height: 2),
            Text(
              'Ultima: ${_fmt(item.lastMaintainedAt!)}',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Segna come eseguita'),
              style: OutlinedButton.styleFrom(foregroundColor: color),
              onPressed: onMarkDone,
            ),
          ),
        ],
      ),
    );
  }

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _NfcCard extends StatelessWidget {
  final Item item;
  final bool isWriting;
  final VoidCallback onWrite;

  const _NfcCard({
    required this.item,
    required this.isWriting,
    required this.onWrite,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.nfc_outlined, size: 16, color: cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                'Tag NFC',
                style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Scrivi su tag NFC',
            style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            'Avvicina un tag NFC per salvare i dati dell\'oggetto',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: isWriting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.nfc_outlined),
              label: Text(isWriting ? 'In attesa del tag...' : 'Scrivi su NFC'),
              onPressed: isWriting ? null : onWrite,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String content;
  final VoidCallback? onCopy;
  final bool isMonospace;

  const _SectionCard({
    required this.icon,
    required this.label,
    required this.content,
    this.onCopy,
    this.isMonospace = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                label,
                style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              const Spacer(),
              if (onCopy != null)
                GestureDetector(
                  onTap: onCopy,
                  child: Icon(Icons.copy_outlined,
                      size: 18, color: cs.onSurfaceVariant),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: isMonospace
                ? tt.bodyLarge?.copyWith(
                    fontFamily: 'monospace', letterSpacing: 0.5)
                : tt.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _ExpiryCard extends StatelessWidget {
  final Item item;
  const _ExpiryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final expired = item.isExpired;
    final days = item.daysUntilExpiry;
    final color = expired
        ? cs.error
        : (days != null && days <= 30)
            ? Colors.orange
            : cs.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        children: [
          Icon(Icons.event_outlined, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Scadenza',
                    style:
                        tt.labelSmall?.copyWith(color: color)),
                const SizedBox(height: 2),
                Text(
                  '${item.expiryDate!.day.toString().padLeft(2, '0')}/${item.expiryDate!.month.toString().padLeft(2, '0')}/${item.expiryDate!.year}',
                  style: tt.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              expired
                  ? 'SCADUTO'
                  : days != null
                      ? '${days}gg'
                      : '',
              style: tt.labelSmall?.copyWith(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _WarrantyCard extends StatelessWidget {
  final Item item;
  const _WarrantyCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final expired = item.isWarrantyExpired;
    final days = item.daysUntilWarrantyExpiry;
    final color = expired
        ? cs.error
        : (days != null && days <= 30)
            ? Colors.orange
            : Colors.green.shade700;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_outlined, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Garanzia',
                    style: tt.labelSmall?.copyWith(color: color)),
                const SizedBox(height: 2),
                Text(
                  '${item.warrantyDate!.day.toString().padLeft(2, '0')}/${item.warrantyDate!.month.toString().padLeft(2, '0')}/${item.warrantyDate!.year}',
                  style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              expired
                  ? 'SCADUTA'
                  : days != null
                      ? '${days}gg'
                      : '',
              style: tt.labelSmall?.copyWith(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
