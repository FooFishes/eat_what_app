import 'package:eat_what_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class RestaurantPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('餐厅'), centerTitle: false),
      body: Center(
        child: Padding(
          padding: const .symmetric(horizontal: 24),
          child: Container(
            width: double.infinity,
            padding: const .all(28),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: .circular(28),
            ),
            child: Column(
              mainAxisSize: .min,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: const BoxDecoration(
                    color: AppColors.card,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    size: 42,
                    color: AppColors.accentBrown,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  '今日推荐',
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: .w900),
                ),
                const SizedBox(height: 10),
                Text(
                  '餐厅推荐内容正在接入接口，当前先保留版位与视觉结构。',
                  textAlign: .center,
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const .symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: .circular(999),
                  ),
                  child: const Text(
                    '精彩内容即将上线',
                    style: TextStyle(fontWeight: .w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
