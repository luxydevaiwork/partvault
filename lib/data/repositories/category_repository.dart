import 'package:sqflite/sqflite.dart';
import '../models/category_model.dart';

class CategoryRepository {
  final Database _db;
  CategoryRepository(this._db);

  Future<List<CategoryModel>> getAll() async {
    final maps = await _db.query(
      'categories',
      orderBy: 'is_default DESC, name ASC',
    );
    return maps.map(CategoryModel.fromMap).toList();
  }

  Future<CategoryModel?> getById(String id) async {
    final maps = await _db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return CategoryModel.fromMap(maps.first);
  }

  Future<void> insert(CategoryModel category) async {
    await _db.insert('categories', category.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> update(CategoryModel category) async {
    await _db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<void> delete(String id) async {
    await _db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }
}
