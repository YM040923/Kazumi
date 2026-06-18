import 'dart:io';
import 'package:flutter/material.dart';
import 'package:kazumi/app_module.dart';
import 'package:kazumi/app_widget.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/bean/settings/theme_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:kazumi/utils/storage.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:kazumi/utils/proxy_manager.dart';
import 'package:flutter/services.dart';
import 'package:kazumi/utils/utils.dart';
import 'package:media_kit/media_kit.dart';
import 'package:window_manager/window_manager.dart';
import 'package:kazumi/pages/error/storage_error_page.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:kazumi/utils/ui_verification.dart';

const Size _desktopMinimumWindowSize = Size(960, 640);

void main(List<String> args) async {
  UiVerification.configure(args);
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  if (Platform.isAndroid || Platform.isIOS) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      statusBarColor: Colors.transparent,
    ));
  }

  if (Platform.isAndroid) {
    await Utils.checkWebViewFeatureSupport();
  }

  try {
    final hivePath = '${(await getApplicationSupportDirectory()).path}/hive';
    await Hive.initFlutter(hivePath);
    await GStorage.init();
  } catch (e) {
    // Log the error for debugging (if logger is available)
    debugPrint('Storage initialization failed: $e');

    if (Platform.isWindows) {
      await windowManager.ensureInitialized();
      windowManager.waitUntilReadyToShow(null, () async {
        // Native window show has been blocked in `flutter_windows.cppL36` to avoid flickering.
        // Without this. the window will never show on Windows.
        await windowManager.show();
        await windowManager.focus();
      });
    }
    runApp(MaterialApp(
        title: '初始化失败',
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [
          Locale.fromSubtags(
              languageCode: 'zh', scriptCode: 'Hans', countryCode: "CN")
        ],
        locale: const Locale.fromSubtags(
            languageCode: 'zh', scriptCode: 'Hans', countryCode: "CN"),
        builder: (context, child) {
          return const StorageErrorPage();
        }));
    return;
  }
  bool showWindowButton = await GStorage.setting
      .get(SettingBoxKey.showWindowButton, defaultValue: false);
  if (Utils.isDesktop()) {
    await windowManager.ensureInitialized();
    bool isLowResolution = await Utils.isLowResolution();
    final initialWindowSize =
        isLowResolution ? const Size(1120, 720) : const Size(1360, 860);
    final restoredWindowSize = UiVerification.isEnabled
        ? const Size(1280, 860)
        : _initialDesktopWindowSize(initialWindowSize);
    final restoredWindowPosition =
        UiVerification.isEnabled ? null : _initialDesktopWindowPosition();
    final restoreMaximized = !UiVerification.isEnabled &&
        GStorage.setting
            .get(SettingBoxKey.desktopWindowMaximized, defaultValue: false);
    WindowOptions windowOptions = WindowOptions(
      size: restoredWindowSize,
      minimumSize: _desktopMinimumWindowSize,
      center: restoredWindowPosition == null,
      skipTaskbar: false,
      // macOS always hide title bar regardless of showWindowButton setting
      titleBarStyle: (Platform.isMacOS || !showWindowButton)
          ? TitleBarStyle.hidden
          : TitleBarStyle.normal,
      windowButtonVisibility: showWindowButton,
      title: 'Kazumi',
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      // Native window show has been blocked in `flutter_windows.cppL36` to avoid flickering.
      // Without this. the window will never show on Windows.
      if (restoredWindowPosition != null) {
        await windowManager.setPosition(restoredWindowPosition);
      }
      if (restoreMaximized) {
        await windowManager.maximize();
      }
      await windowManager.show();
      await windowManager.focus();
    });
  }
  ProxyManager.applyProxy();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: ModularApp(
        module: AppModule(),
        child: const AppWidget(),
      ),
    ),
  );
}

Size _initialDesktopWindowSize(Size fallbackSize) {
  final width = GStorage.setting.get(SettingBoxKey.desktopWindowWidth);
  final height = GStorage.setting.get(SettingBoxKey.desktopWindowHeight);
  if (width is! num || height is! num) {
    return fallbackSize;
  }

  return Size(
    width
        .clamp(
          _desktopMinimumWindowSize.width,
          3840,
        )
        .toDouble(),
    height
        .clamp(
          _desktopMinimumWindowSize.height,
          2160,
        )
        .toDouble(),
  );
}

Offset? _initialDesktopWindowPosition() {
  final x = GStorage.setting.get(SettingBoxKey.desktopWindowX);
  final y = GStorage.setting.get(SettingBoxKey.desktopWindowY);
  if (x is! num || y is! num) {
    return null;
  }

  return Offset(x.toDouble(), y.toDouble());
}
