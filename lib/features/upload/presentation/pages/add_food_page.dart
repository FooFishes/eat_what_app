import 'dart:typed_data';

import 'package:eat_what_app/core/error/app_error_presenter.dart';
import 'package:eat_what_app/core/theme/app_colors.dart';
import 'package:eat_what_app/features/upload/presentation/view_models/add_food_view_model.dart';
import 'package:eat_what_app/shared/presentation/widgets/app_toast.dart';
import 'package:eat_what_app/features/upload/presentation/widgets/editable_image_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class AddFoodPage extends ConsumerStatefulWidget {
  final int restaurantId;

  const AddFoodPage({super.key, required this.restaurantId});

  @override
  ConsumerState<AddFoodPage> createState() => _AddFoodPageState();
}

class _AddFoodPageState extends ConsumerState<AddFoodPage> {
  static const Map<String, String> _categoryLabels = {
    'STAPLE': '主食',
    'DRINK': '饮品',
    'SNACK': '小吃',
    'DESSERT': '甜品',
    'SOUP': '汤品',
    'HOT_POT': '火锅',
    'GRILL': '烧烤',
    'COLD_DISH': '凉菜',
    'SIDE_DISH': '配菜',
    'OTHER': '其他',
  };

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _customTagsController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  // Local UI state — image selection and form choices stay in the page.
  final List<XFile> _images = [];
  final List<Uint8List> _imageBytes = [];
  final Set<int> _selectedSystemTagIds = <int>{};
  String? _selectedCategory;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _customTagsController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage();
    if (picked.isEmpty) return;
    final remaining = 9 - _images.length;
    if (remaining <= 0) return;
    final selected = picked.take(remaining).toList();
    final bytes = await Future.wait(selected.map((item) => item.readAsBytes()));
    if (!mounted) return;
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

  List<String> _parseCustomTags() {
    return _customTagsController.text
        .split(RegExp(r'[,，、\s\n]+'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .take(20)
        .toList();
  }

  double? _parsePrice() {
    final raw = _priceController.text.trim();
    if (raw.isEmpty) return null;
    return double.tryParse(raw);
  }

  Future<void> _submit({required bool finishAfterSubmit}) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      AppErrorPresenter.showMessageToast(context, '请输入菜品名称',
          type: AppToastType.warning);
      return;
    }
    if (_images.isEmpty) {
      AppErrorPresenter.showMessageToast(context, '请至少上传一张菜品照片',
          type: AppToastType.warning);
      return;
    }
    final price = _parsePrice();
    if (_priceController.text.trim().isNotEmpty && price == null) {
      AppErrorPresenter.showMessageToast(context, '价格格式不正确',
          type: AppToastType.warning);
      return;
    }

    try {
      final customTags = _parseCustomTags();
      final createdFood = await ref
          .read(addFoodViewModelProvider.notifier)
          .createFood(
            restaurantId: widget.restaurantId,
            name: name,
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            price: price,
            category: _selectedCategory,
            images: _images,
            selectedSystemTagIds: _selectedSystemTagIds,
            customTags: customTags,
          );

      if (!mounted) return;

      if (createdFood == null &&
          (_selectedSystemTagIds.isNotEmpty || customTags.isNotEmpty)) {
        AppErrorPresenter.showMessageToast(
          context,
          '菜品主体已上传，但本次未自动补标签',
          type: AppToastType.info,
          duration: const Duration(seconds: 3),
        );
      }

      if (finishAfterSubmit) {
        AppErrorPresenter.showMessageToast(context, '菜品上传完成',
            type: AppToastType.success);
        context.pop();
        return;
      }

      setState(() {
        _nameController.clear();
        _descriptionController.clear();
        _priceController.clear();
        _customTagsController.clear();
        _images.clear();
        _imageBytes.clear();
        _selectedSystemTagIds.clear();
        _selectedCategory = null;
      });
      AppErrorPresenter.showMessageToast(context, '已保存，可继续添加下一道菜',
          type: AppToastType.success);
    } catch (error) {
      if (!mounted) return;
      AppErrorPresenter.showErrorToast(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vmState = ref.watch(addFoodViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('添加菜品'), centerTitle: false),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('菜品名称'),
              const SizedBox(height: 8),
              _buildInput(controller: _nameController, hintText: '请输入菜品名称'),
              const SizedBox(height: 18),
              _buildSectionTitle('菜品描述'),
              const SizedBox(height: 8),
              _buildInput(
                controller: _descriptionController,
                hintText: '描述口味、分量、推荐原因',
                maxLines: 4,
              ),
              const SizedBox(height: 18),
              _buildSectionTitle('价格'),
              const SizedBox(height: 8),
              _buildInput(
                controller: _priceController,
                hintText: '可选，例如 18.5',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 18),
              _buildSectionTitle('分类'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String?>(
                initialValue: _selectedCategory,
                items: [
                  const DropdownMenuItem<String?>(
                      value: null, child: Text('不选择')),
                  ..._categoryLabels.entries.map(
                    (entry) => DropdownMenuItem<String?>(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _selectedCategory = value),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surfaceAlt,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _buildSectionTitle('菜品标签'),
              const SizedBox(height: 10),
              if (vmState.isLoadingTags)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: CircularProgressIndicator(),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final tag in vmState.systemTags)
                      FilterChip(
                        label: Text(tag.name),
                        selected: _selectedSystemTagIds.contains(tag.id),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedSystemTagIds.add(tag.id);
                            } else {
                              _selectedSystemTagIds.remove(tag.id);
                            }
                          });
                        },
                      ),
                  ],
                ),
              const SizedBox(height: 12),
              _buildInput(
                controller: _customTagsController,
                hintText: '自定义标签，支持逗号或空格分隔',
              ),
              const SizedBox(height: 18),
              _buildSectionTitle('菜品照片'),
              const SizedBox(height: 10),
              EditableImageGrid(
                images: _imageBytes,
                onAdd: _pickImages,
                onRemove: _removeImage,
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: vmState.isSubmitting
                          ? null
                          : () => _submit(finishAfterSubmit: false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryStrong,
                        side: const BorderSide(color: AppColors.primaryStrong),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text('Next'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: vmState.isSubmitting
                          ? null
                          : () => _submit(finishAfterSubmit: true),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryStrong,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: vmState.isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Finish'),
                    ),
                  ),
                ],
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
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.w800),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
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
