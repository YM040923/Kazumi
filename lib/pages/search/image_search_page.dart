import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kazumi/bean/appbar/drag_to_move_bar.dart' as dtb;
import 'package:kazumi/bean/appbar/window_control_inset.dart';
import 'package:kazumi/bean/card/network_img_layer.dart';
import 'package:kazumi/bean/dialog/dialog_helper.dart';
import 'package:kazumi/design/desktop_layout.dart';
import 'package:kazumi/design/design_tokens.dart';
import 'package:kazumi/design/kazumi_glass.dart';
import 'package:kazumi/modules/search/image_search_module.dart';
import 'package:kazumi/pages/search/search_controller.dart';
import 'package:kazumi/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

const _imageSearchTitle = '\u56fe\u7247\u641c\u7d22';
const _startSearchText = '\u5f00\u59cb\u641c\u7d22';
const _urlHintText = '\u8bf7\u8f93\u5165\u56fe\u7247\u94fe\u63a5';
const _urlPreviewHintText =
    '\u8f93\u5165\u56fe\u7247\u94fe\u63a5\u540e\u9884\u89c8';
const _urlCheckHintText =
    '\u8bf7\u68c0\u67e5\u94fe\u63a5\u662f\u5426\u6709\u6548';
const _similarityLabel = '\u76f8\u4f3c\u5ea6';
const _timeLabel = '\u65f6\u95f4';

class ImageSearchPage extends StatefulWidget {
  const ImageSearchPage({super.key});

  @override
  State<ImageSearchPage> createState() => _ImageSearchPageState();
}

class _ImageSearchPageState extends State<ImageSearchPage> {
  final TextEditingController _urlController = TextEditingController();
  final SearchPageController _searchPageController = SearchPageController();
  final ImagePicker _picker = ImagePicker();
  bool _isUrlMode = false;
  String _previewUrl = '';
  Timer? _debounceTimer;
  File? _selectedImageFile;
  String? _selectedImageName;

  @override
  void initState() {
    super.initState();
    _urlController.addListener(_onUrlChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _urlController.removeListener(_onUrlChanged);
    _urlController.dispose();
    super.dispose();
  }

  void _onUrlChanged() {
    _debounceTimer?.cancel();
    final text = _urlController.text.trim();
    if (text.isEmpty) {
      setState(() => _previewUrl = '');
      return;
    }
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        _searchPageController.clearImageSearchState();
        _previewUrl = text;
      });
    });
  }

  Future<void> _pickImageFile() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    const int maxImageBytes = 25 * 1024 * 1024;
    final imageFile = File(image.path);
    final imageBytes = await imageFile.length();
    if (imageBytes > maxImageBytes) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '\u56fe\u7247\u5927\u5c0f\u4e0d\u80fd\u8d85\u8fc7 25MB',
          ),
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _searchPageController.clearImageSearchState();
      _selectedImageFile = imageFile;
      _selectedImageName = image.name;
    });
  }

  Future<void> _startSearch() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_isUrlMode) {
      final imageUrl = _urlController.text.trim();
      final uri = Uri.tryParse(imageUrl);
      if (imageUrl.isEmpty ||
          uri == null ||
          !uri.hasScheme ||
          !const ['http', 'https'].contains(uri.scheme.toLowerCase())) {
        KazumiDialog.showToast(
          message:
              '\u8bf7\u8f93\u5165\u6709\u6548\u7684\u56fe\u7247\u94fe\u63a5',
        );
        return;
      }
      await _searchPageController.searchImageByUrl(imageUrl);
    } else {
      final imageFile = _selectedImageFile;
      if (imageFile == null) {
        KazumiDialog.showToast(
          message: '\u8bf7\u5148\u9009\u62e9\u56fe\u7247\u6587\u4ef6',
        );
        return;
      }
      await _searchPageController.searchImageByFile(imageFile);
    }

    if (!mounted) return;

    if (_searchPageController.imageSearchError.isNotEmpty &&
        _searchPageController.imageSearchResults.isEmpty) {
      KazumiDialog.showToast(message: _searchPageController.imageSearchError);
    }
  }

  void _setMode(bool isUrlMode) {
    if (_isUrlMode == isUrlMode) return;
    setState(() {
      _isUrlMode = isUrlMode;
      _searchPageController.clearImageSearchState();
    });
  }

  void _leaveImageSearchPage() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).maybePop();
      return;
    }
    Modular.to.navigate('/search/');
  }

  static String _formatTraceResultTitle(ResultItem result) {
    final title = result.anilist?.title;
    return title?.chinese ??
        title?.native ??
        title?.romaji ??
        title?.english ??
        result.filename ??
        '\u672a\u77e5\u756a\u5267';
  }

  static String _formatTraceEpisode(dynamic episode) {
    String formatEpisodeValue(num value) {
      return value % 1 == 0 ? value.toInt().toString() : value.toString();
    }

    if (episode is num) {
      return '\u7b2c ${formatEpisodeValue(episode)} \u96c6';
    }
    if (episode is List && episode.isNotEmpty) {
      final episodes = episode.whereType<num>().map(formatEpisodeValue);
      if (episodes.isNotEmpty) {
        return '\u5267\u96c6: ${episodes.join(' / ')}';
      }
    }
    return '\u5267\u96c6\u672a\u77e5';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _leaveImageSearchPage();
      },
      child: Scaffold(
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              WindowControlInset(
                child: _ImageSearchHeader(
                  onBack: _leaveImageSearchPage,
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 22),
                  child: KazumiDesktopPageFrame(
                    maxWidth: KazumiDesktopShell.mediaPageMaxWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 18,
                      children: [
                        _ImageInputPanel(
                          isUrlMode: _isUrlMode,
                          urlController: _urlController,
                          previewUrl: _previewUrl,
                          selectedImageFile: _selectedImageFile,
                          selectedImageName: _selectedImageName,
                          onModeChanged: _setMode,
                          onPickImage: _pickImageFile,
                          onStartSearch: _startSearch,
                          searchPageController: _searchPageController,
                        ),
                        _ImageSearchResultSection(
                          controller: _searchPageController,
                        ),
                        const _ImageSearchTips(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageSearchHeader extends StatelessWidget {
  const _ImageSearchHeader({
    required this.onBack,
  });

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: scheme.surface.withValues(alpha: 0.62),
      child: dtb.DragToMoveArea(
        child: SafeArea(
          bottom: false,
          child: KazumiDesktopPageFrame(
            maxWidth: KazumiDesktopShell.mediaPageMaxWidth,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 14, 0, 14),
              child: Row(
                children: [
                  IconButton(
                    tooltip: '\u8fd4\u56de',
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.image_search_rounded,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _imageSearchTitle,
                          style: textTheme.headlineSmall?.copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w900,
                            height: 1.05,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '\u4e0a\u4f20\u622a\u56fe\u6216\u7c98\u8d34\u56fe\u7247\u94fe\u63a5\uff0c\u8bc6\u522b\u53ef\u80fd\u7684\u756a\u5267\u6761\u76ee',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ImageInputPanel extends StatelessWidget {
  const _ImageInputPanel({
    required this.isUrlMode,
    required this.urlController,
    required this.previewUrl,
    required this.selectedImageFile,
    required this.selectedImageName,
    required this.onModeChanged,
    required this.onPickImage,
    required this.onStartSearch,
    required this.searchPageController,
  });

  final bool isUrlMode;
  final TextEditingController urlController;
  final String previewUrl;
  final File? selectedImageFile;
  final String? selectedImageName;
  final ValueChanged<bool> onModeChanged;
  final VoidCallback onPickImage;
  final VoidCallback onStartSearch;
  final SearchPageController searchPageController;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return KazumiGlassSurface(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment<bool>(
                    value: false,
                    icon: Icon(Icons.upload_file_rounded),
                    label: Text('\u4e0a\u4f20\u56fe\u7247'),
                  ),
                  ButtonSegment<bool>(
                    value: true,
                    icon: Icon(Icons.link_rounded),
                    label: Text('\u56fe\u7247\u94fe\u63a5'),
                  ),
                ],
                selected: {isUrlMode},
                onSelectionChanged: (value) => onModeChanged(value.first),
              ),
              Observer(
                builder: (context) {
                  final isSearching = searchPageController.isImageSearching;
                  return FilledButton.icon(
                    onPressed: isSearching ? null : onStartSearch,
                    icon: isSearching
                        ? SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: scheme.onPrimary,
                            ),
                          )
                        : const Icon(Icons.image_search_rounded),
                    label: Text(
                      isSearching ? '\u641c\u7d22\u4e2d...' : _startSearchText,
                    ),
                  );
                },
              ),
            ],
          ),
          AnimatedSwitcher(
            duration: KazumiDurations.normal,
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: isUrlMode
                ? _ImageUrlPanel(
                    key: const ValueKey('url-panel'),
                    controller: urlController,
                    previewUrl: previewUrl,
                  )
                : _ImageUploadPanel(
                    key: const ValueKey('upload-panel'),
                    selectedImageFile: selectedImageFile,
                    selectedImageName: selectedImageName,
                    onPickImage: onPickImage,
                  ),
          ),
          Text(
            isUrlMode
                ? '\u652f\u6301 http/https \u56fe\u7247\u5730\u5740\uff0c\u9884\u89c8\u6210\u529f\u540e\u53ef\u76f4\u63a5\u641c\u7d22\u3002'
                : '\u5efa\u8bae\u4f7f\u7528\u539f\u59cb\u6bd4\u4f8b\u7684\u756a\u5267\u622a\u56fe\uff0c\u907f\u514d\u8fc7\u5ea6\u538b\u7f29\u6216\u6c34\u5370\u3002',
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageUploadPanel extends StatelessWidget {
  const _ImageUploadPanel({
    super.key,
    required this.selectedImageFile,
    required this.selectedImageName,
    required this.onPickImage,
  });

  final File? selectedImageFile;
  final String? selectedImageName;
  final VoidCallback onPickImage;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onPickImage,
      borderRadius: BorderRadius.circular(KazumiRadius.lg),
      child: Ink(
        width: double.infinity,
        height: 260,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.32),
          borderRadius: BorderRadius.circular(KazumiRadius.lg),
          border: Border.all(
            color: scheme.outline.withValues(alpha: 0.18),
          ),
        ),
        child: selectedImageFile == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 46,
                    color: scheme.primary,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '\u70b9\u51fb\u9009\u62e9\u56fe\u7247',
                    style: textTheme.titleMedium?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '\u652f\u6301 JPG\u3001PNG\u3001WEBP\uff0c\u6700\u5927 25MB',
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(KazumiRadius.lg),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(
                      color: scheme.surfaceContainerLow,
                      child: Image.file(
                        selectedImageFile!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Text(
                            '\u56fe\u7247\u9884\u89c8\u5931\u8d25',
                            style: textTheme.bodyMedium?.copyWith(
                              color: scheme.error,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.76),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 26, 16, 14),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  selectedImageName ??
                                      '\u5df2\u9009\u62e9\u56fe\u7247',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.titleSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              FilledButton.tonalIcon(
                                onPressed: onPickImage,
                                icon: const Icon(Icons.edit_outlined),
                                label: const Text(
                                  '\u91cd\u65b0\u9009\u62e9',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _ImageUrlPanel extends StatelessWidget {
  const _ImageUrlPanel({
    super.key,
    required this.controller,
    required this.previewUrl,
  });

  final TextEditingController controller;
  final String previewUrl;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        TextField(
          controller: controller,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: _urlHintText,
            prefixIcon: const Icon(Icons.link_rounded),
            suffixIcon: controller.text.isEmpty
                ? null
                : IconButton(
                    tooltip: '\u6e05\u9664',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: controller.clear,
                  ),
            filled: true,
            fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.42),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(KazumiRadius.md),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(KazumiRadius.md),
              borderSide: BorderSide(
                color: scheme.primary.withValues(alpha: 0.62),
              ),
            ),
          ),
        ),
        Container(
          height: 240,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(KazumiRadius.lg),
            border: Border.all(
              color: scheme.outline.withValues(alpha: 0.18),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: previewUrl.isEmpty
              ? _ImagePreviewPlaceholder(
                  text: _urlPreviewHintText,
                )
              : Image.network(
                  previewUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    final total = loadingProgress.expectedTotalBytes;
                    final loaded = loadingProgress.cumulativeBytesLoaded;
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: total != null ? loaded / total : null,
                            strokeWidth: 2.4,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '\u52a0\u8f7d\u4e2d...',
                            style: textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return _ImagePreviewPlaceholder(
                      icon: Icons.broken_image_outlined,
                      iconColor: scheme.error,
                      title: '\u56fe\u7247\u52a0\u8f7d\u5931\u8d25',
                      text: _urlCheckHintText,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ImagePreviewPlaceholder extends StatelessWidget {
  const _ImagePreviewPlaceholder({
    required this.text,
    this.title,
    this.icon = Icons.image_outlined,
    this.iconColor,
  });

  final String text;
  final String? title;
  final IconData icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 38,
            color: iconColor ?? scheme.onSurfaceVariant.withValues(alpha: 0.46),
          ),
          if (title != null) ...[
            const SizedBox(height: 10),
            Text(
              title!,
              style: textTheme.titleSmall?.copyWith(
                color: iconColor ?? scheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageSearchResultSection extends StatelessWidget {
  const _ImageSearchResultSection({
    required this.controller,
  });

  final SearchPageController controller;

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (context) {
        if (controller.isImageSearching) {
          return const _ImageSearchStateCard(
            progress: true,
            title: '\u6b63\u5728\u8bc6\u522b\u56fe\u7247',
            description:
                '\u6b63\u5728\u4ece\u622a\u56fe\u4e2d\u5339\u914d\u756a\u5267\u4fe1\u606f',
          );
        }

        final results = controller.imageSearchResults.toList();
        final errorMessage = controller.imageSearchError;
        if (results.isEmpty) {
          return _ImageSearchStateCard(
            icon: errorMessage.isEmpty
                ? Icons.grid_view_rounded
                : Icons.error_outline_rounded,
            isError: errorMessage.isNotEmpty,
            title: errorMessage.isEmpty
                ? '\u641c\u7d22\u7ed3\u679c\u5c06\u5728\u8fd9\u91cc\u5c55\u793a'
                : '\u672a\u83b7\u53d6\u5230\u641c\u7d22\u7ed3\u679c',
            description: errorMessage.isEmpty
                ? '\u9009\u62e9\u56fe\u7247\u6587\u4ef6\u6216\u8f93\u5165\u56fe\u7247\u94fe\u63a5\u540e\u5f00\u59cb\u641c\u7d22'
                : errorMessage,
          );
        }

        return KazumiGlassSurface(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '\u8bc6\u522b\u7ed3\u679c',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = _imageResultGridColumns(
                    constraints.maxWidth,
                  );
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: results.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      mainAxisExtent: 154,
                    ),
                    itemBuilder: (context, index) {
                      final result = results[index];
                      return _ImageResultCard(result: result);
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ImageSearchStateCard extends StatelessWidget {
  const _ImageSearchStateCard({
    required this.title,
    required this.description,
    this.icon,
    this.progress = false,
    this.isError = false,
  });

  final String title;
  final String description;
  final IconData? icon;
  final bool progress;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final iconColor = isError ? scheme.error : scheme.primary;

    return KazumiGlassSurface(
      padding: const EdgeInsets.all(24),
      showShadow: false,
      child: Column(
        children: [
          if (progress)
            const SizedBox.square(
              dimension: 32,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            )
          else
            Icon(
              icon ?? Icons.image_search_rounded,
              size: 34,
              color: iconColor,
            ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageResultCard extends StatelessWidget {
  const _ImageResultCard({
    required this.result,
  });

  final ResultItem result;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final coverUrl = result.image ??
        result.anilist?.coverImage?.large ??
        result.anilist?.coverImage?.medium ??
        '';
    final title = _ImageSearchPageState._formatTraceResultTitle(result);

    return InkWell(
      onTap: () => Navigator.of(context).pop(title),
      borderRadius: BorderRadius.circular(KazumiRadius.md),
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(KazumiRadius.md),
          border: Border.all(
            color: scheme.outline.withValues(alpha: 0.14),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(KazumiRadius.sm),
              child: NetworkImgLayer(
                src: coverUrl,
                width: 128,
                height: 72,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                  ),
                  const Spacer(),
                  _TraceInfoLine(
                    value: _ImageSearchPageState._formatTraceEpisode(
                      result.episode,
                    ),
                  ),
                  _TraceInfoLine(
                    value:
                        '$_similarityLabel: ${Utils.formatTraceSimilarity(result.similarity)}',
                  ),
                  _TraceInfoLine(
                    value:
                        '$_timeLabel: ${Utils.durationToString(Duration(seconds: (result.from ?? 0).floor()))} - ${Utils.durationToString(Duration(seconds: (result.to ?? 0).floor()))}',
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

class _TraceInfoLine extends StatelessWidget {
  const _TraceInfoLine({
    required this.value,
  });

  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _ImageSearchTips extends StatelessWidget {
  const _ImageSearchTips();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final baseStyle = textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
      height: 1.5,
      fontWeight: FontWeight.w600,
    );

    return KazumiGlassSurface(
      padding: const EdgeInsets.all(16),
      showShadow: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                '\u4ee5\u56fe\u641c\u756a',
                style: textTheme.labelLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '\u622a\u56fe\u8d8a\u63a5\u8fd1\u539f\u753b\u9762\uff0c\u8bc6\u522b\u7ed3\u679c\u8d8a\u7a33\u5b9a\u3002',
            style: baseStyle,
          ),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              style: baseStyle,
              children: [
                const TextSpan(
                  text: '\u641c\u7d22\u5f15\u64ce\u7531 ',
                ),
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: GestureDetector(
                    onTap: () => launchUrl(
                      Uri.parse('https://trace.moe'),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: Text(
                      'trace.moe',
                      style: baseStyle?.copyWith(
                        color: scheme.primary,
                        decoration: TextDecoration.underline,
                        decorationColor: scheme.primary,
                      ),
                    ),
                  ),
                ),
                const TextSpan(
                  text: ' \u63d0\u4f9b\u652f\u6301',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

int _imageResultGridColumns(double contentWidth) {
  if (contentWidth >= 980) return 2;
  return 1;
}
