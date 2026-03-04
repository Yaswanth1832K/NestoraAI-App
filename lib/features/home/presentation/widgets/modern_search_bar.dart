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
        color: Theme.of(context).primaryColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: TextField(
        onSubmitted: onSearch,
        decoration: InputDecoration(
          icon: Icon(Icons.search, color: Theme.of(context).primaryColor),
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
