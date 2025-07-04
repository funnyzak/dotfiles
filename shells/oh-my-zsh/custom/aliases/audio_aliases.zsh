# Description: Audio conversion and manipulation aliases

#------------------------------------------------------------------------------
# Audio Helper Functions
#------------------------------------------------------------------------------

# Check if ffmpeg is installed
_audio_check_ffmpeg() {
  if ! command -v ffmpeg &> /dev/null; then
    echo "Error: ffmpeg is not installed. Please install it first." >&2
    return 1
  fi
  return 0
}

# Validate file exists and is readable
_audio_validate_file() {
  local file="$1"
  if [ ! -f "$file" ]; then
    echo "Error: File \"$file\" does not exist or is not a regular file." >&2
    return 1
  fi
  if [ ! -r "$file" ]; then
    echo "Error: File \"$file\" is not readable." >&2
    return 1
  fi
  return 0
}

# Validate directory exists and is readable
_audio_validate_dir() {
  local dir="$1"
  if [ ! -d "$dir" ]; then
    echo "Error: Directory \"$dir\" does not exist or is not a directory." >&2
    return 1
  fi
  if [ ! -r "$dir" ]; then
    echo "Error: Directory \"$dir\" is not readable." >&2
    return 1
  fi
  return 0
}

#------------------------------------------------------------------------------
# Audio Conversion
#------------------------------------------------------------------------------

alias ado-to-mp3='() {
  echo "Convert audio to MP3 format."
  echo "Usage:"
  echo "  ado-to-mp3 <audio_file_path> [bitrate:128k]"

  if [ $# -eq 0 ]; then
    return 1
  fi

  local input_file="$1"
  local bitrate="${2:-128k}"

  _audio_validate_file "$input_file" || return 1
  _audio_check_ffmpeg || return 1

  local output_file="${input_file%.*}.mp3"

  echo "Converting $input_file to MP3 format with bitrate $bitrate..."

  if ffmpeg -i "$input_file" -c:a libmp3lame -b:a "$bitrate" "$output_file"; then
    echo "Conversion complete, exported to $output_file"
  else
    echo "Error: Audio conversion failed" >&2
    return 1
  fi
}' # Convert audio file to MP3 format with specified bitrate

alias ado-dir-to-mp3='() {
  echo "Convert audio files in directory to MP3 format."
  echo "Usage:"
  echo "  ado-dir-to-mp3 <audio_directory> <source_extension:wav> [bitrate:128k]"

  if [ $# -eq 0 ]; then
    return 1
  fi

  local aud_folder="${1:-.}"
  local aud_ext="${2:-wav}"
  local bitrate="${3:-128k}"

  _audio_validate_dir "$aud_folder" || return 1
  _audio_check_ffmpeg || return 1

  # Set locale to handle Unicode/Chinese characters properly
  export LC_ALL=en_US.UTF-8
  export LANG=en_US.UTF-8

  # Check if source files exist using a more robust method
  local file_count=0
  local temp_files=()

  # Use process substitution to handle filenames with special characters
  while IFS= read -r -d "" file; do
    temp_files+=("$file")
    ((file_count++))
  done < <(find "$aud_folder" -maxdepth 1 -type f -name "*.${aud_ext}" -print0)

  if [ "$file_count" -eq 0 ]; then
    echo "Error: No ${aud_ext} files found in $aud_folder" >&2
    return 1
  fi

  mkdir -p "${aud_folder}/mp3"
  local errors=0
  local success_count=0

  # Process each file using array to preserve filenames with special characters
  for file in "${temp_files[@]}"; do
    local base_name=$(basename "$file" .${aud_ext})
    local output_file="$aud_folder/mp3/${base_name}.mp3"

    echo "Converting: $(basename "$file") -> ${base_name}.mp3"
    echo "  Bitrate: $bitrate"

    if ffmpeg -i "$file" -c:a libmp3lame -b:a "$bitrate" "$output_file" 2>/dev/null; then
      echo "  ✓ Success"
      ((success_count++))
    else
      echo "  ✗ Error: Failed to convert $(basename "$file")" >&2
      ((errors++))
    fi
    echo ""
  done

  echo "Conversion Summary:"
  echo "  Total files processed: $file_count"
  echo "  Successfully converted: $success_count"
  echo "  Failed conversions: $errors"

  if [ "$errors" -eq 0 ]; then
    echo "Directory audio conversion complete, exported to $aud_folder/mp3"
    return 0
  else
    echo "Warning: Audio conversion completed with $errors errors" >&2
    return 1
  fi
}' # Convert all audio files in a directory to MP3 format

#------------------------------------------------------------------------------
# Audio Information
#------------------------------------------------------------------------------

alias ado-info='() {
  echo "Display detailed information about audio file(s)."
  echo "Usage:"
  echo "  ado-info <audio_file_path> [audio_file_path2 ...]"

  if [ $# -eq 0 ]; then
    return 1
  fi

  _audio_check_ffmpeg || return 1

  local errors=0

  for file in "$@"; do
    if ! _audio_validate_file "$file"; then
      ((errors++))
      continue
    fi

    echo "---- Audio file information for: $file ----"
    if ! ffprobe -v quiet -print_format json -show_format -show_streams "$file"; then
      echo "Error: Could not get information for $file" >&2
      ((errors++))
    fi
    echo "----------------------------------------"
  done

  if [ "$errors" -gt 0 ]; then
    return 1
  fi
  return 0
}' # Display detailed technical information about audio file(s)

#------------------------------------------------------------------------------
# Audio Format Conversion
#------------------------------------------------------------------------------

alias ado-to-wav='() {
  echo "Convert audio to WAV format."
  echo "Usage:"
  echo "  ado-to-wav <audio_file_path> [sample_rate:44100]"

  if [ $# -eq 0 ]; then
    return 1
  fi

  local input_file="$1"
  local sample_rate="${2:-44100}"

  _audio_validate_file "$input_file" || return 1
  _audio_check_ffmpeg || return 1

  local output_file="${input_file%.*}.wav"

  echo "Converting $input_file to WAV format with sample rate $sample_rate Hz..."

  if ffmpeg -i "$input_file" -ar "$sample_rate" "$output_file"; then
    echo "Conversion complete, exported to $output_file"
  else
    echo "Error: Audio conversion failed" >&2
    return 1
  fi
}' # Convert audio file to WAV format with specified sample rate

alias ado-to-ogg='() {
  echo "Convert audio to OGG format."
  echo "Usage:"
  echo "  ado-to-ogg <audio_file_path> [quality:3]"

  if [ $# -eq 0 ]; then
    return 1
  fi

  local input_file="$1"
  local quality="${2:-3}"  # Quality range 0-10, 3 is good default

  _audio_validate_file "$input_file" || return 1
  _audio_check_ffmpeg || return 1

  local output_file="${input_file%.*}.ogg"

  echo "Converting $input_file to OGG format with quality $quality..."

  if ffmpeg -i "$input_file" -c:a libvorbis -q:a "$quality" "$output_file"; then
    echo "Conversion complete, exported to $output_file"
  else
    echo "Error: Audio conversion failed" >&2
    return 1
  fi
}' # Convert audio file to OGG format with specified quality

#------------------------------------------------------------------------------
# Audio Manipulation
#------------------------------------------------------------------------------

alias ado-trim='() {
  echo "Trim audio file to specified start and duration."
  echo "Usage:"
  echo "  ado-trim <audio_file_path> <start_time> <duration>"
  echo "  Time format: hh:mm:ss or seconds (e.g. 00:01:30 or 90)"

  if [ $# -lt 3 ]; then
    return 1
  fi

  local input_file="$1"
  local start_time="$2"
  local duration="$3"

  _audio_validate_file "$input_file" || return 1
  _audio_check_ffmpeg || return 1

  local output_file="${input_file%.*}_trimmed.${input_file##*.}"

  echo "Trimming $input_file from $start_time for $duration..."

  if ffmpeg -i "$input_file" -ss "$start_time" -t "$duration" -c copy "$output_file"; then
    echo "Trimming complete, exported to $output_file"
  else
    echo "Error: Audio trimming failed" >&2
    return 1
  fi
}' # Trim audio file to specified start time and duration

alias ado-volume='() {
  echo -e "Adjust audio volume.\nUsage:\n  ado-volume <audio_file_path> <volume_factor>\n  Volume factor: 0.5 = half volume, 2.0 = double volume\n\nExamples:\n  ado-volume music.mp3 0.8\n  -> Reduces volume to 80% and saves as music_vol.mp3"

  if [ $# -lt 2 ]; then
    return 1
  fi

  local input_file="$1"
  local volume="$2"

  _audio_validate_file "$input_file" || return 1
  _audio_check_ffmpeg || return 1

  local output_file="${input_file%.*}_vol.${input_file##*.}"

  echo "Adjusting volume of $input_file by factor $volume..."

  if ffmpeg -i "$input_file" -filter:a "volume=$volume" "$output_file"; then
    echo "Volume adjustment complete, exported to $output_file"
  else
    echo "Error: Volume adjustment failed" >&2
    return 1
  fi
}' # Adjust audio volume by a factor (e.g., 0.5 for half volume)

alias ado-batch-volume='() {
  echo -e "Adjust volume of multiple audio files in a directory.\nUsage:\n  ado-batch-volume <audio_directory> <volume_factor> <source_extension:mp3>\n\nExamples:\n  ado-batch-volume ./music 0.8 mp3\n  -> Reduces volume to 80% for all mp3 files in ./music directory"

  if [ $# -lt 2 ]; then
    return 1
  fi

  local aud_folder="${1:-.}"
  local volume="$2"
  local aud_ext="${3:-mp3}"

  _audio_validate_dir "$aud_folder" || return 1
  _audio_check_ffmpeg || return 1

  # Set locale to handle Unicode/Chinese characters properly
  export LC_ALL=en_US.UTF-8
  export LANG=en_US.UTF-8

  # Check if source files exist using a more robust method
  local file_count=0
  local temp_files=()

  # Use process substitution to handle filenames with special characters
  while IFS= read -r -d "" file; do
    temp_files+=("$file")
    ((file_count++))
  done < <(find "$aud_folder" -maxdepth 1 -type f -name "*.${aud_ext}" -print0)

  if [ "$file_count" -eq 0 ]; then
    echo "Error: No ${aud_ext} files found in $aud_folder" >&2
    return 1
  fi

  mkdir -p "${aud_folder}/volume_adjusted"
  local errors=0
  local success_count=0

  # Process each file using array to preserve filenames with special characters
  for file in "${temp_files[@]}"; do
    local base_name=$(basename "$file" .${aud_ext})
    local output_file="$aud_folder/volume_adjusted/${base_name}_vol.${aud_ext}"

    echo "Adjusting volume: $(basename "$file") -> ${base_name}_vol.${aud_ext}"
    echo "  Volume factor: $volume"

    if ffmpeg -i "$file" -filter:a "volume=$volume" "$output_file" 2>/dev/null; then
      echo "  ✓ Success"
      ((success_count++))
    else
      echo "  ✗ Error: Failed to adjust volume for $(basename "$file")" >&2
      ((errors++))
    fi
    echo ""
  done

  echo "Volume Adjustment Summary:"
  echo "  Total files processed: $file_count"
  echo "  Successfully adjusted: $success_count"
  echo "  Failed adjustments: $errors"

  if [ "$errors" -eq 0 ]; then
    echo "Batch volume adjustment complete, exported to $aud_folder/volume_adjusted"
    return 0
  else
    echo "Warning: Volume adjustment completed with $errors errors" >&2
    return 1
  fi
}' # Adjust volume of multiple audio files in a directory

alias ado-merge='() {
  echo "Merge multiple audio files into one."
  echo "Usage:"
  echo "  ado-merge <output_file> <input_file1> <input_file2> [...]"

  if [ $# -lt 3 ]; then
    return 1
  fi

  local output_file="$1"
  shift

  _audio_check_ffmpeg || return 1

  # Set locale to handle Unicode/Chinese characters properly
  export LC_ALL=en_US.UTF-8
  export LANG=en_US.UTF-8

  # Create a temp file listing all input files
  local temp_file=$(mktemp)
  local errors=0
  local valid_files=0

  echo "Validating input files..."
  for file in "$@"; do
    if ! _audio_validate_file "$file"; then
      echo "  ✗ Invalid: $(basename "$file")"
      ((errors++))
      continue
    fi
    # Use absolute path to handle special characters properly
    local abs_file=$(realpath "$file")
    echo "file \"$abs_file\"" >> "$temp_file"
    echo "  ✓ Valid: $(basename "$file")"
    ((valid_files++))
  done

  if [ "$errors" -gt 0 ]; then
    echo "Error: $errors invalid files found. Cannot proceed with merge." >&2
    rm "$temp_file"
    return 1
  fi

  if [ "$valid_files" -eq 0 ]; then
    echo "Error: No valid files to merge." >&2
    rm "$temp_file"
    return 1
  fi

  echo ""
  echo "Merging $valid_files audio files into $(basename "$output_file")..."

  if ffmpeg -f concat -safe 0 -i "$temp_file" -c copy "$output_file" 2>/dev/null; then
    echo "✓ Merging complete, exported to $output_file"
    rm "$temp_file"
    return 0
  else
    echo "✗ Error: Audio merging failed" >&2
    rm "$temp_file"
    return 1
  fi
}' # Merge multiple audio files into a single file

#------------------------------------------------------------------------------
# Audio Effects
#------------------------------------------------------------------------------

alias ado-fade='() {
  echo -e "Add fade-in and fade-out to audio file.\nUsage:\n  ado-fade <audio_file_path> <fade_in_seconds:2> <fade_out_seconds:2>\n\nExamples:\n  ado-fade music.mp3 3 4\n  -> Adds 3 second fade-in and 4 second fade-out to music.mp3"

  if [ $# -eq 0 ]; then
    return 1
  fi

  local input_file="$1"
  local fade_in="${2:-2}"
  local fade_out="${3:-2}"

  _audio_validate_file "$input_file" || return 1
  _audio_check_ffmpeg || return 1

  local output_file="${input_file%.*}_fade.${input_file##*.}"

  # Get duration of audio file
  local duration=$(ffprobe -i "$input_file" -show_entries format=duration -v quiet -of csv="p=0")

  if [ -z "$duration" ]; then
    echo "Error: Could not determine audio duration" >&2
    return 1
  fi

  echo "Adding fade-in ($fade_in sec) and fade-out ($fade_out sec) to $input_file..."

  if ffmpeg -i "$input_file" -af "afade=t=in:st=0:d=$fade_in,afade=t=out:st=$( echo "$duration - $fade_out" | bc ):d=$fade_out" "$output_file"; then
    echo "Fade effect added, exported to $output_file"
  else
    echo "Error: Adding fade effect failed" >&2
    return 1
  fi
}' # Add fade-in and fade-out effects to an audio file

alias ado-batch-fade='() {
  echo -e "Add fade-in and fade-out effects to multiple audio files in a directory.\nUsage:\n  ado-batch-fade <audio_directory> <fade_in_seconds:2> <fade_out_seconds:2> <source_extension:mp3>\n\nExamples:\n  ado-batch-fade ./music 3 4 mp3\n  -> Adds 3 second fade-in and 4 second fade-out to all mp3 files in ./music directory"

  if [ $# -lt 1 ]; then
    return 1
  fi

  local aud_folder="${1:-.}"
  local fade_in="${2:-2}"
  local fade_out="${3:-2}"
  local aud_ext="${4:-mp3}"

  _audio_validate_dir "$aud_folder" || return 1
  _audio_check_ffmpeg || return 1

  # Set locale to handle Unicode/Chinese characters properly
  export LC_ALL=en_US.UTF-8
  export LANG=en_US.UTF-8

  # Check if source files exist using a more robust method
  local file_count=0
  local temp_files=()

  # Use process substitution to handle filenames with special characters
  while IFS= read -r -d "" file; do
    temp_files+=("$file")
    ((file_count++))
  done < <(find "$aud_folder" -maxdepth 1 -type f -name "*.${aud_ext}" -print0)

  if [ "$file_count" -eq 0 ]; then
    echo "Error: No ${aud_ext} files found in $aud_folder" >&2
    return 1
  fi

  mkdir -p "${aud_folder}/fade_added"
  local errors=0
  local success_count=0

  # Process each file using array to preserve filenames with special characters
  for file in "${temp_files[@]}"; do
    local base_name=$(basename "$file" .${aud_ext})
    local output_file="$aud_folder/fade_added/${base_name}_fade.${aud_ext}"

    echo "Adding fade effects: $(basename "$file") -> ${base_name}_fade.${aud_ext}"
    echo "  Fade-in: ${fade_in}s, Fade-out: ${fade_out}s"

    # Get duration of audio file
    local duration=$(ffprobe -i "$file" -show_entries format=duration -v quiet -of csv="p=0")

    if [ -z "$duration" ]; then
      echo "  ✗ Error: Could not determine audio duration" >&2
      ((errors++))
      echo ""
      continue
    fi

    # Check if bc is available for calculation
    if ! command -v bc &> /dev/null; then
      echo "  ✗ Error: bc calculator not found. Please install bc." >&2
      ((errors++))
      echo ""
      continue
    fi

    if ffmpeg -i "$file" -af "afade=t=in:st=0:d=$fade_in,afade=t=out:st=$( echo "$duration - $fade_out" | bc ):d=$fade_out" "$output_file" 2>/dev/null; then
      echo "  ✓ Success"
      ((success_count++))
    else
      echo "  ✗ Error: Failed to add fade effect" >&2
      ((errors++))
    fi
    echo ""
  done

  echo "Fade Effect Summary:"
  echo "  Total files processed: $file_count"
  echo "  Successfully processed: $success_count"
  echo "  Failed processing: $errors"

  if [ "$errors" -eq 0 ]; then
    echo "Batch fade effect addition complete, exported to $aud_folder/fade_added"
    return 0
  else
    echo "Warning: Fade effect addition completed with $errors errors" >&2
    return 1
  fi
}' # Add fade-in and fade-out effects to multiple audio files in a directory

alias ado-speed='() {
  echo "Change playback speed of audio file without changing pitch."
  echo "Usage:"
  echo "  ado-speed <audio_file_path> <speed_factor>"
  echo "  Speed factor: 0.5 = half speed, 2.0 = double speed"

  if [ $# -lt 2 ]; then
    return 1
  fi

  local input_file="$1"
  local speed="$2"

  _audio_validate_file "$input_file" || return 1
  _audio_check_ffmpeg || return 1

  local output_file="${input_file%.*}_speed${speed}.${input_file##*.}"

  echo "Changing speed of $input_file by factor $speed..."

  if ffmpeg -i "$input_file" -filter:a "atempo=$speed" "$output_file"; then
    echo "Speed adjustment complete, exported to $output_file"
  else
    echo "Error: Speed adjustment failed" >&2
    return 1
  fi
}' # Change playback speed of audio file without changing pitch

#------------------------------------------------------------------------------
# Audio Help
#------------------------------------------------------------------------------

alias ado-help='() {
  echo "Audio Aliases Help - Available commands:"
  echo
  echo "Conversion Commands:"
  echo "  ado-to-mp3       - Convert audio file to MP3 format"
  echo "  ado-dir-to-mp3   - Convert all audio files in directory to MP3"
  echo "  ado-to-wav       - Convert audio file to WAV format"
  echo "  ado-to-ogg       - Convert audio file to OGG format"
  echo
  echo "Information Commands:"
  echo "  ado-info         - Display detailed information about audio file(s)"
  echo
  echo "Manipulation Commands:"
  echo "  ado-trim         - Trim audio file to specified time range"
  echo "  ado-volume       - Adjust audio volume"
  echo "  ado-merge        - Merge multiple audio files into one"
  echo
  echo "Effect Commands:"
  echo "  ado-fade         - Add fade-in and fade-out to audio file"
  echo "  ado-speed        - Change playback speed without changing pitch"
  echo
  echo "Batch Processing Commands:"
  echo "  ado-batch-volume - Adjust volume of multiple audio files in a directory"
  echo "  ado-batch-fade   - Add fade-in and fade-out effects to multiple audio files"
  echo
  echo "For detailed usage of any command, run the command without arguments"
}' # Display help information for audio aliases

alias audio-help='() {
  ado-help
}' # Alias to call the audio help function
