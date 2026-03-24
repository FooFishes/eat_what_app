import 'dart:typed_data';

import 'package:eat_what_app/core/error/app_error_presenter.dart';
import 'package:eat_what_app/core/theme/app_colors.dart';
import 'package:eat_what_app/model/restaurant/restaurant.dart';
import 'package:eat_what_app/model/restaurant/restaurant_dto.dart';
import 'package:eat_what_app/provider/repository_provider.dart';
import 'package:eat_what_app/widget/app_toast.dart';
import 'package:eat_what_app/widget/editable_image_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class AddRestaurantPage extends ConsumerStatefulWidget {
  const AddRestaurantPage({super.key});

  @override
  ConsumerState<AddRestaurantPage> createState() => _AddRestaurantPageState();
}

class _AddRestaurantPageState extends ConsumerState<AddRestaurantPage> {
  static const double _mockLng = 117.0653;
  static const double _mockLat = 36.6726;
  static const int _mockHubId = 1;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  final List<XFile> _images = [];
  final List<Uint8List> _imageBytes = [];

  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage();
    if (picked.isEmpty) {
      return;
    }

    final remaining = 9 - _images.length;
    if (remaining <= 0) {
      return;
    }

    final selected = picked.take(remaining).toList();
    final bytes = await Future.wait(selected.map((item) => item.readAsBytes()));

    if (!mounted) {
      return;
    }

    setState(() {
      _images.addAll(selected);
      _imageBytes.addAll(bytes);
    });
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
      _imageBytes.removeAt(index);
    });
  }

  Future<Restaurant?> _resolveRestaurant(RestaurantDTO dto) async {
    final repository = ref.read(restaurantRepositoryProvider);
    for (var attempt = 0; attempt < 3; attempt++) {
      final restaurant = await repository.resolveCreatedRestaurant(dto);
      if (restaurant != null) {
        return restaurant;
      }
      await Future<void>.delayed(const Duration(milliseconds: 450));
    }
    return null;
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }

    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    if (name.isEmpty) {
      AppErrorPresenter.showMessageToast(
        context,
        '请输入店铺名称',
        type: AppToastType.warning,
      );
      return;
    }
    if (address.isEmpty) {
      AppErrorPresenter.showMessageToast(
        context,
        '请输入店铺地址',
        type: AppToastType.warning,
      );
      return;
    }
    if (_images.isEmpty) {
      AppErrorPresenter.showMessageToast(
        context,
        '请至少上传一张店铺照片',
        type: AppToastType.warning,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final imageKeys = await ref
          .read(imageUploadRepositoryProvider)
          .uploadImages(images: _images);
      final dto = RestaurantDTO(
        name: name,
        address: address,
        cityId: null,
        gcjLng: _mockLng,
        gcjLat: _mockLat,
        hubId: _mockHubId,
        poi: 'SDU_${DateTime.now().millisecondsSinceEpoch}',
        pictureUrl: imageKeys,
      );

      await ref.read(restaurantRepositoryProvider).addRestaurant(dto);
      final restaurant = await _resolveRestaurant(dto);
      if (!mounted) {
        return;
      }
      if (restaurant == null) {
        AppErrorPresenter.showMessageToast(
          context,
          '店铺已创建，但暂时没取回新店铺 ID，请返回列表后重新选择',
          type: AppToastType.warning,
          duration: const Duration(seconds: 3),
        );
        context.pop();
        return;
      }

      context.go('/upload/restaurant/${restaurant.id}/add-food');
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppErrorPresenter.showErrorToast(context, error);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('新建店铺'), centerTitle: false),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MockInfoCard(
                title: '定位字段将使用 Mock 数据',
                lines: const [
                  'gcjLng: 117.0653',
                  'gcjLat: 36.6726',
                  'hubId: 1',
                  'POI: 自动生成唯一值',
                ],
              ),
              const SizedBox(height: 18),
              _buildSectionTitle('店铺名称'),
              const SizedBox(height: 8),
              _buildInput(controller: _nameController, hintText: '请输入店铺名称'),
              const SizedBox(height: 18),
              _buildSectionTitle('店铺地址'),
              const SizedBox(height: 8),
              _buildInput(controller: _addressController, hintText: '请输入店铺地址'),
              const SizedBox(height: 18),
              _buildSectionTitle('店铺描述（当前仅保留 UI）'),
              const SizedBox(height: 8),
              _buildInput(
                controller: _descriptionController,
                hintText: '后端暂未接收该字段，本期不提交',
                maxLines: 4,
              ),
              const SizedBox(height: 18),
              _buildSectionTitle('店铺照片'),
              const SizedBox(height: 10),
              EditableImageGrid(
                images: _imageBytes,
                onAdd: _pickImages,
                onRemove: _removeImage,
              ),
              const SizedBox(height: 18),
              _buildSectionTitle('店铺标签（预留）'),
              const SizedBox(height: 8),
              const _PlaceholderField(text: '本期先保留样式位，不提交到接口'),
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryStrong,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Next'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: AppColors.surfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _MockInfoCard extends StatelessWidget {
  final String title;
  final List<String> lines;

  const _MockInfoCard({required this.title, required this.lines});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(line),
            ),
        ],
      ),
    );
  }
}

class _PlaceholderField extends StatelessWidget {
  final String text;

  const _PlaceholderField({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}
