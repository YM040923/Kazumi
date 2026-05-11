import 'package:flutter/material.dart';

/// Kazumi 设计系统 - 统一设计Token
///
/// 所有间距、圆角、阴影、动画时长等设计参数统一在此管理，
/// 确保整个应用的视觉一致性。

class KazumiSpacing {
  KazumiSpacing._();

  /// 超小间距 - 用于紧凑元素
  static const double xs = 4;

  /// 小间距 - 用于内部元素
  static const double sm = 8;

  /// 标准间距 - 用于卡片间距、列表间隔
  static const double md = 12;

  /// 大间距 - 用于页面边距
  static const double lg = 16;

  /// 超大间距 - 用于区块间距
  static const double xl = 24;

  /// 超大间距 - 用于布局分隔
  static const double xxl = 32;
}

class KazumiRadius {
  KazumiRadius._();

  /// 小圆角 - 用于按钮、输入框
  static const double sm = 8;

  /// 标准圆角 - 用于卡片
  static const double md = 12;

  /// 大圆角 - 用于面板、弹窗
  static const double lg = 16;

  /// 超大圆角 - 用于页面容器
  static const double xl = 20;

  /// 全圆角 - 用于头像
  static const double full = 50;

  static BorderRadius get cardBorder => BorderRadius.circular(md);
  static BorderRadius get panelBorder => BorderRadius.circular(lg);
  static BorderRadius get containerBorder => BorderRadius.circular(xl);

  /// 顶部大圆角 - 用于底部弹出面板
  static BorderRadius get bottomSheetBorder =>
      const BorderRadius.vertical(top: Radius.circular(lg));
}

class KazumiDurations {
  KazumiDurations._();

  /// 快速过渡 - 悬停反馈、图标切换
  static const Duration fast = Duration(milliseconds: 150);

  /// 标准过渡 - 卡片动画、页面切换
  static const Duration normal = Duration(milliseconds: 250);

  /// 慢速过渡 - 进场动画、展开收起
  static const Duration slow = Duration(milliseconds: 350);

  /// 弹性动画
  static const Duration bouncy = Duration(milliseconds: 400);
}

class KazumiElevations {
  KazumiElevations._();

  /// 无阴影 - 平铺元素
  static const double none = 0;

  /// 微阴影 - 卡片默认状态
  static const double subtle = 1;

  /// 低阴影 - 浮动元素
  static const double low = 2;

  /// 标准阴影 - 悬浮卡、FAB
  static const double standard = 4;

  /// 高阴影 - 弹窗、抽屉
  static const double high = 8;
}
