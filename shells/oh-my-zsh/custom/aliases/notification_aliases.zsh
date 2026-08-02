# Description: Notification related aliases for sending push notifications using Apprise.

# Apprise Push Notifications (requires Apprise and apprise command-line tool)
alias notif='() {
  echo -e "Send push notifications using Apprise.\nUsage:\n notif <message> [tag]\n  - message: The notification message to send\n  - tag: Optional tag for the notification (default: \"me\")"
  # Function to send push notifications using Apprise
  if [ $# -eq 0 ]; then
    echo "Usage: notif <message> [tag]"
    echo "  - message: The notification message to send"
    echo "  - tag: Optional tag for the notification (default: \"me\")"
    return 1
  fi

  message=$1
  tag=${2:-"me"}

  # Check if apprise is installed
  if ! command -v apprise >/dev/null 2>&1; then
    echo "Error: apprise command not found. Please install Apprise first." >&2
    return 2
  fi

  echo "Sending push notification with message: \"$message\" and tag: \"$tag\"..."

  # Send notification and capture exit status
  apprise -vv --tag="$tag" --body="$message" --title="Notification " || {
    echo "Error: Failed to send notification. Check apprise configuration." >&2
    return 3
  }

  echo "Notification sent successfully."
}' # Send push notification using Apprise

# Help function for notification aliases
alias notification-help='() {
  echo "Notification Aliases Help"
  echo "======================="
  echo "Available commands:"
  echo "  notif             - Send push notifications using Apprise"
  echo "  notification-help - Display this help message"
}' # Display help for notification aliases
