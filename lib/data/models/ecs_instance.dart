import '../../core/utils/json_value.dart';

/// 云服务器实例。
///
/// 对应 `GET /v1/ecs/instance/list` 返回的 data.list 元素，字段与
/// go_flamecloud 的 `fc_ecs_instance` 表保持一致。
///
/// 注意：实例表**未存储公网/私网 IP**（下单流程也未落库），故 [publicIp] /
/// [privateIp] 在真实数据下通常为 null，详情页与列表统一展示「未分配」。
/// [region] 存的是地域编码（如 `cn-hangzhou`），后端未提供中文标签的关联，
/// 展示时直接显示编码值。操作系统由 [imageOs] + [imageVersion] 拼接。
class EcsInstance {
  const EcsInstance({
    required this.id,
    required this.instanceId,
    required this.instanceName,
    required this.region,
    required this.status,
    this.zone,
    this.cpu,
    this.memory,
    this.imageOs,
    this.imageVersion,
    this.systemDiskSize,
    this.systemDiskType,
    this.vpcId,
    this.lineType,
    this.bandwidth,
    this.remark,
    required this.createdAt,
    this.publicIp,
    this.privateIp,
  });

  /// 从接口返回的列表元素构造。
  factory EcsInstance.fromMap(Map<String, dynamic> map) {
    return EcsInstance(
      id: JsonValue.integer(map['id']) ?? 0,
      instanceId: JsonValue.string(map['instance_id']) ?? '',
      instanceName: JsonValue.string(map['instance_name']) ?? '',
      region: JsonValue.string(map['region']) ?? '',
      status: JsonValue.string(map['status']) ?? 'stopped',
      zone: JsonValue.string(map['zone']),
      cpu: JsonValue.string(map['cpu']),
      memory: JsonValue.string(map['memory']),
      imageOs: JsonValue.string(map['image_os']),
      imageVersion: JsonValue.string(map['image_version']),
      systemDiskSize: JsonValue.integer(map['system_disk_size']),
      systemDiskType: JsonValue.string(map['system_disk_type']),
      vpcId: JsonValue.string(map['vpc_id']),
      lineType: JsonValue.string(map['line_type']),
      bandwidth: JsonValue.integer(map['bandwidth']),
      remark: JsonValue.string(map['remark']),
      createdAt: JsonValue.string(map['created_at']) ?? '',
      publicIp: JsonValue.string(map['public_ip']),
      privateIp: JsonValue.string(map['private_ip']),
    );
  }

  /// 数据库主键。
  final int id;

  /// 实例 ID，形如 `ecs-xxxxxxxx`。
  final String instanceId;

  /// 实例名称，下单时默认生成 `ECS-<instance_id>`。
  final String instanceName;

  /// 地域编码（如 `cn-hangzhou`）。
  final String region;

  /// 可用区编码。
  final String? zone;

  /// 运行状态：`running` / `stopped`（其他值按「已停止」处理）。
  final String status;

  /// CPU 描述，如「2核」。
  final String? cpu;

  /// 内存描述，如「4GB」。
  final String? memory;

  /// 镜像操作系统，如「Ubuntu」。
  final String? imageOs;

  /// 镜像版本，如「22.04 LTS」。
  final String? imageVersion;

  /// 系统盘大小（GB）。
  final int? systemDiskSize;

  /// 系统盘类型，如「高效云盘」。
  final String? systemDiskType;

  /// 私网 VPC ID。
  final String? vpcId;

  /// 线路类型，如「电信」「BGP」。
  final String? lineType;

  /// 带宽（Mbps）。
  final int? bandwidth;

  /// 实例备注。
  final String? remark;

  /// 创建时间，后端返回的原始时间串。
  final String createdAt;

  /// 公网 IP，真实数据下通常为 null（实例表未存储）。
  final String? publicIp;

  /// 私网 IP，真实数据下通常为 null。
  final String? privateIp;

  /// 是否运行中。
  bool get isRunning => status == 'running';

  /// 状态中文。
  String get statusText => isRunning ? '运行中' : '已停止';

  /// 展示用名称：实例名为空时回退到备注，再回退到实例 ID。
  String get displayName {
    if (instanceName.isNotEmpty) {
      return instanceName;
    }
    if (remark != null && remark!.isNotEmpty) {
      return remark!;
    }
    return instanceId.isNotEmpty ? instanceId : 'ECS实例';
  }

  /// 规格文案：`cpu / memory`，任一缺失时只显示另一项。
  String get specText {
    final List<String> parts = <String>[
      if (cpu != null && cpu!.isNotEmpty) cpu!,
      if (memory != null && memory!.isNotEmpty) memory!,
    ];
    return parts.isEmpty ? '—' : parts.join(' / ');
  }

  /// 操作系统文案：`image_os image_version`。
  String get osText {
    final List<String> parts = <String>[
      if (imageOs != null && imageOs!.isNotEmpty) imageOs!,
      if (imageVersion != null && imageVersion!.isNotEmpty) imageVersion!,
    ];
    return parts.isEmpty ? '—' : parts.join(' ');
  }

  /// 列表/详情展示的 IP：优先公网，回退私网，均无则「未分配」。
  String get ipText {
    if (publicIp != null && publicIp!.isNotEmpty) {
      return publicIp!;
    }
    if (privateIp != null && privateIp!.isNotEmpty) {
      return privateIp!;
    }
    return '未分配';
  }

  /// 是否拥有任一 IP。
  bool get hasIp =>
      (publicIp != null && publicIp!.isNotEmpty) ||
      (privateIp != null && privateIp!.isNotEmpty);
}
