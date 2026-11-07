import 'package:flutter/material.dart';

class CategoryFilterBar extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onSelectCategory;
  final VoidCallback onAddCategory;

  const CategoryFilterBar({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onSelectCategory,
    required this.onAddCategory,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allCategories = ['Semua', ...categories];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: allCategories.length + 1, // +1 for "Tambah Kategori (+)"
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          // Last item is Add Category button
          if (index == allCategories.length) {
            return ActionChip(
              avatar: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Kategori Baru', style: TextStyle(fontSize: 12)),
              onPressed: onAddCategory,
              side: BorderSide(
                color: theme.colorScheme.primary.withAlpha(80),
                style: BorderStyle.solid,
              ),
              backgroundColor: theme.colorScheme.primary.withAlpha(15),
            );
          }

          final cat = allCategories[index];
          final isSelected = selectedCategory.toLowerCase() == cat.toLowerCase();

          return ChoiceChip(
            label: Text(
              cat,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            selected: isSelected,
            selectedColor: theme.colorScheme.primary,
            backgroundColor: theme.colorScheme.surface,
            elevation: isSelected ? 2 : 0,
            pressElevation: 0,
            side: BorderSide(
              color: isSelected
                  ? Colors.transparent
                  : theme.colorScheme.outline.withAlpha(40),
              width: 1,
            ),
            onSelected: (selected) {
              if (selected) {
                onSelectCategory(cat);
              }
            },
          );
        },
      ),
    );
  }
}
