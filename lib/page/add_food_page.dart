import 'dart:typed_data';

import 'package:eat_what_app/core/error/app_error_presenter.dart';
import 'package:eat_what_app/core/theme/app_colors.dart';
import 'package:eat_what_app/model/food/create_food_dto.dart';
import 'package:eat_what_app/model/food/food_tag_summary_vo.dart';
import 'package:eat_what_app/model/food/food_vo.dart';
import 'package:eat_what_app/provider/repository_provider.dart';
import 'package:eat_what_app/widget/app_toast.dart';
import 'package:eat_what_app/widget/editable_image_grid.dart';
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

  final List<XFile> _images = [];
  final List<Uint8List> _imageBytes = [];
  final Set<int> _selectedSystemTagIds = <int>{};

  List<FoodTagSummaryVO> _systemTags = const [];
  String? _selectedCategory;
  bool _isLoadingTags = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadSystemTags);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _customTagsController.dispose();
    super.dispose();
  }

  Future<void> _loadSystemTags() async {
    try {
      final tags = await ref.read(foodRepositoryProvider).getSystemTags();
      if (!mounted) {
        return;
      }
      setState(() {
        _systemTags = tags;
        _isLoadingTags = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingTags = false;
      });
      AppErrorPresenter.showErrorToast(context, error);
    }
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
    if (raw.isEmpty) {
      return null;
    }
    return double.tryParse(raw);
  }

  Future<FoodVO?> _resolveFood({
    required String name,
    required List<String> imageKeys,
  }) async {
    final repository = ref.read(foodRepositoryProvider);
    for (var attempt = 0; attempt < 3; attempt++) {
      final food = await repository.resolveCreatedFood(
        restaurantId: widget.restaurantId,
        name: name,
        pictureUrl: imageKeys,
      );
      if (food != null) {
        return food;
      }
      await Future<void>.delayed(const Duration(milliseconds: 450));
    }
    return null;
  }

  Future<void> _submit({required bool finishAfterSubmit}) async {
    if (_isSubmitting) {
      return;
    }

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      AppErrorPresenter.showMessageToast(
        context,
        '请输入菜品名称',
        type: AppToastType.warning,
      );
      return;
    }
    if (_images.isEmpty) {
      AppErrorPresenter.showMessageToast(
        context,
        '请至少上传一张菜品照片',
        type: AppToastType.warning,
      );
      return;
    }

    final price = _parsePrice();
    if (_priceController.text.trim().isNotEmpty && price == null) {
      AppErrorPresenter.showMessageToast(
        context,
        '价格格式不正确',
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
      final dto = CreateFoodDTO(
        restaurantId: widget.restaurantId,
        name: name,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        price: price,
        category: _selectedCategory,
        pictureUrl: imageKeys,
      );

      await ref.read(foodRepositoryProvider).uploadFood(dto);
      final createdFood = await _resolveFood(name: name, imageKeys: imageKeys);
      final customTags = _parseCustomTags();

      if (createdFood != null) {
        if (_selectedSystemTagIds.isNotEmpty) {
          await ref
              .read(foodRepositoryProvider)
              .addSystemTags(createdFood.id, _selectedSystemTagIds.toList());
        }
        if (customTags.isNotEmpty) {
          await ref
              .read(foodRepositoryProvider)
              .addCustomTags(createdFood.id, customTags);
        }
      }

      if (!mounted) {
        return;
      }

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
        AppErrorPresenter.showMessageToast(
          context,
          '菜品上传完成',
          type: AppToastType.success,
        );
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
      AppErrorPresenter.showMessageToast(
        context,
        '已保存，可继续添加下一道菜',
        type: AppToastType.success,
      );
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
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 18),
              _buildSectionTitle('分类'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String?>(
                initialValue: _selectedCategory,
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('不选择'),
                  ),
                  ..._categoryLabels.entries.map(
                    (entry) => DropdownMenuItem<String?>(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
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
              if (_isLoadingTags)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: CircularProgressIndicator(),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final tag in _systemTags)
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
                      onPressed: _isSubmitting
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
                      onPressed: _isSubmitting
                          ? null
                          : () => _submit(finishAfterSubmit: true),
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
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
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
