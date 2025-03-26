# Description: Notification related aliases for sending push notifications using Apprise.

# Apprise Push Notifications (requires Apprise and apprise command-line tool)
alias apprise_push='() {
  echo "Send push notification using Apprise.\nUsage:\n push <message> [tag]"
  if [ $# -eq 0 ]; then
    echo "Please specify message to send."
    return 1
  fi
  message=$1
  tag=${2:-"me"}
  echo "Sending push notification with message: '$message' and tag: '$tag'..."
  apprise -vv --tag="$tag" --body="$message" --title="Notification "
}' # Send push notification using Apprise