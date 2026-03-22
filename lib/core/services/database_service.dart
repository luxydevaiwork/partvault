import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';

class DatabaseService {
  static Database? _db;

  static Database get database {
    assert(_db != null, 'DatabaseService.initialize() must be called first.');
    return _db!;
  }

  static Future<void> initialize() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'partvault.db');
    _db = await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon_code_point INTEGER NOT NULL,
        color_value INTEGER NOT NULL,
        is_default INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE items (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category_id TEXT NOT NULL,
        model_code TEXT,
        measures TEXT,
        notes TEXT,
        image_path TEXT,
        maintenance_interval_days INTEGER,
        last_maintained_at INTEGER,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 1,
        location TEXT,
        expiry_date INTEGER,
        purchase_price REAL,
        warranty_date INTEGER,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    await db.execute(
        'CREATE INDEX idx_items_category ON items(category_id)');
    await db.execute('CREATE INDEX idx_items_updated ON items(updated_at DESC)');

    await _seedDefaultCategories(db);
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE items ADD COLUMN maintenance_interval_days INTEGER');
      await db.execute('ALTER TABLE items ADD COLUMN last_maintained_at INTEGER');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE items ADD COLUMN quantity INTEGER NOT NULL DEFAULT 1');
      await db.execute('ALTER TABLE items ADD COLUMN location TEXT');
      await db.execute('ALTER TABLE items ADD COLUMN expiry_date INTEGER');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE items ADD COLUMN purchase_price REAL');
      await db.execute('ALTER TABLE items ADD COLUMN warranty_date INTEGER');
    }
  }

  static Future<void> _seedDefaultCategories(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    const uuid = Uuid();

    final defaults = [
      {
        'name': 'Cucina',
        'icon': Icons.kitchen.codePoint,
        'color': 0xFFFF6B35
      },
      {
        'name': 'Bagno',
        'icon': Icons.bathtub.codePoint,
        'color': 0xFF2196F3
      },
      {
        'name': 'Salotto',
        'icon': Icons.weekend.codePoint,
        'color': 0xFF9C27B0
      },
      {
        'name': 'Camera',
        'icon': Icons.bed.codePoint,
        'color': 0xFF5C6BC0
      },
      {
        'name': 'Auto',
        'icon': Icons.directions_car.codePoint,
        'color': 0xFFE53935
      },
      {
        'name': 'Garage',
        'icon': Icons.handyman.codePoint,
        'color': 0xFF616161
      },
      {
        'name': 'Ufficio',
        'icon': Icons.computer.codePoint,
        'color': 0xFF00897B
      },
      {
        'name': 'Esterno',
        'icon': Icons.yard.codePoint,
        'color': 0xFF43A047
      },
      {
        'name': 'Altro',
        'icon': Icons.category.codePoint,
        'color': 0xFF546E7A
      },
    ];

    for (final cat in defaults) {
      await db.insert('categories', {
        'id': uuid.v4(),
        'name': cat['name'],
        'icon_code_point': cat['icon'],
        'color_value': cat['color'],
        'is_default': 1,
        'created_at': now,
      });
    }
  }
}
