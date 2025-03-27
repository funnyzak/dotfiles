# Description: MinIO client (mc) aliases for object storage operations, management, and file transfers.

# Helper function - Check if mc command is available
_check_mc_installed_mc() {
  if ! command -v mc &> /dev/null; then
    echo "Error: MinIO client (mc) is not installed or not in PATH"
    echo "Please install MinIO client first: https://min.io/docs/minio/linux/reference/minio-mc.html"
    return 1
  fi
  return 0
}

# Helper function - Validate MinIO alias
_validate_minio_alias_mc() {
  if [ -z "$1" ]; then
    echo "Error: MinIO alias cannot be empty"
    return 1
  fi

  # Verify if the alias is configured
  if ! mc config host ls | grep -q "^$1\s"; then
    echo "Warning: MinIO alias \"$1\" may not be configured yet"
    echo "Tip: Use minio_add_host command to add a new MinIO host configuration"
  fi

  return 0
}

# MinIO host management
alias minio_add_host='() {
  if [ $# -lt 2 ]; then
    echo "Add MinIO host configuration.\nUsage:\n minio_add_host <alias> <serverURL> [accessKey] [secretKey]"
    echo "Example:\n minio_add_host myminio http://192.168.1.100:9000"
    echo "      minio_add_host myminio http://192.168.1.100:9000 accesskey secretkey"
    return 1
  fi

  if ! _check_mc_installed_mc; then
    return 1
  fi

  alias="$1"
  url="$2"
  access_key="$3"
  secret_key="$4"

  echo "Adding MinIO host \"$alias\" connecting to \"$url\"..."

  if [ -n "$access_key" ] && [ -n "$secret_key" ]; then
    if mc config host add "$alias" "$url" "$access_key" "$secret_key"; then
      echo "Successfully added MinIO host \"$alias\""
    else
      echo "Error: Unable to add MinIO host"
      return 1
    fi
  else
    if mc config host add "$alias" "$url"; then
      echo "Successfully added MinIO host \"$alias\""
    else
      echo "Error: Unable to add MinIO host"
      return 1
    fi
  fi
}'  # Add MinIO host configuration

alias minio_list_hosts='() {
  if ! _check_mc_installed_mc; then
    return 1
  fi

  echo "Listing all configured MinIO hosts..."
  mc config host ls
}'  # List all configured MinIO hosts

alias minio_remove_host='() {
  if [ $# -eq 0 ]; then
    echo "Remove MinIO host configuration.\nUsage:\n minio_remove_host <alias>"
    return 1
  fi

  if ! _check_mc_installed_mc; then
    return 1
  fi

  alias="$1"
  echo "Removing MinIO host \"$alias\"..."

  if mc config host rm "$alias"; then
    echo "Successfully removed MinIO host \"$alias\""
  else
    echo "Error: Unable to remove MinIO host \"$alias\""
    return 1
  fi
}'  # Remove MinIO host configuration

# Bucket and object operations
alias minio_list='() {
  if [ $# -eq 0 ]; then
    echo "List MinIO buckets or objects.\nUsage:\n minio_list <alias>[/bucketName[/objectPath]]"
    echo "Example:\n minio_list myminio            # List all buckets"
    echo "      minio_list myminio/bucket      # List objects in the bucket"
    echo "      minio_list myminio/bucket/dir  # List objects in the specified directory"
    return 1
  fi

  if ! _check_mc_installed_mc; then
    return 1
  fi

  path="$1"
  alias=$(echo "$path" | cut -d'/' -f1)

  if ! _validate_minio_alias_mc "$alias"; then
    # Only warn, do not block execution
    :
  fi

  echo "Listing contents of \"$path\"..."

  if mc ls "$path"; then
    echo "List operation completed"
  else
    echo "Error: Unable to list contents of \"$path\", please check if the path is correct"
    return 1
  fi
}'  # List MinIO buckets or objects

alias minio_make_bucket='() {
  if [ $# -lt 2 ]; then
    echo "Create MinIO bucket.\nUsage:\n minio_make_bucket <alias> <bucketName>"
    echo "Example:\n minio_make_bucket myminio my-new-bucket"
    return 1
  fi

  if ! _check_mc_installed_mc; then
    return 1
  fi

  alias="$1"
  bucket="$2"

  if ! _validate_minio_alias_mc "$alias"; then
    # Only warn, do not block execution
    :
  fi

  echo "Creating bucket \"$bucket\" on host \"$alias\"..."

  if mc mb "$alias/$bucket"; then
    echo "Bucket \"$bucket\" created successfully"
  else
    echo "Error: Unable to create bucket, it may already exist or you do not have sufficient permissions"
    return 1
  fi
}'  # Create MinIO bucket

alias minio_remove_bucket='() {
  if [ $# -lt 2 ]; then
    echo "Delete MinIO bucket.\nUsage:\n minio_remove_bucket <alias> <bucketName> [--force]"
    echo "Options:\n --force  Force delete non-empty bucket"
    echo "Example:\n minio_remove_bucket myminio my-bucket"
    echo "      minio_remove_bucket myminio my-bucket --force"
    return 1
  fi

  if ! _check_mc_installed_mc; then
    return 1
  fi

  alias="$1"
  bucket="$2"
  force=""

  if [ "$3" = "--force" ]; then
    force="--force"
  fi

  if ! _validate_minio_alias_mc "$alias"; then
    # Only warn, do not block execution
    :
  fi

  echo "Deleting bucket \"$bucket\" from host \"$alias\"..."

  if [ -n "$force" ]; then
    echo "Warning: Using force mode, all objects in the bucket will be deleted"
    if ! mc rb "$alias/$bucket" --force; then
      echo "Error: Unable to delete bucket"
      return 1
    fi
  else
    if ! mc rb "$alias/$bucket"; then
      echo "Error: Unable to delete bucket, it may not be empty or you do not have sufficient permissions"
      echo "Tip: Use --force option to force delete non-empty bucket"
      return 1
    fi
  fi

  echo "Bucket \"$bucket\" has been successfully deleted"
}'  # Delete MinIO bucket

alias minio_copy='() {
  if [ $# -lt 3 ]; then
    echo "Copy MinIO object.\nUsage:\n minio_copy <sourcePath> <targetPath> [options]"
    echo "Example:\n minio_copy myminio/bucket/file.txt myminio/bucket/backup/file.txt"
    echo "      minio_copy localfile.txt myminio/bucket/file.txt"
    echo "      minio_copy myminio/bucket/file.txt localfile.txt"
    return 1
  fi

  if ! _check_mc_installed_mc; then
    return 1
  fi

  source="$1"
  target="$2"
  options="${@:3}"

  # Check if the source path contains a MinIO alias
  if [[ "$source" == *"/"* ]]; then
    source_alias=$(echo "$source" | cut -d'/' -f1)
    if ! _validate_minio_alias_mc "$source_alias"; then
      # Only warn, do not block execution
      :
    fi
  fi

  # Check if the target path contains a MinIO alias
  if [[ "$target" == *"/"* ]]; then
    target_alias=$(echo "$target" | cut -d'/' -f1)
    if ! _validate_minio_alias_mc "$target_alias"; then
      # Only warn, do not block execution
      :
    fi
  fi

  echo "Copying \"$source\" to \"$target\"..."

  if mc cp $options "$source" "$target"; then
    echo "Copy operation completed"
  else
    echo "Error: Copy failed, please check the paths and permissions"
    return 1
  fi
}'  # Copy MinIO object

alias minio_remove='() {
  if [ $# -lt 2 ]; then
    echo "Delete MinIO object.\nUsage:\n minio_remove <alias> <objectPath> [--recursive]"
    echo "Options:\n --recursive  Recursively delete directory and its contents"
    echo "Example:\n minio_remove myminio bucket/file.txt"
    echo "      minio_remove myminio bucket/directory --recursive"
    return 1
  fi

  if ! _check_mc_installed_mc; then
    return 1
  fi

  alias="$1"
  object_path="$2"
  recursive=""

  if [ "$3" = "--recursive" ]; then
    recursive="--recursive"
  fi

  if ! _validate_minio_alias_mc "$alias"; then
    # Only warn, do not block execution
    :
  fi

  if [ -n "$recursive" ]; then
    echo "Warning: Using recursive mode, \"$alias/$object_path\" and all its contents will be deleted"
    read -p "Confirm deletion? (y/n): " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
      echo "Operation cancelled"
      return 0
    fi
  fi

  echo "Deleting object \"$alias/$object_path\"..."

  if mc rm $recursive "$alias/$object_path"; then
    echo "Delete operation completed"
  else
    echo "Error: Delete failed, please check the paths and permissions"
    return 1
  fi
}'  # Delete MinIO object

alias minio_cat='() {
  if [ $# -lt 2 ]; then
    echo "View MinIO object content.\nUsage:\n minio_cat <alias> <objectPath>"
    echo "Example:\n minio_cat myminio bucket/file.txt"
    return 1
  fi

  if ! _check_mc_installed_mc; then
    return 1
  fi

  alias="$1"
  object_path="$2"

  if ! _validate_minio_alias_mc "$alias"; then
    # Only warn, do not block execution
    :
  fi

  echo "Viewing content of object \"$alias/$object_path\"..."
  echo "----------------------------------------"

  if ! mc cat "$alias/$object_path"; then
    echo "----------------------------------------"
    echo "Error: Unable to view object content, please check if the path is correct"
    return 1
  fi

  echo "----------------------------------------"
}'  # View MinIO object content

alias minio_share='() {
  if [ $# -lt 2 ]; then
    echo "Generate a shareable link for MinIO object.\nUsage:\n minio_share <alias> <objectPath> [expirationTime:24h]"
    echo "Example:\n minio_share myminio bucket/file.txt"
    echo "      minio_share myminio bucket/file.txt 7d       # Expires in 7 days"
    echo "      minio_share myminio bucket/file.txt 12h      # Expires in 12 hours"
    return 1
  fi

  if ! _check_mc_installed_mc; then
    return 1
  fi

  alias="$1"
  object_path="$2"
  expire="${3:-24h}"

  if ! _validate_minio_alias_mc "$alias"; then
    # Only warn, do not block execution
    :
  fi

  echo "Generating a shareable link for object \"$alias/$object_path\" with an expiration time of $expire..."

  if mc share download --expire "$expire" "$alias/$object_path"; then
    echo "Link generated successfully"
  else
    echo "Error: Unable to generate shareable link, please check the paths and permissions"
    return 1
  fi
}'  # Generate a shareable link for MinIO object

alias minio_find='() {
  if [ $# -lt 2 ]; then
    echo "Find objects in MinIO.\nUsage:\n minio_find <alias>[/bucket] <pattern>"
    echo "Example:\n minio_find myminio \"*.jpg\"           # Find jpg files in all buckets"
    echo "      minio_find myminio/bucket \"*.txt\"     # Find txt files in the specified bucket"
    return 1
  fi

  if ! _check_mc_installed_mc; then
    return 1
  fi

  path="$1"
  pattern="$2"

  alias=$(echo "$path" | cut -d'/' -f1)

  if ! _validate_minio_alias_mc "$alias"; then
    # Only warn, do not block execution
    :
  fi

  echo "Finding objects matching \"$pattern\" in \"$path\"..."

  if mc find "$path" --name "$pattern"; then
    echo "Find operation completed"
  else
    echo "No matching objects found or an error occurred"
    return 1
  fi
}'  # Find objects in MinIO
