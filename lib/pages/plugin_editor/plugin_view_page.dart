import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/utils/utils.dart';
import 'package:kazumi/bean/dialog/dialog_helper.dart';
import 'package:kazumi/plugins/plugins.dart';
import 'package:kazumi/plugins/plugins_controller.dart';
import 'package:kazumi/bean/widget/settings_page_shell.dart';
import 'package:kazumi/design/design_tokens.dart';
import 'package:kazumi/design/kazumi_glass.dart';

class PluginViewPage extends StatefulWidget {
  const PluginViewPage({super.key});

  @override
  State<PluginViewPage> createState() => _PluginViewPageState();
}

class _PluginViewPageState extends State<PluginViewPage> {
  final PluginsController pluginsController = Modular.get<PluginsController>();

  // 是否处于多选模式
  bool isMultiSelectMode = false;

  // 已选中的规则名称集合
  final Set<String> selectedNames = {};

  Future<void> _handleUpdate() async {
    KazumiDialog.showLoading(msg: '更新中');
    int count = await pluginsController.tryUpdateAllPlugin();
    KazumiDialog.dismiss();
    if (count == 0) {
      KazumiDialog.showToast(message: '所有规则已是最新');
    } else {
      KazumiDialog.showToast(message: '更新成功 $count 条');
    }
  }

  void _handleAdd() {
    KazumiDialog.show(builder: (context) {
      return AlertDialog(
        // contentPadding: EdgeInsets.zero, // 设置为零以减小内边距
        content: SingleChildScrollView(
          // 使用可滚动的SingleChildScrollView包装Column
          child: Column(
            mainAxisSize: MainAxisSize.min, // 设置为MainAxisSize.min以减小高度
            children: [
              ListTile(
                title: const Text('新建规则'),
                onTap: () {
                  KazumiDialog.dismiss();
                  Modular.to.pushNamed('/settings/plugin/editor',
                      arguments: Plugin.fromTemplate());
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                title: const Text('从规则仓库导入'),
                onTap: () {
                  KazumiDialog.dismiss();
                  Modular.to.pushNamed('/settings/plugin/shop',
                      arguments: Plugin.fromTemplate());
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                title: const Text('从剪贴板导入'),
                onTap: () {
                  KazumiDialog.dismiss();
                  _showInputDialog();
                },
              ),
            ],
          ),
        ),
      );
    });
  }

  void _showInputDialog() {
    final TextEditingController textController = TextEditingController();
    KazumiDialog.show(builder: (context) {
      return AlertDialog(
        title: const Text('导入规则'),
        content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return TextField(
            controller: textController,
          );
        }),
        actions: [
          TextButton(
            onPressed: () => KazumiDialog.dismiss(),
            child: Text(
              '取消',
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            return TextButton(
              onPressed: () async {
                final String msg = textController.text;
                try {
                  pluginsController.updatePlugin(Plugin.fromJson(
                      json.decode(Utils.kazumiBase64ToJson(msg))));
                  KazumiDialog.showToast(message: '导入成功');
                } catch (e) {
                  KazumiDialog.dismiss();
                  KazumiDialog.showToast(message: '导入失败 ${e.toString()}');
                }
                KazumiDialog.dismiss();
              },
              child: const Text('导入'),
            );
          })
        ],
      );
    });
  }

  void onBackPressed(BuildContext context) {
    if (KazumiDialog.observer.hasKazumiDialog) {
      KazumiDialog.dismiss();
      return;
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {});
    return PopScope(
      canPop: !isMultiSelectMode,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (isMultiSelectMode) {
          setState(() {
            isMultiSelectMode = false;
            selectedNames.clear();
          });
          return;
        }
        onBackPressed(context);
      },
      child: Scaffold(
        body: Observer(
          builder: (context) {
            final count = pluginsController.pluginList.length;

            return KazumiSettingsPageShell(
              title:
                  isMultiSelectMode ? '已选择 ${selectedNames.length} 项' : '规则管理',
              subtitle:
                  count == 0 ? '添加规则后才能搜索和播放视频源。' : '共 $count 条本地规则，可拖拽调整优先级。',
              icon: Icons.extension_rounded,
              actions: _buildHeaderActions(),
              children: [
                if (pluginsController.pluginList.isEmpty)
                  const _PluginEmptyState()
                else
                  ReorderableListView.builder(
                    buildDefaultDragHandles: false,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    proxyDecorator: (child, index, animation) {
                      return Material(
                        elevation: 0,
                        color: Colors.transparent,
                        child: child,
                      );
                    },
                    onReorder: (int oldIndex, int newIndex) {
                      pluginsController.onReorder(oldIndex, newIndex);
                    },
                    itemCount: pluginsController.pluginList.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        key: ValueKey(pluginsController.pluginList[index].name),
                        padding: EdgeInsets.only(
                          bottom:
                              index == pluginsController.pluginList.length - 1
                                  ? 0
                                  : KazumiSpacing.sm,
                        ),
                        child: _buildPluginCard(index),
                      );
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderActions() {
    if (isMultiSelectMode) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton.filledTonal(
            onPressed: () {
              setState(() {
                isMultiSelectMode = false;
                selectedNames.clear();
              });
            },
            tooltip: '取消选择',
            icon: const Icon(Icons.close),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            onPressed: selectedNames.isEmpty ? null : _confirmDeleteSelected,
            tooltip: '删除选中规则',
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          onPressed: _handleUpdate,
          tooltip: '更新全部',
          icon: const Icon(Icons.update),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: _handleAdd,
          icon: const Icon(Icons.add),
          label: const Text('添加'),
        ),
      ],
    );
  }

  void _confirmDeleteSelected() {
    KazumiDialog.show(
      builder: (context) => AlertDialog(
        title: const Text('删除规则'),
        content: Text('确定要删除选中的 ${selectedNames.length} 条规则吗？'),
        actions: [
          TextButton(
            onPressed: () => KazumiDialog.dismiss(),
            child: Text(
              '取消',
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          TextButton(
            onPressed: () {
              pluginsController.removePlugins(selectedNames);
              setState(() {
                isMultiSelectMode = false;
                selectedNames.clear();
              });
              KazumiDialog.dismiss();
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  Widget _buildPluginCard(int index) {
    final plugin = pluginsController.pluginList[index];
    final canUpdate =
        pluginsController.pluginUpdateStatus(plugin) == 'updatable';
    final scheme = Theme.of(context).colorScheme;

    return KazumiGlassSurface(
      borderRadius: KazumiRadius.cardBorder,
      blurSigma: 14,
      opacity: Theme.of(context).brightness == Brightness.dark ? 0.64 : 0.76,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: KazumiSpacing.lg,
          vertical: KazumiSpacing.xs,
        ),
        trailing: pluginCardTrailing(index),
        onLongPress: () {
          if (!isMultiSelectMode) {
            setState(() {
              isMultiSelectMode = true;
              selectedNames.add(plugin.name);
            });
          }
        },
        onTap: () {
          if (isMultiSelectMode) {
            setState(() {
              if (selectedNames.contains(plugin.name)) {
                selectedNames.remove(plugin.name);
                if (selectedNames.isEmpty) {
                  isMultiSelectMode = false;
                }
              } else {
                selectedNames.add(plugin.name);
              }
            });
          }
        },
        selected: selectedNames.contains(plugin.name),
        selectedTileColor: scheme.primaryContainer.withValues(alpha: 0.36),
        title: Text(
          plugin.name,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Version: ${plugin.version}',
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              if (canUpdate)
                _StatusBadge(
                  text: '可更新',
                  background: scheme.errorContainer,
                  foreground: scheme.onErrorContainer,
                ),
              if (pluginsController.validityTracker.isSearchValid(plugin.name))
                _StatusBadge(
                  text: '搜索有效',
                  background: scheme.tertiaryContainer,
                  foreground: scheme.onTertiaryContainer,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget pluginCardTrailing(int index) {
    final plugin = pluginsController.pluginList[index];
    return Row(mainAxisSize: MainAxisSize.min, children: [
      isMultiSelectMode
          ? Checkbox(
              value: selectedNames.contains(plugin.name),
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    selectedNames.add(plugin.name);
                  } else {
                    selectedNames.remove(plugin.name);
                    if (selectedNames.isEmpty) {
                      isMultiSelectMode = false;
                    }
                  }
                });
              },
            )
          : popupMenuButton(index),
      ReorderableDragStartListener(
        index: index,
        child: const Icon(Icons.drag_handle), // 单独的拖拽按钮
      )
    ]);
  }

  Widget popupMenuButton(int index) {
    final plugin = pluginsController.pluginList[index];
    return MenuAnchor(
      consumeOutsideTap: true,
      builder:
          (BuildContext context, MenuController controller, Widget? child) {
        return IconButton(
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          icon: const Icon(Icons.more_vert),
        );
      },
      menuChildren: [
        MenuItemButton(
          requestFocusOnHover: false,
          onPressed: () async {
            var state = pluginsController.pluginUpdateStatus(plugin);
            if (state == "nonexistent") {
              KazumiDialog.showToast(message: '规则仓库中没有当前规则');
            } else if (state == "latest") {
              KazumiDialog.showToast(message: '规则已是最新');
            } else if (state == "updatable") {
              KazumiDialog.showLoading(msg: '更新中');
              int res = await pluginsController.tryUpdatePlugin(plugin);
              KazumiDialog.dismiss();
              if (res == 0) {
                KazumiDialog.showToast(message: '更新成功');
              } else if (res == 1) {
                KazumiDialog.showToast(message: 'kazumi版本过低, 此规则不兼容当前版本');
              } else if (res == 2) {
                KazumiDialog.showToast(message: '更新规则失败');
              }
            }
          },
          child: Container(
            height: 48,
            constraints: BoxConstraints(minWidth: 112),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Icon(Icons.update_rounded),
                  SizedBox(width: 8),
                  Text('更新'),
                ],
              ),
            ),
          ),
        ),
        MenuItemButton(
          requestFocusOnHover: false,
          onPressed: () {
            Modular.to.pushNamed('/settings/plugin/editor', arguments: plugin);
          },
          child: Container(
            height: 48,
            constraints: BoxConstraints(minWidth: 112),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('编辑'),
                ],
              ),
            ),
          ),
        ),
        MenuItemButton(
          requestFocusOnHover: false,
          onPressed: () {
            Modular.to.pushNamed('/settings/plugin/test', arguments: plugin);
          },
          child: Container(
            height: 48,
            constraints: BoxConstraints(minWidth: 112),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Icon(Icons.bug_report_outlined),
                  SizedBox(width: 8),
                  Text('测试'),
                ],
              ),
            ),
          ),
        ),
        MenuItemButton(
          requestFocusOnHover: false,
          onPressed: () {
            KazumiDialog.show(builder: (context) {
              return AlertDialog(
                title: const Text('规则链接'),
                content: SelectableText(
                  Utils.jsonToKazumiBase64(json
                      .encode(pluginsController.pluginList[index].toJson())),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                actions: [
                  TextButton(
                    onPressed: () => KazumiDialog.dismiss(),
                    child: Text(
                      '取消',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.outline),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(
                        text: Utils.jsonToKazumiBase64(
                          json.encode(
                            pluginsController.pluginList[index].toJson(),
                          ),
                        ),
                      ));
                      KazumiDialog.dismiss();
                    },
                    child: const Text('复制到剪贴板'),
                  ),
                ],
              );
            });
          },
          child: Container(
            height: 48,
            constraints: BoxConstraints(minWidth: 112),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Icon(Icons.share),
                  SizedBox(width: 8),
                  Text('分享'),
                ],
              ),
            ),
          ),
        ),
        MenuItemButton(
          requestFocusOnHover: false,
          onPressed: () async {
            setState(() {
              pluginsController.removePlugin(plugin);
            });
          },
          child: Container(
            height: 48,
            constraints: BoxConstraints(minWidth: 112),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Icon(Icons.delete),
                  SizedBox(width: 8),
                  Text('删除'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.text,
    required this.background,
    required this.foreground,
  });

  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PluginEmptyState extends StatelessWidget {
  const _PluginEmptyState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return KazumiGlassSurface(
      borderRadius: KazumiRadius.panelBorder,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 42),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.extension_off_rounded,
            size: 56,
            color: scheme.primary.withValues(alpha: 0.72),
          ),
          const SizedBox(height: KazumiSpacing.md),
          Text(
            '没有可用规则',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: KazumiSpacing.xs),
          Text(
            '从规则仓库导入，或新建一条规则。',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
