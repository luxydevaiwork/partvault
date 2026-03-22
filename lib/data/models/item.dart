import 'package:uuid/uuid.dart';

class Item {
  final String id;
  final String name;
  final String categoryId;
  final String? modelCode;
  final String? measures;
  final String? notes;
  final String? imagePath;
  final int? maintenanceIntervalDays;
  final DateTime? lastMaintainedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int quantity;
  final String? location;
  final DateTime? expiryDate;
  final double? purchasePrice;
  final DateTime? warrantyDate;

  const Item({
    required this.id,
    required this.name,
    required this.categoryId,
    this.modelCode,
    this.measures,
    this.notes,
    this.imagePath,
    this.maintenanceIntervalDays,
    this.lastMaintainedAt,
    required this.createdAt,
    required this.updatedAt,
    this.quantity = 1,
    this.location,
    this.expiryDate,
    this.purchasePrice,
    this.warrantyDate,
  });

  bool get isMaintenanceDue {
    if (maintenanceIntervalDays == null) return false;
    final base = lastMaintainedAt ?? createdAt;
    final due = base.add(Duration(days: maintenanceIntervalDays!));
    return DateTime.now().isAfter(due);
  }

  DateTime? get nextMaintenanceDate {
    if (maintenanceIntervalDays == null) return null;
    final base = lastMaintainedAt ?? createdAt;
    return base.add(Duration(days: maintenanceIntervalDays!));
  }

  bool get isWarrantyExpired {
    if (warrantyDate == null) return false;
    return DateTime.now().isAfter(warrantyDate!);
  }

  int? get daysUntilWarrantyExpiry {
    if (warrantyDate == null) return null;
    return warrantyDate!.difference(DateTime.now()).inDays;
  }

  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }

  int? get daysUntilExpiry {
    if (expiryDate == null) return null;
    return expiryDate!.difference(DateTime.now()).inDays;
  }

  factory Item.create({
    required String name,
    required String categoryId,
    String? modelCode,
    String? measures,
    String? notes,
    String? imagePath,
    int? maintenanceIntervalDays,
    int quantity = 1,
    String? location,
    DateTime? expiryDate,
    double? purchasePrice,
    DateTime? warrantyDate,
  }) {
    final now = DateTime.now();
    return Item(
      id: const Uuid().v4(),
      name: name,
      categoryId: categoryId,
      modelCode: modelCode,
      measures: measures,
      notes: notes,
      imagePath: imagePath,
      maintenanceIntervalDays: maintenanceIntervalDays,
      lastMaintainedAt: null,
      createdAt: now,
      updatedAt: now,
      quantity: quantity,
      location: location,
      expiryDate: expiryDate,
      purchasePrice: purchasePrice,
      warrantyDate: warrantyDate,
    );
  }

  Item copyWith({
    String? name,
    String? categoryId,
    Object? modelCode = _sentinel,
    Object? measures = _sentinel,
    Object? notes = _sentinel,
    Object? imagePath = _sentinel,
    Object? maintenanceIntervalDays = _sentinel,
    Object? lastMaintainedAt = _sentinel,
    int? quantity,
    Object? location = _sentinel,
    Object? expiryDate = _sentinel,
    Object? purchasePrice = _sentinel,
    Object? warrantyDate = _sentinel,
  }) {
    return Item(
      id: id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      modelCode: modelCode == _sentinel ? this.modelCode : modelCode as String?,
      measures: measures == _sentinel ? this.measures : measures as String?,
      notes: notes == _sentinel ? this.notes : notes as String?,
      imagePath: imagePath == _sentinel ? this.imagePath : imagePath as String?,
      maintenanceIntervalDays: maintenanceIntervalDays == _sentinel
          ? this.maintenanceIntervalDays
          : maintenanceIntervalDays as int?,
      lastMaintainedAt: lastMaintainedAt == _sentinel
          ? this.lastMaintainedAt
          : lastMaintainedAt as DateTime?,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      quantity: quantity ?? this.quantity,
      location: location == _sentinel ? this.location : location as String?,
      expiryDate:
          expiryDate == _sentinel ? this.expiryDate : expiryDate as DateTime?,
      purchasePrice: purchasePrice == _sentinel
          ? this.purchasePrice
          : purchasePrice as double?,
      warrantyDate: warrantyDate == _sentinel
          ? this.warrantyDate
          : warrantyDate as DateTime?,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'category_id': categoryId,
        'model_code': modelCode,
        'measures': measures,
        'notes': notes,
        'image_path': imagePath,
        'maintenance_interval_days': maintenanceIntervalDays,
        'last_maintained_at': lastMaintainedAt?.millisecondsSinceEpoch,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
        'quantity': quantity,
        'location': location,
        'expiry_date': expiryDate?.millisecondsSinceEpoch,
        'purchase_price': purchasePrice,
        'warranty_date': warrantyDate?.millisecondsSinceEpoch,
      };

  factory Item.fromMap(Map<String, dynamic> map) => Item(
        id: map['id'] as String,
        name: map['name'] as String,
        categoryId: map['category_id'] as String,
        modelCode: map['model_code'] as String?,
        measures: map['measures'] as String?,
        notes: map['notes'] as String?,
        imagePath: map['image_path'] as String?,
        maintenanceIntervalDays: map['maintenance_interval_days'] as int?,
        lastMaintainedAt: map['last_maintained_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(
                map['last_maintained_at'] as int)
            : null,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
        updatedAt:
            DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
        quantity: (map['quantity'] as int?) ?? 1,
        location: map['location'] as String?,
        expiryDate: map['expiry_date'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['expiry_date'] as int)
            : null,
        purchasePrice: map['purchase_price'] != null
            ? (map['purchase_price'] as num).toDouble()
            : null,
        warrantyDate: map['warranty_date'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['warranty_date'] as int)
            : null,
      );

  /// Encodes item as a compact string for NFC/QR sharing.
  String toShareString() {
    final parts = <String>[
      'PV1',
      name,
      modelCode ?? '',
      measures ?? '',
      notes ?? '',
    ];
    return parts.join('|');
  }

  /// Parses a share string created by [toShareString].
  static Item? fromShareString(String raw, {required String categoryId}) {
    try {
      final parts = raw.split('|');
      if (parts.length < 5 || parts[0] != 'PV1') return null;
      return Item.create(
        name: parts[1],
        categoryId: categoryId,
        modelCode: parts[2].isEmpty ? null : parts[2],
        measures: parts[3].isEmpty ? null : parts[3],
        notes: parts[4].isEmpty ? null : parts[4],
      );
    } catch (_) {
      return null;
    }
  }
}

const _sentinel = Object();
