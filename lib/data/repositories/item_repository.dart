import 'package:sqflite/sqflite.dart';
import '../models/item.dart';

class ItemRepository {
  final Database _db;
  ItemRepository(this._db);

  Future<List<Item>> getAll() async {
    final maps = await _db.query('items', orderBy: 'updated_at DESC');
    return maps.map(Item.fromMap).toList();
  }

  Future<List<Item>> getByCategory(String categoryId) async {
    final maps = await _db.query(
      'items',
      where: 'category_id = ?',
      whereArgs: [categoryId],
      orderBy: 'updated_at DESC',
    );
    return maps.map(Item.fromMap).toList();
  }

  Future<Item?> getById(String id) async {
    final maps = await _db.query(
      'items',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Item.fromMap(maps.first);
  }

  Future<List<Item>> search(String query) async {
    if (query.trim().isEmpty) return [];
    final q = '%${query.trim()}%';
    final maps = await _db.query(
      'items',
      where:
          'name LIKE ? OR model_code LIKE ? OR measures LIKE ? OR notes LIKE ? OR location LIKE ?',
      whereArgs: [q, q, q, q, q],
      orderBy: 'updated_at DESC',
    );
    return maps.map(Item.fromMap).toList();
  }

  Future<Map<String, int>> getCountPerCategory() async {
    final result = await _db.rawQuery(
      'SELECT category_id, COUNT(*) as count FROM items GROUP BY category_id',
    );
    return {
      for (final row in result)
        row['category_id'] as String: row['count'] as int,
    };
  }

  Future<void> insert(Item item) async {
    await _db.insert('items', item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> update(Item item) async {
    await _db.update(
      'items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> delete(String id) async {
    await _db.delete('items', where: 'id = ?', whereArgs: [id]);
  }
}
