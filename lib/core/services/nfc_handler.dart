import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/item.dart';
import '../../providers/categories_provider.dart';
import '../../providers/items_provider.dart';

const _channel = MethodChannel('com.urban.partvault/nfc');

/// Call this from a widget's [didChangeAppLifecycleState] or on app start
/// to handle any NFC tag tap that launched the app.
Future<void> checkPendingNfcPayload(
    BuildContext context, WidgetRef ref) async {
  try {
    final payload =
        await _channel.invokeMethod<String>('getPendingNfcPayload');
    if (payload == null || !payload.startsWith('PV1|')) return;
    if (!context.mounted) return;
    await _importFromShareString(context, ref, payload);
  } catch (_) {
    // NFC not available or no pending payload
  }
}

Future<void> _importFromShareString(
    BuildContext context, WidgetRef ref, String shareString) async {
  final categories = ref.read(categoriesProvider).valueOrNull ?? [];
  if (categories.isEmpty) return;

  String? selectedCategoryId;
  if (context.mounted) {
    selectedCategoryId = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Oggetto rilevato via NFC'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Seleziona una categoria per importarlo:'),
            const SizedBox(height: 12),
            ...categories.map((cat) => ListTile(
                  leading: Icon(cat.icon, color: cat.color),
                  title: Text(cat.name),
                  dense: true,
                  onTap: () => Navigator.pop(ctx, cat.id),
                )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Ignora'),
          ),
        ],
      ),
    );
  }

  if (selectedCategoryId == null) return;
  final item =
      Item.fromShareString(shareString, categoryId: selectedCategoryId);
  if (item == null) return;

  await ref.read(itemsProvider.notifier).addItem(item);
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item.name} importato via NFC!')),
    );
  }
}
