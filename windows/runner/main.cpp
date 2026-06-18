#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

// recommended by NVIDIA to enable high-performance GPU
extern "C"
{
  __declspec(dllexport) DWORD NvOptimusEnablement = 0x00000001;
}

// recommended by AMD to enable high-performance GPU
extern "C"
{
  __declspec(dllexport) int AmdPowerXpressRequestHighPerformance = 1;
}

HANDLE mutex = NULL;

// Window class name must match the one in win32_window.cpp
constexpr const wchar_t kWindowClassName[] = L"FLUTTER_RUNNER_WIN32_WINDOW";
constexpr int kDefaultWindowWidth = 1280;
constexpr int kDefaultWindowHeight = 860;
constexpr int kMinimumWindowWidth = 960;
constexpr int kMinimumWindowHeight = 640;

BOOL CALLBACK FindKazumiWindowProc(HWND hwnd, LPARAM lparam)
{
  wchar_t class_name[256] = {};
  if (::GetClassName(hwnd, class_name, 256) == 0)
  {
    return TRUE;
  }

  if (std::wcscmp(class_name, kWindowClassName) == 0)
  {
    *reinterpret_cast<HWND *>(lparam) = hwnd;
    return FALSE;
  }

  return TRUE;
}

HWND FindKazumiWindow()
{
  HWND hwnd = nullptr;
  ::EnumWindows(FindKazumiWindowProc, reinterpret_cast<LPARAM>(&hwnd));
  return hwnd;
}

void EnsureUsableWindowSize(HWND hwnd)
{
  RECT rect = {};
  if (!::GetWindowRect(hwnd, &rect))
  {
    return;
  }

  const int width = rect.right - rect.left;
  const int height = rect.bottom - rect.top;
  if (width >= kMinimumWindowWidth && height >= kMinimumWindowHeight)
  {
    return;
  }

  ::SetWindowPos(hwnd, nullptr, rect.left, rect.top, kDefaultWindowWidth,
                 kDefaultWindowHeight, SWP_NOZORDER | SWP_NOACTIVATE);
}

bool ActivateExistingWindow()
{
  HWND hwnd = FindKazumiWindow();
  if (hwnd != NULL)
  {
    EnsureUsableWindowSize(hwnd);

    // Check if window is hidden (e.g., minimized to tray)
    if (!::IsWindowVisible(hwnd))
    {
      // Show the hidden window
      ::ShowWindow(hwnd, SW_SHOW);
    }
    // If window is minimized, restore it
    else if (::IsIconic(hwnd))
    {
      ::ShowWindow(hwnd, SW_RESTORE);
    }

    // Bring window to foreground
    ::SetForegroundWindow(hwnd);

    // Flash the window to get user's attention
    FLASHWINFO fwi = {0};
    fwi.cbSize = sizeof(FLASHWINFO);
    fwi.hwnd = hwnd;
    fwi.dwFlags = FLASHW_ALL | FLASHW_TIMERNOFG;
    fwi.uCount = 3;
    fwi.dwTimeout = 0;
    ::FlashWindowEx(&fwi);

    return true;
  }
  return false;
}

bool isSingleInstance()
{
  if (mutex != NULL)
  {
    return true;
  }
  std::wstring mutex_str = L"kazumi.win.mutex";
  mutex = ::CreateMutex(NULL, TRUE, mutex_str.c_str());
  if (mutex == NULL || GetLastError() == ERROR_ALREADY_EXISTS)
  {
    CloseHandle(mutex);
    mutex = NULL;
    return false;
  }
  return true;
}

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command)
{
  // Make sure the application is a single instance.
  // This is important for the application to work correctly with the local storage.
  if (!isSingleInstance())
  {
    // Try to activate the existing window instead of showing an error
    ActivateExistingWindow();
    return EXIT_SUCCESS;
  }
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent())
  {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  // Disable thread merge to improve performance
  // Attention: This may impact plugin performance and may be incompatible with future Flutter releases.
  project.set_ui_thread_policy(flutter::UIThreadPolicy::RunOnSeparateThread);

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(kDefaultWindowWidth, kDefaultWindowHeight);
  if (!window.Create(L"kazumi", origin, size))
  {
    if (mutex) {
      CloseHandle(mutex);
    }
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0))
  {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  if (mutex) {
    CloseHandle(mutex);
  }
  return EXIT_SUCCESS;
}
