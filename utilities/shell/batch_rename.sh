#!/bin/bash

# This script batch renames files in a directory.
# It takes two arguments: a pattern to match and a replacement string.

# Check if the correct number of arguments is provided
if [ $# -ne 2 ]; then
  echo "Usage: $0 <pattern> <replacement>"
  exit 1
fi

# The pattern to match
PATTERN="$1"

# The replacement string
REPLACEMENT="$2"

# Loop through all files in the current directory
for file in *; do
  # Check if the file matches the pattern
  if [[ "$file" =~ $PATTERN ]]; then
    # Create the new file name
    NEW_NAME="${file/$PATTERN/$REPLACEMENT}"

    # Rename the file
    mv "$file" "$NEW_NAME"

    # Print a message
    echo "Renamed '$file' to '$NEW_NAME'"
  fi
done

exit 0