import 'dart:math';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/failures.dart';
import 'package:hiddify/features/proxy/overview/proxies_overview_notifier.dart';
import 'package:hiddify/features/proxy/widget/proxy_tile.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ProxiesOverviewPage extends HookConsumerWidget with PresLogger {
  const ProxiesOverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;

    final proxies = ref.watch(proxiesOverviewNotifierProvider);
    final sortBy = ref.watch(proxiesSortNotifierProvider);

    // final selectActiveProxyMutation = useMutation(
    //   initialOnFailure: (error) => CustomToast.error(t.presentShortError(error)).show(context),
    // );

    return Scaffold(
      appBar: AppBar(
        title: Text(t.pages.proxies.title),
        actions: [
          PopupMenuButton<ProxiesSort>(
            initialValue: sortBy,
            onSelected: ref.read(proxiesSortNotifierProvider.notifier).update,
            icon: const Icon(FluentIcons.arrow_sort_24_regular),
            tooltip: t.pages.proxies.sort,
            itemBuilder: (context) {
              return [...ProxiesSort.values.map((e) => PopupMenuItem(value: e, child: Text(e.present(t))))];
            },
          ),
          const Gap(8),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async => await ref.read(proxiesOverviewNotifierProvider.notifier).urlTest("select"),
        tooltip: t.pages.proxies.testDelay,
        child: const Icon(FluentIcons.flash_24_filled),
      ),
      body: proxies.when(
        data: (group) => group != null
            ? LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final crossAxisCount = PlatformUtils.isMobile && width < 600 ? 1 : max(1, (width / 268).floor());
                  // 灯塔精简：隐藏核心自动生成的 lowest / balance 等聚合组，
                  // 它们会轮询到劣质节点，对普通用户有迷惑性，只保留真实节点。
                  final visibleItems = group.items.where((p) {
                    final type = p.type.toLowerCase();
                    final tag = p.tag.toLowerCase();
                    if (type.contains('balancer') || type.contains('urltest') || type.contains('selector')) {
                      return false;
                    }
                    return tag != 'lowest' && tag != 'balance' && tag != 'auto' && tag != 'select';
                  }).toList();
                  return GridView.builder(
                    padding: const EdgeInsets.only(bottom: 86),
                    itemCount: visibleItems.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisExtent: 72,
                    ),
                    itemBuilder: (context, index) {
                      final proxy = visibleItems[index];
                      return ProxyTile(
                        proxy,
                        selected: group.selected == proxy.tag,
                        onTap: () async {
                          await ref.read(proxiesOverviewNotifierProvider.notifier).changeProxy(group.tag, proxy.tag);
                          // if (selectActiveProxyMutation.state.isInProgress) return;
                          // selectActiveProxyMutation.setFuture(
                          // );
                        },
                      );
                    },
                  );
                },
              )
            : Center(child: Text(t.pages.proxies.empty)),
        error: (error, stackTrace) => Center(child: Text(t.presentShortError(error))),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
