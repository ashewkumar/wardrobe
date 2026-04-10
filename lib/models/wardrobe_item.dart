import 'package:flutter/material.dart';

class WardrobeItem {
  final String name;
  final String category;
  final String color;
  final String brand;
  final double price;
  final IconData icon;

  const WardrobeItem({
    required this.name,
    required this.category,
    required this.color,
    required this.brand,
    required this.price,
    required this.icon,
  });

  static const samples = [
    WardrobeItem(
      name: "Ivory Linen Shirt",
      category: "Top",
      color: "Ivory",
      brand: "Anaya",
      price: 2200,
      icon: Icons.checkroom,
    ),
    WardrobeItem(
      name: "Navy Tailored Pants",
      category: "Bottom",
      color: "Navy",
      brand: "Form",
      price: 2800,
      icon: Icons.chair,
    ),
    WardrobeItem(
      name: "Tan Loafers",
      category: "Footwear",
      color: "Tan",
      brand: "Lune",
      price: 3500,
      icon: Icons.hiking,
    ),
    WardrobeItem(
      name: "Gold Hoops",
      category: "Accessory",
      color: "Gold",
      brand: "Juno",
      price: 1800,
      icon: Icons.wb_iridescent,
    ),
    WardrobeItem(
      name: "Emerald Kurta",
      category: "Top",
      color: "Green",
      brand: "Rasa",
      price: 2600,
      icon: Icons.checkroom,
    ),
    WardrobeItem(
      name: "Stonewashed Jeans",
      category: "Bottom",
      color: "Blue",
      brand: "Byline",
      price: 2400,
      icon: Icons.chair,
    ),
  ];
}
