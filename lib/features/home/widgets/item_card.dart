import 'dart:io';
import 'package:flutter/material.dart';

import '../../../data/models/category_model.dart';
import '../../../data/models/item.dart';

class ItemCard extends StatelessWidget {
  final Item item;
  final CategoryModel? category;
  final VoidCallback onTap;

  const ItemCard({
    super.key,
    required this.item,
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final catColor = category?.color ?? cs.primary;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Hero(
                tag: 'item_image_${item.id}',
                child: _buildThumbnail(cs, catColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.modelCode != null && item.modelCode!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.modelCode!,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontFamily: 'monospace',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (item.measures != null && item.measures!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.measures!,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (category != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: catColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    category!.name,
                    style: tt.labelSmall?.copyWith(
                      color: catColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(ColorScheme cs, Color catColor) {
    if (item.imagePath != null) {
      final file = File(item.imagePath!);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            file,
            width: 52,
            height: 52,
            fit: BoxFit.cover,
          ),
        );
      }
    }
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: catColor.withAlpha(25),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        category?.icon ?? Icons.inventory_2_outlined,
        color: catColor,
        size: 26,
      ),
    );
  }
}
