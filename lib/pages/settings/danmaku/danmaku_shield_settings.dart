import 'package:flutter/material.dart';
import 'package:kazumi/pages/my/my_controller.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/bean/widget/settings_page_shell.dart';
import 'package:kazumi/design/design_tokens.dart';
import 'package:kazumi/design/kazumi_glass.dart';

class DanmakuShieldSettings extends StatefulWidget {
  const DanmakuShieldSettings({super.key});

  @override
  State<DanmakuShieldSettings> createState() => _DanmakuShieldSettingsState();
}

class _DanmakuShieldSettingsState extends State<DanmakuShieldSettings> {
  final MyController myController = Modular.get<MyController>();
  final TextEditingController textEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DanmakuShieldSettingsContent(
        myController: myController,
        textEditingController: textEditingController,
      ),
    );
  }
}

class DanmakuShieldSettingsContent extends StatelessWidget {
  const DanmakuShieldSettingsContent({
    super.key,
    required this.myController,
    required this.textEditingController,
  });

  final MyController myController;
  final TextEditingController textEditingController;

  void _addKeyword() {
    myController.addShieldList(textEditingController.text.trim());
    textEditingController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return KazumiSettingsPageShell(
      title: '弹幕屏蔽',
      subtitle: '添加关键词或正则表达式，播放时会自动过滤匹配弹幕。',
      icon: Icons.block_rounded,
      children: [
        KazumiGlassSurface(
          borderRadius: KazumiRadius.cardBorder,
          blurSigma: 14,
          opacity:
              Theme.of(context).brightness == Brightness.dark ? 0.64 : 0.76,
          padding: const EdgeInsets.all(KazumiSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: textEditingController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: '输入关键词或正则表达式',
                  suffixIcon: TextButton.icon(
                    onPressed: _addKeyword,
                    icon: const Icon(Icons.add),
                    label: const Text('添加'),
                  ),
                ),
                onSubmitted: (_) => _addKeyword(),
              ),
              const SizedBox(height: KazumiSpacing.sm),
              Text(
                '以 "/" 开头和结尾将视作正则表达式，例如 "/\\\\d+/" 表示屏蔽所有数字。',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: KazumiSpacing.sm),
              Observer(
                builder: (context) {
                  return Text(
                    '已添加 ${myController.shieldList.length} 个关键词',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: KazumiSpacing.md),
        Observer(
          builder: (context) {
            if (myController.shieldList.isEmpty) {
              return KazumiGlassSurface(
                borderRadius: KazumiRadius.cardBorder,
                blurSigma: 14,
                opacity: Theme.of(context).brightness == Brightness.dark
                    ? 0.64
                    : 0.76,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 34,
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 48,
                      color: scheme.primary.withValues(alpha: 0.72),
                    ),
                    const SizedBox(height: KazumiSpacing.sm),
                    Text(
                      '还没有屏蔽词',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
              );
            }

            return KazumiGlassSurface(
              borderRadius: KazumiRadius.cardBorder,
              blurSigma: 14,
              opacity:
                  Theme.of(context).brightness == Brightness.dark ? 0.64 : 0.76,
              padding: const EdgeInsets.all(KazumiSpacing.lg),
              child: Wrap(
                runSpacing: 12,
                spacing: 12,
                children: myController.shieldList
                    .map(
                      (item) => Chip(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32),
                        ),
                        backgroundColor: scheme.secondaryContainer,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        side: BorderSide.none,
                        label: Text(
                          item,
                          style: const TextStyle(fontSize: 14),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        deleteButtonTooltipMessage: '',
                        onDeleted: () {
                          myController.removeShieldList(item);
                        },
                      ),
                    )
                    .toList(),
              ),
            );
          },
        ),
      ],
    );
  }
}
