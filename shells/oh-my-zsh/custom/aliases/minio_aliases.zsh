# Description: MinIO client (mc) aliases for object storage operations, management, and file transfers.

# Helper function - Check if mc command is available
_minio_check_mc_installed() {
  if ! command -v mc &> /dev/null; then
    echo "Error: MinIO client (mc) is not installed or not in PATH" >&2
    echo "Please install MinIO client first: https://min.io/docs/minio/linux/reference/minio-mc.html" >&2
    return 1
  fi
  return 0
}

# Helper function - Validate MinIO alias
_minio_validate_alias() {
  if [ -z "$1" ]; then
    echo "Error: MinIO alias cannot be empty" >&2
    return 1
  fi

  # Verify if the alias is configured
  if ! mc config host ls | grep -q "^$1\s"; then
    echo "Warning: MinIO alias \"$1\" may not be configured yet" >&2
    echo "Tip: Use minio-add-host command to add a new MinIO host configuration" >&2
  fi

  return 0
}

# MinIO host management
alias minio-add-host='() {
  echo "Add MinIO host configuration.\nUsage:\n minio-add-host <alias> <serverURL> [accessKey] [secretKey]"

  if [ $# -lt 2 ]; then
    echo "Example:\n minio-add-host myminio http://192.168.1.100:9000" >&2
    echo "      minio-add-host myminio http://192.168.1.100:9000 accesskey secretkey" >&2
    return 1
  fi

  if ! _minio_check_mc_installed; then
    return 1
  fi

  local alias_name="$1"
  local url="$2"
  local access_key="$3"
  local secret_key="$4"

  echo "Adding MinIO host \"$alias_name\" connecting to \"$url\"..."

  if [ -n "$access_key" ] && [ -n "$secret_key" ]; then
    if mc config host add "$alias_name" "$url" "$access_key" "$secret_key"; then
      echo "Successfully added MinIO host \"$alias_name\""
    else
      echo "Error: Unable to add MinIO host" >&2
      return 1
    fi
  else
    if mc config host add "$alias_name" "$url"; then
      echo "Successfully added MinIO host \"$alias_name\""
    else
      echo "Error: Unable to add MinIO host" >&2
      return 1
    fi
  fi
}'  # Add MinIO host configuration

alias minio-list-hosts='() {
  echo "List all configured MinIO hosts."

  if ! _minio_check_mc_installed; then
    return 1
  fi

  echo "Listing all configured MinIO hosts..."
  mc config host ls
}'  # List all configured MinIO hosts

alias minio-remove-host='() {
  echo "Remove MinIO host configuration.\nUsage:\n minio-remove-host <alias>"

  if [ $# -eq 0 ]; then
    return 1
  fi

  if ! _minio_check_mc_installed; then
    return 1
  fi

  local alias_name="$1"
  echo "Removing MinIO host \"$alias_name\"..."

  if mc config host rm "$alias_name"; then
    echo "Successfully removed MinIO host \"$alias_name\""
  else
    echo "Error: Unable to remove MinIO host \"$alias_name\"" >&2
    return 1
  fi
}'  # Remove MinIO host configuration

# Bucket and object operations
alias minio-list='() {
  echo "List MinIO buckets or objects.\nUsage:\n minio-list <alias>[/bucketName[/objectPath]]"

  if [ $# -eq 0 ]; then
    echo "Example:\n minio-list myminio            # List all buckets" >&2
    echo "      minio-list myminio/bucket      # List objects in the bucket" >&2
    echo "      minio-list myminio/bucket/dir  # List objects in the specified directory" >&2
    return 1
  fi

  if ! _minio_check_mc_installed; then
    return 1
  fi

  local path="$1"
  local alias_name=$(echo "$path" | cut -d'/' -f1)

  if ! _minio_validate_alias "$alias_name"; then
    # Only warn, do not block execution
    :
  fi

  echo "Listing contents of \"$path\"..."

  if mc ls "$path"; then
    echo "List operation completed"
  else
    echo "Error: Unable to list contents of \"$path\", please check if the path is correct" >&2
    return 1
  fi
}'  # List MinIO buckets or objects

alias minio-make-bucket='() {
  echo "Create MinIO bucket.\nUsage:\n minio-make-bucket <alias> <bucketName>"

  if [ $# -lt 2 ]; then
    echo "Example:\n minio-make-bucket myminio my-new-bucket" >&2
    return 1
  fi

  if ! _minio_check_mc_installed; then
    return 1
  fi

  local alias_name="$1"
  local bucket="$2"

  if ! _minio_validate_alias "$alias_name"; then
    # Only warn, do not block execution
    :
  fi

  echo "Creating bucket \"$bucket\" on host \"$alias_name\"..."

  if mc mb "$alias_name/$bucket"; then
    echo "Bucket \"$bucket\" created successfully"
  else
    echo "Error: Unable to create bucket, it may already exist or you do not have sufficient permissions" >&2
    return 1
  fi
}'  # Create MinIO bucket

alias minio-remove-bucket='() {
  echo "Delete MinIO bucket.\nUsage:\n minio-remove-bucket <alias> <bucketName> [--force]"
  echo "Options:\n --force  Force delete non-empty bucket"

  if [ $# -lt 2 ]; then
    echo "Example:\n minio-remove-bucket myminio my-bucket" >&2
    echo "      minio-remove-bucket myminio my-bucket --force" >&2
    return 1
  fi

  if ! _minio_check_mc_installed; then
    return 1
  fi

  local alias_name="$1"
  local bucket="$2"
  local force=""

  if [ "$3" = "--force" ]; then
    force="--force"
  fi

  if ! _minio_validate_alias "$alias_name"; then
    # Only warn, do not block execution
    :
  fi

  echo "Deleting bucket \"$bucket\" from host \"$alias_name\"..."

  if [ -n "$force" ]; then
    echo "Warning: Using force mode, all objects in the bucket will be deleted"
    if ! mc rb "$alias_name/$bucket" --force; then
      echo "Error: Unable to delete bucket" >&2
      return 1
    fi
  else
    if ! mc rb "$alias_name/$bucket"; then
      echo "Error: Unable to delete bucket, it may not be empty or you do not have sufficient permissions" >&2
      echo "Tip: Use --force option to force delete non-empty bucket" >&2
      return 1
    fi
  fi

  echo "Bucket \"$bucket\" has been successfully deleted"
}'  # Delete MinIO bucket

alias minio-copy='() {
  echo "Copy MinIO object.\nUsage:\n minio-copy <sourcePath> <targetPath> [options]"

  if [ $# -lt 2 ]; then
    echo "Example:\n minio-copy myminio/bucket/file.txt myminio/bucket/backup/file.txt" >&2
    echo "      minio-copy localfile.txt myminio/bucket/file.txt" >&2
    echo "      minio-copy myminio/bucket/file.txt localfile.txt" >&2
    return 1
  fi

  if ! _minio_check_mc_installed; then
    return 1
  fi

  local source="$1"
  local target="$2"
  local options="${@:3}"

  # Check if the source path contains a MinIO alias
  if [[ "$source" == *"/"* ]]; then
    local source_alias=$(echo "$source" | cut -d'/' -f1)
    if ! _minio_validate_alias "$source_alias"; then
      # Only warn, do not block execution
      :
    fi
  fi

  # Check if the target path contains a MinIO alias
  if [[ "$target" == *"/"* ]]; then
    local target_alias=$(echo "$target" | cut -d'/' -f1)
    if ! _minio_validate_alias "$target_alias"; then
      # Only warn, do not block execution
      :
    fi
  fi

  echo "Copying \"$source\" to \"$target\"..."

  if mc cp $options "$source" "$target"; then
    echo "Copy operation completed"
  else
    echo "Error: Copy failed, please check the paths and permissions" >&2
    return 1
  fi
}'  # Copy MinIO object

alias minio-remove='() {
  echo "Delete MinIO object.\nUsage:\n minio-remove <alias> <objectPath> [--recursive]"
  echo "Options:\n --recursive  Recursively delete directory and its contents"

  if [ $# -lt 2 ]; then
    echo "Example:\n minio-remove myminio bucket/file.txt" >&2
    echo "      minio-remove myminio bucket/directory --recursive" >&2
    return 1
  fi

  if ! _minio_check_mc_installed; then
    return 1
  fi

  local alias_name="$1"
  local object_path="$2"
  local recursive=""

  if [ "$3" = "--recursive" ]; then
    recursive="--recursive"
  fi

  if ! _minio_validate_alias "$alias_name"; then
    # Only warn, do not block execution
    :
  fi

  if [ -n "$recursive" ]; then
    echo "Warning: Using recursive mode, \"$alias_name/$object_path\" and all its contents will be deleted"
    read -p "Confirm deletion? (y/n): " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
      echo "Operation cancelled"
      return 0
    fi
  fi

  echo "Deleting object \"$alias_name/$object_path\"..."

  if mc rm $recursive "$alias_name/$object_path"; then
    echo "Delete operation completed"
  else
    echo "Error: Delete failed, please check the paths and permissions" >&2
    return 1
  fi
}'  # Delete MinIO object

alias minio-cat='() {
  echo "View MinIO object content.\nUsage:\n minio-cat <alias> <objectPath>"

  if [ $# -lt 2 ]; then
    echo "Example:\n minio-cat myminio bucket/file.txt" >&2
    return 1
  fi

  if ! _minio_check_mc_installed; then
    return 1
  fi

  local alias_name="$1"
  local object_path="$2"

  if ! _minio_validate_alias "$alias_name"; then
    # Only warn, do not block execution
    :
  fi

  echo "Viewing content of object \"$alias_name/$object_path\"..."
  echo "----------------------------------------"

  if ! mc cat "$alias_name/$object_path"; then
    echo "----------------------------------------"
    echo "Error: Unable to view object content, please check if the path is correct" >&2
    return 1
  fi

  echo "----------------------------------------"
}'  # View MinIO object content

alias minio-share='() {
  echo "Generate a shareable link for MinIO object.\nUsage:\n minio-share <alias> <objectPath> [expirationTime:24h]"

  if [ $# -lt 2 ]; then
    echo "Example:\n minio-share myminio bucket/file.txt" >&2
    echo "      minio-share myminio bucket/file.txt 7d       # Expires in 7 days" >&2
    echo "      minio-share myminio bucket/file.txt 12h      # Expires in 12 hours" >&2
    return 1
  fi

  if ! _minio_check_mc_installed; then
    return 1
  fi

  local alias_name="$1"
  local object_path="$2"
  local expire="${3:-24h}"

  if ! _minio_validate_alias "$alias_name"; then
    # Only warn, do not block execution
    :
  fi

  echo "Generating a shareable link for object \"$alias_name/$object_path\" with an expiration time of $expire..."

  if mc share download --expire "$expire" "$alias_name/$object_path"; then
    echo "Link generated successfully"
  else
    echo "Error: Unable to generate shareable link, please check the paths and permissions" >&2
    return 1
  fi
}'  # Generate a shareable link for MinIO object

alias minio-find='() {
  echo "Find objects in MinIO.\nUsage:\n minio-find <alias>[/bucket] <pattern>"

  if [ $# -lt 2 ]; then
    echo "Example:\n minio-find myminio \"*.jpg\"           # Find jpg files in all buckets" >&2
    echo "      minio-find myminio/bucket \"*.txt\"     # Find txt files in the specified bucket" >&2
    return 1
  fi

  if ! _minio_check_mc_installed; then
    return 1
  fi

  local path="$1"
  local pattern="$2"

  local alias_name=$(echo "$path" | cut -d'/' -f1)

  if ! _minio_validate_alias "$alias_name"; then
    # Only warn, do not block execution
    :
  fi

  echo "Finding objects matching \"$pattern\" in \"$path\"..."

  if mc find "$path" --name "$pattern"; then
    echo "Find operation completed"
  else
    echo "No matching objects found or an error occurred" >&2
    return 1
  fi
}'  # Find objects in MinIO

# Additional useful MinIO operations
alias minio-sync='() {
  echo "Synchronize files between local filesystem and MinIO or between MinIO locations.\nUsage:\n minio-sync <source> <target> [options]"

  if [ $# -lt 2 ]; then
    echo "Example:\n minio-sync /local/folder myminio/bucket/folder" >&2
    echo "      minio-sync myminio/bucket/folder /local/folder" >&2
    echo "      minio-sync myminio/bucket1/folder myminio/bucket2/folder" >&2
    echo "Options:\n --remove  Remove extraneous files from target" >&2
    return 1
  fi

  if ! _minio_check_mc_installed; then
    return 1
  fi

  local source="$1"
  local target="$2"
  local options="${@:3}"

  # Check if the source path contains a MinIO alias
  if [[ "$source" == *"/"* ]]; then
    local source_alias=$(echo "$source" | cut -d'/' -f1)
    if [[ "$source_alias" != /* ]] && [[ "$source_alias" != .* ]]; then
      if ! _minio_validate_alias "$source_alias"; then
        # Only warn, do not block execution
        :
      fi
    fi
  fi

  # Check if the target path contains a MinIO alias
  if [[ "$target" == *"/"* ]]; then
    local target_alias=$(echo "$target" | cut -d'/' -f1)
    if [[ "$target_alias" != /* ]] && [[ "$target_alias" != .* ]]; then
      if ! _minio_validate_alias "$target_alias"; then
        # Only warn, do not block execution
        :
      fi
    fi
  fi

  echo "Synchronizing \"$source\" to \"$target\"..."

  if mc mirror $options "$source" "$target"; then
    echo "Synchronization completed successfully"
  else
    echo "Error: Synchronization failed, please check the paths and permissions" >&2
    return 1
  fi
}'  # Synchronize files between local filesystem and MinIO

alias minio-policy='() {
  echo "Manage bucket policies.\nUsage:\n minio-policy <command> <alias> <bucket> [policy]"
  echo "Commands:\n set    Set bucket policy\n get    Get bucket policy\n list   List all bucket policies\n remove Remove bucket policy"
  echo "Policies:\n public    Public read-only access\n download  Public download access\n upload    Public upload access\n none      No public access"

  if [ $# -lt 3 ]; then
    echo "Example:\n minio-policy set myminio my-bucket download" >&2
    echo "      minio-policy get myminio my-bucket" >&2
    echo "      minio-policy remove myminio my-bucket" >&2
    return 1
  fi

  if ! _minio_check_mc_installed; then
    return 1
  fi

  local command="$1"
  local alias_name="$2"
  local bucket="$3"
  local policy="$4"

  if ! _minio_validate_alias "$alias_name"; then
    # Only warn, do not block execution
    :
  fi

  case "$command" in
    set)
      if [ -z "$policy" ]; then
        echo "Error: Policy type is required for 'set' command" >&2
        return 1
      fi
      echo "Setting \"$policy\" policy for bucket \"$alias_name/$bucket\"..."
      if mc policy set "$policy" "$alias_name/$bucket"; then
        echo "Policy set successfully"
      else
        echo "Error: Failed to set policy" >&2
        return 1
      fi
      ;;
    get)
      echo "Getting policy for bucket \"$alias_name/$bucket\"..."
      if ! mc policy get "$alias_name/$bucket"; then
        echo "Error: Failed to get policy" >&2
        return 1
      fi
      ;;
    list)
      echo "Listing policies for \"$alias_name/$bucket\"..."
      if ! mc policy list "$alias_name/$bucket"; then
        echo "Error: Failed to list policies" >&2
        return 1
      fi
      ;;
    remove)
      echo "Removing policy from bucket \"$alias_name/$bucket\"..."
      if mc policy set none "$alias_name/$bucket"; then
        echo "Policy removed successfully"
      else
        echo "Error: Failed to remove policy" >&2
        return 1
      fi
      ;;
    *)
      echo "Error: Unknown command \"$command\". Use 'set', 'get', 'list', or 'remove'" >&2
      return 1
      ;;
  esac
}'  # Manage bucket policies

alias minio-events='() {
  echo "Manage bucket events.\nUsage:\n minio-events <command> <alias> <bucket> [args...]"
  echo "Commands:\n add     Add a new bucket notification\n list    List bucket notifications\n remove  Remove a bucket notification"

  if [ $# -lt 3 ]; then
    echo "Example:\n minio-events list myminio my-bucket" >&2
    echo "      minio-events add myminio my-bucket arn:aws:sqs::1:webhook --event put" >&2
    echo "      minio-events remove myminio my-bucket arn:aws:sqs::1:webhook" >&2
    return 1
  fi

  if ! _minio_check_mc_installed; then
    return 1
  fi

  local command="$1"
  local alias_name="$2"
  local bucket="$3"
  local args="${@:4}"

  if ! _minio_validate_alias "$alias_name"; then
    # Only warn, do not block execution
    :
  fi

  case "$command" in
    add)
      if [ -z "$args" ]; then
        echo "Error: Event configuration is required for 'add' command" >&2
        return 1
      fi
      echo "Adding event notification to bucket \"$alias_name/$bucket\"..."
      if mc event add "$alias_name/$bucket" $args; then
        echo "Event notification added successfully"
      else
        echo "Error: Failed to add event notification" >&2
        return 1
      fi
      ;;
    list)
      echo "Listing event notifications for bucket \"$alias_name/$bucket\"..."
      if ! mc event list "$alias_name/$bucket"; then
        echo "Error: Failed to list event notifications" >&2
        return 1
      fi
      ;;
    remove)
      if [ -z "$args" ]; then
        echo "Error: Event ARN is required for 'remove' command" >&2
        return 1
      fi
      echo "Removing event notification from bucket \"$alias_name/$bucket\"..."
      if mc event remove "$alias_name/$bucket" $args; then
        echo "Event notification removed successfully"
      else
        echo "Error: Failed to remove event notification" >&2
        return 1
      fi
      ;;
    *)
      echo "Error: Unknown command \"$command\". Use 'add', 'list', or 'remove'" >&2
      return 1
      ;;
  esac
}'  # Manage bucket events

alias minio-encrypt='() {
  echo "Encrypt/Decrypt files.\nUsage:\n minio-encrypt <command> <source> <target> <passphrase>"
  echo "Commands:\n encrypt    Encrypt file\n decrypt    Decrypt file"

  if [ $# -lt 4 ]; then
    echo "Example:\n minio-encrypt encrypt myfile.txt myfile.txt.enc "my secret passphrase"" >&2
    echo "      minio-encrypt decrypt myfile.txt.enc myfile.txt "my secret passphrase"" >&2
    return 1
  fi

  if ! _minio_check_mc_installed; then
    return 1
  fi

  local command="$1"
  local source="$2"
  local target="$3"
  local passphrase="$4"

  case "$command" in
    encrypt)
      echo "Encrypting \"$source\" to \"$target\"..."
      if echo "$passphrase" | mc encrypt "$source" "$target"; then
        echo "File encrypted successfully"
      else
        echo "Error: Failed to encrypt file" >&2
        return 1
      fi
      ;;
    decrypt)
      echo "Decrypting \"$source\" to \"$target\"..."
      if echo "$passphrase" | mc decrypt "$source" "$target"; then
        echo "File decrypted successfully"
      else
        echo "Error: Failed to decrypt file" >&2
        return 1
      fi
      ;;
    *)
      echo "Error: Unknown command \"$command\". Use 'encrypt' or 'decrypt'" >&2
      return 1
      ;;
  esac
}'  # Encrypt/Decrypt files

# Help function for MinIO aliases
alias minio-help='() {
  echo "MinIO Client (mc) Aliases Help"
  echo "============================="
  echo ""
  echo "Host Management:"
  echo "  minio-add-host       - Add MinIO host configuration"
  echo "  minio-list-hosts     - List all configured MinIO hosts"
  echo "  minio-remove-host    - Remove MinIO host configuration"
  echo ""
  echo "Bucket Operations:"
  echo "  minio-list           - List MinIO buckets or objects"
  echo "  minio-make-bucket    - Create MinIO bucket"
  echo "  minio-remove-bucket  - Delete MinIO bucket"
  echo "  minio-policy         - Manage bucket policies"
  echo "  minio-events         - Manage bucket events"
  echo ""
  echo "Object Operations:"
  echo "  minio-copy           - Copy MinIO object"
  echo "  minio-remove         - Delete MinIO object"
  echo "  minio-cat            - View MinIO object content"
  echo "  minio-share          - Generate a shareable link for MinIO object"
  echo "  minio-find           - Find objects in MinIO"
  echo "  minio-sync           - Synchronize files between local filesystem and MinIO"
  echo "  minio-encrypt        - Encrypt/Decrypt files"
  echo ""
  echo "For detailed usage of each command, run the command without arguments."
}'  # Help function for MinIO aliases
