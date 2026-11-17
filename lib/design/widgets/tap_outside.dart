import 'package:flutter/widgets.dart';

/// 输入框的 `onTapOutside`: 手指按到输入框外面 (包括开始滚动) 时取消焦点, 收起键盘.
///
/// Flutter 在 iOS 和 Android 上默认点外面不失焦; iOS 没有返回键, 数字键盘也没有回车, 不处理的话键盘收不起来.
/// 输入框自带的按钮 (发送验证码, 清空等) 用 [TextFieldTapRegion] 和输入框包在一起, 点它们不算外面.
/// 所有输入框同属一组, 从一个输入框点到另一个时焦点直接切过去, 键盘不会先收再弹.
void unfocusOnTapOutside(PointerDownEvent event) =>
    FocusManager.instance.primaryFocus?.unfocus();
