import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/image_service.dart';
import '../../data/models/item.dart';
import '../../providers/items_provider.dart';

/// Modalità Negozio — high contrast, large text, one-hand optimized.
class ShopModeScreen extends ConsumerStatefulWidget {
  const ShopModeScreen({super.key});

  @override
  ConsumerState<ShopModeScreen> createState() => _ShopModeScreenState();
}

class _ShopModeScreenState extends ConsumerState<ShopModeScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _searchController.dispose();
    super.dispose();
  }

  List<Item> _filter(List<Item> items) {
    if (_query.isEmpty) return items;
    final q = _query.toLowerCase();
    return items.where((i) {
      return i.name.toLowerCase().contains(q) ||
          (i.modelCode?.toLowerCase().contains(q) ?? false) ||
          (i.measures?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  Future<void> _deleteItem(Item item) async {
    ImageService.deleteImage(item.imagePath);
    await ref.read(itemsProvider.notifier).deleteItem(item.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${item.name}" eliminato'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _confirmDelete(BuildContext context, Item item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1C),
        title: const Text('Elimina oggetto',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Eliminare "${item.name}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('Annulla', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteItem(item);
            },
            child: const Text('Elimina',
                style: TextStyle(color: Color(0xFFFF5252))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(itemsProvider).valueOrNull ?? [];
    final filtered = _filter(items);

    return Theme(
      data: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E5FF),
          surface: Color(0xFF0A0A0A),
          onSurface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
      ),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    const Icon(Icons.shopping_cart_outlined,
                        color: Color(0xFF00E5FF), size: 28),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Modalità Negozio',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  decoration: InputDecoration(
                    hintText: 'Cerca...',
                    hintStyle: const TextStyle(
                        color: Colors.white38, fontSize: 18),
                    prefixIcon:
                        const Icon(Icons.search, color: Colors.white54),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear,
                                color: Colors.white54),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFF1A1A1A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              // Item count + hint
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      '${filtered.length} oggetti',
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 13),
                    ),
                    const Spacer(),
                    const Text(
                      'Tieni premuto per eliminare',
                      style: TextStyle(color: Colors.white24, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // List
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Text(
                          'Nessun oggetto trovato',
                          style: TextStyle(
                              color: Colors.white38, fontSize: 18),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          return _ShopItemCard(
                            item: item,
                            onDelete: () => _confirmDelete(context, item),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShopItemCard extends StatelessWidget {
  final Item item;
  final VoidCallback onDelete;

  const _ShopItemCard({required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFB71C1C),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      confirmDismiss: (_) async {
        bool confirmed = false;
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1C1C1C),
            title: const Text('Elimina oggetto',
                style: TextStyle(color: Colors.white)),
            content: Text(
              'Eliminare "${item.name}"?',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annulla',
                    style: TextStyle(color: Colors.white54)),
              ),
              TextButton(
                onPressed: () {
                  confirmed = true;
                  Navigator.pop(ctx);
                },
                child: const Text('Elimina',
                    style: TextStyle(color: Color(0xFFFF5252))),
              ),
            ],
          ),
        );
        return confirmed;
      },
      onDismissed: (_) => onDelete(),
      child: Card(
        color: const Color(0xFF1C1C1C),
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showDetail(context),
          onLongPress: onDelete,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (item.imagePath != null)
                  _buildThumbnail()
                else
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.inventory_2_outlined,
                        color: Colors.white38, size: 28),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (item.modelCode != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.modelCode!,
                          style: const TextStyle(
                            color: Color(0xFF00E5FF),
                            fontSize: 16,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                      if (item.measures != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.measures!,
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 15),
                        ),
                      ],
                    ],
                  ),
                ),
                // Actions column
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (item.modelCode != null)
                      IconButton(
                        icon: const Icon(Icons.copy_outlined,
                            color: Colors.white38),
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: item.modelCode!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Codice copiato!'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Color(0xFFFF5252), size: 20),
                      onPressed: onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.file(
        File(item.imagePath!),
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 56,
          height: 56,
          color: const Color(0xFF2A2A2A),
          child: const Icon(Icons.broken_image_outlined,
              color: Colors.white38),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ShopItemDetail(item: item),
    );
  }
}

class _ShopItemDetail extends StatelessWidget {
  final Item item;
  const _ShopItemDetail({required this.item});

  void _copy(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copiato: $text'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (item.imagePath != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(item.imagePath!),
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            item.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (item.modelCode != null)
            _DetailRow(
              label: 'Codice',
              value: item.modelCode!,
              onCopy: () => _copy(context, item.modelCode!),
              valueStyle: const TextStyle(
                color: Color(0xFF00E5FF),
                fontSize: 22,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
              ),
            ),
          if (item.measures != null)
            _DetailRow(
              label: 'Misure',
              value: item.measures!,
              onCopy: () => _copy(context, item.measures!),
              valueStyle: const TextStyle(
                color: Colors.white,
                fontSize: 22,
              ),
            ),
          if (item.notes != null) ...[
            const SizedBox(height: 8),
            const Text('Note',
                style: TextStyle(color: Colors.white38, fontSize: 13)),
            const SizedBox(height: 4),
            Text(item.notes!,
                style:
                    const TextStyle(color: Colors.white70, fontSize: 16)),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onCopy;
  final TextStyle? valueStyle;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.onCopy,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 13)),
                const SizedBox(height: 2),
                Text(value, style: valueStyle),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_outlined, color: Colors.white38),
            onPressed: onCopy,
          ),
        ],
      ),
    );
  }
}
