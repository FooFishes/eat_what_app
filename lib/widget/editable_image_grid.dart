import 'dart:typed_data';

import 'package:eat_what_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class EditableImageGrid extends StatelessWidget {
  final List<Uint8List> images;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final int maxCount;

  const EditableImageGrid({
    super.key,
    required this.images,
    required this.onAdd,
    required this.onRemove,
    this.maxCount = 9,
  });

  @override
  Widget build(BuildContext context) {
    final canAddMore = images.length < maxCount;
    final itemCount = images.length + (canAddMore ? 1 : 0);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index < images.length) {
          return _ImageTile(
            bytes: images[index],
            onRemove: () => onRemove(index),
          );
        }
        return _AddTile(
          onTap: onAdd,
          label: '添加照片',
          subtitle: '${images.length}/$maxCount',
        );
      },
    );
  }
}

class _ImageTile extends StatelessWidget {
  final Uint8List bytes;
  final VoidCallback onRemove;

  const _ImageTile({required this.bytes, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.memory(bytes, fit: BoxFit.cover),
        ),
        Positioned(
          top: 5,
          right: 5,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddTile extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  final String subtitle;

  const _AddTile({
    required this.onTap,
    required this.label,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.35)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_photo_alternate_outlined, color: AppColors.accentRed, size: 30),
            const SizedBox(height: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}
