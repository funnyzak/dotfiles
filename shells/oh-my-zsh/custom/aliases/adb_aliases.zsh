# Description: ADB (Android Debug Bridge) related aliases for Android development and debugging.

# Helper functions
# ---------------

# Helper function to check if adb is installed
_adb_check_installed() {
  if ! command -v adb >/dev/null 2>&1; then
    echo >&2 "Error: adb is not installed. Please install Android SDK platform tools first."
    return 1
  fi
  return 0
}

# Helper function to display error message
_adb_error() {
  echo >&2 "Error: $1"
  return 1
}

# Helper function to check if device is connected
_adb_check_device() {
  local device_count
  device_count=$(adb devices | grep -v "List of devices attached" | grep -v "^$" | wc -l | tr -d " ")

  if [ "$device_count" -eq 0 ]; then
    _adb_error "No Android devices connected. Please connect a device and try again."
    return 1
  fi

  return 0
}

# Helper function to check if multiple devices are connected
_adb_check_multiple_devices() {
  local device_count
  device_count=$(adb devices | grep -v "List of devices attached" | grep -v "^$" | wc -l | tr -d " ")

  if [ "$device_count" -gt 1 ]; then
    echo "Multiple devices detected. Please specify a device with -s option or set ANDROID_SERIAL environment variable."
    adb devices
    return 0
  fi

  return 1
}

# Basic Device Commands
# -------------------

alias adb-devices='() {
  echo "List all connected Android devices."
  echo "Usage: adb-devices"

  # Check if adb is installed
  _adb_check_installed || return 1

  echo "Listing connected Android devices..."
  adb devices -l
}' # List all connected Android devices with details

alias adb-connect='() {
  echo "Connect to a device over TCP/IP."
  echo "Usage: adb-connect <ip_address[:port]>"
  echo "Example: adb-connect 192.168.1.100:5555"

  # Check if adb is installed
  _adb_check_installed || return 1

  # Verify parameters
  if [ $# -eq 0 ]; then
    _adb_error "No IP address specified. Please provide an IP address."
    return 1
  fi

  echo "Connecting to device at $1..."
  adb connect "$1"
}' # Connect to a device over TCP/IP

alias adb-disconnect='() {
  echo "Disconnect from a device over TCP/IP."
  echo "Usage: adb-disconnect [ip_address[:port]]"
  echo "Example: adb-disconnect 192.168.1.100:5555"

  # Check if adb is installed
  _adb_check_installed || return 1

  if [ $# -eq 0 ]; then
    echo "Disconnecting from all connected devices..."
    adb disconnect
  else
    echo "Disconnecting from device at $1..."
    adb disconnect "$1"
  fi
}' # Disconnect from a device over TCP/IP

alias adb-tcpip='() {
  echo "Restart adb in TCP/IP mode on the specified port."
  echo "Usage: adb-tcpip <port_number:5555>"

  # Check if adb is installed
  _adb_check_installed || return 1

  # Check if device is connected
  _adb_check_device || return 1

  # Check if multiple devices are connected
  _adb_check_multiple_devices

  # Use default port if not specified
  local port=${1:-5555}

  echo "Restarting adb in TCP/IP mode on port $port..."
  adb tcpip "$port"
}' # Restart adb in TCP/IP mode

alias adb-usb='() {
  echo "Restart adb in USB mode."
  echo "Usage: adb-usb"

  # Check if adb is installed
  _adb_check_installed || return 1

  # Check if device is connected
  _adb_check_device || return 1

  # Check if multiple devices are connected
  _adb_check_multiple_devices

  echo "Restarting adb in USB mode..."
  adb usb
}' # Restart adb in USB mode

alias adb-reboot='() {
  echo "Reboot the device."
  echo "Usage: adb-reboot [bootloader|recovery|sideload|sideload-auto-reboot]"

  # Check if adb is installed
  _adb_check_installed || return 1

  # Check if device is connected
  _adb_check_device || return 1

  # Check if multiple devices are connected
  _adb_check_multiple_devices

  if [ $# -eq 0 ]; then
    echo "Rebooting device..."
    adb reboot
  else
    echo "Rebooting device into $1 mode..."
    adb reboot "$1"
  fi
}' # Reboot the device

# Application Management Commands
# -----------------------------

alias adb-install='() {
  echo "Install an APK on the device."
  echo "Usage: adb-install [-r] [-g] [-t] <apk_path>"
  echo "Options:"
  echo "  -r: Replace existing application"
  echo "  -g: Grant all runtime permissions"
  echo "  -t: Allow test packages"

  # Check if adb is installed
  _adb_check_installed || return 1

  # Check if device is connected
  _adb_check_device || return 1

  # Check if multiple devices are connected
  _adb_check_multiple_devices

  # Verify parameters
  if [ $# -eq 0 ]; then
    _adb_error "No APK file specified. Please provide an APK file path."
    return 1
  fi

  # Get the last argument as the APK path
  local apk_path="${@: -1}"

  # Check if the APK file exists
  if [ ! -f "$apk_path" ]; then
    _adb_error "APK file not found: $apk_path"
    return 1
  fi

  echo "Installing $apk_path..."
  adb install "$@"
}' # Install an APK on the device

alias adb-uninstall='() {
  echo "Uninstall an application from the device."
  echo "Usage: adb-uninstall [-k] <package_name>"
  echo "Options:"
  echo "  -k: Keep the data and cache directories"

  # Check if adb is installed
  _adb_check_installed || return 1

  # Check if device is connected
  _adb_check_device || return 1

  # Check if multiple devices are connected
  _adb_check_multiple_devices

  # Verify parameters
  if [ $# -eq 0 ]; then
    _adb_error "No package name specified. Please provide a package name."
    return 1
  fi

  echo "Uninstalling package $@..."
  adb uninstall "$@"
}' # Uninstall an application from the device

alias adb-packages='() {
  echo "List all installed packages on the device."
  echo "Usage: adb-packages [-s|-3|-f]"
  echo "Options:"
  echo "  -s: List system packages only"
  echo "  -3: List third-party packages only"
  echo "  -f: List package name and associated file"

  # Check if adb is installed
  _adb_check_installed || return 1

  # Check if device is connected
  _adb_check_device || return 1

  # Check if multiple devices are connected
  _adb_check_multiple_devices

  local option=""
  if [ $# -gt 0 ]; then
    option="$1"
  fi

  echo "Listing installed packages..."
  adb shell pm list packages "$option"
}' # List all installed packages on the device

alias adb-clear='() {
  echo "Clear app data for a specific package."
  echo "Usage: adb-clear <package_name>"

  # Check if adb is installed
  _adb_check_installed || return 1

  # Check if device is connected
  _adb_check_device || return 1

  # Check if multiple devices are connected
  _adb_check_multiple_devices

  # Verify parameters
  if [ $# -eq 0 ]; then
    _adb_error "No package name specified. Please provide a package name."
    return 1
  fi

  echo "Clearing data for package $1..."
  adb shell pm clear "$1"
}' # Clear app data for a specific package

alias adb-start='() {
  echo "Start an application on the device."
  echo "Usage: adb-start <package_name/activity_name>"
  echo "Example: adb-start com.android.settings/com.android.settings.Settings"

  # Check if adb is installed
  _adb_check_installed || return 1

  # Check if device is connected
  _adb_check_device || return 1

  # Check if multiple devices are connected
  _adb_check_multiple_devices

  # Verify parameters
  if [ $# -eq 0 ]; then
    _adb_error "No package/activity specified. Please provide a package/activity name."
    return 1
  fi

  echo "Starting $1..."
  adb shell am start -n "$1"
}' # Start an application on the device

alias adb-stop='() {
  echo "Force stop an application on the device."
  echo "Usage: adb-stop <package_name>"

  # Check if adb is installed
  _adb_check_installed || return 1

  # Check if device is connected
  _adb_check_device || return 1

  # Check if multiple devices are connected
  _adb_check_multiple_devices

  # Verify parameters
  if [ $# -eq 0 ]; then
    _adb_error "No package name specified. Please provide a package name."
    return 1
  fi

  echo "Force stopping $1..."
  adb shell am force-stop "$1"
}' # Force stop an application on the device

# File Management Commands
# ----------------------

alias adb-push='() {
  echo "Push a file or directory to the device."
  echo "Usage: adb-push <local_path> <remote_path>"

  # Check if adb is installed
  _adb_check_installed || return 1

  # Check if device is connected
  _adb_check_device || return 1

  # Check if multiple devices are connected
  _adb_check_multiple_devices

  # Verify parameters
  if [ $# -lt 2 ]; then
    _adb_error "Insufficient parameters. Please provide both local and remote paths."
    return 1
  fi

  # Check if the local file exists
  if [ ! -e "$1" ]; then
    _adb_error "Local file or directory not found: $1"
    return 1
  fi

  echo "Pushing $1 to $2..."
  adb push "$1" "$2"
}' # Push a file or directory to the device

alias adb-pull='() {
  echo "Pull a file or directory from the device."
  echo "Usage: adb-pull <remote_path> [local_path]"

  # Check if adb is installed
  _adb_check_installed || return 1

  # Check if device is connected
  _adb_check_device || return 1

  # Check if multiple devices are connected
  _adb_check_multiple_devices

  # Verify parameters
  if [ $# -eq 0 ]; then
    _adb_error "No remote path specified. Please provide a remote path."
    return 1
  fi

  if [ $# -eq 1 ]; then
    echo "Pulling $1 to current directory..."
    adb pull "$1" .
  else
    echo "Pulling $1 to $2..."
    adb pull "$1" "$2"
  fi
}' # Pull a file or directory from the device

alias adb-ls='() {
  echo "List files on the device."
  echo "Usage: adb-ls [remote_path:/sdcard]"

  # Check if adb is installed
  _adb_check_installed || return 1

  # Check if device is connected
  _adb_check_device || return 1

  # Check if multiple devices are connected
  _adb_check_multiple_devices

  local remote_path=${1:-/sdcard}

  echo "Listing files in $remote_path..."
  adb shell ls -la "$remote_path"
}' # List files on the device

alias adb-rm='() {
  echo "Remove a file or directory from the device."
  echo "Usage: adb-rm <remote_path>"

  # Check if adb is installed
  _adb_check_installed || return 1

  # Check if device is connected
  _adb_check_device || return 1

  # Check if multiple devices are connected
  _adb_check_multiple_devices

  # Verify parameters
  if [ $# -eq 0 ]; then
    _adb_error "No remote path specified. Please provide a remote path."
    return 1
  fi

  echo "Removing $1 from device..."
  adb shell rm -rf "$1"
}' # Remove a file or directory from the device

# Logging and Debugging Commands
# ----------------------------

alias adb-logcat='() {
  echo "View device log output."
  echo "Usage: adb-logcat [options] [filter_spec]"
  echo "Example: adb-logcat -v time ActivityManager:I *:E"

  # Check if adb is installed
  _adb_check_installed || return 1

  # Check if device is connected
  _adb_check_device || return 1

  # Check if multiple devices are connected
  _adb_check_multiple_devices

  echo "Starting logcat..."
  adb logcat "$@"
}' # View device log output

alias adb-logcat-clear='() {
  echo "Clear the logcat buffer."
  echo "Usage: adb-logcat-clear"

  # Check if adb is installed
  _adb_check_installed || return 1

  # Check if device is connected
  _adb_check_device || return 1

  # Check if multiple devices are connected
  _adb_check_multiple_devices

  echo "Clearing logcat buffer..."
  adb logcat -c
}' # Clear the logcat buffer

alias adb-bugreport='() {
  echo "Generate a bug report from the device."
  echo "Usage: adb-bugreport [output_path:./bugreport.zip]"

  # Check if adb is installed
  _adb_check_installed || return 1

  # Check if device is connected
  _adb_check_device || return 1

  # Check if multiple devices are connected
  _adb_check_multiple_devices

  local output_path=${1:-./bugreport.zip}

  echo "Generating bug report to $output_path..."
  adb bugreport "$output_path"
}' # Generate a bug report from the device

# Screen and Input Commands
# -----------------------

alias adb-screenshot='() {
  echo "Take a screenshot from the device."
  echo "Usage: adb-screenshot [output_path:./screenshot.png]"

  # Check if adb is installed
  _adb_check_installed || return 1

  # Check if device is connected
  _adb_check_device || return 1

  # Check if multiple devices are connected
  _adb_check_multiple_devices

  local output_path=${1:-./screenshot.png}
  local temp_path="/sdcard/screenshot.png"

  echo "Taking screenshot..."
  adb shell screencap -p "$temp_path"
  adb pull "$temp_path" "$output_path"
  adb shell rm "$temp_path"

  echo "Screenshot saved to $output_path"
}' # Take a screenshot from the device

alias adb-screenrecord='() {
  echo "Record the device screen."
  echo "Usage: adb-screenrecord [output_path:./screenrecord.mp4] [time_limit_seconds:180]"

  # Check if adb is installed
  _adb_check_installed || return 1

  # Check if device is connected
  _adb_check_device || return 1

  # Check if multiple devices are connected
  _adb_check_multiple_devices

  local output_path=${1:-./screenrecord.mp4}
  local time_limit=${2:-180}
  local temp_path="/sdcard/screenrecord.mp4"

  echo "Recording screen for $time_limit seconds..."
  echo "Press Ctrl+C to stop recording early."

  adb shell "screenrecord --time-limit $time_limit $temp_path"
  adb pull "$temp_path" "$output_path"
  adb shell rm "$temp_path"

  echo "Screen recording saved to $output_path"
}' # Record the device screen

alias adb-tap='() {
  echo "Simulate a tap on the screen."
  echo "Usage: adb-tap <x_coordinate> <y_coordinate>"

  # Check if adb is installed
  _adb_check_installed || return 1

  # Check if device is connected
  _adb_check_device || return 1

  # Check if multiple devices are connected
  _adb_check_multiple_devices

  # Verify parameters
  if [ $# -lt 2 ]; then
    _adb_error "Insufficient parameters. Please provide both x and y coordinates."
    return 1
  fi

  echo "Tapping at coordinates ($1, $2)..."
  adb shell input tap "$1" "$2"
}' # Simulate a tap on the screen

alias adb-swipe='() {
  echo "Simulate a swipe on the screen."
  echo "Usage: adb-swipe <x1> <y1> <x2> <y2> [duration_ms:300]"

  # Check if adb is installed
  _adb_check_installed || return 1

  # Check if device is connected
  _adb_check_device || return 1

  # Check if multiple devices are connected
  _adb_check_multiple_devices

  # Verify parameters
  if [ $# -lt 4 ]; then
    _adb_error "Insufficient parameters. Please provide x1, y1, x2, and y2 coordinates."
    return 1
  fi

  local duration=${5:-300}

  echo "Swiping from ($1, $2) to ($3, $4) with duration $duration ms..."
  adb shell input swipe "$1" "$2" "$3" "$4" "$duration"
}' # Simulate a swipe on the screen

alias adb-text='() {
  echo "Input text on the device."
  echo "Usage: adb-text <text>"

  # Check if adb is installed
  _adb_check_installed || return 1

  # Check if device is connected
  _adb_check_device || return 1

  # Check if multiple devices are connected
  _adb_check_multiple_devices

  # Verify parameters
  if [ $# -eq 0 ]; then
    _adb_error "No text specified. Please provide text to input."
    return 1
  fi

  echo "Inputting text: $1"
  adb shell input text "$1"
}' # Input text on the device

alias adb-key='() {
  echo "Simulate a keyevent on the device."
  echo "Usage: adb-key <keycode>"
  echo "Common keycodes: KEYCODE_HOME (3), KEYCODE_BACK (4), KEYCODE_MENU (82)"

  # Check if adb is installed
  _adb_check_installed || return 1

  # Check if device is connected
  _adb_check_device || return 1

  # Check if multiple devices are connected
  _adb_check_multiple_devices

  # Verify parameters
  if [ $# -eq 0 ]; then
    _adb_error "No keycode specified. Please provide a keycode."
    return 1
  fi

  echo "Sending keyevent: $1"
  adb shell input keyevent "$1"
}' # Simulate a keyevent on the device

# Network Commands
# --------------

alias adb-wifi='() {
  echo "Enable wireless debugging on device."
  echo "Usage: adb-wifi"

  # Check if adb is installed
  _adb_check_installed || return 1

  # Check if device is connected
  _adb_check_device || return 1

  # Check if multiple devices are connected
  _adb_check_multiple_devices

  local device_ip
  device_ip=$(adb shell ip route | awk '{print $9}' | head -n 1)

  if [ -z "$device_ip" ]; then
    _adb_error "Could not determine device IP address. Make sure the device is connected to WiFi."
    return 1
  fi

  echo "Device IP: $device_ip"
  echo "Enabling TCP/IP mode..."
  adb tcpip 5555

  echo "Wait a moment for the device to switch to TCP/IP mode..."
  sleep 3

  echo "Connecting to $device_ip:5555..."
  adb connect "$device_ip:5555"

  echo "You can now disconnect the USB cable and continue using ADB wirelessly."
}' # Enable wireless debugging on device

alias adb-forward='() {
  echo "Forward local port to device port."
  echo "Usage: adb-forward <local_port> <remote_port>"

  # Check if adb is installed
  _adb_check_installed || return 1

  # Check if device is connected
  _adb_check_device || return 1

  # Check if multiple devices are connected
  _adb_check_multiple_devices

  # Verify parameters
  if [ $# -lt 2 ]; then
    _adb_error "Insufficient parameters. Please provide both local and remote ports."
    return 1
  fi

  echo "Forwarding local port $1 to device port $2..."
  adb forward tcp:"$1" tcp:"$2"
}' # Forward local port to device port

alias adb-reverse='() {
  echo "Reverse forward device port to local port."
  echo "Usage: adb-reverse <remote_port> <local_port>"

  # Check if adb is installed
  _adb_check_installed || return 1

  # Check if device is connected
  _adb_check_device || return 1

  # Check if multiple devices are connected
  _adb_check_multiple_devices

  # Verify parameters
  if [ $# -lt 2 ]; then
    _adb_error "Insufficient parameters. Please provide both remote and local ports."
    return 1
  fi

  echo "Reverse forwarding device port $1 to local port $2..."
  adb reverse tcp:"$1" tcp:"$2"
}' # Reverse forward device port to local port

# System Commands
# -------------

alias adb-shell='() {
  echo "Start a remote shell on the device."
  echo "Usage: adb-shell [command]"

  # Check if adb is installed
  _adb_check_installed || return 1

  # Check if device is connected
  _adb_check_device || return 1

  # Check if multiple devices are connected
  _adb_check_multiple_devices

  if [ $# -eq 0 ]; then
    echo "Starting interactive shell..."
    adb shell
  else
    echo "Running command: $@"
    adb shell "$@"
  fi
}' # Start a remote shell on the device

alias adb-prop='() {
  echo "Get or set a system property."
  echo "Usage: adb-prop [property_name] [property_value]"

  # Check if adb is installed
  _adb_check_installed || return 1

  # Check if device is connected
  _adb_check_device || return 1

  # Check if multiple devices are connected
  _adb_check_multiple_devices

  if [ $# -eq 0 ]; then
    echo "Listing all system properties..."
    adb shell getprop
  elif [ $# -eq 1 ]; then
    echo "Getting property: $1"
    adb shell getprop "$1"
  else
    echo "Setting property $1 to $2..."
    adb shell setprop "$1" "$2"
  fi
}' # Get or set a system property

alias adb-version='() {
  echo "Show ADB version."
  echo "Usage: adb-version"

  # Check if adb is installed
  _adb_check_installed || return 1

  echo "ADB version:"
  adb version
}' # Show ADB version

alias adb-root='() {
  echo "Restart ADB with root permissions."
  echo "Usage: adb-root"

  # Check if adb is installed
  _adb_check_installed || return 1

  # Check if device is connected
  _adb_check_device || return 1

  # Check if multiple devices are connected
  _adb_check_multiple_devices

  echo "Restarting ADB with root permissions..."
  adb root
}' # Restart ADB with root permissions

alias adb-unroot='() {
  echo "Restart ADB without root permissions."
  echo "Usage: adb-unroot"

  # Check if adb is installed
  _adb_check_installed || return 1

  # Check if device is connected
  _adb_check_device || return 1

  # Check if multiple devices are connected
  _adb_check_multiple_devices

  echo "Restarting ADB without root permissions..."
  adb unroot
}' # Restart ADB without root permissions

# Help Command
# -----------

alias adb-help='() {
  echo "ADB aliases help guide"
  echo "--------------------"
  echo ""
  echo "Device Commands:"
  echo "  adb-devices       - List all connected Android devices"
  echo "  adb-connect       - Connect to a device over TCP/IP"
  echo "  adb-disconnect    - Disconnect from a device over TCP/IP"
  echo "  adb-tcpip         - Restart adb in TCP/IP mode"
  echo "  adb-usb           - Restart adb in USB mode"
  echo "  adb-reboot        - Reboot the device"
  echo "  adb-wifi          - Enable wireless debugging on device"
  echo ""
  echo "Application Commands:"
  echo "  adb-install       - Install an APK on the device"
  echo "  adb-uninstall     - Uninstall an application from the device"
  echo "  adb-packages      - List all installed packages"
  echo "  adb-clear         - Clear app data for a specific package"
  echo "  adb-start         - Start an application on the device"
  echo "  adb-stop          - Force stop an application on the device"
  echo ""
  echo "File Management Commands:"
  echo "  adb-push          - Push a file or directory to the device"
  echo "  adb-pull          - Pull a file or directory from the device"
  echo "  adb-ls            - List files on the device"
  echo "  adb-rm            - Remove a file or directory from the device"
  echo ""
  echo "Logging and Debugging Commands:"
  echo "  adb-logcat        - View device log output"
  echo "  adb-logcat-clear  - Clear the logcat buffer"
  echo "  adb-bugreport     - Generate a bug report from the device"
  echo ""
  echo "Screen and Input Commands:"
  echo "  adb-screenshot    - Take a screenshot from the device"
  echo "  adb-screenrecord  - Record the device screen"
  echo "  adb-tap           - Simulate a tap on the screen"
  echo "  adb-swipe         - Simulate a swipe on the screen"
  echo "  adb-text          - Input text on the device"
  echo "  adb-key           - Simulate a keyevent on the device"
  echo ""
  echo "Network Commands:"
  echo "  adb-forward       - Forward local port to device port"
  echo "  adb-reverse       - Reverse forward device port to local port"
  echo ""
  echo "System Commands:"
  echo "  adb-shell         - Start a remote shell on the device"
  echo "  adb-prop          - Get or set a system property"
  echo "  adb-version       - Show ADB version"
  echo "  adb-root          - Restart ADB with root permissions"
  echo "  adb-unroot        - Restart ADB without root permissions"
}' # Show help information for ADB aliases
