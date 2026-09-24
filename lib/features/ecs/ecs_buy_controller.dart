import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/net/api_exception.dart';
import '../../data/models/ecs.dart';
import '../../data/repositories/ecs_repository.dart';

/// 镜像类型。
const List<String> imageTypes = <String>['系统镜像', '自定义镜像'];

/// 镜像操作系统选项（硬编码，与后端镜像库对齐）。
const List<String> imageOsOptions = <String>[
  'CentOS',
  'Ubuntu',
  'Windows Server',
  'Debian',
  'RedHat',
];

/// 各操作系统对应的版本选项。
const Map<String, List<String>> imageVersionOptions = <String, List<String>>{
  'CentOS': <String>['7.9 64位', '8.0 64位', 'Stream 9 64位'],
  'Ubuntu': <String>['18.04 LTS', '20.04 LTS', '22.04 LTS'],
  'Windows Server': <String>['2019 数据中心版', '2022 数据中心版'],
  'Debian': <String>['10 64位', '11 64位', '12 64位'],
  'RedHat': <String>['7.9 64位', '8.0 64位'],
};

/// 数据盘类型。
const List<String> diskTypes = <String>['性能型', '容量型', 'SSD云盘'];

/// 线路类型。
const List<String> lineTypes = <String>['电信', 'BGP'];

/// 密码设置模式。
const List<String> passwordModes = <String>['设置密码', '暂不设置'];

/// 私网 VPC 选项（硬编码；后端未提供 VPC 列表接口，与 Vue 端一致）。
class VpcOption {
  const VpcOption({required this.value, required this.label});

  /// 提交下单时作为 `vpc_id` 发送的值。
  final String value;

  /// 展示文案。
  final String label;
}

const List<VpcOption> privateNetworks = <VpcOption>[
  VpcOption(value: 'vpc-001', label: '默认私有网络 192.168.0.0/16'),
  VpcOption(value: 'vpc-002', label: '生产环境VPC 10.0.0.0/8'),
];

/// 后端异常时的兜底周期配置（与数据库默认值一致）。
const List<EcsPeriod> _defaultPeriods = <EcsPeriod>[
  EcsPeriod(month: 1, label: '1个月', discount: 1),
  EcsPeriod(month: 2, label: '2个月', discount: 1),
  EcsPeriod(month: 3, label: '3个月', discount: 1),
  EcsPeriod(month: 6, label: '6个月', discount: 0.95),
  EcsPeriod(month: 12, label: '1年', discount: 0.9),
  EcsPeriod(month: 24, label: '2年', discount: 0.83),
  EcsPeriod(month: 36, label: '3年', discount: 0.75),
];

/// 购买表单状态。
class EcsBuyState {
  const EcsBuyState({
    this.regions = const <EcsRegion>[],
    this.zones = const <EcsZone>[],
    this.specs = const <EcsSpec>[],
    this.periods = const <EcsPeriod>[],
    this.selectedRegionId,
    this.selectedZoneId,
    this.selectedSpecId,
    this.imageType = '系统镜像',
    this.imageOs = '',
    this.imageVersion = '',
    this.dataDisks = const <EcsDataDisk>[],
    this.systemDiskSize = 40,
    this.systemDiskType = '高效云盘',
    this.bandwidth = 1,
    this.selectedVpc = '',
    this.line = '电信',
    this.hasPublicIp = true,
    this.passwordMode = '暂不设置',
    this.rootPassword = '',
    this.confirmPassword = '',
    this.purchaseCount = 1,
    this.selectedPeriod = 1,
    this.remark = '',
    this.price,
    this.configLoading = false,
    this.priceLoading = false,
    this.submitting = false,
    this.errorMessage,
  });

  /// 地域列表。
  final List<EcsRegion> regions;

  /// 当前地域下的可用区列表。
  final List<EcsZone> zones;

  /// 当前可用区下的规格列表。
  final List<EcsSpec> specs;

  /// 购买周期与折扣配置。
  final List<EcsPeriod> periods;

  /// 选中的地域 id。
  final int? selectedRegionId;

  /// 选中的可用区 id。
  final int? selectedZoneId;

  /// 选中的规格 id。
  final int? selectedSpecId;

  /// 镜像类型。
  final String imageType;

  /// 选中的镜像操作系统。
  final String imageOs;

  /// 选中的镜像版本。
  final String imageVersion;

  /// 数据盘列表。
  final List<EcsDataDisk> dataDisks;

  /// 系统盘大小（GB），免费赠送。
  final int systemDiskSize;

  /// 系统盘类型。
  final String systemDiskType;

  /// 带宽（Mbps）。
  final int bandwidth;

  /// 选中的私网 VPC 值。
  final String selectedVpc;

  /// 线路类型。
  final String line;

  /// 是否分配公网 IP。
  final bool hasPublicIp;

  /// 密码设置模式。
  final String passwordMode;

  /// root 密码。
  final String rootPassword;

  /// 确认密码。
  final String confirmPassword;

  /// 购买数量（台）。
  final int purchaseCount;

  /// 选中的购买周期（月）。
  final int selectedPeriod;

  /// 实例备注。
  final String remark;

  /// 当前询价结果，未计算时为 null。
  final EcsPrice? price;

  /// 是否正在加载地域/可用区/规格。
  final bool configLoading;

  /// 是否正在询价。
  final bool priceLoading;

  /// 是否正在提交订单。
  final bool submitting;

  /// 错误提示，非空时展示重试入口。
  final String? errorMessage;

  /// 复制出新状态。
  EcsBuyState copyWith({
    List<EcsRegion>? regions,
    List<EcsZone>? zones,
    List<EcsSpec>? specs,
    List<EcsPeriod>? periods,
    int? selectedRegionId,
    int? selectedZoneId,
    int? selectedSpecId,
    String? imageType,
    String? imageOs,
    String? imageVersion,
    List<EcsDataDisk>? dataDisks,
    int? systemDiskSize,
    String? systemDiskType,
    int? bandwidth,
    String? selectedVpc,
    String? line,
    bool? hasPublicIp,
    String? passwordMode,
    String? rootPassword,
    String? confirmPassword,
    int? purchaseCount,
    int? selectedPeriod,
    String? remark,
    EcsPrice? price,
    bool? configLoading,
    bool? priceLoading,
    bool? submitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return EcsBuyState(
      regions: regions ?? this.regions,
      zones: zones ?? this.zones,
      specs: specs ?? this.specs,
      periods: periods ?? this.periods,
      selectedRegionId: selectedRegionId ?? this.selectedRegionId,
      selectedZoneId: selectedZoneId ?? this.selectedZoneId,
      selectedSpecId: selectedSpecId ?? this.selectedSpecId,
      imageType: imageType ?? this.imageType,
      imageOs: imageOs ?? this.imageOs,
      imageVersion: imageVersion ?? this.imageVersion,
      dataDisks: dataDisks ?? this.dataDisks,
      systemDiskSize: systemDiskSize ?? this.systemDiskSize,
      systemDiskType: systemDiskType ?? this.systemDiskType,
      bandwidth: bandwidth ?? this.bandwidth,
      selectedVpc: selectedVpc ?? this.selectedVpc,
      line: line ?? this.line,
      hasPublicIp: hasPublicIp ?? this.hasPublicIp,
      passwordMode: passwordMode ?? this.passwordMode,
      rootPassword: rootPassword ?? this.rootPassword,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      purchaseCount: purchaseCount ?? this.purchaseCount,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      remark: remark ?? this.remark,
      price: price ?? this.price,
      configLoading: configLoading ?? this.configLoading,
      priceLoading: priceLoading ?? this.priceLoading,
      submitting: submitting ?? this.submitting,
      errorMessage:
          clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// ECS 购买页控制器。
///
/// 搬迁自 vue_flamecloud 的 EcsBuyPage：进入时并行加载地域与周期配置，
/// 选中地域后联动加载可用区 -> 规格 -> 询价；任意配置项变化后重新询价。
class EcsBuyController extends Notifier<EcsBuyState> {
  /// 数据盘自增 id 计数。
  int _diskSeq = 0;

  EcsRepository get _repo => ref.read(ecsRepositoryProvider);

  @override
  EcsBuyState build() {
    return const EcsBuyState();
  }

  /// 当前选中的地域。
  EcsRegion? get _selectedRegion {
    for (final EcsRegion r in state.regions) {
      if (r.id == state.selectedRegionId) {
        return r;
      }
    }
    return null;
  }

  /// 当前选中的可用区。
  EcsZone? get _selectedZone {
    for (final EcsZone z in state.zones) {
      if (z.id == state.selectedZoneId) {
        return z;
      }
    }
    return null;
  }

  /// 当前选中的规格。
  EcsSpec? get _selectedSpec {
    for (final EcsSpec s in state.specs) {
      if (s.id == state.selectedSpecId) {
        return s;
      }
    }
    return null;
  }

  /// 进入页面时加载地域与周期配置。
  ///
  /// 通过 [force] 强制触发「地域 -> 可用区 -> 规格」的完整级联，
  /// 绕过 [selectRegion]/[selectZone] 的早退守卫。这样即使上一次进入时
  /// 加载被部分打断或失败（非 autoDispose 的 provider 会保留旧状态），
  /// 再次进入仍能自动重新拉取规格，避免「规格不自动加载、需手动切换」的问题。
  Future<void> init() async {
    await Future.wait(<Future<void>>[_loadRegions(force: true), _loadPeriods()]);
  }

  /// 当前操作系统对应的版本选项。
  List<String> imageVersionsFor(String os) => imageVersionOptions[os] ?? const <String>[];

  /// 是否还能继续添加数据盘。
  bool get canAddDataDisk => state.dataDisks.length < 5;

  Future<void> _loadRegions({bool force = false}) async {
    state = state.copyWith(configLoading: true, clearError: true);
    try {
      final List<EcsRegion> regions = await _repo.fetchRegions();
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(regions: regions);
      final int? firstId = regions.isEmpty ? null : regions.first.id;
      if (firstId != null) {
        await selectRegion(firstId, force: force);
      } else {
        state = state.copyWith(configLoading: false);
      }
    } on ApiException catch (error) {
      _failConfig(error.message.isEmpty ? '地域配置加载失败' : error.message);
    } on NetworkException catch (error) {
      _failConfig(error.message);
    } on Exception {
      _failConfig('地域配置加载失败');
    }
  }

  Future<void> _loadPeriods() async {
    try {
      final List<EcsPeriod> periods = await _repo.fetchPeriods();
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        periods: periods.isNotEmpty ? periods : _defaultPeriods,
      );
    } on ApiException catch (error) {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(periods: _defaultPeriods, errorMessage: error.message);
    } on NetworkException catch (error) {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(periods: _defaultPeriods, errorMessage: error.message);
    } on Exception {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(periods: _defaultPeriods);
    }
  }

  Future<void> selectRegion(int id, {bool force = false}) async {
    // 手动切换相同地域且可用区已加载时跳过重复请求；[force] 用于进入页面时的强制级联。
    if (!force && state.selectedRegionId == id && state.zones.isNotEmpty) {
      return;
    }
    state = state.copyWith(
      selectedRegionId: id,
      zones: const <EcsZone>[],
      selectedZoneId: null,
      specs: const <EcsSpec>[],
      selectedSpecId: null,
      price: null,
      configLoading: true,
      clearError: true,
    );
    await _loadZones(id);
  }

  /// 切换可用区后重新加载该可用区下的规格并询价。
  ///
  /// [force] 用于进入页面时的强制级联，绕过「相同可用区且规格已加载」的早退守卫。
  Future<void> selectZone(int id, {bool force = false}) async {
    if (!force && state.selectedZoneId == id && state.specs.isNotEmpty) {
      return;
    }
    state = state.copyWith(
      selectedZoneId: id,
      specs: const <EcsSpec>[],
      selectedSpecId: null,
      price: null,
      configLoading: true,
      clearError: true,
    );
    await _loadSpecs();
  }

  Future<void> _loadZones(int regionId) async {
    try {
      final List<EcsZone> zones = await _repo.fetchZones(regionId);
      if (!ref.mounted) {
        return;
      }
      final int? firstId = zones.isEmpty ? null : zones.first.id;
      state = state.copyWith(zones: zones, selectedZoneId: firstId);
      if (firstId != null) {
        await _loadSpecs();
      } else {
        state = state.copyWith(configLoading: false);
      }
    } on ApiException catch (error) {
      _failConfig(error.message.isEmpty ? '可用区加载失败' : error.message);
    } on NetworkException catch (error) {
      _failConfig(error.message);
    } on Exception {
      _failConfig('可用区加载失败');
    }
  }

  Future<void> _loadSpecs() async {
    if (state.selectedRegionId == null || state.selectedZoneId == null) {
      state = state.copyWith(
        specs: const <EcsSpec>[],
        selectedSpecId: null,
        configLoading: false,
      );
      return;
    }
    try {
      final List<EcsSpec> specs = await _repo.fetchSpecs(
        regionId: state.selectedRegionId!,
        zoneId: state.selectedZoneId,
      );
      if (!ref.mounted) {
        return;
      }
      final int? firstId = specs.isEmpty ? null : specs.first.id;
      state = state.copyWith(specs: specs, selectedSpecId: firstId);
      await quotePrice();
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(configLoading: false);
    } on ApiException catch (error) {
      _failConfig(error.message.isEmpty ? '规格加载失败' : error.message);
    } on NetworkException catch (error) {
      _failConfig(error.message);
    } on Exception {
      _failConfig('规格加载失败');
    }
  }

  /// 切换规格后重新询价。
  void selectSpec(int id) {
    state = state.copyWith(selectedSpecId: id, clearError: true);
    unawaited(quotePrice());
  }

  /// 选择镜像操作系统（切换时清空已选版本）。
  void selectImageOs(String os) {
    state = state.copyWith(imageOs: os, imageVersion: '');
    unawaited(quotePrice());
  }

  /// 选择镜像版本后重新询价。
  void selectImageVersion(String version) {
    state = state.copyWith(imageVersion: version);
    unawaited(quotePrice());
  }

  /// 选择镜像类型。
  void selectImageType(String type) {
    state = state.copyWith(imageType: type);
  }

  /// 新增一块数据盘。
  void addDataDisk() {
    if (!canAddDataDisk) {
      return;
    }
    _diskSeq += 1;
    final List<EcsDataDisk> next = <EcsDataDisk>[
      ...state.dataDisks,
      EcsDataDisk(id: _diskSeq, size: 20, type: diskTypes.first),
    ];
    state = state.copyWith(dataDisks: next);
    unawaited(quotePrice());
  }

  /// 移除指定数据盘。
  void removeDataDisk(int id) {
    state = state.copyWith(
      dataDisks: state.dataDisks.where((EcsDataDisk d) => d.id != id).toList(),
    );
    unawaited(quotePrice());
  }

  /// 调整数据盘容量（步长 10GB，10~2000）。
  void adjustDataDiskSize(int id, int delta) {
    state = state.copyWith(
      dataDisks: state.dataDisks.map((EcsDataDisk d) {
        if (d.id != id) {
          return d;
        }
        final int size = (d.size + delta).clamp(10, 2000);
        return d.copyWith(size: size);
      }).toList(),
    );
    unawaited(quotePrice());
  }

  /// 切换数据盘类型。
  void setDataDiskType(int id, String type) {
    state = state.copyWith(
      dataDisks: state.dataDisks
          .map((EcsDataDisk d) => d.id == id ? d.copyWith(type: type) : d)
          .toList(),
    );
    unawaited(quotePrice());
  }

  /// 调整带宽（1~600 Mbps）。
  void setBandwidth(int value) {
    state = state.copyWith(bandwidth: value.clamp(1, 600));
    unawaited(quotePrice());
  }

  /// 调整购买数量（1~100 台）。
  void setPurchaseCount(int value) {
    state = state.copyWith(purchaseCount: value.clamp(1, 100));
    unawaited(quotePrice());
  }

  /// 选择购买周期后重新询价。
  void selectPeriod(int month) {
    state = state.copyWith(selectedPeriod: month);
    unawaited(quotePrice());
  }

  /// 选择线路。
  void setLine(String line) {
    state = state.copyWith(line: line);
    unawaited(quotePrice());
  }

  /// 选择私网 VPC。
  void selectVpc(String value) {
    state = state.copyWith(selectedVpc: value);
  }

  /// 切换公网 IP 分配。
  void setHasPublicIp(bool value) {
    state = state.copyWith(hasPublicIp: value);
  }

  /// 选择密码设置模式。
  void setPasswordMode(String mode) {
    state = state.copyWith(passwordMode: mode);
  }

  /// 设置 root 密码。
  void setRootPassword(String value) {
    state = state.copyWith(rootPassword: value);
  }

  /// 设置确认密码。
  void setConfirmPassword(String value) {
    state = state.copyWith(confirmPassword: value);
  }

  /// 设置实例备注。
  void setRemark(String value) {
    state = state.copyWith(remark: value);
  }

  /// 重新计算总价（地域/可用区/规格缺失时清空）。
  Future<void> quotePrice() async {
    if (state.selectedRegionId == null ||
        state.selectedZoneId == null ||
        state.selectedSpecId == null) {
      if (ref.mounted) {
        state = state.copyWith(price: null);
      }
      return;
    }
    state = state.copyWith(priceLoading: true);
    try {
      final Map<String, Object?> params = <String, Object?>{
        'region_id': state.selectedRegionId,
        'zone_id': state.selectedZoneId,
        'spec_id': state.selectedSpecId,
        'bandwidth': state.bandwidth,
        'purchase_count': state.purchaseCount,
        'purchase_period': state.selectedPeriod,
        'data_disks': encodeDataDisks(state.dataDisks),
        'image_os': state.imageOs,
        'image_version': state.imageVersion,
      };
      final EcsPrice price = await _repo.fetchPrice(params);
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(price: price, priceLoading: false);
    } on ApiException catch (error) {
      _failPrice(error.message.isEmpty ? '价格计算失败' : error.message);
    } on NetworkException catch (error) {
      _failPrice(error.message);
    } on Exception {
      _failPrice('价格计算失败');
    }
  }

  /// 创建订单，返回新订单 id；校验不通过时抛出 [Exception] 由页面提示。
  Future<int> createOrder() async {
    final EcsSpec? spec = _selectedSpec;
    if (spec == null) {
      throw Exception('请选择实例规格');
    }
    if (state.imageOs.isEmpty || state.imageVersion.isEmpty) {
      throw Exception('请选择镜像操作系统和版本');
    }
    if (state.selectedVpc.isEmpty) {
      throw Exception('请选择私网VPC');
    }
    if (state.passwordMode == '设置密码' &&
        (state.rootPassword.isEmpty ||
            state.rootPassword != state.confirmPassword)) {
      throw Exception('请输入密码并确保两次输入一致');
    }
    final EcsRegion? region = _selectedRegion;
    final EcsZone? zone = _selectedZone;
    if (region == null || zone == null) {
      throw Exception('请选择地域与可用区');
    }
    if (state.price == null) {
      throw Exception('价格计算中，请稍候');
    }

    state = state.copyWith(submitting: true, clearError: true);
    try {
      final Map<String, Object?> params = <String, Object?>{
        'region': region.value,
        'zone': zone.name,
        'cpu': spec.cpu,
        'memory': spec.memory,
        'image_os': state.imageOs,
        'image_version': state.imageVersion,
        'system_disk_size': state.systemDiskSize,
        'system_disk_type': state.systemDiskType,
        'data_disks': encodeDataDisks(state.dataDisks),
        'vpc_id': state.selectedVpc,
        'line_type': state.line,
        'bandwidth': state.bandwidth,
        'has_public_ip': state.hasPublicIp ? 1 : 0,
        'password_mode': state.passwordMode,
        'root_password': state.rootPassword,
        'purchase_count': state.purchaseCount,
        'purchase_period': state.selectedPeriod,
        'remark': state.remark,
        'total_price': state.price!.totalPrice,
      };
      final EcsOrder order = await _repo.createOrder(params);
      if (!ref.mounted) {
        return order.id;
      }
      state = state.copyWith(submitting: false);
      return order.id;
    } on ApiException catch (error) {
      if (!ref.mounted) {
        rethrow;
      }
      state = state.copyWith(
        submitting: false,
        errorMessage: error.message.isEmpty ? '订单创建失败' : error.message,
      );
      throw Exception(error.message.isEmpty ? '订单创建失败' : error.message);
    } on NetworkException catch (error) {
      if (!ref.mounted) {
        rethrow;
      }
      state = state.copyWith(submitting: false, errorMessage: error.message);
      throw Exception(error.message);
    } on Exception {
      if (!ref.mounted) {
        rethrow;
      }
      state = state.copyWith(submitting: false, errorMessage: '订单创建失败');
      rethrow;
    }
  }

  void _failConfig(String message) {
    if (!ref.mounted) {
      return;
    }
    state = state.copyWith(configLoading: false, errorMessage: message);
  }

  void _failPrice(String message) {
    if (!ref.mounted) {
      return;
    }
    state = state.copyWith(priceLoading: false, errorMessage: message);
  }
}

/// ECS 购买页控制器实例。
final NotifierProvider<EcsBuyController, EcsBuyState>
    ecsBuyControllerProvider =
    NotifierProvider<EcsBuyController, EcsBuyState>(EcsBuyController.new);
