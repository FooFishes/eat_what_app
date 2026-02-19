import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:eat_what_app/core/api/model/result.dart';
import 'package:eat_what_app/core/error/api_exception.dart';
import 'package:eat_what_app/core/error/app_error_presenter.dart';
import 'package:eat_what_app/core/theme/app_colors.dart';
import 'package:eat_what_app/model/activity/regional_food.dart';
import 'package:eat_what_app/model/province/province.dart';
import 'package:flutter/material.dart';
import 'package:eat_what_app/model/province/province_dto.dart';

class FoodieMapPage extends StatefulWidget {
  const FoodieMapPage({super.key});

  @override
  State<FoodieMapPage> createState() => _FoodieMapPageState();
}

class _FoodieMapPageState extends State<FoodieMapPage> {
  int? localProvinceId;
  int? selectedProvinceId; //选择的省份 用于省份条UI及时更新
  int? committedProvinceId; //确认选择的省份 防抖处理
  late List<ProvinceDto> provinces;

  late bool _isInitialLoading;

  late bool _isProvincesBarLoading;
  late bool _hasProvincesBarError;

  Timer? _debounceTimer;
  static const debounceDuration = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    _isInitialLoading = true;
    _hasProvincesBarError = false;
    _isProvincesBarLoading = true;

    Future<int?> localProvinceIdFuture = _locate();
    Future<Result<List<ProvinceDto>>> provincesFuture = _fetchProvinces();

    Future.wait([localProvinceIdFuture, provincesFuture]).then((values) {
      if (!mounted) return;
      localProvinceId = values[0] as int?;
      var result = values[1] as Result<List<ProvinceDto>>;

      result.when(
        success: (data) {
          _hasProvincesBarError = false;
          provinces = generateDisplayProvinces(data, localProvinceId);
          selectedProvinceId = provinces.isEmpty ? null : provinces[0].id;
          committedProvinceId = selectedProvinceId;
        },
        failure: (error) {
          _hasProvincesBarError = true;
          provinces = [];
          selectedProvinceId = null;
          committedProvinceId = null;
          AppErrorPresenter.showErrorToast(context, error);
        },
      );

      _isProvincesBarLoading = false;
      setState(() {
        _isInitialLoading = false;
      });
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialLoading) {
      return Scaffold(
        body: SafeArea(
          child: FeatureTitle(
            "Foodie Map",
            child: Center(child: _buildLoadingIndicator(isLarge: true)),
          ),
        ),
      );
    }

    Widget provincesBar;
    if (_isProvincesBarLoading) {
      provincesBar = SizedBox(
        height: 60,
        width: double.infinity,
        child: Center(child: _buildLoadingIndicator()),
      );
    } else if (_hasProvincesBarError) {
      provincesBar = SizedBox(
        height: 60,
        width: double.infinity,
        child: Center(
          child: _buildRetryMessage(
            context,
            message: "省份加载失败",
            hint: "点击重试",
            onPressed: _loadProvinces,
          ),
        ),
      );
    } else if (provinces.isEmpty) {
      provincesBar = SizedBox(
        height: 60,
        width: double.infinity,
        child: Center(
          child: _buildRetryMessage(
            context,
            message: "暂无省份发布过美食",
            hint: "点击刷新",
            onPressed: _loadProvinces,
          ),
        ),
      );
    } else {
      provincesBar = _ProvincesBar(
        provinces: provinces,
        selectedProvinceId: selectedProvinceId,
        onChanged: (newProvinceId) {
          setState(() {
            selectedProvinceId = newProvinceId;
            committedProvinceId = null;
          });
          _debounce(() {
            if (!mounted) return;
            setState(() {
              committedProvinceId = newProvinceId;
            });
          }, debounceDuration);
        },
      );
    }

    return Scaffold(
      body: SafeArea(
        child: FeatureTitle(
          "Foodie Map",
          child: Column(
            children: [
              _FoodieMapHeader(localProvinceId),
              provincesBar,
              committedProvinceId == null
                  ? Spacer()
                  : _FoodList(
                      committedProvinceId!,
                      key: ValueKey(committedProvinceId),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  void _debounce(VoidCallback callback, Duration duration) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(duration, callback);
  }

  List<ProvinceDto> generateDisplayProvinces(List<ProvinceDto> list, int? id) {
    var newList = list
        .map(
          (item) => ProvinceDto(
            id: item.id,
            name: Province.fromId(item.id)?.shortName ?? item.name,
          ),
        )
        .toList(); //显示使用短名称

    if (id == null) return newList;

    newList.removeWhere((item) => item.id == id); //当前定位放在第一个
    newList.insert(
      0,
      ProvinceDto(id: id, name: Province.fromId(id)?.shortName ?? "未知省份"),
    );
    return newList;
  }

  Future<void> _loadProvinces() async {
    if (!mounted) return;
    if (_isProvincesBarLoading) return;

    setState(() {
      _isProvincesBarLoading = true;
    });

    var result = await _fetchProvinces();
    if (!mounted) return;
    result.when(
      success: (data) {
        _hasProvincesBarError = false;
        provinces = generateDisplayProvinces(data, localProvinceId);
        selectedProvinceId = provinces.isEmpty ? null : provinces[0].id;
        committedProvinceId = selectedProvinceId;
      },
      failure: (error) {
        _hasProvincesBarError = true;
        provinces = [];
        selectedProvinceId = null;
        committedProvinceId = null;
        AppErrorPresenter.showErrorToast(context, error);
      },
    );

    setState(() {
      _isProvincesBarLoading = false;
    });
  }

  Future<int?> _locate() async {
    //TODO: 获取当前定位的省份id
    await Future.delayed(Duration(milliseconds: 300));
    return 8;
  }

  Future<Result<List<ProvinceDto>>> _fetchProvinces() async {
    //TODO: 获取省份列表
    await Future.delayed(Duration(milliseconds: 5000));

    int type = 4;
    switch (type) {
      case 1:
        return Success([ProvinceDto(id: 1, name: "北京市")]);
      case 2:
        return Success([]);
      case 3:
        return Failure(NetworkException(message: "网络错误"));
      case _:
        String json =
            "[{\"id\":1,\"name\":\"北京市\"},{\"id\":2,\"name\":\"天津市\"},{\"id\":3,\"name\":\"河北省\"},{\"id\":4,\"name\":\"山西省\"},{\"id\":5,\"name\":\"内蒙古自治区\"},{\"id\":6,\"name\":\"辽宁省\"},{\"id\":7,\"name\":\"吉林省\"},{\"id\":8,\"name\":\"黑龙江省\"},{\"id\":9,\"name\":\"上海市\"},{\"id\":10,\"name\":\"江苏省\"},{\"id\":11,\"name\":\"浙江省\"},{\"id\":12,\"name\":\"安徽省\"},{\"id\":13,\"name\":\"福建省\"},{\"id\":14,\"name\":\"江西省\"},{\"id\":15,\"name\":\"山东省\"},{\"id\":16,\"name\":\"河南省\"},{\"id\":17,\"name\":\"湖北省\"},{\"id\":18,\"name\":\"湖南省\"},{\"id\":19,\"name\":\"广东省\"},{\"id\":20,\"name\":\"广西壮族自治区\"},{\"id\":21,\"name\":\"海南省\"},{\"id\":22,\"name\":\"重庆市\"},{\"id\":23,\"name\":\"四川省\"},{\"id\":24,\"name\":\"贵州省\"},{\"id\":25,\"name\":\"云南省\"},{\"id\":26,\"name\":\"西藏自治区\"},{\"id\":27,\"name\":\"陕西省\"},{\"id\":28,\"name\":\"甘肃省\"},{\"id\":29,\"name\":\"青海省\"},{\"id\":30,\"name\":\"宁夏回族自治区\"},{\"id\":31,\"name\":\"新疆维吾尔自治区\"}]";
        final decoded = jsonDecode(json) as List<dynamic>;
        return Success(decoded.map((e) => ProvinceDto.fromJson(e)).toList());
    }
  }
}

class _FoodieMapHeader extends StatelessWidget {
  final int? provinceId;

  const _FoodieMapHeader(this.provinceId);

  @override
  Widget build(BuildContext context) {
    Widget locationWidget;

    if (provinceId == null) {
      locationWidget = Positioned(
        left: 20,
        bottom: 30,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Icon(Icons.location_on, size: 30, color: AppColors.primaryStrong),
            Text(
              "未获取到当前位置",
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
    } else {
      String name = Province.fromId(provinceId!)?.shortName ?? "未知省份";
      double nameLeftPadding = switch (name.length) {
        //根据省份字数决定padding
        <= 2 => 50,
        == 3 => 40,
        _ => 0,
      };
      locationWidget = Positioned(
        left: 20,
        right: 60,
        bottom: 15,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Icon(
                  Icons.location_on,
                  size: 30,
                  color: AppColors.primaryStrong,
                ),
                Text(
                  "当前所在地：",
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.only(left: nameLeftPadding, top: 10),
              child: FittedBox(
                child: Text(
                  name,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: AppColors.accentRed,
                    letterSpacing: 8,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 200,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned(right: 10, top: 10, child: _buildChinaMap(provinceId)),
          locationWidget,
        ],
      ),
    );
  }

  Widget _buildChinaMap(int? provinceId) {
    String? code = provinceId == null
        ? null
        : Province.fromId(provinceId)?.code;
    String path = code == null
        ? "assets/images/china_map/base.png"
        : "assets/images/china_map/$code.png";
    return Image.asset(path, height: 170);
  }
}

class FeatureTitle extends StatelessWidget {
  final String title;
  final Widget child;

  const FeatureTitle(this.title, {required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        children: [
          child,
          InkWell(
            onTap: () => Navigator.pop(context),
            child: Image.asset("assets/images/firework.png", height: 50),
          ),

          Positioned(
            left: 30,
            top: 30,
            right: 10,

            child: Align(
              alignment: Alignment.topLeft,
              child: FittedBox(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProvincesBar extends StatelessWidget {
  final int? selectedProvinceId;
  final List<ProvinceDto> provinces;
  final void Function(int) onChanged;

  const _ProvincesBar({
    required this.provinces,
    required this.selectedProvinceId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      width: double.infinity,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: provinces.length,
        itemBuilder: (context, index) {
          int currentId = provinces[index].id;
          String currentName = provinces[index].name;
          bool isSelected = (currentId == selectedProvinceId);
          return Container(
            margin: EdgeInsets.fromLTRB(5, 10, 5, 10),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.textPrimary, width: 1),
              ),
              onPressed: () {
                if (isSelected) return;
                onChanged(currentId);
              },
              child: Text(
                currentName,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isSelected ? AppColors.accentRed : null,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FoodList extends StatefulWidget {
  final int provinceId;

  const _FoodList(this.provinceId, {super.key});

  @override
  State<_FoodList> createState() => _FoodListState();
}

class _FoodListState extends State<_FoodList> {
  static const debounceDuration = Duration(microseconds: 300);
  static const pageSize = 10;

  final List<RegionalFood> _regionalFoods = [];
  final ScrollController _scrollController = ScrollController();

  late bool _isLoading;
  late bool _hasError;

  late int _currentPage; //当前已加载的页数
  late bool _hasNext;

  Timer? _debounceTimer;

  double _lastScrollPosition = 0;

  @override
  void initState() {
    super.initState();
    _currentPage = 0;
    _isLoading = false;
    _hasNext = true;
    _hasError = false;
    _loadNextPage();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    double currentScrollPosition = _scrollController.position.pixels;
    if (currentScrollPosition > _lastScrollPosition &&
        currentScrollPosition >=
            _scrollController.position.maxScrollExtent - 150) {
      _debounce(_loadNextPage, debounceDuration);
    }
    _lastScrollPosition = currentScrollPosition;
  }

  Future<void> _loadNextPage() async {
    if (!mounted) return;
    if (_isLoading || !_hasNext) return;

    setState(() {
      _isLoading = true;
    });

    try {
      var (loadedRegionalFoods, hasNext) = await _fetchFoods(
        _currentPage + 1,
        pageSize,
        widget.provinceId,
      );
      _regionalFoods.addAll(loadedRegionalFoods);
      _hasNext = hasNext;
      _hasError = false;
      _currentPage++;
    } catch (error) {
      AppErrorPresenter.showErrorToast(context, error);
      _hasError = true;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _debounce(VoidCallback callback, Duration duration) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(duration, callback);
  }

  @override
  Widget build(BuildContext context) {
    if (_regionalFoods.isEmpty) {
      if (_isLoading) {
        return Expanded(
          child: Align(
            alignment: Alignment(0, -0.3),
            child: _buildLoadingIndicator(isLarge: true),
          ),
        );
      }
      if (_hasError) {
        return Expanded(
          child: Align(
            alignment: Alignment(0, -0.3),
            child: _buildRetryMessage(
              context,
              message: "加载失败",
              hint: "点击重试",
              onPressed: _loadNextPage,
            ),
          ),
        );
      }
      return Expanded(
        child: Align(
          alignment: Alignment(0, -0.3),
          child: _buildRetryMessage(
            context,
            message: "还没有人上传该地区的美食哦",
            hint: "点击刷新",
            onPressed: () async {
              _hasNext = true;
              _loadNextPage();
            },
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _regionalFoods.length + 1,
        itemBuilder: (context, index) {
          if (index < _regionalFoods.length) {
            return _FoodItem.fromObject(_regionalFoods[index]);
          } else if (_hasNext) {
            return Center(child: _buildLoadingIndicator());
          } else {
            return SizedBox(height: 5);
          }
        },
      ),
    );
  }

  Future<(List<RegionalFood>, bool)> _fetchFoods(
    //TODO: 分页获取美食列表
    int page,
    int pageSize,
    int provinceId,
  ) async {
    List<RegionalFood> regionalFoods = [];
    bool hasNext;

    int total = provinceId % 2 == 0 ? 0 : 17;
    if (provinceId % 3 == 0) total = 2;

    await Future.delayed(Duration(milliseconds: 1000));
    int startIndex = (page - 1) * pageSize;
    int endIndex = total - 1 < page * pageSize - 1
        ? total - 1
        : page * pageSize - 1;
    for (int i = startIndex; i <= endIndex; i++) {
      String description =
          "虽然都喜欢吃黏糊麻辣烫，但是我觉得老式麻辣烫更胜一筹。麻辣烫就应该配炸串，14岁第一次吃炸菜卷，我惊为天人。还有就是，宏宝莱降价";
      String url = "https://img95.699pic.com/photo/50093/6813.jpg_wh860.jpg";
      int id = i + provinceId * 1000;
      var item = RegionalFood(
        id: id,
        foodName: "老式麻辣烫 炸串",
        accountName: "矩阵合同没纠纷",
        accountId: 1,
        description: description,
        isLiked: id % 2 == 0,
        url: url,
      );
      regionalFoods.add(item);
    }
    hasNext = endIndex < total - 1;
    return (regionalFoods, hasNext);
  }
}

class _FoodItem extends StatefulWidget {
  final int id;
  final String foodName;
  final int accountId;
  final String accountName;
  final String description;
  final bool isLiked;
  final String url;

  const _FoodItem({
    required this.id,
    required this.foodName,
    required this.accountName,
    required this.accountId,
    required this.description,
    required this.isLiked,
    required this.url,
  });

  _FoodItem.fromObject(RegionalFood obj)
    : id = obj.id,
      foodName = obj.foodName,
      accountName = obj.accountName,
      accountId = obj.accountId,
      description = obj.description,
      isLiked = obj.isLiked,
      url = obj.url;

  @override
  State<_FoodItem> createState() => _FoodItemState();
}

class _FoodItemState extends State<_FoodItem> {
  late bool isLiked;

  late bool enable;
  static const timeoutDuration = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    isLiked = widget.isLiked;
    enable = true;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFF3EDD1),
        borderRadius: BorderRadius.circular(23),
      ),
      height: 135,
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(15, 5, 15, 5),
      padding: EdgeInsets.all(10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          double maxHeight = constraints.maxHeight;
          return Row(
            children: [
              Container(
                constraints: BoxConstraints(
                  minHeight: maxHeight * 0.8,
                  maxHeight: maxHeight * 0.8,
                  minWidth: maxHeight * 0.8,
                  maxWidth: maxHeight * 0.8,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: CachedNetworkImage(
                    imageUrl: widget.url,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) => Center(
                      child: Text(
                        "图片加载失败",
                        style: Theme.of(
                          context,
                        ).textTheme.labelMedium?.copyWith(),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FittedBox(
                              child: Text(
                                widget.foodName,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 18,
                                    ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 30,
                          height: 30,
                          child: IconButton(
                            onPressed: _onPressed,
                            padding: EdgeInsets.all(0),
                            icon: Icon(
                              size: 25,
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked
                                  ? AppColors.accentRed
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      widget.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Spacer(),
                    FittedBox(
                      child: Text(
                        widget.accountName,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Color(0xFFAAAAAA),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _onPressed() {
    _throttle(() async {
      if (!mounted) return;
      setState(() {
        isLiked = !isLiked;
      });
      Result<void> result = isLiked
          ? await _like(widget.id)
          : await _disLike(widget.id);
      result.when(
        success: (_) {},
        failure: (error) {
          if (!mounted) return;
          setState(() {
            isLiked = !isLiked;
          });
          AppErrorPresenter.showErrorToast(context, error);
        },
      );
    }, timeoutDuration);
  }

  void _throttle(Future<void> Function() callback, Duration duration) {
    if (!enable) return;
    enable = false;
    Future.wait([callback(), Future.delayed(duration)])
        .then((_) {
          enable = true;
        })
        .catchError((error, stackTrace) {
          enable = true;
        });
  }

  Future<Result<void>> _like(int id) async {
    //待实现: 点赞
    await Future.delayed(Duration(milliseconds: 500));
    return Success(null);
  }

  Future<Result<void>> _disLike(int id) async {
    //待实现: 取消点赞
    await Future.delayed(Duration(milliseconds: 500));
    return Success(null);
  }
}

Widget _buildLoadingIndicator({bool isLarge = false}) {
  double side = isLarge ? 50 : 20;
  double strokeWidth = isLarge ? 5 : 3;
  return Padding(
    padding: EdgeInsets.all(5),
    child: SizedBox(
      height: side,
      width: side,
      child: CircularProgressIndicator(strokeWidth: strokeWidth),
    ),
  );
}

Widget _buildRetryMessage(
  BuildContext context, {
  required String message,
  required String hint,
  required VoidCallback onPressed,
}) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
      ),
      TextButton(
        onPressed: onPressed,
        child: Text(
          hint,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.primary,
            decoration: TextDecoration.underline,
            decorationColor: AppColors.primary,
          ),
        ),
      ),
    ],
  );
}
