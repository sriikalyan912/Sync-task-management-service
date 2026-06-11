import 'package:flutter/material.dart';

/// Icons are stored in the database by key (not codePoint) so that the
/// IconData instances stay const and icon tree-shaking keeps working.
const Map<String, IconData> categoryIcons = {
  'food': Icons.restaurant,
  'groceries': Icons.shopping_basket,
  'transport': Icons.directions_bus,
  'shopping': Icons.shopping_bag,
  'bills': Icons.receipt_long,
  'entertainment': Icons.movie,
  'health': Icons.medical_services,
  'education': Icons.school,
  'travel': Icons.flight,
  'other': Icons.category,
};

class ExpenseCategory {
  final int? id;
  final String name;
  final String iconKey;
  final int colorValue;

  const ExpenseCategory({
    this.id,
    required this.name,
    required this.iconKey,
    required this.colorValue,
  });

  Color get color => Color(colorValue);

  IconData get icon => categoryIcons[iconKey] ?? Icons.category;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'icon': iconKey,
        'color': colorValue,
      };

  factory ExpenseCategory.fromMap(Map<String, dynamic> map) => ExpenseCategory(
        id: map['id'] as int?,
        name: map['name'] as String,
        iconKey: map['icon'] as String,
        colorValue: map['color'] as int,
      );
}
