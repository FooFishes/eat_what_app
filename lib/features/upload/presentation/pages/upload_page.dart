import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:eat_what_app/features/upload/presentation/view_models/activity_upload_state.dart';
import 'package:eat_what_app/features/upload/presentation/view_models/activity_upload_view_model.dart';
import 'package:eat_what_app/core/error/app_error_presenter.dart';
import 'package:eat_what_app/core/theme/app_colors.dart';
import 'package:eat_what_app/shared/location/data/models/city_response.dart';
import 'package:eat_what_app/shared/location/data/models/province_response.dart';
import 'package:eat_what_app/features/upload/presentation/pages/restaurant_search_page.dart';
import 'package:eat_what_app/shared/presentation/widgets/app_toast.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

/// 上传页面
/// 包含两个子页面：Campus页面和New Year页面
class UploadPage extends ConsumerStatefulWidget {
  const UploadPage({super.key});

  @override
  ConsumerState<UploadPage> createState() => _ActivityUploadState();
}

class _ActivityUploadState extends ConsumerState<UploadPage> {
  /// 是否选中Campus选项卡
  bool _isCampusSelected = true;

  /// 图片选择器实例
  final ImagePicker _picker = ImagePicker();

  /// 已选择的图片文件列表
  final List<XFile> _selectedImages = [];

  /// 已选择的图片原始字节列表（用于跨平台显示）
  final List<Uint8List> _imageBytes = [];

  /// 图片尺寸信息列表
  final List<ui.Image> _imageInfos = [];

  /// 轮播图控制器
  final PageController _pageController = PageController();

  /// 当前轮播页面索引
  int _currentPageIndex = 0;

  /// 菜品名称控制器
  final TextEditingController _foodNameController = TextEditingController();

  /// 菜品描述控制器
  final TextEditingController _descriptionController = TextEditingController();

  /// 店铺名称控制器
  final TextEditingController _shopNameController = TextEditingController();

  @override
  void dispose() {
    _selectedImages.clear();
    _imageBytes.clear();
    _imageInfos.clear();
    _pageController.dispose();
    _foodNameController.dispose();
    _descriptionController.dispose();
    _shopNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ActivityUploadState>(activityUploadViewModelProvider, (
      ActivityUploadState? previous,
      ActivityUploadState next,
    ) {
      final feedback = next.feedback;
      if (feedback == null || feedback.id == previous?.feedback?.id) {
        return;
      }

      _handleUploadFeedback(feedback);

      if (feedback.kind == ActivityUploadFeedbackKind.success) {
        _resetLocalForm();
      }

      ref.read(activityUploadViewModelProvider.notifier).clearFeedback();
    });

    return Scaffold(
      appBar: AppBar(title: const Text('上传页'), centerTitle: false),
      body: Padding(
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 16,
        ),
        child: Column(
          children: [
            _buildToggleSwitch(),
            const SizedBox(height: 20),
            Expanded(
              child: _isCampusSelected
                  ? _buildCampusSubPage()
                  : _buildNewYearSubPage(),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建顶部切换开关组件
  /// 用于在Campus和New Year两个选项卡之间切换
  Widget _buildToggleSwitch() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final slideWidth = constraints.maxWidth / 2;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    left: _isCampusSelected ? 2 : slideWidth + 2,
                    right: _isCampusSelected ? slideWidth + 2 : 2,
                    top: 2,
                    bottom: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.accentRed,
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      _buildToggleOption('Campus', true),
                      _buildToggleOption('New Year', false),
                    ],
                  ),
                ],
              ),
            ),
            if (!_isCampusSelected)
              Positioned(
                top: -20,
                left: -16,
                child: Image.asset(
                  'assets/images/firework_left.png',
                  width: 56,
                  height: 49,
                ),
              ),
          ],
        );
      },
    );
  }

  /// 构建切换选项组件
  /// [label] 选项卡显示的文字
  /// [isCampus] 是否为Campus选项
  Widget _buildToggleOption(String label, bool isCampus) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _isCampusSelected = isCampus),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: _isCampusSelected == isCampus
                  ? Colors.white
                  : AppColors.textSecondary,
              fontWeight: _isCampusSelected == isCampus
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  /// 构建Campus子页面
  Widget _buildCampusSubPage() {
    return const RestaurantSearchPage();
  }

  /// 构建New Year子页面
  Widget _buildNewYearSubPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              '添加菜品',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 30),
          // 必填项：菜品名称
          _buildFormField(
            '菜品名称',
            true,
            _buildInputField('请输入菜品名称', controller: _foodNameController),
          ),
          const SizedBox(height: 20),
          // 可选项：菜品描述
          _buildFormField(
            '菜品描述',
            false,
            _buildTextArea('请输入菜品描述', controller: _descriptionController),
          ),
          const SizedBox(height: 20),
          // 必填项：菜品照片
          _buildFormField('菜品照片', true, _buildPhotoUploadArea()),
          const SizedBox(height: 20),
          // 必填项：城市
          _buildFormField(
            '城市',
            true,
            Row(
              children: [
                Expanded(child: _buildProvinceDropdown()),
                const SizedBox(width: 8),
                Text(
                  '--',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: _buildCityDropdown()),
              ],
            ),
          ),
          const SizedBox(height: 20),

          /* 后端没有实现上传店铺名称
          // 可选项：店铺名称
          _buildFormField(
            '店铺名称',
            false,
            _buildInputField('请输入店铺名称', controller: _shopNameController),
          ),
          const SizedBox(height: 20),
           */
          _buildFinishButton(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// 构建表单字段组件
  /// [label] 字段标签
  /// [isRequired] 是否为必填项，必填项会显示红色圆点标记
  /// [field] 字段内容组件
  Widget _buildFormField(String label, bool isRequired, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, isRequired),
        const SizedBox(height: 8),
        field,
      ],
    );
  }

  /// 构建标签组件
  /// [label] 标签文字
  /// [isRequired] 是否为必填项，必填项会显示红色圆点
  Widget _buildLabel(String label, bool isRequired) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        if (isRequired)
          Positioned(
            top: -2,
            right: -8,
            child: Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: AppColors.accentRed,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }

  /// 构建单行输入框组件
  /// [hintText] 提示文字
  /// [controller] 文本控制器
  Widget _buildInputField(
    String hintText, {
    TextEditingController? controller,
  }) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.transparent),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.transparent),
          ),
          disabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.transparent),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.transparent),
          ),
          contentPadding: const EdgeInsets.only(top: 0, bottom: 0, left: 8),
        ),
      ),
    );
  }

  /// 构建多行文本域组件
  /// [hintText] 提示文字
  /// [controller] 文本控制器
  Widget _buildTextArea(String hintText, {TextEditingController? controller}) {
    return Container(
      height: 116,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(25),
      ),
      child: TextField(
        controller: controller,
        maxLines: null,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  /// 构建照片上传区域组件
  Widget _buildPhotoUploadArea() {
    final int totalPages = _selectedImages.isEmpty
        ? 1
        : _selectedImages.length + 1;

    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(25),
      ),
      child: PageView.builder(
        controller: _pageController,
        itemCount: totalPages,
        onPageChanged: (index) {
          setState(() {
            _currentPageIndex = index;
          });
        },
        itemBuilder: (context, index) {
          if (index < _selectedImages.length) {
            return _buildImagePage(index);
          } else {
            return _buildAddPage();
          }
        },
      ),
    );
  }

  /// 构建图片页面
  Widget _buildImagePage(int index) {
    return GestureDetector(
      onTap: () => _showImagePreview(index),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: Image.memory(_imageBytes[index], fit: BoxFit.cover),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => _removeImage(index),
              child: Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${index + 1}/${_selectedImages.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建添加页面
  Widget _buildAddPage() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Icon(
                  Icons.add,
                  color: AppColors.accentRed,
                  size: 30,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '添加照片',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              if (_selectedImages.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${_selectedImages.length}/9',
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 显示图片预览
  void _showImagePreview(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            _ImagePreviewPage(imageBytes: _imageBytes, initialIndex: index),
      ),
    );
  }

  /// 选择图片方法
  Future<void> _pickImage() async {
    if (_selectedImages.length >= 9) {
      if (context.mounted) {
        AppErrorPresenter.showMessageToast(
          context,
          '最多只能上传9张照片',
          type: AppToastType.warning,
        );
      }
      return;
    }

    // On web, permission_handler is not supported —
    // the browser manages permissions natively via the file picker.
    if (kIsWeb) {
      await _pickFromGallery();
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('拍照'),
              onTap: () async {
                Navigator.pop(context);
                final status = await Permission.camera.request();
                if (status.isGranted) {
                  final XFile? photo = await _picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 80,
                  );
                  if (photo != null) {
                    await _handleSelectedImage(photo);
                  }
                } else {
                  if (context.mounted) {
                    AppErrorPresenter.showMessageToast(
                      context,
                      '需要相机权限才能拍照',
                      type: AppToastType.warning,
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('从相册选择'),
              onTap: () async {
                Navigator.pop(context);
                final status = await Permission.photos.request();
                if (status.isGranted) {
                  await _pickFromGallery();
                } else {
                  if (context.mounted) {
                    AppErrorPresenter.showMessageToast(
                      context,
                      '需要相册权限才能选择图片',
                      type: AppToastType.warning,
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 删除图片方法
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      _imageBytes.removeAt(index);
      _imageInfos.removeAt(index);
      if (_currentPageIndex >= _selectedImages.length) {
        _currentPageIndex = _selectedImages.isNotEmpty
            ? _selectedImages.length - 1
            : 0;
        _pageController.animateToPage(
          _currentPageIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  /// 处理选择的图片
  Future<void> _handleSelectedImage(XFile image) async {
    if (_selectedImages.length >= 9) {
      if (context.mounted) {
        AppErrorPresenter.showMessageToast(
          context,
          '最多只能上传9张照片',
          type: AppToastType.warning,
        );
      }
      return;
    }

    final bytes = await image.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final img = frame.image;

    setState(() {
      _selectedImages.add(image);
      _imageBytes.add(bytes);
      _imageInfos.add(img);
    });
  }

  /// 从相册选择图片（共用逻辑，适用于 Web 和 Native）
  Future<void> _pickFromGallery() async {
    final List<XFile> images = await _picker.pickMultiImage(imageQuality: 80);
    if (images.isNotEmpty) {
      final remainingSlots = 9 - _selectedImages.length;
      final imagesToAdd = images.take(remainingSlots).toList();
      for (final image in imagesToAdd) {
        await _handleSelectedImage(image);
      }
      if (images.length > remainingSlots && mounted) {
        AppErrorPresenter.showMessageToast(
          context,
          '最多只能上传9张照片，已添加前$remainingSlots张',
          type: AppToastType.warning,
        );
      }
    }
  }

  /// 构建下拉框容器
  Widget _buildDropdownContainer(Widget child) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: child,
    );
  }

  /// 构建通用下拉选择器组件
  /// [T] 下拉框数据类型
  /// [value] 当前选中的值
  /// [items] 下拉选项列表
  /// [hintText] 提示文字
  /// [isLoading] 是否正在加载
  /// [isEmpty] 数据是否为空
  /// [onTapEmpty] 当数据为空且未加载时的点击回调
  /// [onChanged] 选项变化回调
  /// [itemBuilder] 选项构建器
  Widget _buildDropdown<T>({
    required T? value,
    required List<T> items,
    required String hintText,
    required bool isLoading,
    required bool isEmpty,
    VoidCallback? onTapEmpty,
    required ValueChanged<T?>? onChanged,
    required Widget Function(T item) itemBuilder,
  }) {
    return GestureDetector(
      onTap: () {
        if (isEmpty && !isLoading && onTapEmpty != null) {
          onTapEmpty();
        }
      },
      child: _buildDropdownContainer(
        DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            hint: Text(
              isLoading ? '加载中...' : (isEmpty ? '点击加载' : hintText),
              style: const TextStyle(color: AppColors.textHint, fontSize: 14),
            ),
            value: value,
            isExpanded: true,
            icon: Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
            menuMaxHeight: 300,
            items: items.map((item) {
              return DropdownMenuItem<T>(value: item, child: itemBuilder(item));
            }).toList(),
            onChanged: isLoading ? null : onChanged,
          ),
        ),
      ),
    );
  }

  /// 选择图片方法构建省份下拉选择器组件
  Widget _buildProvinceDropdown() {
    final uploadState = ref.watch(activityUploadViewModelProvider);
    final controller = ref.read(activityUploadViewModelProvider.notifier);

    return _buildDropdown<ProvinceResponse>(
      value: uploadState.selectedProvince,
      items: uploadState.provinces,
      hintText: '请选择省份',
      isLoading: uploadState.isLoadingProvinces,
      isEmpty: uploadState.provinces.isEmpty,
      onTapEmpty: () {
        if (uploadState.provinces.isEmpty && !uploadState.isLoadingProvinces) {
          controller.loadProvinces();
        }
      },
      onChanged: controller.selectProvince,
      itemBuilder: (province) =>
          Text(province.name, style: const TextStyle(fontSize: 14)),
    );
  }

  /// 构建城市下拉选择器组件
  Widget _buildCityDropdown() {
    final uploadState = ref.watch(activityUploadViewModelProvider);
    final controller = ref.read(activityUploadViewModelProvider.notifier);

    return _buildDropdown<CityResponse>(
      value: uploadState.selectedCity,
      items: uploadState.cities,
      hintText: uploadState.selectedProvince == null ? '请先选择省份' : '请选择城市',
      isLoading: uploadState.isLoadingCities,
      isEmpty:
          uploadState.selectedProvince == null || uploadState.cities.isEmpty,
      onTapEmpty: () {
        final province = uploadState.selectedProvince;
        if (province != null &&
            uploadState.cities.isEmpty &&
            !uploadState.isLoadingCities) {
          controller.loadCities(province.id);
        }
      },
      onChanged:
          uploadState.selectedProvince != null && !uploadState.isLoadingCities
          ? controller.selectCity
          : null,
      itemBuilder: (city) =>
          Text(city.name, style: const TextStyle(fontSize: 14)),
    );
  }

  /// 构建完成按钮组件
  Widget _buildFinishButton() {
    final isSubmitting = ref.watch(
      activityUploadViewModelProvider.select((state) => state.isSubmitting),
    );

    return SizedBox(
      width: double.infinity,
      height: 66,
      child: ElevatedButton(
        onPressed: isSubmitting ? null : _handleFinish,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentRed,
          disabledBackgroundColor: AppColors.accentRed.withValues(alpha: 0.72),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(33),
          ),
          elevation: 0,
        ),
        child: isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Finish',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  /// 处理Finish按钮点击
  Future<void> _handleFinish() async {
    await ref
        .read(activityUploadViewModelProvider.notifier)
        .submit(
          foodName: _foodNameController.text,
          description: _descriptionController.text,
          images: List<XFile>.from(_selectedImages),
        );
  }

  void _handleUploadFeedback(ActivityUploadFeedback feedback) {
    if (!mounted) {
      return;
    }

    final toastType = switch (feedback.kind) {
      ActivityUploadFeedbackKind.success => AppToastType.success,
      ActivityUploadFeedbackKind.warning => AppToastType.warning,
      ActivityUploadFeedbackKind.error => AppToastType.error,
    };

    AppErrorPresenter.showMessageToast(
      context,
      feedback.content,
      type: toastType,
    );
  }

  void _resetLocalForm() {
    if (!mounted) {
      return;
    }

    setState(() {
      _selectedImages.clear();
      _imageBytes.clear();
      _imageInfos.clear();
      _foodNameController.clear();
      _descriptionController.clear();
      _shopNameController.clear();
      _currentPageIndex = 0;
    });

    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }

    ref.read(activityUploadViewModelProvider.notifier).resetSelections();
  }
}

/// 图片预览页面
class _ImagePreviewPage extends StatefulWidget {
  final List<Uint8List> imageBytes;
  final int initialIndex;

  const _ImagePreviewPage({
    required this.imageBytes,
    required this.initialIndex,
  });

  @override
  State<_ImagePreviewPage> createState() => _ImagePreviewPageState();
}

class _ImagePreviewPageState extends State<_ImagePreviewPage> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_currentIndex + 1}/${widget.imageBytes.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.imageBytes.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.memory(
                widget.imageBytes[index],
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }
}
