import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hbb/main.dart';
import 'package:flutter_hbb/common.dart';

enum SystemWindowTheme { light, dark }

/// The platform channel for RustDesk.
class RdPlatformChannel {
  RdPlatformChannel._() {
    _hostMethodChannel.setMethodCallHandler(_handleMethodCall);
  }

  static final RdPlatformChannel _windowUtil = RdPlatformChannel._();

  static RdPlatformChannel get instance => _windowUtil;

  final MethodChannel _hostMethodChannel =
      MethodChannel("org.rustdesk.rustdesk/host");
  VoidCallback? _mainWindowHotKeyHandler;

  /// Bump the position of the mouse cursor, if applicable
  Future<bool> bumpMouse({required int dx, required int dy}) async {
    // No debug output; this call is too chatty.

    bool? result = await _hostMethodChannel
      .invokeMethod("bumpMouse", {"dx": dx, "dy": dy});

    return result ?? false;
  }

  /// Change the theme of the system window
  Future<void> changeSystemWindowTheme(SystemWindowTheme theme) {
    assert(isMacOS);
    if (kDebugMode) {
      print(
          "[Window ${kWindowId ?? 'Main'}] change system window theme to ${theme.name}");
    }
    return _hostMethodChannel
        .invokeMethod("setWindowTheme", {"themeName": theme.name});
  }

  /// Terminate .app manually.
  Future<void> terminate() {
    assert(isMacOS);
    return _hostMethodChannel.invokeMethod("terminate");
  }

  void setMainWindowHotKeyHandler(VoidCallback? handler) {
    _mainWindowHotKeyHandler = handler;
  }

  Future<bool> registerMainWindowHotKey({
    required int keyCode,
    bool alt = false,
    bool control = false,
    bool meta = false,
    bool shift = false,
  }) async {
    final result = await _hostMethodChannel.invokeMethod<bool>(
      "registerMainWindowHotKey",
      {
        "keyCode": keyCode,
        "alt": alt,
        "control": control,
        "meta": meta,
        "shift": shift,
      },
    );
    return result ?? false;
  }

  Future<void> unregisterMainWindowHotKey() {
    return _hostMethodChannel.invokeMethod("unregisterMainWindowHotKey");
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case "mainWindowHotKeyPressed":
        _mainWindowHotKeyHandler?.call();
        return null;
      default:
        return null;
    }
  }
}
