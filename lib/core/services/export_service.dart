import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/models/category_model.dart';
import '../../data/models/item.dart';
import '../../providers/categories_provider.dart';
import '../../providers/items_provider.dart';

abstract final class ExportService {
  /// Export all data as a JSON file and share it.
  static Future<void> exportJson(BuildContext context, WidgetRef ref) async {
    try {
      final items = ref.read(itemsProvider).valueOrNull ?? [];
      final categories = ref.read(categoriesProvider).valueOrNull ?? [];

      final data = {
        'version': 2,
        'exported_at': DateTime.now().toIso8601String(),
        'categories': categories.map((c) => c.toMap()).toList(),
        'items': items.map((i) => i.toMap()).toList(),
      };

      final json = const JsonEncoder.withIndent('  ').convert(data);
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/partvault_backup.json');
      await file.writeAsString(json);

      await Share.shareXFiles([XFile(file.path)], subject: 'PartVault Backup');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore esportazione: $e')),
        );
      }
    }
  }

  /// Export items as CSV and share it.
  static Future<void> exportCsv(BuildContext context, WidgetRef ref) async {
    try {
      final items = ref.read(itemsProvider).valueOrNull ?? [];
      final categories = ref.read(categoriesProvider).valueOrNull ?? [];
      final catMap = {for (final c in categories) c.id: c.name};

      final buffer = StringBuffer();
      buffer.writeln(
          'Nome,Categoria,Codice,Misure,Quantità,Posizione,Scadenza,Note');

      for (final item in items) {
        buffer.writeln([
          _csvField(item.name),
          _csvField(catMap[item.categoryId] ?? ''),
          _csvField(item.modelCode ?? ''),
          _csvField(item.measures ?? ''),
          item.quantity,
          _csvField(item.location ?? ''),
          item.expiryDate != null ? _fmtDate(item.expiryDate!) : '',
          _csvField(item.notes ?? ''),
        ].join(','));
      }

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/partvault_export.csv');
      await file.writeAsString(buffer.toString());

      await Share.shareXFiles([XFile(file.path)],
          subject: 'PartVault Export CSV');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore esportazione CSV: $e')),
        );
      }
    }
  }

  /// Pick a JSON backup file and import it.
  static Future<void> importJson(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      final version = data['version'] as int? ?? 1;
      final itemsData = (data['items'] as List<dynamic>? ?? []);
      final categoriesData = (data['categories'] as List<dynamic>? ?? []);

      // Import categories first
      int catImported = 0;
      for (final catMap in categoriesData) {
        try {
          final cat = CategoryModel.fromMap(catMap as Map<String, dynamic>);
          await ref.read(categoriesProvider.notifier).addCategory(cat);
          catImported++;
        } catch (_) {}
      }

      // Import items
      int itemImported = 0;
      for (final itemMap in itemsData) {
        try {
          final map = Map<String, dynamic>.from(itemMap as Map);
          // Handle v1 backups that don't have new fields
          map['quantity'] ??= 1;
          if (version < 2) {
            // v1 backup: no quantity/location/expiry_date
            map.remove('expiry_date');
            map.remove('location');
          }
          final item = Item.fromMap(map);
          await ref.read(itemsProvider.notifier).addItem(item);
          itemImported++;
        } catch (_) {}
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Importati $itemImported oggetti e $catImported categorie'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore importazione: $e')),
        );
      }
    }
  }

  static String _csvField(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
