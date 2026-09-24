import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_flamecloud/core/net/api_exception.dart';
import 'package:flutter_flamecloud/core/router/app_router.dart';
import 'package:flutter_flamecloud/data/models/ecs.dart';
import 'package:flutter_flamecloud/data/models/ecs_instance.dart';
import 'package:flutter_flamecloud/data/repositories/ecs_repository.dart';
import 'package:flutter_flamecloud/features/ecs/ecs_instance_controller.dart';
import 'package:flutter_flamecloud/features/ecs/ecs_page.dart';

/// 实例列表桩：固定一台实例，`load` 无副作用，避免测试触发网络请求。
class _StubEcsInstanceController extends EcsInstanceController {
  @override
  EcsInstanceState build() => const EcsInstanceState(
    items: <EcsInstance>[
      EcsInstance(
        id: 1,
        instanceId: 'ecs-flame-001',
        instanceName: 'ECS-flame-001',
        region: 'cn-hangzhou',
        status: 'running',
        createdAt: '2026-09-01 10:00:00',
      ),
    ],
  );

  @override
  Future<void> load() async {}
}

/// ECS 仓库桩：所有请求立即抛 [ApiException]，保证创建页不触网也能渲染。
class _StubEcsRepository extends EcsRepository {
  _StubEcsRepository() : super(Dio());

  @override
  Future<List<EcsRegion>> fetchRegions() async =>
      throw const ApiException(0, 'stub');

  @override
  Future<List<EcsZone>> fetchZones(int regionId) async =>
      throw const ApiException(0, 'stub');

  @override
  Future<List<EcsSpec>> fetchSpecs({
    required int regionId,
    int? zoneId,
  }) async => throw const ApiException(0, 'stub');

  @override
  Future<List<EcsPeriod>> fetchPeriods() async =>
      throw const ApiException(0, 'stub');

  @override
  Future<EcsPrice> fetchPrice(Map<String, Object?> params) async =>
      throw const ApiException(0, 'stub');

  @override
  Future<List<EcsInstance>> fetchInstances() async =>
      throw const ApiException(0, 'stub');
}

void main() {
  testWidgets('ECS 实例列表提供「创建实例」入口并跳转创建页', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ecsInstanceControllerProvider.overrideWith(
            _StubEcsInstanceController.new,
          ),
          ecsRepositoryProvider.overrideWithValue(_StubEcsRepository()),
        ],
        child: const MaterialApp(
          onGenerateRoute: AppRouter.onGenerateRoute,
          home: EcsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 入口存在：工具栏「创建实例」按钮。
    expect(find.text('创建实例'), findsOneWidget);

    // 点击后进入「创建ECS」页（购买表单 + 确认订单按钮）。
    await tester.tap(find.text('创建实例'));
    await tester.pumpAndSettle();

    expect(find.text('创建ECS'), findsOneWidget);
    expect(find.text('确认订单'), findsOneWidget);
  });

  testWidgets('实例列表为空时空态仍提供「创建实例」入口', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ecsInstanceControllerProvider.overrideWith(
            _StubEmptyEcsInstanceController.new,
          ),
          ecsRepositoryProvider.overrideWithValue(_StubEcsRepository()),
        ],
        child: const MaterialApp(
          onGenerateRoute: AppRouter.onGenerateRoute,
          home: EcsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 空态文案 + 工具栏入口 + 空态内嵌入口。
    expect(find.text('暂无实例，点击下方按钮新建一台'), findsOneWidget);
    expect(find.byIcon(Icons.add_circle_outline), findsWidgets);
  });
}

/// 空实例列表桩。
class _StubEmptyEcsInstanceController extends EcsInstanceController {
  @override
  EcsInstanceState build() => const EcsInstanceState();

  @override
  Future<void> load() async {}
}
