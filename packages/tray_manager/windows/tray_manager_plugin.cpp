#include "include/tray_manager/tray_manager_plugin.h"

// This must be included before many other Windows headers.
#include <stdio.h>
#include <windows.h>

#include <shellapi.h>
#include <strsafe.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <algorithm>
#include <codecvt>
#include <map>
#include <memory>
#include <sstream>
#include <vector>

#define WM_MYMESSAGE (WM_USER + 1)

namespace {

std::vector<HBITMAP> g_menu_bitmaps;
std::wstring_convert<std::codecvt_utf8_utf16<wchar_t>> g_menu_converter;

void ClearMenuBitmaps() {
  for (HBITMAP bmp : g_menu_bitmaps) {
    if (bmp) {
      DeleteObject(bmp);
    }
  }
  g_menu_bitmaps.clear();
}

HBITMAP IconToMenuBitmap(HICON icon, int size) {
  if (!icon) {
    return nullptr;
  }
  HDC hdc_screen = GetDC(nullptr);
  HDC hdc_mem = CreateCompatibleDC(hdc_screen);
  HBITMAP bmp =
      CreateCompatibleBitmap(hdc_screen, size, size);
  HGDIOBJ old_bmp = SelectObject(hdc_mem, bmp);
  RECT rect = {0, 0, size, size};
  FillRect(hdc_mem, &rect, (HBRUSH)GetStockObject(WHITE_BRUSH));
  DrawIconEx(hdc_mem, 0, 0, icon, size, size, 0, nullptr, DI_NORMAL);
  SelectObject(hdc_mem, old_bmp);
  DeleteDC(hdc_mem);
  ReleaseDC(nullptr, hdc_screen);
  return bmp;
}

HBITMAP ScaleBitmapToSize(HBITMAP src, int src_w, int src_h, int dst_w,
                          int dst_h) {
  if (!src || src_w <= 0 || src_h <= 0 || dst_w <= 0 || dst_h <= 0) {
    return nullptr;
  }
  if (src_w == dst_w && src_h == dst_h) {
    return static_cast<HBITMAP>(CopyImage(src, IMAGE_BITMAP, 0, 0, 0));
  }
  HDC hdc_screen = GetDC(nullptr);
  HDC hdc_src = CreateCompatibleDC(hdc_screen);
  HDC hdc_dst = CreateCompatibleDC(hdc_screen);
  HBITMAP dst = CreateCompatibleBitmap(hdc_screen, dst_w, dst_h);
  HGDIOBJ old_src = SelectObject(hdc_src, src);
  HGDIOBJ old_dst = SelectObject(hdc_dst, dst);
  SetStretchBltMode(hdc_dst, HALFTONE);
  SetBrushOrgEx(hdc_dst, 0, 0, nullptr);
  StretchBlt(hdc_dst, 0, 0, dst_w, dst_h, hdc_src, 0, 0, src_w, src_h,
             SRCCOPY);
  SelectObject(hdc_src, old_src);
  SelectObject(hdc_dst, old_dst);
  DeleteDC(hdc_src);
  DeleteDC(hdc_dst);
  ReleaseDC(nullptr, hdc_screen);
  return dst;
}

HBITMAP LoadMenuBitmapFromFile(const std::wstring& path) {
  const int size = GetSystemMetrics(SM_CXSMICON);
  HICON icon = static_cast<HICON>(LoadImageW(
      nullptr, path.c_str(), IMAGE_ICON, size, size, LR_LOADFROMFILE));
  if (icon) {
    HBITMAP bmp = IconToMenuBitmap(icon, size);
    DestroyIcon(icon);
    if (bmp) {
      return bmp;
    }
  }
  HBITMAP loaded = static_cast<HBITMAP>(LoadImageW(
      nullptr, path.c_str(), IMAGE_BITMAP, 0, 0,
      LR_LOADFROMFILE | LR_CREATEDIBSECTION | LR_DEFAULTSIZE));
  if (!loaded) {
    loaded = static_cast<HBITMAP>(LoadImageW(
        nullptr, path.c_str(), IMAGE_BITMAP, size, size,
        LR_LOADFROMFILE | LR_CREATEDIBSECTION));
    return loaded;
  }
  BITMAP bm = {};
  if (GetObject(loaded, sizeof(bm), &bm) == 0) {
    return loaded;
  }
  if (bm.bmWidth == size && bm.bmHeight == size) {
    return loaded;
  }
  HBITMAP scaled =
      ScaleBitmapToSize(loaded, bm.bmWidth, bm.bmHeight, size, size);
  DeleteObject(loaded);
  return scaled ? scaled : loaded;
}

HICON LoadTrayIconFromFile(const std::wstring& path) {
  const int cx = GetSystemMetrics(SM_CXSMICON);
  const int cy = GetSystemMetrics(SM_CYSMICON);
  HICON icon = static_cast<HICON>(LoadImageW(
      nullptr, path.c_str(), IMAGE_ICON, cx, cy, LR_LOADFROMFILE));
  if (icon) {
    return icon;
  }
  icon = static_cast<HICON>(LoadImageW(nullptr, path.c_str(), IMAGE_ICON, 0, 0,
                                      LR_LOADFROMFILE | LR_DEFAULTSIZE));
  if (icon) {
    return icon;
  }
  return static_cast<HICON>(LoadImageW(nullptr, path.c_str(), IMAGE_ICON, 32, 32,
                                       LR_LOADFROMFILE));
}

const flutter::EncodableValue* ValueOrNull(const flutter::EncodableMap& map,
                                           const char* key) {
  auto it = map.find(flutter::EncodableValue(key));
  if (it == map.end()) {
    return nullptr;
  }
  return &(it->second);
}
std::unique_ptr<
    flutter::MethodChannel<flutter::EncodableValue>,
    std::default_delete<flutter::MethodChannel<flutter::EncodableValue>>>
    channel = nullptr;

class TrayManagerPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  TrayManagerPlugin(flutter::PluginRegistrarWindows* registrar);

  virtual ~TrayManagerPlugin();

 private:
  std::wstring_convert<std::codecvt_utf8_utf16<wchar_t>> g_converter;

  flutter::PluginRegistrarWindows* registrar;
  NOTIFYICONDATA nid;
  NOTIFYICONIDENTIFIER niif;
  // do create pop-up menu only once.
  HMENU hMenu = CreatePopupMenu();
  bool tray_icon_setted = false;
  UINT windows_taskbar_created_message_id = 0;

  // The ID of the WindowProc delegate registration.
  int window_proc_id = -1;

  void TrayManagerPlugin::_CreateMenu(HMENU menu, flutter::EncodableMap args);
  void TrayManagerPlugin::_ApplyIcon();

  // Called for top-level WindowProc delegation.
  std::optional<LRESULT> TrayManagerPlugin::HandleWindowProc(HWND hwnd,
                                                             UINT message,
                                                             WPARAM wparam,
                                                             LPARAM lparam);
  HWND TrayManagerPlugin::GetMainWindow();
  void TrayManagerPlugin::Destroy(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void TrayManagerPlugin::SetIcon(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void TrayManagerPlugin::SetToolTip(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void TrayManagerPlugin::SetContextMenu(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void TrayManagerPlugin::PopUpContextMenu(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void TrayManagerPlugin::GetBounds(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

static bool plugin_already_registered = false;

// static
void TrayManagerPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  if (plugin_already_registered) {
    // Skip registration in subwindow
    return;
  }
  
  plugin_already_registered = true;
  
  channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      registrar->messenger(), "tray_manager",
      &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<TrayManagerPlugin>(registrar);

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto& call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

TrayManagerPlugin::TrayManagerPlugin(flutter::PluginRegistrarWindows* registrar)
    : registrar(registrar) {
  window_proc_id = registrar->RegisterTopLevelWindowProcDelegate(
      [this](HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam) {
        return HandleWindowProc(hwnd, message, wparam, lparam);
      });
  windows_taskbar_created_message_id = RegisterWindowMessage(L"TaskbarCreated");
}

TrayManagerPlugin::~TrayManagerPlugin() {
  registrar->UnregisterTopLevelWindowProcDelegate(window_proc_id);
}

void TrayManagerPlugin::_CreateMenu(HMENU menu, flutter::EncodableMap args) {
  flutter::EncodableList items = std::get<flutter::EncodableList>(
      args.at(flutter::EncodableValue("items")));

  int count = GetMenuItemCount(menu);
  for (int i = 0; i < count; i++) {
    // always remove at 0 because they shift every time
    RemoveMenu(menu, 0, MF_BYPOSITION);
  }
  if (menu == hMenu) {
    ClearMenuBitmaps();
  }

  for (flutter::EncodableValue item_value : items) {
    flutter::EncodableMap item_map =
        std::get<flutter::EncodableMap>(item_value);
    int id = std::get<int>(item_map.at(flutter::EncodableValue("id")));
    std::string type =
        std::get<std::string>(item_map.at(flutter::EncodableValue("type")));
    std::string label =
        std::get<std::string>(item_map.at(flutter::EncodableValue("label")));
    auto* checked = std::get_if<bool>(ValueOrNull(item_map, "checked"));
    auto* icon_path = std::get_if<std::string>(ValueOrNull(item_map, "icon"));
    bool disabled =
        std::get<bool>(item_map.at(flutter::EncodableValue("disabled")));

    UINT_PTR item_id = id;
    UINT uFlags = MF_STRING;
    std::wstring label_w = g_menu_converter.from_bytes(label);

    if (disabled) {
      uFlags |= MF_GRAYED;
    }

    if (type.compare("separator") == 0) {
      AppendMenuW(menu, MF_SEPARATOR, item_id, NULL);
    } else if (type.compare("submenu") == 0) {
      uFlags |= MF_POPUP;
      HMENU sub_menu = ::CreatePopupMenu();
      _CreateMenu(sub_menu, std::get<flutter::EncodableMap>(item_map.at(
                                flutter::EncodableValue("submenu"))));
      item_id = reinterpret_cast<UINT_PTR>(sub_menu);
      AppendMenuW(menu, uFlags, item_id, label_w.c_str());
    } else if (icon_path != nullptr && !icon_path->empty()) {
      const std::wstring icon_w = g_menu_converter.from_bytes(*icon_path);
      HBITMAP bmp = LoadMenuBitmapFromFile(icon_w);
      if (bmp) {
        g_menu_bitmaps.push_back(bmp);
      }

      MENUITEMINFOW mii = {};
      mii.cbSize = sizeof(MENUITEMINFOW);
      mii.fMask = MIIM_STRING | MIIM_ID | MIIM_BITMAP | MIIM_STATE | MIIM_FTYPE;
      mii.fType = MFT_STRING;
      mii.wID = static_cast<UINT>(id);
      mii.dwTypeData = const_cast<wchar_t*>(label_w.c_str());
      mii.hbmpItem = bmp;
      mii.fState = disabled ? (MFS_DISABLED | MFS_GRAYED) : MFS_ENABLED;
      if (type.compare("checkbox") == 0 && checked != nullptr) {
        mii.fState |= (*checked == true ? MFS_CHECKED : MFS_UNCHECKED);
      }
      InsertMenuItemW(menu, static_cast<UINT>(-1), TRUE, &mii);
    } else {
      if (type.compare("checkbox") == 0) {
        if (checked == nullptr) {
          // skip
        } else {
          uFlags |= (*checked == true ? MF_CHECKED : MF_UNCHECKED);
        }
      }
      AppendMenuW(menu, uFlags, item_id, label_w.c_str());
    }
  }
}

std::optional<LRESULT> TrayManagerPlugin::HandleWindowProc(HWND hWnd,
                                                           UINT message,
                                                           WPARAM wParam,
                                                           LPARAM lParam) {
  std::optional<LRESULT> result;
  if (message == WM_DESTROY) {
    if (tray_icon_setted) {
      Shell_NotifyIcon(NIM_DELETE, &nid);
      DestroyIcon(nid.hIcon);
    }
  } else if (message == WM_COMMAND) {
    flutter::EncodableMap eventData = flutter::EncodableMap();
    eventData[flutter::EncodableValue("id")] =
        flutter::EncodableValue((int)wParam);

    channel->InvokeMethod("onTrayMenuItemClick",
                          std::make_unique<flutter::EncodableValue>(eventData));
  } else if (message == WM_MYMESSAGE) {
    switch (lParam) {
      case WM_LBUTTONUP:
        channel->InvokeMethod("onTrayIconMouseDown",
                              std::make_unique<flutter::EncodableValue>());
        break;
      case WM_RBUTTONUP:
        channel->InvokeMethod("onTrayIconRightMouseDown",
                              std::make_unique<flutter::EncodableValue>());
        break;
      default:
        return DefWindowProc(hWnd, message, wParam, lParam);
    };
  } else if (message == windows_taskbar_created_message_id) {
    if (windows_taskbar_created_message_id != 0 && tray_icon_setted) {
      // restore the icon with the existing resource.
      tray_icon_setted = false;
      _ApplyIcon();
    }
  }
  return result;
}

HWND TrayManagerPlugin::GetMainWindow() {
  return ::GetAncestor(registrar->GetView()->GetNativeWindow(), GA_ROOT);
}

void TrayManagerPlugin::Destroy(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  Shell_NotifyIcon(NIM_DELETE, &nid);
  DestroyIcon(nid.hIcon);
  tray_icon_setted = false;

  result->Success(flutter::EncodableValue(true));
}

void TrayManagerPlugin::SetIcon(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const flutter::EncodableMap& args =
      std::get<flutter::EncodableMap>(*method_call.arguments());

  std::string iconPath =
      std::get<std::string>(args.at(flutter::EncodableValue("iconPath")));

  std::wstring_convert<std::codecvt_utf8_utf16<wchar_t>> converter;

  if (nid.hIcon != nullptr) {
    DestroyIcon(nid.hIcon);
  }

  const std::wstring wpath = converter.from_bytes(iconPath);
  nid.hIcon = LoadTrayIconFromFile(wpath);

  _ApplyIcon();

  result->Success(flutter::EncodableValue(true));
}

void TrayManagerPlugin::_ApplyIcon() {
  HWND hwnd = GetMainWindow();
  if (!hwnd || !nid.hIcon) {
    return;
  }

  nid.hWnd = hwnd;
  nid.uID = 1;
  nid.uCallbackMessage = WM_MYMESSAGE;
  nid.uFlags = NIF_MESSAGE | NIF_ICON;

  if (tray_icon_setted) {
    Shell_NotifyIcon(NIM_MODIFY, &nid);
  } else {
    nid.cbSize = sizeof(NOTIFYICONDATA);
    Shell_NotifyIcon(NIM_ADD, &nid);
    tray_icon_setted = true;
  }

  niif.cbSize = sizeof(NOTIFYICONIDENTIFIER);
  niif.hWnd = nid.hWnd;
  niif.uID = nid.uID;
  niif.guidItem = GUID_NULL;
}

void TrayManagerPlugin::SetToolTip(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const flutter::EncodableMap& args =
      std::get<flutter::EncodableMap>(*method_call.arguments());

  std::string toolTip =
      std::get<std::string>(args.at(flutter::EncodableValue("toolTip")));

  std::wstring_convert<std::codecvt_utf8_utf16<wchar_t>> converter;
  nid.uFlags = NIF_MESSAGE | NIF_ICON | NIF_TIP;
  StringCchCopy(nid.szTip, _countof(nid.szTip),
                converter.from_bytes(toolTip).c_str());
  Shell_NotifyIcon(NIM_MODIFY, &nid);

  result->Success(flutter::EncodableValue(true));
}

void TrayManagerPlugin::SetContextMenu(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const flutter::EncodableMap& args =
      std::get<flutter::EncodableMap>(*method_call.arguments());

  _CreateMenu(hMenu, std::get<flutter::EncodableMap>(
                         args.at(flutter::EncodableValue("menu"))));

  result->Success(flutter::EncodableValue(true));
}

void TrayManagerPlugin::PopUpContextMenu(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const flutter::EncodableMap& args =
      std::get<flutter::EncodableMap>(*method_call.arguments());

  bool bringAppToFront =
      std::get<bool>(args.at(flutter::EncodableValue("bringAppToFront")));

  HWND hWnd = GetMainWindow();

  double x, y;

  // RECT rect;
  // Shell_NotifyIconGetRect(&niif, &rect);

  // x = rect.left + ((rect.right - rect.left) / 2);
  // y = rect.top + ((rect.bottom - rect.top) / 2);

  POINT cursorPos;
  GetCursorPos(&cursorPos);
  x = cursorPos.x;
  y = cursorPos.y;

  if (bringAppToFront) {
    SetForegroundWindow(hWnd);
  }
  TrackPopupMenu(hMenu, TPM_BOTTOMALIGN | TPM_LEFTALIGN, static_cast<int>(x),
                 static_cast<int>(y), 0, hWnd, NULL);
  result->Success(flutter::EncodableValue(true));
}

void TrayManagerPlugin::GetBounds(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const flutter::EncodableMap& args =
      std::get<flutter::EncodableMap>(*method_call.arguments());

  if (!tray_icon_setted) {
    result->Success();
    return;
  }

  double devicePixelRatio =
      std::get<double>(args.at(flutter::EncodableValue("devicePixelRatio")));

  RECT rect;
  Shell_NotifyIconGetRect(&niif, &rect);
  flutter::EncodableMap resultMap = flutter::EncodableMap();

  double x = rect.left / devicePixelRatio * 1.0f;
  double y = rect.top / devicePixelRatio * 1.0f;
  double width = (rect.right - rect.left) / devicePixelRatio * 1.0f;
  double height = (rect.bottom - rect.top) / devicePixelRatio * 1.0f;

  resultMap[flutter::EncodableValue("x")] = flutter::EncodableValue(x);
  resultMap[flutter::EncodableValue("y")] = flutter::EncodableValue(y);
  resultMap[flutter::EncodableValue("width")] = flutter::EncodableValue(width);
  resultMap[flutter::EncodableValue("height")] =
      flutter::EncodableValue(height);

  result->Success(flutter::EncodableValue(resultMap));
}

void TrayManagerPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name().compare("destroy") == 0) {
    Destroy(method_call, std::move(result));
  } else if (method_call.method_name().compare("setIcon") == 0) {
    SetIcon(method_call, std::move(result));
  } else if (method_call.method_name().compare("setToolTip") == 0) {
    SetToolTip(method_call, std::move(result));
  } else if (method_call.method_name().compare("setContextMenu") == 0) {
    SetContextMenu(method_call, std::move(result));
  } else if (method_call.method_name().compare("popUpContextMenu") == 0) {
    PopUpContextMenu(method_call, std::move(result));
  } else if (method_call.method_name().compare("getBounds") == 0) {
    GetBounds(method_call, std::move(result));
  } else {
    result->NotImplemented();
  }
}

}  // namespace

void TrayManagerPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  TrayManagerPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
