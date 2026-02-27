import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/theme/app_colors.dart';
import '../../core/error/app_error_presenter.dart';
import '../../widget/app_toast.dart';
import '../../model/location/province_dto.dart';
import '../../model/location/city_dto.dart';
import '../../provider/repository_provider.dart';

/// 上传页面
/// 包含两个子页面：Campus页面和New Year页面
class UploadPage extends ConsumerStatefulWidget {
  const UploadPage({super.key});

  @override
  ConsumerState<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends ConsumerState<UploadPage> {
  /// 是否选中Campus选项卡
  bool _isCampusSelected = true;

  /// 是否点击了Enter按钮
  bool _hasClickedEnter = false;

  /// 图片选择器实例
  final ImagePicker _picker = ImagePicker();

  /// 已选择的图片文件列表
  List<File> _selectedImages = [];

  /// 图片尺寸信息列表
  List<ui.Image> _imageInfos = [];

  /// 轮播图控制器
  final PageController _pageController = PageController();

  /// 当前轮播页面索引
  int _currentPageIndex = 0;

  /// 选中的省份
  ProvinceDto? _selectedProvince;

  /// 选中的城市
  CityDto? _selectedCity;

  /// 省份列表
  List<ProvinceDto> _provinces = [];

  /// 城市列表
  List<CityDto> _cities = [];

  /// 菜品名称控制器
  final TextEditingController _foodNameController = TextEditingController();

  /// 菜品描述控制器
  final TextEditingController _descriptionController = TextEditingController();

  /// 店铺名称控制器
  final TextEditingController _shopNameController = TextEditingController();

  /// 是否正在加载
  bool _isLoading = false;

  /// 是否正在加载省份
  bool _isLoadingProvinces = false;

  /// 是否正在加载城市
  bool _isLoadingCities = false;

  @override
  void initState() {
    super.initState();
    _loadProvinces();
  }

  Future<void> _loadProvinces() async {
    if (_isLoadingProvinces || _provinces.isNotEmpty) return;

    setState(() {
      _isLoadingProvinces = true;
    });

    final repo = ref.read(locationRepositoryProvider);
    final result = await repo.getProvinces();

    if (mounted) {
      setState(() {
        _isLoadingProvinces = false;
      });
    }

    result.when(
      success: (provinces) {
        if (mounted) {
          setState(() {
            _provinces = provinces;
          });
        }
      },
      failure: (error) {
        if (mounted) {
          AppErrorPresenter.showErrorToast(context, error);
        }
      },
    );
  }

  Future<void> _loadCities(int provinceId) async {
    if (_isLoadingCities) return;

    setState(() {
      _isLoadingCities = true;
    });

    final repo = ref.read(locationRepositoryProvider);
    final result = await repo.getCities(provinceId);

    if (mounted) {
      setState(() {
        _isLoadingCities = false;
      });
    }

    result.when(
      success: (cities) {
        if (mounted) {
          setState(() {
            _cities = cities;
          });
        }
      },
      failure: (error) {
        if (mounted) {
          AppErrorPresenter.showErrorToast(context, error);
        }
      },
    );
  }

  @override
  void dispose() {
    _selectedImages.clear();
    _imageInfos.clear();
    _pageController.dispose();
    _selectedProvince = null;
    _selectedCity = null;
    _foodNameController.dispose();
    _descriptionController.dispose();
    _shopNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('上传页')),
      body: Padding(
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 125,
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
    // 示例店铺数据列表
    final shops = [
      {
        'name': '袁记云饺（高新万达店）',
        'rating': 5.0,
        'collection': '200+人次收藏该店铺',
        'monthly': '月售500+',
      },
      {
        'name': '袁记云饺（软件园内店）',
        'rating': 5.0,
        'collection': '200+人次收藏该店铺',
        'monthly': '月售500+',
      },
      {
        'name': '袁记云饺（章丘区店）',
        'rating': 5.0,
        'collection': '200+人次收藏该店铺',
        'monthly': '月售500+',
      },
    ];

    return Column(
      children: [
        _buildSearchBar(),
        const SizedBox(height: 5),
        Expanded(
          // 未点击Enter时显示说明卡片，点击后显示店铺列表
          child: _hasClickedEnter
              ? _buildShopList(shops)
              : _buildInstructionCard(),
        ),
      ],
    );
  }

  /// 构建搜索栏组件
  Widget _buildSearchBar() {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.only(right: 80),
          child: TextField(
            decoration: InputDecoration(
              hintText: '请输入店铺名称',
              hintStyle: TextStyle(color: AppColors.textHint),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
        Positioned(
          right: 8,
          top: 4,
          bottom: 4,
          child: ElevatedButton(
            onPressed: () => setState(() => _hasClickedEnter = true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text('Enter'),
          ),
        ),
      ],
    );
  }

  /// 构建说明卡片组件
  Widget _buildInstructionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Center(
                  child: Transform.rotate(
                    angle: -0.05,
                    child: _buildNewYearCard(),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HOW',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 48,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.primary,
                      ),
                    ),
                    _buildStepCard('搜索店铺名称，判断是否已被上传', 'Step1', true),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildStepCard(
            '如果是已被上传的店铺，你只能添加新菜品\n如果店铺未上传，你需要添加新店铺并添加菜品哦',
            'Step2',
            false,
          ),
        ],
      ),
    );
  }

  /// 构建新年专题卡片组件
  Widget _buildNewYearCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          children: const [
            TextSpan(text: '新年将至\n我们还添加了\n'),
            TextSpan(
              text: '新年专题',
              style: TextStyle(color: AppColors.accentRed),
            ),
            TextSpan(text: '哦\n欢迎来体验'),
          ],
        ),
      ),
    );
  }

  /// 构建步骤卡片组件
  /// [text] 步骤的详细说明文字
  /// [label] 步骤标签
  /// [isRight] 标签是否显示在右侧，false则显示在左侧
  Widget _buildStepCard(String text, String label, bool isRight) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 4),
          margin: const EdgeInsets.only(top: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            text,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
          ),
        ),
        Positioned(
          top: 0,
          right: isRight ? 16 : null,
          left: isRight ? null : 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            color: AppColors.surface,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 构建店铺列表组件
  /// [shops] 店铺数据列表
  Widget _buildShopList(List<Map<String, dynamic>> shops) {
    return Column(
      children: [
        _buildAddShopButton(),
        Expanded(
          child: ListView.builder(
            itemCount: shops.length,
            itemBuilder: (context, index) => _buildShopItem(shops[index]),
          ),
        ),
      ],
    );
  }

  /// 构建添加店铺按钮组件
  Widget _buildAddShopButton() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(30),
      ),
      height: 50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '没有找到你想的店铺？点击添加',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  /// 构建单个店铺项组件
  /// [shop] 店铺数据
  Widget _buildShopItem(Map<String, dynamic> shop) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          _buildShopLogo(),
          const SizedBox(width: 12),
          Expanded(child: _buildShopInfo(shop)),
        ],
      ),
    );
  }

  /// 构建店铺Logo组件
  Widget _buildShopLogo() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          '袁记云饺',
          style: TextStyle(
            color: AppColors.primaryStrong,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// 构建店铺信息组件
  /// [shop] 店铺数据
  /// 显示店铺名称、评分、收藏数和月售量
  Widget _buildShopInfo(Map<String, dynamic> shop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          shop['name'],
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.star, color: Colors.yellow[600], size: 14),
            const SizedBox(width: 4),
            Text(
              '${shop['rating']}',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          shop['collection'],
          style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
        ),
        Text(
          shop['monthly'],
          style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
        ),
      ],
    );
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
          const SizedBox(height: 210),
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
              child: Image.file(_selectedImages[index], fit: BoxFit.cover),
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
            _ImagePreviewPage(images: _selectedImages, initialIndex: index),
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: EdgeInsets.only(
          bottom: 100 + MediaQuery.of(context).padding.bottom,
        ),
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
                  final List<XFile> images = await _picker.pickMultiImage(
                    imageQuality: 80,
                  );
                  if (images.isNotEmpty) {
                    final remainingSlots = 9 - _selectedImages.length;
                    final imagesToAdd = images.take(remainingSlots).toList();
                    for (var image in imagesToAdd) {
                      await _handleSelectedImage(image);
                    }
                    if (images.length > remainingSlots && context.mounted) {
                      AppErrorPresenter.showMessageToast(
                        context,
                        '最多只能上传9张照片，已添加前$remainingSlots张',
                        type: AppToastType.warning,
                      );
                    }
                  }
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
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// 删除图片方法
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
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
      _selectedImages.add(File(image.path));
      _imageInfos.add(img);
    });
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
    return _buildDropdown<ProvinceDto>(
      value: _selectedProvince,
      items: _provinces,
      hintText: '请选择省份',
      isLoading: _isLoadingProvinces,
      isEmpty: _provinces.isEmpty,
      onTapEmpty: () {
        if (_provinces.isEmpty && !_isLoadingProvinces) {
          _loadProvinces();
        }
      },
      onChanged: (ProvinceDto? newValue) {
        setState(() {
          _selectedProvince = newValue;
          _selectedCity = null;
          _cities = [];
          if (newValue != null) {
            _loadCities(newValue.id);
          }
        });
      },
      itemBuilder: (province) =>
          Text(province.name, style: const TextStyle(fontSize: 14)),
    );
  }

  /// 构建城市下拉选择器组件
  Widget _buildCityDropdown() {
    return _buildDropdown<CityDto>(
      value: _selectedCity,
      items: _cities,
      hintText: _selectedProvince == null ? '请先选择省份' : '请选择城市',
      isLoading: _isLoadingCities,
      isEmpty: _selectedProvince == null || _cities.isEmpty,
      onTapEmpty: () {
        if (_selectedProvince != null && _cities.isEmpty && !_isLoadingCities) {
          _loadCities(_selectedProvince!.id);
        }
      },
      onChanged: _selectedProvince != null && !_isLoadingCities
          ? (CityDto? newValue) {
              setState(() {
                _selectedCity = newValue;
              });
            }
          : null,
      itemBuilder: (city) =>
          Text(city.name, style: const TextStyle(fontSize: 14)),
    );
  }

  /// 构建完成按钮组件
  Widget _buildFinishButton() {
    return SizedBox(
      width: double.infinity,
      height: 66,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleFinish,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentRed,
          disabledBackgroundColor: AppColors.accentRed.withValues(alpha: 0.72),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(33),
          ),
          elevation: 0,
        ),
        child: _isLoading
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
    final validationError = _validateForm();
    if (validationError != null) {
      if (mounted) {
        AppErrorPresenter.showMessageToast(
          context,
          validationError,
          type: AppToastType.warning,
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final foodName = _foodNameController.text.trim();
    final description = _descriptionController.text.trim();

    try {
      final uploadRepo = ref.read(uploadRepositoryProvider);

      final fileInfos = <Map<String, dynamic>>[];
      for (var i = 0; i < _selectedImages.length; i++) {
        final file = _selectedImages[i];
        final fileName = file.path.split(Platform.pathSeparator).last;
        final fileBytes = await file.readAsBytes();
        final contentType = _getMimeType(fileName);

        fileInfos.add({
          'fileName': fileName,
          'contentType': contentType,
          'fileSize': fileBytes.length,
        });
      }

      final presignResult = await uploadRepo.presignBatchUpload(
        biz: 'activity',
        files: fileInfos,
      );

      if (!presignResult.isSuccess) {
        if (mounted) {
          AppErrorPresenter.showErrorToast(context, presignResult.error!);
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final presignData = presignResult.data!;
      final uploadedKeys = <String>[];

      for (var i = 0; i < _selectedImages.length; i++) {
        final file = _selectedImages[i];
        final presignInfo = presignData.files[i];
        final contentType = _getMimeType(
          file.path.split(Platform.pathSeparator).last,
        );

        final uploadResult = await uploadRepo.uploadFileToPresignedUrl(
          putUrl: presignInfo.putUrl,
          file: file,
          contentType: contentType,
        );

        if (!uploadResult.isSuccess) {
          if (mounted) {
            AppErrorPresenter.showErrorToast(context, uploadResult.error!);
          }
          setState(() {
            _isLoading = false;
          });
          return;
        }

        uploadedKeys.add(presignInfo.key);
      }

      final activityRepo = ref.read(activityRepositoryProvider);
      final createResult = await activityRepo.createActivityFood(
        foodName: foodName,
        description: description.isEmpty ? null : description,
        provinceId: _selectedProvince!.id,
        cityId: _selectedCity!.id,
        pictureUrl: uploadedKeys,
      );

      if (!createResult.isSuccess) {
        if (mounted) {
          AppErrorPresenter.showErrorToast(context, createResult.error!);
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      if (mounted) {
        AppErrorPresenter.showMessageToast(
          context,
          '发布成功！',
          type: AppToastType.success,
        );
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        AppErrorPresenter.showMessageToast(
          context,
          '上传失败: $e',
          type: AppToastType.error,
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 根据文件名获取MIME类型
  String _getMimeType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'bmp':
        return 'image/bmp';
      default:
        return 'image/jpeg';
    }
  }

  /// 验证表单
  String? _validateForm() {
    if (_foodNameController.text.trim().isEmpty) {
      return '请输入菜品名称';
    }

    if (_selectedImages.isEmpty) {
      return '请至少上传一张菜品照片';
    }

    if (_selectedProvince == null) {
      return '请选择省份';
    }

    if (_selectedCity == null) {
      return '请选择城市';
    }

    return null;
  }
}

/// 图片预览页面
class _ImagePreviewPage extends StatefulWidget {
  final List<File> images;
  final int initialIndex;

  const _ImagePreviewPage({required this.images, required this.initialIndex});

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
          '${_currentIndex + 1}/${widget.images.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
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
              child: Image.file(widget.images[index], fit: BoxFit.contain),
            ),
          );
        },
      ),
    );
  }
}
