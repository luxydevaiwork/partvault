import 'package:flutter/material.dart';
import '../../../data/models/category_model.dart';

class CategoryGridCard extends StatelessWidget {
  final CategoryModel category;
  final int itemCount;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const CategoryGridCard({
    super.key,
    required this.category,
    required this.itemCount,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final catColor = category.color;

    return Card(
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: catColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(category.icon, color: catColor, size: 24),
              ),
              const Spacer(),
              Text(
                category.name,
                style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '$itemCount ${itemCount == 1 ? 'oggetto' : 'oggetti'}',
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
