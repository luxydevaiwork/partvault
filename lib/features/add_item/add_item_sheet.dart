import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/services/image_service.dart';
import '../../core/services/ocr_service.dart';
import '../../data/models/item.dart';
import '../../providers/categories_provider.dart';
import '../../providers/items_provider.dart';
import '../barcode_scanner/barcode_scanner_screen.dart';

class AddItemSheet extends ConsumerStatefulWidget {
  final String? preselectedCategoryId;

  const AddItemSheet({super.key, this.preselectedCategoryId});

  @override
  ConsumerState<AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends ConsumerState<AddItemSheet> {
  final _nameFocus = FocusNode();
  final _nameController = TextEditingController();
  final _modelController = TextEditingController();
  final _measuresController = TextEditingController();
  final _notesController = TextEditingController();
  final _locationController = TextEditingController();

  String? _selectedCategoryId;
  String? _imagePath;
  bool _isExpanded = true;
  bool _isSaving = false;
  List<String> _ocrTokens = [];
  bool _isOcrRunning = false;
  int _quantity = 1;
  DateTime? _expiryDate;
  double? _purchasePrice;
  DateTime? _warrantyDate;
  final _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.preselectedCategoryId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nameFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _nameFocus.dispose();
    _nameController.dispose();
    _modelController.dispose();
    _measuresController.dispose();
    _notesController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _nameController.text.trim().isNotEmpty &&
      _selectedCategoryId != null &&
      !_isSaving;

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context);
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: source, imageQuality: 90);
    if (photo == null) return;
    final saved = await ImageService.saveImage(photo.path);
    if (saved != null && mounted) {
      setState(() {
        _imagePath = saved;
        _ocrTokens = [];
      });
      _runOcr(saved);
    }
  }

  Future<void> _runOcr(String path) async {
    if (!mounted) return;
    setState(() => _isOcrRunning = true);
    final tokens = await OcrService.extractTokens(path);
    if (mounted) {
      setState(() {
        _ocrTokens = tokens;
        _isOcrRunning = false;
        if (tokens.isNotEmpty) _isExpanded = true;
      });
    }
  }

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
          ],
        ),
      ),
    );
  }

  Future<void> _scanBarcode() async {
    final code = await scanBarcodeForCode(context);
    if (code != null && mounted) {
      setState(() {
        _modelController.text = code;
        _isExpanded = true;
      });
    }
  }

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _isSaving = true);

    final item = Item.create(
      name: _nameController.text.trim(),
      categoryId: _selectedCategoryId!,
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
      await ref.read(itemsProvider.notifier).addItem(item);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item.name} salvato')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore nel salvataggio: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Row(
                children: [
                  Text('Nuovo oggetto', style: tt.titleLarge),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // Category chips
            if (categories.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('Categoria *',
                    style: tt.labelMedium
                        ?.copyWith(color: cs.onSurfaceVariant)),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final cat = categories[i];
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
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Name field + photo button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      focusNode: _nameFocus,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Nome oggetto *',
                        prefixIcon: Icon(Icons.label_outline),
                      ),
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => _save(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildPhotoButton(cs),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // OCR loading indicator
            if (_isOcrRunning)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cs.secondaryContainer.withAlpha(80),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: cs.secondary),
                      ),
                      const SizedBox(width: 8),
                      Text('Leggo l\'etichetta...',
                          style: tt.bodySmall
                              ?.copyWith(color: cs.onSecondaryContainer)),
                    ],
                  ),
                ),
              ),

            // OCR suggestions
            if (!_isOcrRunning && _ocrTokens.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cs.secondaryContainer.withAlpha(80),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: cs.secondary.withAlpha(60)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_awesome,
                              size: 13, color: cs.secondary),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              'Tocca un testo per usarlo come codice:',
                              style: tt.labelSmall?.copyWith(
                                  color: cs.onSecondaryContainer),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _ocrTokens = []),
                            child: Icon(Icons.close,
                                size: 15,
                                color: cs.onSecondaryContainer),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: _ocrTokens
                            .map((t) => GestureDetector(
                                  onTap: () {
                                    _modelController.text = t;
                                    setState(() => _ocrTokens = []);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: cs.secondaryContainer,
                                      borderRadius:
                                          BorderRadius.circular(6),
                                      border: Border.all(
                                          color:
                                              cs.secondary.withAlpha(100)),
                                    ),
                                    child: Text(t,
                                        style: tt.labelSmall?.copyWith(
                                          color: cs.onSecondaryContainer,
                                          fontFamily: 'monospace',
                                        )),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 4),

            // Expand toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: InkWell(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        _isExpanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: cs.onSurfaceVariant,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isExpanded
                            ? 'Meno dettagli'
                            : 'Aggiungi modello, misure, note...',
                        style: tt.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Expanded fields
            if (_isExpanded) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _modelController,
                            decoration: const InputDecoration(
                              hintText: 'Codice / Modello',
                              prefixIcon: Icon(Icons.qr_code_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Barcode scan button
                        Container(
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: Icon(Icons.qr_code_scanner_outlined,
                                color: cs.onSurfaceVariant),
                            tooltip: 'Scansiona barcode',
                            onPressed: _scanBarcode,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _measuresController,
                      decoration: const InputDecoration(
                        hintText: 'Misure (es. 60\u00d740\u00d72 cm)',
                        prefixIcon: Icon(Icons.straighten_outlined),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        hintText: 'Posizione (es. Garage, Scaffale 2)',
                        prefixIcon: Icon(Icons.place_outlined),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Quantity stepper
                    Row(
                      children: [
                        const Icon(Icons.layers_outlined, size: 20),
                        const SizedBox(width: 12),
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
                    const SizedBox(height: 4),
                    // Expiry date picker
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _expiryDate ??
                              DateTime.now()
                                  .add(const Duration(days: 365)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                          helpText: 'Data di scadenza',
                        );
                        if (picked != null) {
                          setState(() => _expiryDate = picked);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Icon(Icons.event_outlined,
                                size: 20,
                                color: cs.onSurfaceVariant),
                            const SizedBox(width: 12),
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
                    const SizedBox(height: 8),
                    // Warranty date picker
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _warrantyDate ??
                              DateTime.now().add(const Duration(days: 365)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                          helpText: 'Fine garanzia',
                        );
                        if (picked != null) {
                          setState(() => _warrantyDate = picked);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Icon(Icons.verified_outlined,
                                size: 20,
                                color: cs.onSurfaceVariant),
                            const SizedBox(width: 12),
                            Text(
                              _warrantyDate != null
                                  ? 'Garanzia fino: ${_warrantyDate!.day.toString().padLeft(2, '0')}/${_warrantyDate!.month.toString().padLeft(2, '0')}/${_warrantyDate!.year}'
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
                    const SizedBox(height: 4),
                    // Purchase price
                    TextField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: const InputDecoration(
                        hintText: 'Prezzo di acquisto (opzionale)',
                        prefixIcon: Icon(Icons.euro_outlined),
                      ),
                      onChanged: (v) {
                        _purchasePrice = double.tryParse(
                            v.replaceAll(',', '.'));
                      },
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'Note',
                        prefixIcon: Icon(Icons.notes_outlined),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Save button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: FilledButton.icon(
                onPressed: _canSave ? _save : null,
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check),
                label: const Text('Salva'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoButton(ColorScheme cs) {
    if (_imagePath != null) {
      return GestureDetector(
        onTap: _showImageSourceDialog,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(_imagePath!),
            width: 52,
            height: 52,
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(Icons.camera_alt_outlined, color: cs.onSurfaceVariant),
        onPressed: _showImageSourceDialog,
      ),
    );
  }
}
