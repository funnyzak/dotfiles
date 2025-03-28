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

  # Check if source files exist
  local file_count=$(find "$aud_folder" -maxdepth 1 -type f -name "*.${aud_ext}" | wc -l)
  if [ "$file_count" -eq 0 ]; then
    echo "Error: No ${aud_ext} files found in $aud_folder" >&2
    return 1
  fi

  mkdir -p "${aud_folder}/mp3"
  local errors=0

  find "$aud_folder" -maxdepth 1 -type f -name "*.${aud_ext}" | while read -r file; do
    local output_file="$aud_folder/mp3/$(basename "$file" .${aud_ext}).mp3"
    echo "Converting $file to $output_file with bitrate $bitrate..."
    if ! ffmpeg -i "$file" -c:a libmp3lame -b:a "$bitrate" "$output_file"; then
      echo "Error: Failed to convert $file" >&2
      ((errors++))
    fi
  done

  if [ "$errors" -eq 0 ]; then
    echo "Directory audio conversion complete, exported to $aud_folder/mp3"
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
  echo "Adjust audio volume."
  echo "Usage:"
  echo "  ado-volume <audio_file_path> <volume_factor>"
  echo "  Volume factor: 0.5 = half volume, 2.0 = double volume"

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

  # Create a temp file listing all input files
  local temp_file=$(mktemp)
  local errors=0

  for file in "$@"; do
    if ! _audio_validate_file "$file"; then
      ((errors++))
      continue
    fi
    echo "file '$file'" >> "$temp_file"
  done

  if [ "$errors" -gt 0 ]; then
    rm "$temp_file"
    return 1
  fi

  echo "Merging audio files into $output_file..."

  if ffmpeg -f concat -safe 0 -i "$temp_file" -c copy "$output_file"; then
    echo "Merging complete, exported to $output_file"
    rm "$temp_file"
  else
    echo "Error: Audio merging failed" >&2
    rm "$temp_file"
    return 1
  fi
}' # Merge multiple audio files into a single file

#------------------------------------------------------------------------------
# Audio Effects
#------------------------------------------------------------------------------

alias ado-fade='() {
  echo "Add fade-in and fade-out to audio file."
  echo "Usage:"
  echo "  ado-fade <audio_file_path> <fade_in_seconds:2> <fade_out_seconds:2>"

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
  echo "For detailed usage of any command, run the command without arguments"
}' # Display help information for audio aliases
