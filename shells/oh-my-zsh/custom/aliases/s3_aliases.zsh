# Description: S3 protocol aliases for object storage operations across multiple providers (AWS S3, MinIO, Wasabi, etc.).

# Helper function - Check if AWS CLI is installed
_s3_check_aws_installed() {
  if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI is not installed or not in PATH" >&2
    echo "Please install AWS CLI first: https://aws.amazon.com/cli/" >&2
    return 1
  fi
  return 0
}

# Helper function - Check if s3cmd is installed
_s3_check_s3cmd_installed() {
  if ! command -v s3cmd &> /dev/null; then
    echo "Error: s3cmd is not installed or not in PATH" >&2
    echo "Please install s3cmd first: https://s3tools.org/s3cmd" >&2
    return 1
  fi
  return 0
}

# Helper function - Check if rclone is installed
_s3_check_rclone_installed() {
  if ! command -v rclone &> /dev/null; then
    echo "Error: rclone is not installed or not in PATH" >&2
    echo "Please install rclone first: https://rclone.org/install/" >&2
    return 1
  fi
  return 0
}

# Helper function - Show error message
_s3_show_error() {
  echo "Error: $1" >&2
}

# Helper function - Validate S3 profile
_s3_validate_profile() {
  local profile="$1"
  local tool="$2"

  if [ -z "$profile" ]; then
    echo "Error: S3 profile cannot be empty" >&2
    return 1
  fi

  case "$tool" in
    aws)
      # Verify if the profile is configured in AWS CLI
      if ! aws configure list --profile "$profile" &>/dev/null; then
        echo "Warning: AWS profile \"$profile\" may not be configured yet" >&2
        echo "Tip: Use s3-config-aws command to configure a new AWS profile" >&2
      fi
      ;;
    s3cmd)
      # Check if s3cmd config exists
      if [ ! -f "$HOME/.s3cfg" ]; then
        echo "Warning: s3cmd configuration file not found" >&2
        echo "Tip: Use s3-config-s3cmd command to configure s3cmd" >&2
      fi
      ;;
    rclone)
      # Verify if the remote is configured in rclone
      if ! rclone listremotes | grep -q "^$profile:$"; then
        echo "Warning: rclone remote \"$profile\" may not be configured yet" >&2
        echo "Tip: Use s3-config-rclone command to configure a new rclone remote" >&2
      fi
      ;;
  esac

  return 0
}

# Helper function - Get default profile from environment variable
_s3_get_default_profile() {
  local tool="$1"
  local default_profile=""

  case "$tool" in
    aws)
      default_profile="${S3_AWS_PROFILE:-default}"
      ;;
    s3cmd)
      default_profile="${S3_S3CMD_PROFILE:-default}"
      ;;
    rclone)
      default_profile="${S3_RCLONE_REMOTE:-s3}"
      ;;
  esac

  echo "$default_profile"
}

# Helper function - Get default region from environment variable
_s3_get_default_region() {
  echo "${S3_DEFAULT_REGION:-us-east-1}"
}

# S3 Configuration Management
alias s3-config-aws='() {
  echo "Configure AWS CLI profile for S3 access.\nUsage:\n s3-config-aws [profile_name:default]\nParameters:\n profile_name: AWS profile name to configure"

  if ! _s3_check_aws_installed; then
    return 1
  fi

  local profile="${1:-default}"

  echo "Configuring AWS CLI profile \"$profile\" for S3 access..."
  echo "You will be prompted to enter your AWS access key, secret key, region, and output format."
  echo "Note: For security, consider using AWS IAM roles or temporary credentials instead of long-term access keys."

  if aws configure --profile "$profile"; then
    echo "AWS CLI profile \"$profile\" configured successfully."
    echo "To set this as your default profile, run: export S3_AWS_PROFILE=$profile"
  else
    _s3_show_error "Failed to configure AWS CLI profile."
    return 1
  fi
}' # Configure AWS CLI profile for S3 access

alias s3-config-s3cmd='() {
  echo "Configure s3cmd for S3 access.\nUsage:\n s3-config-s3cmd"

  if ! _s3_check_s3cmd_installed; then
    return 1
  fi

  echo "Configuring s3cmd for S3 access..."
  echo "You will be prompted to enter your S3 access key, secret key, region, and other settings."
  echo "Note: For security, consider using temporary credentials or restricted IAM policies."

  if s3cmd --configure; then
    echo "s3cmd configured successfully."
  else
    _s3_show_error "Failed to configure s3cmd."
    return 1
  fi
}' # Configure s3cmd for S3 access

alias s3-config-rclone='() {
  echo "Configure rclone for S3 access.\nUsage:\n s3-config-rclone [remote_name:s3]"

  if ! _s3_check_rclone_installed; then
    return 1
  fi

  local remote="${1:-s3}"

  echo "Configuring rclone remote \"$remote\" for S3 access..."
  echo "You will be prompted to select a storage provider and enter your credentials."
  echo "Note: For security, consider using restricted access policies for your credentials."

  if rclone config create "$remote" s3; then
    echo "rclone remote \"$remote\" configured successfully."
    echo "To set this as your default remote, run: export S3_RCLONE_REMOTE=$remote"
  else
    _s3_show_error "Failed to configure rclone remote."
    return 1
  fi
}' # Configure rclone for S3 access

alias s3-list-profiles='() {
  echo "List configured S3 profiles across different tools.\nUsage:\n s3-list-profiles [--tool <aws|s3cmd|rclone>]"

  local tool=""

  # Parse arguments
  if [ "$1" = "--tool" ] && [ -n "$2" ]; then
    tool="$2"
    if [ "$tool" != "aws" ] && [ "$tool" != "s3cmd" ] && [ "$tool" != "rclone" ]; then
      _s3_show_error "Invalid tool specified. Use \"aws\", \"s3cmd\", or \"rclone\"."
      return 1
    fi
  fi

  echo "Listing configured S3 profiles..."

  if [ -z "$tool" ] || [ "$tool" = "aws" ]; then
    if _s3_check_aws_installed; then
      echo "\nAWS CLI profiles:"
      echo "----------------"
      aws configure list-profiles 2>/dev/null || echo "No AWS profiles found."
      echo "Default AWS profile: $(_s3_get_default_profile aws)"
    fi
  fi

  if [ -z "$tool" ] || [ "$tool" = "s3cmd" ]; then
    if _s3_check_s3cmd_installed; then
      echo "\ns3cmd configuration:"
      echo "-------------------"
      if [ -f "$HOME/.s3cfg" ]; then
        echo "s3cmd is configured. Config file: $HOME/.s3cfg"
      else
        echo "s3cmd is not configured yet."
      fi
    fi
  fi

  if [ -z "$tool" ] || [ "$tool" = "rclone" ]; then
    if _s3_check_rclone_installed; then
      echo "\nrclone remotes:"
      echo "--------------"
      rclone listremotes 2>/dev/null || echo "No rclone remotes found."
      echo "Default rclone remote: $(_s3_get_default_profile rclone)"
    fi
  fi
}' # List configured S3 profiles across different tools

# Bucket Operations
alias s3-ls='() {
  echo "List S3 buckets or objects.\nUsage:\n s3-ls [--profile <profile_name>] [--tool <aws|s3cmd|rclone>] [bucket_name] [prefix]"

  local profile=""
  local tool="aws"
  local bucket=""
  local prefix=""

  # Parse arguments
  local i=1
  while [ $i -le $# ]; do
    local arg="${!i}"
    case "$arg" in
      --profile)
        i=$((i+1))
        if [ $i -le $# ]; then
          profile="${!i}"
        else
          _s3_show_error "Missing value for --profile option."
          return 1
        fi
        ;;
      --tool)
        i=$((i+1))
        if [ $i -le $# ]; then
          tool="${!i}"
          if [ "$tool" != "aws" ] && [ "$tool" != "s3cmd" ] && [ "$tool" != "rclone" ]; then
            _s3_show_error "Invalid tool specified. Use \"aws\", \"s3cmd\", or \"rclone\"."
            return 1
          fi
        else
          _s3_show_error "Missing value for --tool option."
          return 1
        fi
        ;;
      --*)
        _s3_show_error "Unknown option: $arg"
        return 1
        ;;
      *)
        if [ -z "$bucket" ]; then
          bucket="$arg"
        elif [ -z "$prefix" ]; then
          prefix="$arg"
        else
          _s3_show_error "Too many arguments."
          return 1
        fi
        ;;
    esac
    i=$((i+1))
  done

  # Set default profile if not specified
  if [ -z "$profile" ]; then
    profile="$(_s3_get_default_profile $tool)"
  fi

  # Check if the required tool is installed
  case "$tool" in
    aws)
      if ! _s3_check_aws_installed; then return 1; fi
      if ! _s3_validate_profile "$profile" "aws"; then
        # Only warn, do not block execution
        :
      fi
      ;;
    s3cmd)
      if ! _s3_check_s3cmd_installed; then return 1; fi
      if ! _s3_validate_profile "$profile" "s3cmd"; then
        # Only warn, do not block execution
        :
      fi
      ;;
    rclone)
      if ! _s3_check_rclone_installed; then return 1; fi
      if ! _s3_validate_profile "$profile" "rclone"; then
        # Only warn, do not block execution
        :
      fi
      ;;
  esac

  # Execute the appropriate command based on the tool and arguments
  if [ -z "$bucket" ]; then
    echo "Listing all buckets using $tool with profile $profile..."
    case "$tool" in
      aws)
        aws s3 ls --profile "$profile"
        ;;
      s3cmd)
        s3cmd ls
        ;;
      rclone)
        rclone lsd "$profile:" --max-depth 1
        ;;
    esac
  elif [ -z "$prefix" ]; then
    echo "Listing objects in bucket $bucket using $tool with profile $profile..."
    case "$tool" in
      aws)
        aws s3 ls "s3://$bucket/" --profile "$profile"
        ;;
      s3cmd)
        s3cmd ls "s3://$bucket/"
        ;;
      rclone)
        rclone ls "$profile:$bucket"
        ;;
    esac
  else
    echo "Listing objects with prefix $prefix in bucket $bucket using $tool with profile $profile..."
    case "$tool" in
      aws)
        aws s3 ls "s3://$bucket/$prefix" --profile "$profile"
        ;;
      s3cmd)
        s3cmd ls "s3://$bucket/$prefix"
        ;;
      rclone)
        rclone ls "$profile:$bucket/$prefix"
        ;;
    esac
  fi

  if [ $? -ne 0 ]; then
    _s3_show_error "Failed to list S3 resources."
    return 1
  fi
}' # List S3 buckets or objects

alias s3-mb='() {
  echo "Create a new S3 bucket.\nUsage:\n s3-mb <bucket_name> [--profile <profile_name>] [--tool <aws|s3cmd|rclone>] [--region <region_name>]"

  local bucket=""
  local profile=""
  local tool="aws"
  local region=""

  # Parse arguments
  local i=1
  while [ $i -le $# ]; do
    local arg="${!i}"
    case "$arg" in
      --profile)
        i=$((i+1))
        if [ $i -le $# ]; then
          profile="${!i}"
        else
          _s3_show_error "Missing value for --profile option."
          return 1
        fi
        ;;
      --tool)
        i=$((i+1))
        if [ $i -le $# ]; then
          tool="${!i}"
          if [ "$tool" != "aws" ] && [ "$tool" != "s3cmd" ] && [ "$tool" != "rclone" ]; then
            _s3_show_error "Invalid tool specified. Use \"aws\", \"s3cmd\", or \"rclone\"."
            return 1
          fi
        else
          _s3_show_error "Missing value for --tool option."
          return 1
        fi
        ;;
      --region)
        i=$((i+1))
        if [ $i -le $# ]; then
          region="${!i}"
        else
          _s3_show_error "Missing value for --region option."
          return 1
        fi
        ;;
      --*)
        _s3_show_error "Unknown option: $arg"
        return 1
        ;;
      *)
        if [ -z "$bucket" ]; then
          bucket="$arg"
        else
          _s3_show_error "Too many arguments."
          return 1
        fi
        ;;
    esac
    i=$((i+1))
  done

  # Check if bucket name is provided
  if [ -z "$bucket" ]; then
    _s3_show_error "Bucket name is required."
    return 1
  fi

  # Set default profile if not specified
  if [ -z "$profile" ]; then
    profile="$(_s3_get_default_profile $tool)"
  fi

  # Set default region if not specified
  if [ -z "$region" ]; then
    region="$(_s3_get_default_region)"
  fi

  # Check if the required tool is installed
  case "$tool" in
    aws)
      if ! _s3_check_aws_installed; then return 1; fi
      if ! _s3_validate_profile "$profile" "aws"; then
        # Only warn, do not block execution
        :
      fi
      ;;
    s3cmd)
      if ! _s3_check_s3cmd_installed; then return 1; fi
      if ! _s3_validate_profile "$profile" "s3cmd"; then
        # Only warn, do not block execution
        :
      fi
      ;;
    rclone)
      if ! _s3_check_rclone_installed; then return 1; fi
      if ! _s3_validate_profile "$profile" "rclone"; then
        # Only warn, do not block execution
        :
      fi
      ;;
  esac

  echo "Creating bucket $bucket using $tool with profile $profile in region $region..."

  # Execute the appropriate command based on the tool
  case "$tool" in
    aws)
      if aws s3 mb "s3://$bucket" --region "$region" --profile "$profile"; then
        echo "Bucket $bucket created successfully."
      else
        _s3_show_error "Failed to create bucket $bucket."
        return 1
      fi
      ;;
    s3cmd)
      if s3cmd mb "s3://$bucket" --region="$region"; then
        echo "Bucket $bucket created successfully."
      else
        _s3_show_error "Failed to create bucket $bucket."
        return 1
      fi
      ;;
    rclone)
      if rclone mkdir "$profile:$bucket"; then
        echo "Bucket $bucket created successfully."
      else
        _s3_show_error "Failed to create bucket $bucket."
        return 1
      fi
      ;;
  esac
}' # Create a new S3 bucket

alias s3-rb='() {
  echo "Remove an S3 bucket.\nUsage:\n s3-rb <bucket_name> [--profile <profile_name>] [--tool <aws|s3cmd|rclone>] [--force]"

  local bucket=""
  local profile=""
  local tool="aws"
  local force=false

  # Parse arguments
  local i=1
  while [ $i -le $# ]; do
    local arg="${!i}"
    case "$arg" in
      --profile)
        i=$((i+1))
        if [ $i -le $# ]; then
          profile="${!i}"
        else
          _s3_show_error "Missing value for --profile option."
          return 1
        fi
        ;;
      --tool)
        i=$((i+1))
        if [ $i -le $# ]; then
          tool="${!i}"
          if [ "$tool" != "aws" ] && [ "$tool" != "s3cmd" ] && [ "$tool" != "rclone" ]; then
            _s3_show_error "Invalid tool specified. Use \"aws\", \"s3cmd\", or \"rclone\"."
            return 1
          fi
        else
          _s3_show_error "Missing value for --tool option."
          return 1
        fi
        ;;
      --force)
        force=true
        ;;
      --*)
        _s3_show_error "Unknown option: $arg"
        return 1
        ;;
      *)
        if [ -z "$bucket" ]; then
          bucket="$arg"
        else
          _s3_show_error "Too many arguments."
          return 1
        fi
        ;;
    esac
    i=$((i+1))
  done

  # Check if bucket name is provided
  if [ -z "$bucket" ]; then
    _s3_show_error "Bucket name is required."
    return 1
  fi

  # Set default profile if not specified
  if [ -z "$profile" ]; then
    profile="$(_s3_get_default_profile $tool)"
  fi

  # Check if the required tool is installed
  case "$tool" in
    aws)
      if ! _s3_check_aws_installed; then return 1; fi
      if ! _s3_validate_profile "$profile" "aws"; then
        # Only warn, do not block execution
        :
      fi
      ;;
    s3cmd)
      if ! _s3_check_s3cmd_installed; then return 1; fi
      if ! _s3_validate_profile "$profile" "s3cmd"; then
        # Only warn, do not block execution
        :
      fi
      ;;
    rclone)
      if ! _s3_check_rclone_installed; then return 1; fi
      if ! _s3_validate_profile "$profile" "rclone"; then
        # Only warn, do not block execution
        :
      fi
      ;;
  esac

  if [ "$force" = true ]; then
    echo "Warning: Using force mode. All objects in bucket $bucket will be deleted."
    read -p "Are you sure you want to continue? (y/n): " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
      echo "Operation cancelled."
      return 0
    fi
  fi

  echo "Removing bucket $bucket using $tool with profile $profile..."

  # Execute the appropriate command based on the tool and force flag
  case "$tool" in
    aws)
      if [ "$force" = true ]; then
        if aws s3 rb "s3://$bucket" --force --profile "$profile"; then
          echo "Bucket $bucket and all its contents removed successfully."
        else
          _s3_show_error "Failed to remove bucket $bucket."
          return 1
        fi
      else
        if aws s3 rb "s3://$bucket" --profile "$profile"; then
          echo "Bucket $bucket removed successfully."
        else
          _s3_show_error "Failed to remove bucket $bucket. It may not be empty."
          echo "Use --force option to remove a non-empty bucket." >&2
          return 1
        fi
      fi
      ;;
    s3cmd)
      if [ "$force" = true ]; then
        if s3cmd rb "s3://$bucket" --recursive; then
          echo "Bucket $bucket and all its contents removed successfully."
        else
          _s3_show_error "Failed to remove bucket $bucket."
          return 1
        fi
      else
        if s3cmd rb "s3://$bucket"; then
          echo "Bucket $bucket removed successfully."
        else
          _s3_show_error "Failed to remove bucket $bucket. It may not be empty."
          echo "Use --force option to remove a non-empty bucket." >&2
          return 1
        fi
      fi
      ;;
    rclone)
      if [ "$force" = true ]; then
        if rclone purge "$profile:$bucket"; then
          echo "Bucket $bucket and all its contents removed successfully."
        else
          _s3_show_error "Failed to remove bucket $bucket."
          return 1
        fi
      else
        if rclone rmdir "$profile:$bucket"; then
          echo "Bucket $bucket removed successfully."
        else
          _s3_show_error "Failed to remove bucket $bucket. It may not be empty."
          echo "Use --force option to remove a non-empty bucket." >&2
          return 1
        fi
      fi
      ;;
  esac
}' # Remove an S3 bucket

# Object Operations
alias s3-cp='() {
  echo "Copy files to/from S3.\nUsage:\n s3-cp <source> <destination> [--profile <profile_name>] [--tool <aws|s3cmd|rclone>] [--recursive]"

  local source=""
  local destination=""
  local profile=""
  local tool="aws"
  local recursive=false

  # Parse arguments
  local i=1
  while [ $i -le $# ]; do
    local arg="${!i}"
    case "$arg" in
      --profile)
        i=$((i+1))
        if [ $i -le $# ]; then
          profile="${!i}"
        else
          _s3_show_error "Missing value for --profile option."
          return 1
        fi
        ;;
      --tool)
        i=$((i+1))
        if [ $i -le $# ]; then
          tool="${!i}"
          if [ "$tool" != "aws" ] && [ "$tool" != "s3cmd" ] && [ "$tool" != "rclone" ]; then
            _s3_show_error "Invalid tool specified. Use \"aws\", \"s3cmd\", or \"rclone\"."
            return 1
          fi
        else
          _s3_show_error "Missing value for --tool option."
          return 1
        fi
        ;;
      --recursive)
        recursive=true
        ;;
      --*)
        _s3_show_error "Unknown option: $arg"
        return 1
        ;;
      *)
        if [ -z "$source" ]; then
          source="$arg"
        elif [ -z "$destination" ]; then
          destination="$arg"
        else
          _s3_show_error "Too many arguments."
          return 1
        fi
        ;;
    esac
    i=$((i+1))
  done

  # Check if source and destination are provided
  if [ -z "$source" ] || [ -z "$destination" ]; then
    _s3_show_error "Both source and destination are required."
    echo "Example: s3-cp file.txt s3://my-bucket/file.txt" >&2
    echo "         s3-cp s3://my-bucket/file.txt file.txt" >&2
    echo "         s3-cp s3://my-bucket/folder/ local-folder/ --recursive" >&2
    return 1
  fi

  # Set default profile if not specified
  if [ -z "$profile" ]; then
    profile="$(_s3_get_default_profile $tool)"
  fi

  # Check if the required tool is installed
  case "$tool" in
    aws)
      if ! _s3_check_aws_installed; then return 1; fi
      if ! _s3_validate_profile "$profile" "aws"; then
        # Only warn, do not block execution
        :
      fi
      ;;
    s3cmd)
      if ! _s3_check_s3cmd_installed; then return 1; fi
      if ! _s3_validate_profile "$profile" "s3cmd"; then
        # Only warn, do not block execution
        :
      fi
      ;;
    rclone)
      if ! _s3_check_rclone_installed; then return 1; fi
      if ! _s3_validate_profile "$profile" "rclone"; then
        # Only warn, do not block execution
        :
      fi
      ;;
  esac

  echo "Copying from $source to $destination using $tool with profile $profile..."

  # Execute the appropriate command based on the tool and recursive flag
  case "$tool" in
    aws)
      local recursive_flag=""
      if [ "$recursive" = true ]; then
        recursive_flag="--recursive"
      fi

      if aws s3 cp "$source" "$destination" $recursive_flag --profile "$profile"; then
        echo "Copy operation completed successfully."
      else
        _s3_show_error "Failed to copy from $source to $destination."
        return 1
      fi
      ;;
    s3cmd)
      local recursive_flag=""
      if [ "$recursive" = true ]; then
        recursive_flag="--recursive"
      fi

      if s3cmd cp "$source" "$destination" $recursive_flag; then
        echo "Copy operation completed successfully."
      else
        _s3_show_error "Failed to copy from $source to $destination."
        return 1
      fi
      ;;
    rclone)
      if [ "$recursive" = true ]; then
        # For rclone, we need to handle s3:// URLs differently
        local src_modified="$source"
        local dst_modified="$destination"

        # Convert s3:// URLs to rclone format
        if [[ "$source" == s3://* ]]; then
          src_modified="$profile:${source#s3://}"
        fi

        if [[ "$destination" == s3://* ]]; then
          dst_modified="$profile:${destination#s3://}"
        fi

        if rclone copy "$src_modified" "$dst_modified"; then
          echo "Copy operation completed successfully."
        else
          _s3_show_error "Failed to copy from $source to $destination."
          return 1
        fi
      else
        # For non-recursive copy with rclone
        local src_modified="$source"
        local dst_modified="$destination"

        # Convert s3:// URLs to rclone format
        if [[ "$source" == s3://* ]]; then
          src_modified="$profile:${source#s3://}"
        fi

        if [[ "$destination" == s3://* ]]; then
          dst_modified="$profile:${destination#s3://}"
        fi

        if rclone copyto "$src_modified" "$dst_modified"; then
          echo "Copy operation completed successfully."
        else
          _s3_show_error "Failed to copy from $source to $destination."
          return 1
        fi
      fi
      ;;
  esac
}' # Copy files to/from S3

alias s3-mv='() {
  echo "Move files to/from S3.\nUsage:\n s3-mv <source> <destination> [--profile <profile_name>] [--tool <aws|s3cmd|rclone>] [--recursive]"

  local source=""
  local destination=""
  local profile=""
  local tool="aws"
  local recursive=false

  # Parse arguments
  local i=1
  while [ $i -le $# ]; do
    local arg="${!i}"
    case "$arg" in
      --profile)
        i=$((i+1))
        if [ $i -le $# ]; then
          profile="${!i}"
        else
          _s3_show_error "Missing value for --profile option."
          return 1
        fi
        ;;
      --tool)
        i=$((i+1))
        if [ $i -le $# ]; then
          tool="${!i}"
          if [ "$tool" != "aws" ] && [ "$tool" != "s3cmd" ] && [ "$tool" != "rclone" ]; then
            _s3_show_error "Invalid tool specified. Use \"aws\", \"s3cmd\", or \"rclone\"."
            return 1
          fi
        else
          _s3_show_error "Missing value for --tool option."
          return 1
        fi
        ;;
      --recursive)
        recursive=true
        ;;
      --*)
        _s3_show_error "Unknown option: $arg"
        return 1
        ;;
      *)
        if [ -z "$source" ]; then
          source="$arg"
        elif [ -z "$destination" ]; then
          destination="$arg"
        else
          _s3_show_error "Too many arguments."
          return 1
        fi
        ;;
    esac
    i=$((i+1))
  done

  # Check if source and destination are provided
  if [ -z "$source" ] || [ -z "$destination" ]; then
    _s3_show_error "Both source and destination are required."
    echo "Example: s3-mv file.txt s3://my-bucket/file.txt" >&2
    echo "         s3-mv s3://my-bucket/file.txt file.txt" >&2
    echo "         s3-mv s3://my-bucket/folder/ local-folder/ --recursive" >&2
    return 1
  fi

  # Set default profile if not specified
  if [ -z "$profile" ]; then
    profile="$(_s3_get_default_profile $tool)"
  fi

  # Check if the required tool is installed
  case "$tool" in
    aws)
      if ! _s3_check_aws_installed; then return 1; fi
      if ! _s3_validate_profile "$profile" "aws"; then
        # Only warn, do not block execution
        :
      fi
      ;;
    s3cmd)
      if ! _s3_check_s3cmd_installed; then return 1; fi
      if ! _s3_validate_profile "$profile" "s3cmd"; then
        # Only warn, do not block execution
        :
      fi
      ;;
    rclone)
      if ! _s3_check_rclone_installed; then return 1; fi
      if ! _s3_validate_profile "$profile" "rclone"; then
        # Only warn, do not block execution
        :
      fi
      ;;
  esac

  echo "Moving from $source to $destination using $tool with profile $profile..."

  # Execute the appropriate command based on the tool and recursive flag
  case "$tool" in
    aws)
      local recursive_flag=""
      if [ "$recursive" = true ]; then
        recursive_flag="--recursive"
      fi

      if aws s3 mv "$source" "$destination" $recursive_flag --profile "$profile"; then
        echo "Move operation completed successfully."
      else
        _s3_show_error "Failed to move from $source to $destination."
        return 1
      fi
      ;;
    s3cmd)
      local recursive_flag=""
      if [ "$recursive" = true ]; then
        recursive_flag="--recursive"
      fi

      if s3cmd mv "$source" "$destination" $recursive_flag; then
        echo "Move operation completed successfully."
      else
        _s3_show_error "Failed to move from $source to $destination."
        return 1
      fi
      ;;
    rclone)
      # For rclone, we need to handle s3:// URLs differently
      local src_modified="$source"
      local dst_modified="$destination"

      # Convert s3:// URLs to rclone format
      if [[ "$source" == s3://* ]]; then
        src_modified="$profile:${source#s3://}"
      fi

      if [[ "$destination" == s3://* ]]; then
        dst_modified="$profile:${destination#s3://}"
      fi

      if [ "$recursive" = true ]; then
        if rclone move "$src_modified" "$dst_modified"; then
          echo "Move operation completed successfully."
        else
          _s3_show_error "Failed to move from $source to $destination."
          return 1
        fi
      else
        if rclone moveto "$src_modified" "$dst_modified"; then
          echo "Move operation completed successfully."
        else
          _s3_show_error "Failed to move from $source to $destination."
          return 1
        fi
      fi
      ;;
  esac
}' # Move files to/from S3

alias s3-rm='() {
  echo "Remove objects from S3.\nUsage:\n s3-rm <s3_path> [--profile <profile_name>] [--tool <aws|s3cmd|rclone>] [--recursive]"

  local s3_path=""
  local profile=""
  local tool="aws"
  local recursive=false

  # Parse arguments
  local i=1
  while [ $i -le $# ]; do
    local arg="${!i}"
    case "$arg" in
      --profile)
        i=$((i+1))
        if [ $i -le $# ]; then
          profile="${!i}"
        else
          _s3_show_error "Missing value for --profile option."
          return 1
        fi
        ;;
      --tool)
        i=$((i+1))
        if [ $i -le $# ]; then
          tool="${!i}"
          if [ "$tool" != "aws" ] && [ "$tool" != "s3cmd" ] && [ "$tool" != "rclone" ]; then
            _s3_show_error "Invalid tool specified. Use \"aws\", \"s3cmd\", or \"rclone\"."
            return 1
          fi
        else
          _s3_show_error "Missing value for --tool option."
          return 1
        fi
        ;;
      --recursive)
        recursive=true
        ;;
      --*)
        _s3_show_error "Unknown option: $arg"
        return 1
        ;;
      *)
        if [ -z "$s3_path" ]; then
          s3_path="$arg"
        else
          _s3_show_error "Too many arguments."
          return 1
        fi
        ;;
    esac
    i=$((i+1))
  done

  # Check if S3 path is provided
  if [ -z "$s3_path" ]; then
    _s3_show_error "S3 path is required."
    echo "Example: s3-rm s3://my-bucket/file.txt" >&2
    echo "         s3-rm s3://my-bucket/folder/ --recursive" >&2
    return 1
  fi

  # Set default profile if not specified
  if [ -z "$profile" ]; then
    profile="$(_s3_get_default_profile $tool)"
  fi

  # Check if the required tool is installed
  case "$tool" in
    aws)
      if ! _s3_check_aws_installed; then return 1; fi
      if ! _s3_validate_profile "$profile" "aws"; then
        # Only warn, do not block execution
        :
      fi
      ;;
    s3cmd)
      if ! _s3_check_s3cmd_installed; then return 1; fi
      if ! _s3_validate_profile "$profile" "s3cmd"; then
        # Only warn, do not block execution
        :
      fi
      ;;
    rclone)
      if ! _s3_check_rclone_installed; then return 1; fi
      if ! _s3_validate_profile "$profile" "rclone"; then
        # Only warn, do not block execution
        :
      fi
      ;;
  esac

  if [ "$recursive" = true ]; then
    echo "Warning: Using recursive mode. All objects under $s3_path will be deleted."
    read -p "Are you sure you want to continue? (y/n): " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
      echo "Operation cancelled."
      return 0
    fi
  fi

  echo "Removing $s3_path using $tool with profile $profile..."

  # Execute the appropriate command based on the tool and recursive flag
  case "$tool" in
    aws)
      local recursive_flag=""
      if [ "$recursive" = true ]; then
        recursive_flag="--recursive"
      fi

      if aws s3 rm "$s3_path" $recursive_flag --profile "$profile"; then
        echo "Remove operation completed successfully."
      else
        _s3_show_error "Failed to remove $s3_path."
        return 1
      fi
      ;;
    s3cmd)
      local recursive_flag=""
      if [ "$recursive" = true ]; then
        recursive_flag="--recursive"
      fi

      if s3cmd rm "$s3_path" $recursive_flag; then
        echo "Remove operation completed successfully."
      else
        _s3_show_error "Failed to remove $s3_path."
        return 1
      fi
      ;;
    rclone)
      # For rclone, we need to handle s3:// URLs differently
      if [[ "$s3_path" != s3://* ]]; then
        _s3_show_error "For rclone, the S3 path must start with 's3://'."
        return 1
      fi

      local path_modified="$profile:${s3_path#s3://}"

      if [ "$recursive" = true ]; then
        if rclone purge "$path_modified"; then
          echo "Remove operation completed successfully."
        else
          _s3_show_error "Failed to remove $s3_path."
          return 1
        fi
      else
        if rclone deletefile "$path_modified"; then
          echo "Remove operation completed successfully."
        else
          _s3_show_error "Failed to remove $s3_path."
          return 1
        fi
      fi
      ;;
  esac
}' # Remove objects from S3

alias s3-sync='() {
  echo "Synchronize directories to/from S3.\nUsage:\n s3-sync <source> <destination> [--profile <profile_name>] [--tool <aws|s3cmd|rclone>] [--delete]"

  local source=""
  local destination=""
  local profile=""
  local tool="aws"
  local delete=false

  # Parse arguments
  local i=1
  while [ $i -le $# ]; do
    local arg="${!i}"
    case "$arg" in
      --profile)
        i=$((i+1))
        if [ $i -le $# ]; then
          profile="${!i}"
        else
          _s3_show_error "Missing value for --profile option."
          return 1
        fi
        ;;
      --tool)
        i=$((i+1))
        if [ $i -le $# ]; then
          tool="${!i}"
          if [ "$tool" != "aws" ] && [ "$tool" != "s3cmd" ] && [ "$tool" != "rclone" ]; then
            _s3_show_error "Invalid tool specified. Use \"aws\", \"s3cmd\", or \"rclone\"."
            return 1
          fi
        else
          _s3_show_error "Missing value for --tool option."
          return 1
        fi
        ;;
      --delete)
        delete=true
        ;;
      --*)
        _s3_show_error "Unknown option: $arg"
        return 1
        ;;
      *)
        if [ -z "$source" ]; then
          source="$arg"
        elif [ -z "$destination" ]; then
          destination="$arg"
        else
          _s3_show_error "Too many arguments."
          return 1
        fi
        ;;
    esac
    i=$((i+1))
  done

  # Check if source and destination are provided
  if [ -z "$source" ] || [ -z "$destination" ]; then
    _s3_show_error "Both source and destination are required."
    echo "Example: s3-sync local-folder/ s3://my-bucket/folder/" >&2
    echo "         s3-sync s3://my-bucket/folder/ local-folder/" >&2
    echo "         s3-sync s3://my-bucket/folder1/ s3://another-bucket/folder2/" >&2
    return 1
  fi

  # Set default profile if not specified
  if [ -z "$profile" ]; then
    profile="$(_s3_get_default_profile $tool)"
  fi

  # Check if the required tool is installed
  case "$tool" in
    aws)
      if ! _s3_check_aws_installed; then return 1; fi
      if ! _s3_validate_profile "$profile" "aws"; then
        # Only warn, do not block execution
        :
      fi
      ;;
    s3cmd)
      if ! _s3_check_s3cmd_installed; then return 1; fi
      if ! _s3_validate_profile "$profile" "s3cmd"; then
        # Only warn, do not block execution
        :
      fi
      ;;
    rclone)
      if ! _s3_check_rclone_installed; then return 1; fi
      if ! _s3_validate_profile "$profile" "rclone"; then
        # Only warn, do not block execution
        :
      fi
      ;;
  esac

  if [ "$delete" = true ]; then
    echo "Warning: Using delete mode. Files in the destination that don"t exist in the source will be deleted."
    read -p "Are you sure you want to continue? (y/n): " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
      echo "Operation cancelled."
      return 0
    fi
  fi

  echo "Synchronizing from $source to $destination using $tool with profile $profile..."

  # Execute the appropriate command based on the tool and delete flag
  case "$tool" in
    aws)
      local delete_flag=""
      if [ "$delete" = true ]; then
        delete_flag="--delete"
      fi

      if aws s3 sync "$source" "$destination" $delete_flag --profile "$profile"; then
        echo "Sync operation completed successfully."
      else
        _s3_show_error "Failed to sync from $source to $destination."
        return 1
      fi
      ;;
    s3cmd)
      local delete_flag=""
      if [ "$delete" = true ]; then
        delete_flag="--delete-removed"
      fi

      if s3cmd sync "$source" "$destination" $delete_flag; then
        echo "Sync operation completed successfully."
      else
        _s3_show_error "Failed to sync from $source to $destination."
        return 1
      fi
      ;;
    rclone)
      # For rclone, we need to handle s3:// URLs differently
      local src_modified="$source"
      local dst_modified="$destination"

      # Convert s3:// URLs to rclone format
      if [[ "$source" == s3://* ]]; then
        src_modified="$profile:${source#s3://}"
      fi

      if [[ "$destination" == s3://* ]]; then
        dst_modified="$profile:${destination#s3://}"
      fi

      local delete_flag=""
      if [ "$delete" = true ]; then
        delete_flag="--delete-dest"
      fi

      if rclone sync "$src_modified" "$dst_modified" $delete_flag; then
        echo "Sync operation completed successfully."
      else
        _s3_show_error "Failed to sync from $source to $destination."
        return 1
      fi
      ;;
  esac
}' # Synchronize directories to/from S3

alias s3-cat='() {
  echo "View S3 object content.\nUsage:\n s3-cat <s3_path> [--profile <profile_name>] [--tool <aws|s3cmd|rclone>]"

  local s3_path=""
  local profile=""
  local tool="aws"

  # Parse arguments
  local i=1
  while [ $i -le $# ]; do
    local arg="${!i}"
    case "$arg" in
      --profile)
        i=$((i+1))
        if [ $i -le $# ]; then
          profile="${!i}"
        else
          _s3_show_error "Missing value for --profile option."
          return 1
        fi
        ;;
      --tool)
        i=$((i+1))
        if [ $i -le $# ]; then
          tool="${!i}"
          if [ "$tool" != "aws" ] && [ "$tool" != "s3cmd" ] && [ "$tool" != "rclone" ]; then
            _s3_show_error "Invalid tool specified. Use \"aws\", \"s3cmd\", or \"rclone\"."
            return 1
          fi
        else
          _s3_show_error "Missing value for --tool option."
          return 1
        fi
        ;;
      --*)
        _s3_show_error "Unknown option: $arg"
        return 1
        ;;
      *)
        if [ -z "$s3_path" ]; then
          s3_path="$arg"
        else
          _s3_show_error "Too many arguments."
          return 1
        fi
        ;;
    esac
    i=$((i+1))
  done

  # Check if S3 path is provided
  if [ -z "$s3_path" ]; then
    _s3_show_error "S3 path is required."
    echo "Example: s3-cat s3://my-bucket/file.txt" >&2
    return 1
  fi

  # Set default profile if not specified
  if [ -z "$profile" ]; then
    profile="$(_s3_get_default_profile $tool)"
  fi

  # Check if the required tool is installed
  case "$tool" in
    aws)
      if ! _s3_check_aws_installed; then return 1; fi
      if ! _s3_validate_profile "$profile" "aws"; then
        # Only warn, do not block execution
        :
      fi
      ;;
    s3cmd)
      if ! _s3_check_s3cmd_installed; then return 1; fi
      if ! _s3_validate_profile "$profile" "s3cmd"; then
        # Only warn, do not block execution
        :
      fi
      ;;
    rclone)
      if ! _s3_check_rclone_installed; then return 1; fi
      if ! _s3_validate_profile "$profile" "rclone"; then
        # Only warn, do not block execution
        :
      fi
      ;;
  esac

  echo "Viewing content of $s3_path using $tool with profile $profile..."
  echo "----------------------------------------"

  # Execute the appropriate command based on the tool
  case "$tool" in
    aws)
      if ! aws s3 cp "$s3_path" - --profile "$profile"; then
        echo "----------------------------------------"
        _s3_show_error "Failed to view content of $s3_path."
        return 1
      fi
      ;;
    s3cmd)
      if ! s3cmd get "$s3_path" -; then
        echo "----------------------------------------"
        _s3_show_error "Failed to view content of $s3_path."
        return 1
      fi
      ;;
    rclone)
      # For rclone, we need to handle s3:// URLs differently
      if [[ "$s3_path" != s3://* ]]; then
        echo "----------------------------------------"
        _s3_show_error "For rclone, the S3 path must start with 's3://'."
        return 1
      fi

      local path_modified="$profile:${s3_path#s3://}"

      if ! rclone cat "$path_modified"; then
        echo "----------------------------------------"
        _s3_show_error "Failed to view content of $s3_path."
        return 1
      fi
      ;;
  esac

  echo "----------------------------------------"
}' # View S3 object content

alias s3-presign='() {
  echo "Generate a pre-signed URL for S3 object.\nUsage:\n s3-presign <s3_path> [--profile <profile_name>] [--expires <seconds:3600>]"

  local s3_path=""
  local profile=""
  local expires=3600

  # Parse arguments
  local i=1
  while [ $i -le $# ]; do
    local arg="${!i}"
    case "$arg" in
      --profile)
        i=$((i+1))
        if [ $i -le $# ]; then
          profile="${!i}"
        else
          _s3_show_error "Missing value for --profile option."
          return 1
        fi
        ;;
      --expires)
        i=$((i+1))
        if [ $i -le $# ]; then
          expires="${!i}"
          if ! [[ "$expires" =~ ^[0-9]+$ ]]; then
            _s3_show_error "Expiration time must be a positive integer."
            return 1
          fi
        else
          _s3_show_error "Missing value for --expires option."
          return 1
        fi
        ;;
      --*)
        _s3_show_error "Unknown option: $arg"
        return 1
        ;;
      *)
        if [ -z "$s3_path" ]; then
          s3_path="$arg"
        else
          _s3_show_error "Too many arguments."
          return 1
        fi
        ;;
    esac
    i=$((i+1))
  done

  # Check if S3 path is provided
  if [ -z "$s3_path" ]; then
    _s3_show_error "S3 path is required."
    echo "Example: s3-presign s3://my-bucket/file.txt" >&2
    echo "         s3-presign s3://my-bucket/file.txt --expires 86400" >&2
    return 1
  fi

  # Set default profile if not specified
  if [ -z "$profile" ]; then
    profile="$(_s3_get_default_profile aws)"
  fi

  # Check if AWS CLI is installed
  if ! _s3_check_aws_installed; then
    return 1
  fi

  if ! _s3_validate_profile "$profile" "aws"; then
    # Only warn, do not block execution
    :
  fi

  echo "Generating pre-signed URL for $s3_path with expiration of $expires seconds..."

  # Extract bucket and key from s3_path
  if [[ "$s3_path" != s3://* ]]; then
    _s3_show_error "S3 path must start with \"s3://\"."
    return 1
  fi

  local bucket=$(echo "$s3_path" | sed -E "s|s3://([^/]+)/.*|\1|")
  local key=$(echo "$s3_path" | sed -E "s|s3://[^/]+/(.*)|\1|")

  if [ -z "$bucket" ] || [ -z "$key" ]; then
    _s3_show_error "Invalid S3 path format. Expected: s3://bucket-name/object-key"
    return 1
  fi

  if ! aws s3 presign "$s3_path" --expires-in "$expires" --profile "$profile"; then
    _s3_show_error "Failed to generate pre-signed URL for $s3_path."
    return 1
  fi
}' # Generate a pre-signed URL for S3 object

# Help function
alias s3-help='() {
  echo "S3 Protocol Aliases Help\n"
  echo "These aliases provide a unified interface to work with S3-compatible storage services"
  echo "using different tools contains AWS CLI, s3cmd, and rclone."
  echo ""

  echo "Configuration Commands:"
  echo "  s3-config-aws [profile_name]       - Configure AWS CLI profile for S3 access"
  echo "  s3-config-s3cmd                    - Configure s3cmd for S3 access"
  echo "  s3-config-rclone [remote_name]     - Configure rclone for S3 access"
  echo "  s3-list-profiles [--tool <name>]    - List configured S3 profiles across different tools"
  echo ""

  echo "Bucket Operations:"
  echo "  s3-ls [--profile <name>] [--tool <name>] [bucket] [prefix]  - List buckets or objects"
  echo "  s3-mb <bucket> [--profile <name>] [--tool <name>] [--region <name>]  - Create bucket"
  echo "  s3-rb <bucket> [--profile <name>] [--tool <name>] [--force]  - Remove bucket"
  echo ""

  echo "Object Operations:"
  echo "  s3-cp <src> <dst> [--profile <name>] [--tool <name>] [--recursive]  - Copy files"
  echo "  s3-mv <src> <dst> [--profile <name>] [--tool <name>] [--recursive]  - Move files"
  echo "  s3-rm <path> [--profile <name>] [--tool <name>] [--recursive]  - Remove objects"
  echo "  s3-sync <src> <dst> [--profile <name>] [--tool <name>] [--delete]  - Sync directories"
  echo "  s3-cat <path> [--profile <name>] [--tool <name>]  - View object content"
  echo "  s3-presign <path> [--profile <name>] [--expires <seconds>]  - Generate pre-signed URL"
  echo ""

  echo "Environment Variables:"
  echo "  S3_AWS_PROFILE     - Default AWS CLI profile (default: \"default\")"
  echo "  S3_S3CMD_PROFILE   - Default s3cmd profile (default: \"default\")"
  echo "  S3_RCLONE_REMOTE   - Default rclone remote (default: \"s3\")"
  echo "  S3_DEFAULT_REGION  - Default region for bucket creation (default: \"us-east-1\")"
  echo ""

  echo "Examples:"
  echo "  s3-ls                                  - List all buckets using AWS CLI"
  echo "  s3-ls my-bucket --tool rclone          - List objects in bucket using rclone"
  echo "  s3-cp file.txt s3://my-bucket/         - Upload file using AWS CLI"
  echo "  s3-sync local-dir/ s3://my-bucket/dir/ - Sync local directory to S3"
  echo "  s3-presign s3://my-bucket/file.txt     - Generate pre-signed URL valid for 1 hour"
}' # S3 help function
