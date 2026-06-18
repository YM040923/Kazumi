import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kazumi/bean/dialog/dialog_helper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:kazumi/bean/widget/settings_page_shell.dart';
import 'package:kazumi/design/design_tokens.dart';
import 'package:kazumi/design/kazumi_glass.dart';

class LogsPage extends StatefulWidget {
  const LogsPage({super.key});

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  final List<String> _logLines = [];
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  bool _hasError = false;
  String _fullContent = '';

  static const int _initialLoadCount = 50;
  static const int _loadMoreCount = 100;
  int _displayedLines = 0;
  List<String> _allLines = [];

  @override
  void initState() {
    super.initState();
    _loadLogs();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!mounted || _displayedLines >= _allLines.length) {
      return;
    }

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = maxScroll * 0.8;

    if (currentScroll >= threshold) {
      _loadMoreLines();
    }
  }

  Future<void> _loadLogs() async {
    if (!mounted) return;

    try {
      final file = await _getLogsFile();
      if (!mounted) return;

      if (await file.exists()) {
        final content = await file.readAsString();
        if (!mounted) return;

        _allLines = content.split('\n');
        _fullContent = content;

        final initialCount = _allLines.length < _initialLoadCount
            ? _allLines.length
            : _initialLoadCount;

        if (!mounted) return;
        setState(() {
          _logLines.clear();
          _logLines.addAll(_allLines.take(initialCount));
          _displayedLines = initialCount;
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  void _loadMoreLines() {
    if (_displayedLines >= _allLines.length) {
      return;
    }

    // 使用 Future.microtask 避免在构建过程中调用 setState
    Future.microtask(() {
      if (!mounted) return;

      final remainingLines = _allLines.length - _displayedLines;
      final linesToLoad =
          remainingLines < _loadMoreCount ? remainingLines : _loadMoreCount;

      final newLines = _allLines.skip(_displayedLines).take(linesToLoad);

      if (!mounted) return;
      setState(() {
        _logLines.addAll(newLines);
        _displayedLines += linesToLoad;
      });
    });
  }

  Future<File> _getLogsFile() async {
    final directory = await getApplicationSupportDirectory();
    final path = directory.path;
    return File('$path/logs/kazumi_logs.log');
  }

  Future<void> _clearLogs() async {
    try {
      final file = await _getLogsFile();
      await file.writeAsString('');
      if (!mounted) return;

      setState(() {
        _logLines.clear();
        _allLines.clear();
        _fullContent = '';
        _displayedLines = 0;
      });
    } catch (e) {
      if (!mounted) return;
      KazumiDialog.showToast(message: '清空失败: $e');
    }
  }

  Future<void> _copyLogs() async {
    try {
      await Clipboard.setData(ClipboardData(text: _fullContent));
      if (!mounted) return;
      KazumiDialog.showToast(message: '已复制到剪贴板');
    } catch (e) {
      if (!mounted) return;
      KazumiDialog.showToast(message: '复制失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: KazumiSettingsPageShell(
        title: '日志',
        subtitle: _logLines.isEmpty
            ? '查看运行日志、复制内容或清空文件。'
            : '已加载 $_displayedLines / ${_allLines.length} 行日志。',
        icon: Icons.article_outlined,
        actions: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton.filledTonal(
              onPressed: _logLines.isEmpty ? null : _clearLogs,
              tooltip: '清空日志',
              icon: const Icon(Icons.clear_all),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: _fullContent.isEmpty ? null : _copyLogs,
              tooltip: '复制日志',
              icon: const Icon(Icons.copy),
            ),
          ],
        ),
        children: [buildBody],
      ),
    );
  }

  Widget get buildBody {
    if (_isLoading) {
      return const SizedBox(
        height: 280,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_hasError) {
      return const _LogStateCard(
        icon: Icons.error_outline,
        title: '加载日志失败',
      );
    }

    if (_logLines.isEmpty) {
      return const _LogStateCard(
        icon: Icons.article_outlined,
        title: '没有日志数据',
      );
    }

    return KazumiGlassSurface(
      borderRadius: KazumiRadius.cardBorder,
      blurSigma: 14,
      opacity: Theme.of(context).brightness == Brightness.dark ? 0.64 : 0.76,
      child: SizedBox(
        height: 560,
        child: SelectionArea(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: MediaQuery.of(context).size.width.clamp(720, 1800),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(KazumiSpacing.lg),
                itemCount: _logLines.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text(
                      _logLines[index],
                      softWrap: false,
                      overflow: TextOverflow.clip,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LogStateCard extends StatelessWidget {
  const _LogStateCard({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return KazumiGlassSurface(
      borderRadius: KazumiRadius.cardBorder,
      blurSigma: 14,
      opacity: Theme.of(context).brightness == Brightness.dark ? 0.64 : 0.76,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 42),
      child: Column(
        children: [
          Icon(
            icon,
            size: 56,
            color: scheme.primary.withValues(alpha: 0.72),
          ),
          const SizedBox(height: KazumiSpacing.md),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}
