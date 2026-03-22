import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../data/models/item.dart';
import '../../providers/categories_provider.dart';
import '../../providers/items_provider.dart';
import '../barcode_scanner/barcode_scanner_screen.dart';

/// Bottom sheet showing a QR code for sharing an item.
class QrShareSheet extends ConsumerWidget {
  final Item item;
  const QrShareSheet({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final shareData = item.toShareString();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Condividi oggetto', style: tt.titleLarge),
          const SizedBox(height: 4),
          Text(
            item.name,
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(30),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: QrImageView(
                data: shareData,
                version: QrVersions.auto,
                size: 220,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.modelCode != null)
                  _InfoRow(label: 'Codice', value: item.modelCode!),
                if (item.measures != null)
                  _InfoRow(label: 'Misure', value: item.measures!),
                if (item.notes != null)
                  _InfoRow(label: 'Note', value: item.notes!),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Scansiona con PartVault per importare',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Shows the QR share bottom sheet.
void showQrShare(BuildContext context, Item item) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => QrShareSheet(item: item),
  );
}

/// Scans a QR code and imports an item from it.
/// Returns true if successfully imported.
Future<bool> importItemFromQr(
    BuildContext context, WidgetRef ref) async {
  final shareString = await scanBarcodeForShareString(context);
  if (shareString == null || !context.mounted) return false;

  final categories = ref.read(categoriesProvider).valueOrNull ?? [];
  if (categories.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nessuna categoria disponibile')),
      );
    }
    return false;
  }

  // Show category selection dialog
  String? selectedCategoryId;
  if (context.mounted) {
    selectedCategoryId = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Seleziona categoria'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: categories.length,
            itemBuilder: (_, i) {
              final cat = categories[i];
              return ListTile(
                leading: Icon(cat.icon, color: cat.color),
                title: Text(cat.name),
                onTap: () => Navigator.pop(ctx, cat.id),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla'),
          ),
        ],
      ),
    );
  }

  if (selectedCategoryId == null) return false;

  final item = Item.fromShareString(shareString,
      categoryId: selectedCategoryId);
  if (item == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('QR code non valido')),
      );
    }
    return false;
  }

  await ref.read(itemsProvider.notifier).addItem(item);
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item.name} importato!')),
    );
  }
  return true;
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          Expanded(
            child: Text(value,
                style: tt.bodySmall?.copyWith(
                    color: cs.onSurface, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
