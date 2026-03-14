import 'package:flutter/services.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/consts.dart';
import 'package:flutter_hbb/utils/platform_channel.dart';

class MainWindowHotkey {
  MainWindowHotkey({
    required this.key,
    required this.control,
    required this.alt,
    required this.meta,
  });

  final String key;
  final bool control;
  final bool alt;
  final bool meta;

  static const Set<String> _blockedLetterKeys = {
    'F',
    'H',
    'L',
    'M',
    'P',
    'Q',
    'R',
    'T',
    'W',
  };

  static MainWindowHotkey recommended() {
    return isMacOS
        ? MainWindowHotkey(key: 'J', control: false, alt: true, meta: true)
        : MainWindowHotkey(key: 'J', control: true, alt: true, meta: false);
  }

  static MainWindowHotkey? tryParse(String raw) {
    if (raw.trim().isEmpty) {
      return null;
    }
    final parts = raw
        .split('+')
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.length != 3) {
      return null;
    }
    final key = parts.last.toUpperCase();
    final hotkey = MainWindowHotkey(
      key: key,
      control: parts.take(2).contains('ctrl'),
      alt: parts.take(2).contains('alt'),
      meta: parts.take(2).contains('cmd'),
    );
    return hotkey.isValid ? hotkey : null;
  }

  static MainWindowHotkey? fromKeyEvent(RawKeyEvent event) {
    final key = _normalizeKey(event.logicalKey);
    if (key == null) {
      return null;
    }
    return MainWindowHotkey(
      key: key,
      control: event.isControlPressed,
      alt: event.isAltPressed,
      meta: event.isMetaPressed,
    );
  }

  static String? _normalizeKey(LogicalKeyboardKey logicalKey) {
    final keyLabel = logicalKey.keyLabel.trim();
    if (keyLabel.length == 1) {
      final char = keyLabel.toUpperCase();
      final codeUnit = char.codeUnitAt(0);
      final isLetter = codeUnit >= 65 && codeUnit <= 90;
      final isDigit = codeUnit >= 48 && codeUnit <= 57;
      if (isLetter || isDigit) {
        return char;
      }
    }

    const functionKeys = {
      LogicalKeyboardKey.f1: 'F1',
      LogicalKeyboardKey.f2: 'F2',
      LogicalKeyboardKey.f3: 'F3',
      LogicalKeyboardKey.f4: 'F4',
      LogicalKeyboardKey.f5: 'F5',
      LogicalKeyboardKey.f6: 'F6',
      LogicalKeyboardKey.f7: 'F7',
      LogicalKeyboardKey.f8: 'F8',
      LogicalKeyboardKey.f9: 'F9',
      LogicalKeyboardKey.f10: 'F10',
      LogicalKeyboardKey.f11: 'F11',
      LogicalKeyboardKey.f12: 'F12',
    };
    return functionKeys[logicalKey];
  }

  bool get isValid => validationError == null;

  String? get validationError {
    if (!(isWindows || isMacOS)) {
      return 'Global shortcut is only available on Windows and macOS.';
    }
    if (isMacOS) {
      if (!(meta && alt && !control)) {
        return 'Use Command + Option + letter, number, or F key.';
      }
    } else {
      if (!(control && alt && !meta)) {
        return 'Use Ctrl + Alt + letter, number, or F key.';
      }
    }
    if (_blockedLetterKeys.contains(key)) {
      return 'Pick a less common key to avoid conflicts.';
    }
    if (isMacOS && !_macKeyCodes.containsKey(key)) {
      return 'Use a letter, number, or F key.';
    }
    if (!isMacOS && !_windowsKeyCodes.containsKey(key)) {
      return 'Use a letter, number, or F key.';
    }
    return null;
  }

  String toStorage() {
    final modifiers = <String>[];
    if (control) modifiers.add('ctrl');
    if (alt) modifiers.add('alt');
    if (meta) modifiers.add('cmd');
    return [...modifiers, key.toLowerCase()].join('+');
  }

  String get displayLabel {
    final modifiers = <String>[];
    if (control) modifiers.add('Ctrl');
    if (alt) modifiers.add(isMacOS ? 'Option' : 'Alt');
    if (meta) modifiers.add('Cmd');
    return [...modifiers, key].join(' + ');
  }

  int get platformKeyCode {
    if (isMacOS) {
      return _macKeyCodes[key]!;
    }
    return _windowsKeyCodes[key]!;
  }

  static const Map<String, int> _windowsKeyCodes = {
    '0': 0x30,
    '1': 0x31,
    '2': 0x32,
    '3': 0x33,
    '4': 0x34,
    '5': 0x35,
    '6': 0x36,
    '7': 0x37,
    '8': 0x38,
    '9': 0x39,
    'A': 0x41,
    'B': 0x42,
    'C': 0x43,
    'D': 0x44,
    'E': 0x45,
    'F': 0x46,
    'G': 0x47,
    'H': 0x48,
    'I': 0x49,
    'J': 0x4A,
    'K': 0x4B,
    'L': 0x4C,
    'M': 0x4D,
    'N': 0x4E,
    'O': 0x4F,
    'P': 0x50,
    'Q': 0x51,
    'R': 0x52,
    'S': 0x53,
    'T': 0x54,
    'U': 0x55,
    'V': 0x56,
    'W': 0x57,
    'X': 0x58,
    'Y': 0x59,
    'Z': 0x5A,
    'F1': 0x70,
    'F2': 0x71,
    'F3': 0x72,
    'F4': 0x73,
    'F5': 0x74,
    'F6': 0x75,
    'F7': 0x76,
    'F8': 0x77,
    'F9': 0x78,
    'F10': 0x79,
    'F11': 0x7A,
    'F12': 0x7B,
  };

  static const Map<String, int> _macKeyCodes = {
    'A': 0x00,
    'S': 0x01,
    'D': 0x02,
    'F': 0x03,
    'H': 0x04,
    'G': 0x05,
    'Z': 0x06,
    'X': 0x07,
    'C': 0x08,
    'V': 0x09,
    'B': 0x0B,
    'Q': 0x0C,
    'W': 0x0D,
    'E': 0x0E,
    'R': 0x0F,
    'Y': 0x10,
    'T': 0x11,
    '1': 0x12,
    '2': 0x13,
    '3': 0x14,
    '4': 0x15,
    '6': 0x16,
    '5': 0x17,
    '9': 0x19,
    '7': 0x1A,
    '8': 0x1C,
    '0': 0x1D,
    'O': 0x1F,
    'U': 0x20,
    'I': 0x22,
    'P': 0x23,
    'L': 0x25,
    'J': 0x26,
    'K': 0x28,
    'N': 0x2D,
    'M': 0x2E,
    'F1': 122,
    'F2': 120,
    'F3': 99,
    'F4': 118,
    'F5': 96,
    'F6': 97,
    'F7': 98,
    'F8': 100,
    'F9': 101,
    'F10': 109,
    'F11': 103,
    'F12': 111,
  };
}

class MainWindowHotkeyManager {
  MainWindowHotkeyManager._();

  static final MainWindowHotkeyManager instance = MainWindowHotkeyManager._();

  bool get isSupported => isWindows || isMacOS;

  MainWindowHotkey get currentHotkey =>
      MainWindowHotkey.tryParse(
        bind.mainGetLocalOption(key: kOptionMainWindowHotkey),
      ) ??
      MainWindowHotkey.recommended();

  Future<void> initialize() async {
    if (!isSupported) {
      return;
    }
    RdPlatformChannel.instance.setMainWindowHotKeyHandler(() {
      toggleMainWindowVisibility();
    });
  }

  Future<void> ensureStoredHotkey() async {
    if (bind.mainGetLocalOption(key: kOptionMainWindowHotkey).trim().isEmpty) {
      await bind.mainSetLocalOption(
        key: kOptionMainWindowHotkey,
        value: MainWindowHotkey.recommended().toStorage(),
      );
    }
  }

  Future<bool> reload({bool showError = false}) async {
    if (!isSupported) {
      return false;
    }
    await initialize();
    await RdPlatformChannel.instance.unregisterMainWindowHotKey();
    if (!mainGetLocalBoolOptionSync(kOptionEnableMainWindowHotkey)) {
      return true;
    }
    await ensureStoredHotkey();
    final hotkey = currentHotkey;
    final error = hotkey.validationError;
    if (error != null) {
      if (showError) {
        showToast(error);
      }
      return false;
    }
    final registered = await RdPlatformChannel.instance.registerMainWindowHotKey(
      keyCode: hotkey.platformKeyCode,
      alt: hotkey.alt,
      control: hotkey.control,
      meta: hotkey.meta,
    );
    if (!registered && showError) {
      showToast('The shortcut is unavailable. Try another key.');
    }
    return registered;
  }
}
