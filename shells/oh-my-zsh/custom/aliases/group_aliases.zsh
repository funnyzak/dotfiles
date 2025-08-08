# Description: Aliases for grouping files or directories into equal-sized subgroups

# Group files or directories into equal sized groups
alias group-items='() {
  echo -e "Group files or directories into equal-sized groups.\nUsage:\n group-items <directory_path> [num_groups:2] [-t type:file] [-p pattern:*]"
  echo -e "Parameters:"
  echo -e "  directory_path: Directory containing items to group"
  echo -e "  num_groups:     Number of groups to create (default: 2)"
  echo -e "Options:"
  echo -e "  -t, --type:     Type of items to group (file or dir, default: file)"
  echo -e "  -p, --pattern:  Pattern to match items (default: *)"
  echo -e "Examples:\n  group-items ~/Downloads 3\n  group-items ~/Pictures 4 -t file -p \"*.jpg\""

  # Check if help is requested
  if [[ "$1" == "-h" || "$1" == "--help" || "$1" == "help" ]]; then
    return 0
  fi

  # Check if directory is provided
  if [[ -z "$1" ]]; then
    echo "Error: Directory path is required" >&2
    return 1
  fi

  # Initialize variables
  local target_dir="$1"
  local num_groups=2
  local item_type="file"
  local pattern="*"
  local i=1

  # Check if directory exists
  if [[ ! -d "$target_dir" ]]; then
    echo "Error: Directory \"$target_dir\" does not exist" >&2
    return 1
  fi

  # Parse arguments
  shift
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -t|--type)
        if [[ -z "$2" || "$2" == -* ]]; then
          echo "Error: Type option requires a value (file or dir)" >&2
          return 1
        fi
        item_type="$2"
        if [[ "$item_type" != "file" && "$item_type" != "dir" ]]; then
          echo "Error: Type must be \"file\" or \"dir\"" >&2
          return 1
        fi
        shift 2
        ;;
      -p|--pattern)
        if [[ -z "$2" || "$2" == -* ]]; then
          echo "Error: Pattern option requires a value" >&2
          return 1
        fi
        pattern="$2"
        shift 2
        ;;
      -*)
        echo "Error: Unknown option \"$1\"" >&2
        return 1
        ;;
      *)
        # If it"s a number, use it as num_groups
        if [[ "$1" =~ ^[0-9]+$ ]]; then
          num_groups="$1"
          if [[ "$num_groups" -lt 1 ]]; then
            echo "Error: Number of groups must be at least 1" >&2
            return 1
          fi
        else
          echo "Error: Invalid argument \"$1\". Expected a number for groups." >&2
          return 1
        fi
        shift
        ;;
    esac
  done

  # Find items based on type and pattern
  local items_list
  local temp_file
  temp_file=$(mktemp)

  if [[ "$item_type" == "file" ]]; then
    find "$target_dir" -maxdepth 1 -type f -name "$pattern" | sort > "$temp_file"
  else
    find "$target_dir" -maxdepth 1 -type d -name "$pattern" -not -path "$target_dir" | sort > "$temp_file"
  fi

  # Get total number of items
  local total_items
  total_items=$(wc -l < "$temp_file")

  if [[ "$total_items" -eq 0 ]]; then
    echo "Error: No ${item_type}s found matching pattern \"$pattern\" in \"$target_dir\"" >&2
    rm -f "$temp_file"
    return 1
  fi

  # Adjust number of groups if there are fewer items than requested groups
  if [[ "$total_items" -lt "$num_groups" ]]; then
    echo "Warning: Only $total_items ${item_type}s found, reducing number of groups to $total_items"
    num_groups="$total_items"
  fi

  # Calculate items per group (rounded up)
  local items_per_group
  items_per_group=$(( (total_items + num_groups - 1) / num_groups ))

  echo "Found $total_items ${item_type}s. Creating $num_groups groups with ~$items_per_group ${item_type}s each."

  # Create group directories
  local parent_dir
  parent_dir="$target_dir/grouped_$(date +%Y%m%d_%H%M%S)"

  if ! mkdir -p "$parent_dir"; then
    echo "Error: Failed to create parent directory \"$parent_dir\"" >&2
    rm -f "$temp_file"
    return 1
  fi

  local current_group=1
  local current_count=0
  local group_dir

  # Create first group directory
  group_dir="$parent_dir/group_$current_group"
  if ! mkdir -p "$group_dir"; then
    echo "Error: Failed to create group directory \"$group_dir\"" >&2
    rm -f "$temp_file"
    return 1
  fi

  # Process each item
  while IFS= read -r item_path; do
    # Get the item name from the path
    local item_name
    item_name=$(basename "$item_path")

    # Move to next group if current group is full
    if [[ "$current_count" -ge "$items_per_group" && "$current_group" -lt "$num_groups" ]]; then
      current_group=$((current_group + 1))
      current_count=0
      group_dir="$parent_dir/group_$current_group"
      if ! mkdir -p "$group_dir"; then
        echo "Error: Failed to create group directory \"$group_dir\"" >&2
        rm -f "$temp_file"
        return 1
      fi
    fi

    # Copy the item to the group directory
    if ! cp -r "$item_path" "$group_dir/"; then
      echo "Error: Failed to copy \"$item_path\" to \"$group_dir\"" >&2
      rm -f "$temp_file"
      return 1
    fi

    current_count=$((current_count + 1))
  done < "$temp_file"

  rm -f "$temp_file"
  echo "Grouping completed successfully. Groups are located in \"$parent_dir\""
}' # Group files or directories into equal-sized groups

# Alternative alias for compatibility with existing scripts
alias group-files='() {
  echo "This is an alias for group-items. Running group-items with file type..."
  group-items "$@" -t file
}' # Group files into equal-sized groups

alias group-dirs='() {
  echo "This is an alias for group-items. Running group-items with dir type..."
  group-items "$@" -t dir
}' # Group directories into equal-sized groups

alias group-help='(){
  echo "Group Aliases Help"
  echo "========================="
  echo "group-items: Group files or directories into equal-sized groups."
  echo "group-files: Group files into equal-sized groups."
  echo "group-dirs:  Group directories into equal-sized groups."
  echo ""
  echo "For more information on each command, use the -h or --help option."
}'
