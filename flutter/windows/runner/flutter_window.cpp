#include "flutter_window.h"

#include <desktop_multi_window/desktop_multi_window_plugin.h>
#include <texture_rgba_renderer/texture_rgba_renderer_plugin_c_api.h>
#include <flutter_gpu_texture_renderer/flutter_gpu_texture_renderer_plugin_c_api.h>

#include "flutter/generated_plugin_registrant.h"

#include <flutter/event_channel.h>
#include <flutter/event_sink.h>
#include <flutter/event_stream_handler_functions.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <windows.h>

#include <optional>
#include <memory>

#include "win32_desktop.h"

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::RegisterMainWindowHotKey(const flutter::EncodableMap& args) {
  UnregisterMainWindowHotKey();

  UINT modifiers = 0;
  UINT key_code = 0;

  const auto key_it = args.find(flutter::EncodableValue("keyCode"));
  if (key_it != args.end() && std::holds_alternative<int>(key_it->second)) {
    key_code = std::get<int>(key_it->second);
  }
  if (key_code == 0) {
    return false;
  }

  const auto alt_it = args.find(flutter::EncodableValue("alt"));
  if (alt_it != args.end() && std::holds_alternative<bool>(alt_it->second) &&
      std::get<bool>(alt_it->second)) {
    modifiers |= MOD_ALT;
  }

  const auto control_it = args.find(flutter::EncodableValue("control"));
  if (control_it != args.end() &&
      std::holds_alternative<bool>(control_it->second) &&
      std::get<bool>(control_it->second)) {
    modifiers |= MOD_CONTROL;
  }

  const auto shift_it = args.find(flutter::EncodableValue("shift"));
  if (shift_it != args.end() && std::holds_alternative<bool>(shift_it->second) &&
      std::get<bool>(shift_it->second)) {
    modifiers |= MOD_SHIFT;
  }

  const auto meta_it = args.find(flutter::EncodableValue("meta"));
  if (meta_it != args.end() && std::holds_alternative<bool>(meta_it->second) &&
      std::get<bool>(meta_it->second)) {
    modifiers |= MOD_WIN;
  }

  main_window_hotkey_registered_ = RegisterHotKey(
      GetHandle(), main_window_hotkey_id_, modifiers | MOD_NOREPEAT, key_code);
  return main_window_hotkey_registered_;
}

void FlutterWindow::UnregisterMainWindowHotKey() {
  if (!main_window_hotkey_registered_) {
    return;
  }
  UnregisterHotKey(GetHandle(), main_window_hotkey_id_);
  main_window_hotkey_registered_ = false;
}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());

  host_channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(),
      "org.rustdesk.rustdesk/host",
      &flutter::StandardMethodCodec::GetInstance());

  host_channel_->SetMethodCallHandler(
    [this](const flutter::MethodCall<>& call, std::unique_ptr<flutter::MethodResult<>> result) {
      if (call.method_name() == "bumpMouse") {
        auto arguments = call.arguments();

        int dx = 0, dy = 0;

        if (std::holds_alternative<flutter::EncodableMap>(*arguments)) {
          auto argsMap = std::get<flutter::EncodableMap>(*arguments);

          auto dxIt = argsMap.find(flutter::EncodableValue("dx"));
          auto dyIt = argsMap.find(flutter::EncodableValue("dy"));

          if ((dxIt != argsMap.end()) && std::holds_alternative<int>(dxIt->second)) {
            dx = std::get<int>(dxIt->second);
          }
          if ((dyIt != argsMap.end()) && std::holds_alternative<int>(dyIt->second)) {
            dy = std::get<int>(dyIt->second);
          }
        } else if (std::holds_alternative<flutter::EncodableList>(*arguments)) {
          auto argsList = std::get<flutter::EncodableList>(*arguments);

          if ((argsList.size() >= 1) && std::holds_alternative<int>(argsList[0])) {
            dx = std::get<int>(argsList[0]);
          }
          if ((argsList.size() >= 2) && std::holds_alternative<int>(argsList[1])) {
            dy = std::get<int>(argsList[1]);
          }
        }

        bool succeeded = Win32Desktop::BumpMouse(dx, dy);

        result->Success(succeeded);
      } else if (call.method_name() == "registerMainWindowHotKey") {
        if (call.arguments() != nullptr &&
            std::holds_alternative<flutter::EncodableMap>(*call.arguments())) {
          const auto& args = std::get<flutter::EncodableMap>(*call.arguments());
          result->Success(RegisterMainWindowHotKey(args));
        } else {
          result->Success(false);
        }
      } else if (call.method_name() == "unregisterMainWindowHotKey") {
        UnregisterMainWindowHotKey();
        result->Success();
      } else {
        result->NotImplemented();
      }
    });

  DesktopMultiWindowSetWindowCreatedCallback([](void *controller) {
    auto *flutter_view_controller =
        reinterpret_cast<flutter::FlutterViewController *>(controller);
    auto *registry = flutter_view_controller->engine();
    TextureRgbaRendererPluginCApiRegisterWithRegistrar(
        registry->GetRegistrarForPlugin("TextureRgbaRendererPlugin"));
    FlutterGpuTextureRendererPluginCApiRegisterWithRegistrar(
        registry->GetRegistrarForPlugin("FlutterGpuTextureRendererPluginCApi"));
  });
  SetChildContent(flutter_controller_->view()->GetNativeWindow());
  return true;
}

void FlutterWindow::OnDestroy() {
  UnregisterMainWindowHotKey();
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
    case WM_HOTKEY:
      if (wparam == main_window_hotkey_id_ && host_channel_) {
        host_channel_->InvokeMethod("mainWindowHotKeyPressed", nullptr);
        return 0;
      }
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
