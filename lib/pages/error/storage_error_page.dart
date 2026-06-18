import 'dart:io';
import 'package:flutter/material.dart';
import 'package:kazumi/bean/widget/error_widget.dart';
import 'package:kazumi/bean/appbar/drag_to_move_bar.dart' as dtb;
import 'package:kazumi/design/desktop_layout.dart';
import 'package:kazumi/design/design_tokens.dart';
import 'package:kazumi/design/kazumi_glass.dart';
import 'package:path_provider/path_provider.dart';

class StorageErrorPage extends StatelessWidget {
  const StorageErrorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 18),
          children: [
            KazumiDesktopPageFrame(
              maxWidth: KazumiDesktopShell.mediaPageMaxWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _StorageErrorHeader(),
                  const SizedBox(height: KazumiSpacing.md),
                  KazumiGlassSurface(
                    child: SizedBox(
                      height: 360,
                      child: Center(
                        child: FutureBuilder<Directory>(
                          future: getApplicationSupportDirectory(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.done) {
                              final supportDir = snapshot.data;
                              final path =
                                  supportDir != null ? '$supportDir' : '未知路径';
                              return GeneralErrorWidget(
                                errMsg:
                                    '存储初始化错误 \n 当前储存位置 $path \n 尝试删除该目录以重置本地存储',
                                actions: [
                                  GeneralErrorButton(
                                    onPressed: () {
                                      exit(0);
                                    },
                                    text: '退出程序',
                                  ),
                                ],
                              );
                            } else {
                              return const CircularProgressIndicator();
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StorageErrorHeader extends StatelessWidget {
  const _StorageErrorHeader();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: dtb.DragToMoveArea(
        child: KazumiGlassSurface(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: scheme.errorContainer.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  color: scheme.onErrorContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '内部错误',
                      style: textTheme.headlineSmall?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '本地存储初始化失败，需要重置应用数据目录后重新打开。',
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
