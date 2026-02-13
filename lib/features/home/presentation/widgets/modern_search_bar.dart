import 'package:flutter/material.dart';

class ModernSearchBar extends StatelessWidget {
  final String hintText;
  final Function(String) onSearch;

  const ModernSearchBar({
    super.key,
    required this.hintText,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: TextField(
        onSubmitted: onSearch,
        decoration: InputDecoration(
          icon: const Icon(Icons.search, color: Colors.blue),
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
