import 'dart:async';
import 'dart:typed_data';

import 'package:eat_what_app/core/constant/urls.dart';
import 'package:eat_what_app/core/error/app_error_presenter.dart';
import 'package:eat_what_app/core/theme/app_colors.dart';
import 'package:eat_what_app/model/location/city_response.dart';
import 'package:eat_what_app/model/location/province_response.dart';
import 'package:eat_what_app/model/user/update_user_info_request.dart';
import 'package:eat_what_app/model/user/user_info_response.dart';
import 'package:eat_what_app/provider/auth_provider.dart';
import 'package:eat_what_app/provider/navigation_bar_provider.dart';
import 'package:eat_what_app/provider/repository_provider.dart';
import 'package:eat_what_app/widget/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class ProfileInfoPage extends ConsumerStatefulWidget {
  const ProfileInfoPage({super.key});

  @override
  ConsumerState<ProfileInfoPage> createState() => _ProfileInfoPageState();
}

class _ProfileInfoPageState extends ConsumerState<ProfileInfoPage> {
  UserInfoResponse? _userInfo;
  List<ProvinceResponse> _provinces = const [];
  List<CityResponse> _cities = const [];

  bool _isLoading = true;
  bool _isLoadingLocations = false;
  bool _isUploadingAvatar = false;
  Object? _error;
  Uint8List? _avatarPreviewBytes;

  @override
  void initState() {
    super.initState();
    _loadPage();
  }

  Future<void> _loadPage() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userInfo = await ref.read(userRepositoryProvider).getUserInfo();
      List<ProvinceResponse> provinces = const [];
      List<CityResponse> cities = const [];

      if (userInfo.hometownProvinceId != null) {
        provinces = await ref.read(locationRepositoryProvider).getProvinces();
        cities = await ref
            .read(locationRepositoryProvider)
            .getCities(userInfo.hometownProvinceId!);
      }

      if (!mounted) return;

      setState(() {
        _userInfo = userInfo;
        _provinces = provinces;
        _cities = cities;
        _isLoading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = error;
      });
    }
  }

  Future<void> _saveField(UpdateUserInfoRequest request) async {
    try {
      await ref.read(userRepositoryProvider).updateUserInfo(request);
      final refreshed = await ref.read(userRepositoryProvider).getUserInfo();
      if (!mounted) return;
      setState(() => _userInfo = refreshed);
      AppErrorPresenter.showMessageToast(
        context,
        '已保存',
        type: AppToastType.success,
      );
    } catch (error) {
      if (!mounted) return;
      AppErrorPresenter.showErrorToast(context, error);
    }
  }

  Future<void> _editAvatar() async {
    if (_isUploadingAvatar) {
      return;
    }

    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 92,
      maxWidth: 1440,
      maxHeight: 1440,
    );

    if (!mounted || image == null) {
      return;
    }

    setState(() => _isUploadingAvatar = true);

    try {
      final previewBytes = await image.readAsBytes();
      if (!mounted) {
        return;
      }
      setState(() => _avatarPreviewBytes = previewBytes);

      final avatarKey = await ref
          .read(userRepositoryProvider)
          .uploadAvatar(image);
      if (!mounted) {
        return;
      }

      await _saveField(UpdateUserInfoRequest(avatar: avatarKey));
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppErrorPresenter.showErrorToast(context, error);
    } finally {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
      }
    }
  }

  Future<void> _openAuthPage() async {
    await context.push('/auth');
    if (!mounted) return;
    await _loadPage();
  }

  Future<void> _ensureLocationsLoaded() async {
    if (_isLoadingLocations || _provinces.isNotEmpty) return;

    setState(() => _isLoadingLocations = true);

    try {
      final provinces = await ref
          .read(locationRepositoryProvider)
          .getProvinces();

      if (!mounted) return;

      setState(() => _provinces = provinces);

      final provinceId = _userInfo?.hometownProvinceId;
      if (provinceId != null) {
        final cities = await ref
            .read(locationRepositoryProvider)
            .getCities(provinceId);

        if (!mounted) return;
        setState(() => _cities = cities);
      }
    } catch (error) {
      if (mounted) AppErrorPresenter.showErrorToast(context, error);
    } finally {
      if (mounted) setState(() => _isLoadingLocations = false);
    }
  }

  Future<void> _editNickname() async {
    final currentName = _userInfo?.userName ?? '';
    String draftName = currentName;
    var checkState = _UsernameCheckState.idle;
    Timer? debounce;

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void scheduleCheck(String value) {
              debounce?.cancel();
              final trimmed = value.trim();
              if (trimmed == currentName ||
                  trimmed.length < 3 ||
                  trimmed.length > 10) {
                setDialogState(() => checkState = _UsernameCheckState.idle);
                return;
              }
              setDialogState(() => checkState = _UsernameCheckState.loading);
              debounce = Timer(const Duration(milliseconds: 500), () async {
                try {
                  await ref.read(authRepositoryProvider).checkUsername(trimmed);
                  if (dialogContext.mounted) {
                    setDialogState(
                      () => checkState = _UsernameCheckState.available,
                    );
                  }
                } catch (_) {
                  if (dialogContext.mounted) {
                    setDialogState(
                      () => checkState = _UsernameCheckState.unavailable,
                    );
                  }
                }
              });
            }

            Widget? suffixIcon = switch (checkState) {
              _UsernameCheckState.loading => const SizedBox(
                width: 18,
                height: 18,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              _UsernameCheckState.available => const Icon(
                Icons.check_circle_outline_rounded,
                color: Colors.green,
              ),
              _UsernameCheckState.unavailable => const Icon(
                Icons.cancel_outlined,
                color: Colors.red,
              ),
              _UsernameCheckState.idle => null,
            };

            return AlertDialog(
              backgroundColor: AppColors.surfaceAlt,
              title: const Text('修改昵称'),
              content: TextFormField(
                autofocus: true,
                initialValue: draftName,
                maxLength: 10,
                decoration: InputDecoration(
                  hintText: '请输入昵称',
                  suffixIcon: suffixIcon,
                ),
                onChanged: (value) {
                  draftName = value;
                  scheduleCheck(value);
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: checkState == _UsernameCheckState.unavailable
                      ? null
                      : () => Navigator.of(context).pop(draftName.trim()),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryStrong,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('确定'),
                ),
              ],
            );
          },
        );
      },
    );

    debounce?.cancel();
    if (!mounted || result == null) return;

    if (result.length < 3 || result.length > 10) {
      AppErrorPresenter.showMessageToast(
        context,
        '昵称长度需在 3 到 10 个字符之间',
        type: AppToastType.warning,
      );
      return;
    }

    await _saveField(UpdateUserInfoRequest(userName: result));
  }

  Future<void> _editGender() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surfaceAlt,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SheetActionTile(
                  label: '男',
                  onTap: () => Navigator.of(context).pop('male'),
                ),
                _SheetActionTile(
                  label: '女',
                  onTap: () => Navigator.of(context).pop('female'),
                ),
                _SheetActionTile(
                  label: '其他',
                  onTap: () => Navigator.of(context).pop('other'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || result == null) return;
    await _saveField(UpdateUserInfoRequest(gender: result));
  }

  Future<void> _editBirthday() async {
    final initialDate =
        DateTime.tryParse(_userInfo?.birthday ?? '') ??
        DateTime(DateTime.now().year - 20, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1970),
      lastDate: DateTime.now(),
    );

    if (!mounted || picked == null) return;
    await _saveField(UpdateUserInfoRequest(birthday: _formatDate(picked)));
  }

  Future<void> _editHometown() async {
    await _ensureLocationsLoaded();
    if (!mounted) return;

    int? tempProvinceId = _userInfo?.hometownProvinceId;
    int? tempCityId = _userInfo?.hometownCityId;
    List<CityResponse> tempCities = List<CityResponse>.from(_cities);
    bool loadingCities = false;

    final result = await showModalBottomSheet<_HometownSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceAlt,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> onProvinceChanged(int? value) async {
              setModalState(() {
                tempProvinceId = value;
                tempCityId = null;
                tempCities = const [];
                loadingCities = value != null;
              });

              if (value == null) return;

              try {
                final cities = await ref
                    .read(locationRepositoryProvider)
                    .getCities(value);
                if (!sheetContext.mounted) return;
                setModalState(() {
                  tempCities = cities;
                  loadingCities = false;
                });
              } catch (error) {
                if (!sheetContext.mounted) return;
                setModalState(() => loadingCities = false);
                if (!mounted) return;
                AppErrorPresenter.showErrorToast(this.context, error);
              }
            }

            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  24 + MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '选择家乡',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _DropdownField<int>(
                      label: '省份',
                      value: tempProvinceId,
                      items: _provinces
                          .map(
                            (province) => DropdownMenuItem<int>(
                              value: province.id,
                              child: Text(province.name),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: onProvinceChanged,
                    ),
                    const SizedBox(height: 14),
                    _DropdownField<int>(
                      label: '城市',
                      value: tempCityId,
                      loading: loadingCities,
                      items: tempCities
                          .map(
                            (city) => DropdownMenuItem<int>(
                              value: city.id,
                              child: Text(city.name),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: tempProvinceId == null
                          ? null
                          : (value) async {
                              setModalState(() => tempCityId = value);
                            },
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(
                              sheetContext,
                            ).pop(const _HometownSelection()),
                            child: const Text('清空'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              Navigator.of(sheetContext).pop(
                                _HometownSelection(
                                  provinceId: tempProvinceId,
                                  cityId: tempCityId,
                                  cities: tempCities,
                                ),
                              );
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primaryStrong,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('确定'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted || result == null) return;

    if (result.provinceId != null && result.cityId == null) {
      AppErrorPresenter.showMessageToast(
        context,
        '请选择完整的家乡城市信息',
        type: AppToastType.warning,
      );
      return;
    }

    setState(() => _cities = result.cities);
    await _saveField(
      UpdateUserInfoRequest(
        hometownProvinceId: result.provinceId,
        hometownCityId: result.cityId,
      ),
    );
  }

  Future<void> _showSettingsSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceAlt,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!(_userInfo?.verified ?? false))
                  _SheetActionTile(
                    label: '前往认证',
                    onTap: () async {
                      Navigator.of(context).pop();
                      await _openAuthPage();
                    },
                  ),
                _SheetActionTile(
                  label: '退出登录',
                  danger: true,
                  onTap: () async {
                    Navigator.of(context).pop();
                    await ref.read(authProvider.notifier).logout();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  @override
  Widget build(BuildContext context) {
    final userInfo = _userInfo;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null || userInfo == null
            ? _ProfileInfoErrorState(onRetry: _loadPage)
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 12, 0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            context.pop();
                            ref
                                .read(navigationBarProvider.notifier)
                                .showNavigationBar();
                          },
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(22, 8, 22, 32),
                      children: [
                        _ProfileInfoHero(
                          userInfo: userInfo,
                          avatarPreviewBytes: _avatarPreviewBytes,
                          isUploadingAvatar: _isUploadingAvatar,
                          onEditAvatar: _editAvatar,
                        ),
                        const SizedBox(height: 26),
                        _InfoGroup(
                          children: [
                            _InfoRowTile(
                              label: '昵称',
                              value: userInfo.userName,
                              onTap: _editNickname,
                            ),
                            _InfoRowTile(
                              label: '学号',
                              value: userInfo.studentId,
                              onTap: () {
                                AppErrorPresenter.showMessageToast(
                                  context,
                                  '学号由认证结果生成，当前不支持修改',
                                  type: AppToastType.info,
                                );
                              },
                            ),
                            _InfoRowTile(
                              label: '性别',
                              value: switch (userInfo.gender) {
                                'male' => '男',
                                'female' => '女',
                                'other' => '其他',
                                _ => '未设置',
                              },
                              onTap: _editGender,
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _InfoGroup(
                          children: [
                            _InfoRowTile(
                              label: '生日',
                              value: userInfo.birthday ?? '未设置',
                              onTap: _editBirthday,
                            ),
                            _InfoRowTile(
                              label: '家乡',
                              value: () {
                                final hometown =
                                    [
                                          userInfo.hometownProvinceName,
                                          userInfo.hometownCityName,
                                        ]
                                        .whereType<String>()
                                        .where((s) => s.isNotEmpty)
                                        .join('');
                                return hometown.isEmpty ? '未设置' : hometown;
                              }(),
                              onTap: _editHometown,
                            ),
                            _InfoRowTile(
                              label: '认证状态',
                              value: userInfo.verified ? '已认证' : '未认证',
                              onTap: userInfo.verified
                                  ? () {
                                      AppErrorPresenter.showMessageToast(
                                        context,
                                        '当前账号已完成认证',
                                        type: AppToastType.success,
                                      );
                                    }
                                  : _openAuthPage,
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _InfoGroup(
                          children: [
                            _InfoRowTile(
                              label: '设置',
                              value: '',
                              onTap: _showSettingsSheet,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ProfileInfoHero extends StatelessWidget {
  const _ProfileInfoHero({
    required this.userInfo,
    required this.onEditAvatar,
    this.avatarPreviewBytes,
    this.isUploadingAvatar = false,
  });

  final UserInfoResponse userInfo;
  final VoidCallback onEditAvatar;
  final Uint8List? avatarPreviewBytes;
  final bool isUploadingAvatar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _ProfileAvatar(
            avatar: userInfo.avatar,
            name: userInfo.userName,
            size: 108,
            previewBytes: avatarPreviewBytes,
          ),
          Positioned(
            right: -4,
            bottom: -4,
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              elevation: 2,
              child: IconButton(
                onPressed: isUploadingAvatar ? null : onEditAvatar,
                tooltip: '更换头像',
                iconSize: 18,
                constraints: const BoxConstraints.tightFor(
                  width: 38,
                  height: 38,
                ),
                icon: isUploadingAvatar
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.edit_outlined),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoGroup extends StatelessWidget {
  const _InfoGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E8),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRowTile extends StatelessWidget {
  const _InfoRowTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Row(
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileInfoErrorState extends StatelessWidget {
  const _ProfileInfoErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.person_off_rounded,
              size: 54,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            Text('个人资料加载失败', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              '请稍后重试',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            OutlinedButton(onPressed: onRetry, child: const Text('重新加载')),
          ],
        ),
      ),
    );
  }
}

class _SheetActionTile extends StatelessWidget {
  const _SheetActionTile({
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onTap: onTap,
      title: Text(
        label,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: danger ? AppColors.accentRed : AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.loading = false,
  });

  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final Future<void> Function(T? value)? onChanged;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE6D9AF)),
          ),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<T>(
                    value: items.any((item) => item.value == value)
                        ? value
                        : null,
                    isExpanded: true,
                    hint: const Text('请选择'),
                    items: items,
                    onChanged: onChanged == null
                        ? null
                        : (value) async {
                            await onChanged!(value);
                          },
                  ),
                ),
              ),
              if (loading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HometownSelection {
  const _HometownSelection({
    this.provinceId,
    this.cityId,
    this.cities = const [],
  });

  final int? provinceId;
  final int? cityId;
  final List<CityResponse> cities;
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.avatar,
    required this.name,
    required this.size,
    this.previewBytes,
  });

  final String? avatar;
  final String name;
  final double size;
  final Uint8List? previewBytes;

  @override
  Widget build(BuildContext context) {
    if (previewBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: Image.memory(
          previewBytes!,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }

    final avatarUrl = Urls.resolvePublicAssetUrl(avatar);

    if (avatarUrl == null) {
      return _AvatarPlaceholder(name: name, size: size);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: Image.network(
        avatarUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _AvatarPlaceholder(name: name, size: size),
      ),
    );
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder({required this.name, required this.size});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '我' : name.trim().characters.first;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE9BC), Color(0xFFFFC56F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Text(
        initial,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: AppColors.accentBrown,
        ),
      ),
    );
  }
}

enum _UsernameCheckState { idle, loading, available, unavailable }
