import 'dart:typed_data';

import 'package:eat_what_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class EditableImageGrid extends StatelessWidget {
  final List<Uint8List> images;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final int maxCount;
  final double itemSize;

  const EditableImageGrid({
    super.key,
    required this.images,
    required this.onAdd,
    required this.onRemove,
    this.maxCount = 9,
    this.itemSize = 92,
  });

  @override
  Widget build(BuildContext context) {
    final canAddMore = images.length < maxCount;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (var index = 0; index < images.length; index++)
          _ImageTile(
            bytes: images[index],
            size: itemSize,
            onRemove: () => onRemove(index),
          ),
        if (canAddMore)
          _AddTile(
            size: itemSize,
            onTap: onAdd,
            label: '添加照片',
            subtitle: '${images.length}/$maxCount',
          ),
      ],
    );
  }
}

class _ImageTile extends StatelessWidget {
  final Uint8List bytes;
  final double size;
  final VoidCallback onRemove;

  const _ImageTile({
    required this.bytes,
    required this.size,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.memory(
            bytes,
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
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
  final double size;
  final VoidCallback onTap;
  final String label;
  final String subtitle;

  const _AddTile({
    required this.size,
    required this.onTap,
    required this.label,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.35)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_rounded, color: AppColors.accentRed, size: 28),
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
