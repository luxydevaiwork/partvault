import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class CategoryModel {
  final String id;
  final String name;
  final int iconCodePoint;
  final int colorValue;
  final bool isDefault;
  final DateTime createdAt;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.iconCodePoint,
    required this.colorValue,
    required this.isDefault,
    required this.createdAt,
  });

  factory CategoryModel.create({
    required String name,
    required int iconCodePoint,
    required int colorValue,
  }) {
    return CategoryModel(
      id: const Uuid().v4(),
      name: name,
      iconCodePoint: iconCodePoint,
      colorValue: colorValue,
      isDefault: false,
      createdAt: DateTime.now(),
    );
  }

  CategoryModel copyWith({
    String? name,
    int? iconCodePoint,
    int? colorValue,
  }) {
    return CategoryModel(
      id: id,
      name: name ?? this.name,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorValue: colorValue ?? this.colorValue,
      isDefault: isDefault,
      createdAt: createdAt,
    );
  }

  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');
  Color get color => Color(colorValue);

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'icon_code_point': iconCodePoint,
        'color_value': colorValue,
        'is_default': isDefault ? 1 : 0,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory CategoryModel.fromMap(Map<String, dynamic> map) => CategoryModel(
        id: map['id'] as String,
        name: map['name'] as String,
        iconCodePoint: map['icon_code_point'] as int,
        colorValue: map['color_value'] as int,
        isDefault: (map['is_default'] as int) == 1,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      );
}
