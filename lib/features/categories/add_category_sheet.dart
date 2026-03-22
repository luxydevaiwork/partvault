import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/category_model.dart';
import '../../providers/categories_provider.dart';

const _kAvailableIcons = <Map<String, dynamic>>[
  {'icon': Icons.kitchen, 'label': 'Cucina'},
  {'icon': Icons.bathtub, 'label': 'Bagno'},
  {'icon': Icons.weekend, 'label': 'Salotto'},
  {'icon': Icons.bed, 'label': 'Camera'},
  {'icon': Icons.directions_car, 'label': 'Auto'},
  {'icon': Icons.handyman, 'label': 'Officina'},
  {'icon': Icons.computer, 'label': 'Ufficio'},
  {'icon': Icons.yard, 'label': 'Esterno'},
  {'icon': Icons.category, 'label': 'Altro'},
  {'icon': Icons.local_laundry_service, 'label': 'Lavanderia'},
  {'icon': Icons.child_care, 'label': 'Bambini'},
  {'icon': Icons.electrical_services, 'label': 'Elettrica'},
  {'icon': Icons.plumbing, 'label': 'Idraulica'},
  {'icon': Icons.fitness_center, 'label': 'Sport'},
  {'icon': Icons.pets, 'label': 'Animali'},
];

const _kAvailableColors = <Color>[
  Color(0xFFFF6B35),
  Color(0xFF2196F3),
  Color(0xFF9C27B0),
  Color(0xFF5C6BC0),
  Color(0xFFE53935),
  Color(0xFF616161),
  Color(0xFF00897B),
  Color(0xFF43A047),
  Color(0xFF546E7A),
  Color(0xFFF57C00),
  Color(0xFF00ACC1),
  Color(0xFFAD1457),
];

class AddCategorySheet extends ConsumerStatefulWidget {
  final CategoryModel? editCategory;
  const AddCategorySheet({super.key, this.editCategory});

  @override
  ConsumerState<AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends ConsumerState<AddCategorySheet> {
  final _nameController = TextEditingController();
  IconData _selectedIcon = Icons.category;
  Color _selectedColor = const Color(0xFF546E7A);
  bool _isSaving = false;

  bool get _isEditing => widget.editCategory != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final cat = widget.editCategory!;
      _nameController.text = cat.name;
      _selectedIcon = cat.icon;
      _selectedColor = cat.color;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _isSaving = true);

    if (_isEditing) {
      final updated = widget.editCategory!.copyWith(
        name: _nameController.text.trim(),
        iconCodePoint: _selectedIcon.codePoint,
        colorValue: _selectedColor.toARGB32(),
      );
      await ref.read(categoriesProvider.notifier).updateCategory(updated);
    } else {
      final category = CategoryModel.create(
        name: _nameController.text.trim(),
        iconCodePoint: _selectedIcon.codePoint,
        colorValue: _selectedColor.toARGB32(),
      );
      await ref.read(categoriesProvider.notifier).addCategory(category);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Row(
                children: [
                  Text(_isEditing ? 'Modifica categoria' : 'Nuova categoria',
                      style: tt.titleLarge),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Nome categoria',
                  prefixIcon: Icon(
                    _selectedIcon,
                    color: _selectedColor,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Icona', style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 52,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: _kAvailableIcons.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final iconData = _kAvailableIcons[i]['icon'] as IconData;
                  final selected = _selectedIcon == iconData;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = iconData),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: selected
                            ? _selectedColor.withAlpha(40)
                            : cs.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                        border: selected
                            ? Border.all(color: _selectedColor, width: 2)
                            : null,
                      ),
                      child: Icon(iconData,
                          color: selected ? _selectedColor : cs.onSurfaceVariant,
                          size: 22),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Colore', style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: _kAvailableColors.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final color = _kAvailableColors[i];
                  final selected = _selectedColor == color;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: selected
                            ? Border.all(
                                color: cs.onSurface,
                                width: 2.5,
                              )
                            : null,
                      ),
                      child: selected
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 18)
                          : null,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              child: FilledButton.icon(
                onPressed: (_nameController.text.trim().isEmpty || _isSaving)
                    ? null
                    : _save,
                icon: const Icon(Icons.check),
                label: Text(_isEditing ? 'Salva modifiche' : 'Crea categoria'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
