import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_flamecloud/data/models/ecs.dart';
import 'package:flutter_flamecloud/data/repositories/ecs_repository.dart';
import 'package:flutter_flamecloud/features/ecs/ecs_buy_page.dart';

/// 返回真实配置数据的仓库桩，用于验证首屏级联加载与渲染。
class _DataEcsRepository extends EcsRepository {
  _DataEcsRepository() : super(Dio());

  @override
  Future<List<EcsRegion>> fetchRegions() async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return <EcsRegion>[
      const EcsRegion(id: 1, name: '华东1（杭州）', value: 'cn-hangzhou'),
    ];
  }

  @override
  Future<List<EcsZone>> fetchZones(int regionId) async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return <EcsZone>[
      const EcsZone(id: 11, name: '华东一区'),
      const EcsZone(id: 12, name: '华东二区'),
    ];
  }

  @override
  Future<List<EcsSpec>> fetchSpecs({
    required int regionId,
    int? zoneId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    // 仅当可用区参数正确时返回规格，用于暴露自动加载链路是否传入了错误的 zoneId。
    if (zoneId != 11) {
      return const <EcsSpec>[];
    }
    return <EcsSpec>[
      const EcsSpec(id: 101, cpu: '2核', memory: '4GB'),
      const EcsSpec(id: 102, cpu: '4核', memory: '8GB'),
    ];
  }

  @override
  Future<List<EcsPeriod>> fetchPeriods() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return const <EcsPeriod>[
      EcsPeriod(month: 1, label: '1个月', discount: 1),
    ];
  }

  @override
  Future<EcsPrice> fetchPrice(Map<String, Object?> params) async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return const EcsPrice(
      specPrice: '10.00',
      diskPrice: '0.00',
      bandwidthPrice: '0.00',
      imagePrice: '0.00',
      imageRemark: '',
      monthlyBase: '10.00',
      purchaseCount: 1,
      purchasePeriod: 1,
      originalPrice: '10.00',
      discountRate: '1',
      totalPrice: '10.00',
    );
  }
}

void main() {
  testWidgets('进入创建页后首屏应自动加载并渲染规格', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ecsRepositoryProvider.overrideWithValue(_DataEcsRepository()),
        ],
        child: const MaterialApp(home: EcsBuyPage()),
      ),
    );
    // 等待 addPostFrameCallback + 全部异步级联收敛。
    await tester.pumpAndSettle();

    // 规格文案（CPU + 内存拼接）应直接出现在首屏，无需手动切换。
    expect(find.text('2核 4GB'), findsWidgets,
        reason: '首屏应自动渲染规格，规格不应为空或停留在加载态');
    expect(find.text('4核 8GB'), findsWidgets);
    expect(find.text('华东一区'), findsWidgets);
  });
}
