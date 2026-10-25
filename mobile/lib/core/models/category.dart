import 'package:flutter/material.dart';

const supportedCategoryIcons = <IconData>[
  Icons.folder,
  Icons.work,
  Icons.school,
  Icons.person,
  Icons.lightbulb,
  Icons.star,
  Icons.book,
  Icons.code,
  Icons.restaurant,
  Icons.flight,
  Icons.pets,
  Icons.sports_esports,
  Icons.shopping_bag,
  Icons.camera_alt,
  Icons.palette,
  Icons.fitness_center,
  Icons.travel_explore,
  Icons.health_and_safety,
  Icons.brush,
  Icons.park,
  Icons.coffee,
  Icons.science,
  Icons.auto_stories,
];

class CategoryItem {
  const CategoryItem({
    required this.id,
    required this.name,
    required this.icon,
  });

  final String id;
  final String name;
  final IconData icon;

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    return CategoryItem(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: supportedCategoryIcons.firstWhere(
        (icon) => icon.codePoint == json['iconCodePoint'] as int,
        orElse: () => Icons.folder,
      ),
    );
  }
}
