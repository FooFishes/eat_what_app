import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../provider/auth_provider.dart';
import '../widget/stacked_carousel.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<String?> authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '今日推荐',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 32),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),
            // === 顶部的主轮播图 ===
            StackedCarousel(
              height: 240,
              data: [
                CarouselData(
                  imagePath:
                      'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
                  title: '麻辣香锅',
                  content: '超大份量，校园必吃推荐',
                ),
                CarouselData(
                  imagePath:
                      'https://images.unsplash.com/photo-1504674900247-0877df9cc836?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
                  title: '新年美食专题',
                  route: '/activity_home',
                ),
                CarouselData(
                  imagePath:
                      'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
                  title: '人气披萨',
                  content: '手工现烤，拉丝浓郁',
                ),
              ],
            ),
            const SizedBox(height: 10),

            // === 中间左右两块区域 ===
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  // 左侧：活动入口 (类似 StackedCarousel)
                  Expanded(
                    child: StackedCarousel(
                      height: 250,
                      horizontalPadding: 16.0,
                      stackedCardAngle: pi / 30,
                      data: [
                        CarouselData(
                          imagePath:
                              'https://images.unsplash.com/photo-1504674900247-0877df9cc836?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
                          title: '新年美食专题',
                          route: '/activity_home',
                        ),
                        CarouselData(
                          imagePath:
                              'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
                          title: '火锅狂欢',
                        ),
                        CarouselData(
                          imagePath:
                              'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
                          title: '火锅狂欢',
                        ),
                        CarouselData(
                          imagePath:
                              'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
                          title: '火锅狂欢',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.45,
                      height: 250,
                      child: Image.asset("assets/images/map.png"),
                    ),
                    onTap: () => context.go('/map'),
                  ),
                ],
              ),
            ),
            // === 底部长条分享按钮 ===
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: GestureDetector(
                onTap: () {
                  context.go('/upload');
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_rounded,
                        color: AppColors.primary,
                        size: 60,
                        fontWeight: FontWeight.bold,
                      ),
                      SizedBox(height: 8),
                      Text(
                        '今天有什么美食要分享吗 ╰(*°▽°*)╯',
                        style: TextStyle(
                          color: AppColors.textPrimary.withValues(alpha: 0.5),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
            Text('${authState.value}'),
            TextButton(
              onPressed: () {
                ref.read(authProvider.notifier).logout();
              },
              child: const Text('退出登录'),
            ),
            const SizedBox(height: 40), // 底部留白
          ],
        ),
      ),
    );
  }
}
