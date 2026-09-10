import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ticket_list_controller.dart';
import '../ticket_meta.dart';
import 'filter_chip.dart';

/// 状态筛选条：全部 + 四种状态。
class TicketListStatusFilterBar extends ConsumerWidget {
  const TicketListStatusFilterBar({required this.state, super.key});

  final TicketListState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: <Widget>[
          TicketListFilterChip(
            label: '全部',
            selected: state.statusFilter == null,
            onTap: () => unawaited(
              ref.read(ticketListControllerProvider.notifier).selectStatus(null),
            ),
          ),
          for (final int status in const <int>[0, 1, 2, 3])
            TicketListFilterChip(
              label: TicketMeta.statusText(status),
              selected: state.statusFilter == status,
              onTap: () => unawaited(
                ref
                    .read(ticketListControllerProvider.notifier)
                    .selectStatus(status),
              ),
            ),
        ],
      ),
    );
  }
}
