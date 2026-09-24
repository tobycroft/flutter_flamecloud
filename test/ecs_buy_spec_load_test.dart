import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_flamecloud/data/models/ecs.dart';
import 'package:flutter_flamecloud/data/repositories/ecs_repository.dart';
import 'package:flutter_flamecloud/features/ecs/ecs_buy_controller.dart';

/// 返回真实配置数据的仓库桩，用于验证初始化级联加载。
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
    return <EcsSpec>[
      const EcsSpec(id: 101, cpu: '2核', memory: '4GB'),
      const EcsSpec(id: 102, cpu: '4核', memory: '8GB'),
    ];
  }

  @override
  Future<List<EcsPeriod>> fetchPeriods() async {
    await Future<void>.delayed(const Duration(milliseconds: 15));
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
  test('init 应级联加载地域/可用区/规格', () async {
    final ProviderContainer container = ProviderContainer(
      overrides: [
        ecsRepositoryProvider.overrideWithValue(_DataEcsRepository()),
      ],
    );
    final EcsBuyController controller =
        container.read(ecsBuyControllerProvider.notifier);

    await controller.init();

    final EcsBuyState state = container.read(ecsBuyControllerProvider);
    // ignore: avoid_print
    print('regions=${state.regions.length} '
        'selectedRegionId=${state.selectedRegionId} '
        'zones=${state.zones.length} '
        'selectedZoneId=${state.selectedZoneId} '
        'specs=${state.specs.length} '
        'selectedSpecId=${state.selectedSpecId} '
        'configLoading=${state.configLoading}');

    expect(state.selectedRegionId, 1);
    expect(state.zones.length, 2);
    expect(state.selectedZoneId, 11);
    expect(state.specs.length, 2,
        reason: '规格应在初始化时自动加载，无需手动切换');
    expect(state.configLoading, isFalse);
  });
}
