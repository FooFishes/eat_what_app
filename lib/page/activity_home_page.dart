import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:eat_what_app/core/theme/app_colors.dart';

class ActivityHomePage extends ConsumerWidget {
  const ActivityHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildUploadSection(context),
                        _buildRecommendationSection(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            _buildHomeButton(context),
          ],
        ),
      ),
    );
  }

  /// 构建标题组件
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, left: 16, right: 16),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          const Text(
            'New Year',
            style: TextStyle(
              color: AppColors.accentRed,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: AppColors.border,
                  offset: Offset(2, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          Positioned(
            right: -46,
            top: -24,
            child: Image.asset(
              'assets/images/firework_right.png',
              width: 59,
              height: 51,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建上传区域组件
  Widget _buildUploadSection(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        SizedBox(
          width: 320,
          height: 220,
          child: Stack(
            children: [
              Positioned(
                left: 100,
                top: 20,
                child: GestureDetector(
                  onTap: () => context.go('/foodie_map'),
                  child: Image.asset(
                    'assets/images/china_map/base.png',
                    width: 200,
                    height: 180,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 100,
          top: 150,
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '美食地图',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
              ),
              Text(
                '可查看各地美食',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
              ),
            ],
          ),
        ),
        Positioned(
          left: -20,
          bottom: 0,
          child: GestureDetector(
            onTap: () => context.go('/upload?tab=new_year'),
            child: Column(
              children: [
                Image.asset(
                  'assets/images/camera.png',
                  width: 115,
                  height: 90,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 75,
          bottom: 0,
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '上传',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建今日推荐组件
  Widget _buildRecommendationSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text(
            '今日推荐',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {},
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: const DecorationImage(
                      image: NetworkImage(
                        'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Stack(
                    children: [
                      Text(
                        '烧烤',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          foreground: Paint()
                            ..style = PaintingStyle.stroke
                            ..strokeWidth = 3
                            ..color = Colors.black,
                        ),
                      ),
                      const Text(
                        '烧烤',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: -12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'More',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建底部返回按钮组件
  Widget _buildHomeButton(BuildContext context) {
    return Positioned(
      bottom: 30,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: () => context.go('/home'),
          child: Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: AppColors.accentRed,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Image.asset('assets/images/home.png', fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }
}
