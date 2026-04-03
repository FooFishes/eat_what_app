import 'package:flutter/material.dart';
import 'package:flutter_baidu_mapapi_base/flutter_baidu_mapapi_base.dart';
import 'package:flutter_baidu_mapapi_map/flutter_baidu_mapapi_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  BMFMapController? _mapController;
  bool _shouldBuildMap = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _shouldBuildMap = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('地图页'), centerTitle: false),
      body: _shouldBuildMap
          ? BMFMapWidget(
              onBMFMapCreated: (controller) {
                _mapController = controller;
                debugPrint('百度地图加载完成');
              },
              mapOptions: BMFMapOptions(
                center: BMFCoordinate(30.5728, 104.0668), // 成都市中心 (GCJ-02)
                zoomLevel: 15,
                mapType: BMFMapType.Standard,
              ),
            )
          : Center(
              child: ElevatedButton(
                onPressed: () => _trigger,
                child: Text("触发"),
              ),
            ),
    );
  }

  void _trigger() {
    throw Exception("测试错误");
  }
}
