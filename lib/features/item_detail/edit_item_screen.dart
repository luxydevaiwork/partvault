import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/services/image_service.dart';
import '../../core/services/ocr_service.dart';
import '../../data/models/item.dart';
import '../../providers/categories_provider.dart';
import '../../providers/database_provider.dart';
import '../../providers/items_provider.dart';

class EditItemScreen extends ConsumerStatefulWidget {
  final String itemId;
  const EditItemScreen({super.key, required this.itemId});

  @override
  ConsumerState<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends ConsumerState<EditItemScreen> {
  final _nameController = TextEditingController();
  final _modelController = TextEditingController();
  final _measuresController = TextEditingController();
  final _notesController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();

  Item? _original;
  String? _selectedCategoryId;
  String? _imagePath;
  bool _imageChanged = false;
  bool _isSaving = false;
  bool _loaded = false;
  List<String> _ocrTokens = [];
  bool _isOcrRunning = false;
  int _quantity = 1;
  DateTime? _expiryDate;
  double? _purchasePrice;
  DateTime? _warrantyDate;

  @override
  void initState() {
    super.initState();
    _loadItem();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _modelController.dispose();
    _measuresController.dispose();
    _notesController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadItem() async {
    if (_loaded) return;
    _loaded = true;
    final item = await ref.read(itemRepositoryProvider).getById(widget.itemId);
    if (item == null || !mounted) return;
    _original = item;
    _nameController.text = item.name;
    _modelController.text = item.modelCode ?? '';
    _measuresController.text = item.measures ?? '';
    _notesController.text = item.notes ?? '';
    _locationController.text = item.location ?? '';
    _selectedCategoryId = item.categoryId;
    _imagePath = item.imagePath;
    _quantity = item.quantity;
    _expiryDate = item.expiryDate;
    _purchasePrice = item.purchasePrice;
    _warrantyDate = item.warrantyDate;
    if (item.purchasePrice != null) {
      _priceController.text = item.purchasePrice!.toStringAsFixed(2);
    }
    setState(() {});
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context);
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: source, imageQuality: 90);
    if (photo == null) return;
    final saved = await ImageService.saveImage(photo.path);
    if (saved != null && mounted) {
      setState(() {
        _imagePath = saved;
        _imageChanged = true;
        _ocrTokens = [];
      });
      _runOcr(saved);
    }
  }

  Future<void> _runOcr(String path) async {
    if (!mounted) return;
    setState(() => _isOcrRunning = true);
    final tokens = await OcrService.extractTokens(path);
    if (mounted) setState(() { _ocrTokens = tokens; _isOcrRunning = false; });
  }

  void _removeImage() => setState(() {
    _imagePath = null;
    _imageChanged = true;
    _ocrTokens = [];
  });

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Fotocamera'),
              onTap: () => _pickImage(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galleria'),
              onTap: () => _pickImage(ImageSource.gallery),
            ),
            if (_imagePath != null)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Rimuovi foto'),
                onTap: () {
                  Navigator.pop(context);
                  _removeImage();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_original == null) return;
    if (_nameController.text.trim().isEmpty) return;
    if (_selectedCategoryId == null) return;
    setState(() => _isSaving = true);
    if (_imageChanged &&
        _original!.imagePath != null &&
        _original!.imagePath != _imagePath) {
      ImageService.deleteImage(_original!.imagePath);
    }
    final updated = _original!.copyWith(
      name: _nameController.text.trim(),
      categoryId: _selectedCategoryId,
      modelCode: _modelController.text.trim().isEmpty
          ? null
          : _modelController.text.trim(),
      measures: _measuresController.text.trim().isEmpty
          ? null
          : _measuresController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      imagePath: _imagePath,
      quantity: _quantity,
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      expiryDate: _expiryDate,
      purchasePrice: _purchasePrice,
      warrantyDate: _warrantyDate,
    );
    try {
      await ref.read(itemsProvider.notifier).updateItem(updated);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifica'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          FilledButton(
            onPressed: (_isSaving ||
                    _nameController.text.trim().isEmpty ||
                    _selectedCategoryId == null)
                ? null
                : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Salva'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _original == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildImageSection(cs),
                if (_isOcrRunning) ...[
                  const SizedBox(height: 12),
                  const _OcrLoadingCard(),
                ],
                if (!_isOcrRunning && _ocrTokens.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _OcrSuggestionsCard(
                    tokens: _ocrTokens,
                    onSelect: (t) {
                      _modelController.text = t;
                      setState(() => _ocrTokens = []);
                    },
                    onDismiss: () => setState(() => _ocrTokens = []),
                  ),
                ],
                const SizedBox(height: 20),
                TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Nome *',
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                if (categories.isNotEmpty) ...[
                  Text(
                    'Categoria *',
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.map((cat) {
                      final selected = _selectedCategoryId == cat.id;
                      return FilterChip(
                        label: Text(cat.name),
                        selected: selected,
                        avatar: Icon(cat.icon,
                            size: 16,
                            color: selected
                                ? cs.onPrimaryContainer
                                : cat.color),
                        onSelected: (_) =>
                            setState(() => _selectedCategoryId = cat.id),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: _modelController,
                  decoration: const InputDecoration(
                    labelText: 'Codice / Modello',
                    prefixIcon: Icon(Icons.qr_code_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _measuresController,
                  decoration: const InputDecoration(
                    labelText: 'Misure',
                    prefixIcon: Icon(Icons.straighten_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Posizione',
                    prefixIcon: Icon(Icons.place_outlined),
                    hintText: 'es. Garage, Scaffale 2',
                  ),
                ),
                const SizedBox(height: 12),
                // Quantity stepper
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: cs.outlineVariant),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.layers_outlined, size: 18),
                      const SizedBox(width: 10),
                      const Text('Quantità'),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: _quantity > 1
                            ? () => setState(() => _quantity--)
                            : null,
                      ),
                      SizedBox(
                        width: 32,
                        child: Text(
                          '$_quantity',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => setState(() => _quantity++),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Expiry date
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _expiryDate ??
                          DateTime.now().add(const Duration(days: 365)),
                      firstDate: DateTime.now()
                          .subtract(const Duration(days: 1)),
                      lastDate: DateTime(2100),
                      helpText: 'Data di scadenza',
                    );
                    if (picked != null) {
                      setState(() => _expiryDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: cs.outlineVariant),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.event_outlined,
                            size: 18, color: cs.onSurfaceVariant),
                        const SizedBox(width: 10),
                        Text(
                          _expiryDate != null
                              ? 'Scadenza: ${_expiryDate!.day.toString().padLeft(2, '0')}/${_expiryDate!.month.toString().padLeft(2, '0')}/${_expiryDate!.year}'
                              : 'Data scadenza (opzionale)',
                          style: TextStyle(
                              color: _expiryDate != null
                                  ? null
                                  : cs.onSurfaceVariant),
                        ),
                        const Spacer(),
                        if (_expiryDate != null)
                          GestureDetector(
                            onTap: () =>
                                setState(() => _expiryDate = null),
                            child: Icon(Icons.clear,
                                size: 16,
                                color: cs.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Warranty date
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _warrantyDate ??
                          DateTime.now().add(const Duration(days: 365)),
                      firstDate: DateTime.now()
                          .subtract(const Duration(days: 1)),
                      lastDate: DateTime(2100),
                      helpText: 'Fine garanzia',
                    );
                    if (picked != null) {
                      setState(() => _warrantyDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: cs.outlineVariant),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.verified_outlined,
                            size: 18, color: cs.onSurfaceVariant),
                        const SizedBox(width: 10),
                        Text(
                          _warrantyDate != null
                              ? 'Garanzia: ${_warrantyDate!.day.toString().padLeft(2, '0')}/${_warrantyDate!.month.toString().padLeft(2, '0')}/${_warrantyDate!.year}'
                              : 'Fine garanzia (opzionale)',
                          style: TextStyle(
                              color: _warrantyDate != null
                                  ? null
                                  : cs.onSurfaceVariant),
                        ),
                        const Spacer(),
                        if (_warrantyDate != null)
                          GestureDetector(
                            onTap: () =>
                                setState(() => _warrantyDate = null),
                            child: Icon(Icons.clear,
                                size: 16,
                                color: cs.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _priceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Prezzo acquisto',
                    prefixIcon: Icon(Icons.euro_outlined),
                  ),
                  onChanged: (v) {
                    _purchasePrice =
                        double.tryParse(v.replaceAll(',', '.'));
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Note',
                    prefixIcon: Icon(Icons.notes_outlined),
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildImageSection(ColorScheme cs) {
    if (_imagePath != null) {
      final file = File(_imagePath!);
      if (file.existsSync()) {
        return GestureDetector(
          onTap: _showImageSourceDialog,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(file,
                height: 200, width: double.infinity, fit: BoxFit.cover),
          ),
        );
      }
    }
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: cs.outlineVariant.withAlpha(100), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined,
                color: cs.onSurfaceVariant, size: 32),
            const SizedBox(height: 8),
            Text(
              'Aggiungi foto',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _OcrLoadingCard extends StatelessWidget {
  const _OcrLoadingCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.secondaryContainer.withAlpha(80),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child:
                CircularProgressIndicator(strokeWidth: 2, color: cs.secondary),
          ),
          const SizedBox(width: 10),
          Text(
            'Lettura etichetta...',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: cs.onSecondaryContainer),
          ),
        ],
      ),
    );
  }
}

class _OcrSuggestionsCard extends StatelessWidget {
  final List<String> tokens;
  final ValueChanged<String> onSelect;
  final VoidCallback onDismiss;

  const _OcrSuggestionsCard({
    required this.tokens,
    required this.onSelect,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.secondaryContainer.withAlpha(80),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.secondary.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 14, color: cs.secondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Testo rilevato — tocca per usarlo come codice:',
                  style:
                      tt.labelSmall?.copyWith(color: cs.onSecondaryContainer),
                ),
              ),
              GestureDetector(
                onTap: onDismiss,
                child: Icon(Icons.close,
                    size: 16, color: cs.onSecondaryContainer),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: tokens
                .map((t) => GestureDetector(
                      onTap: () => onSelect(t),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: cs.secondaryContainer,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: cs.secondary.withAlpha(100)),
                        ),
                        child: Text(
                          t,
                          style: tt.labelSmall?.copyWith(
                            color: cs.onSecondaryContainer,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
