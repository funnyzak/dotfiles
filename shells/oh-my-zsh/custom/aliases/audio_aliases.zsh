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
  echo -e "Convert audio to MP3 format.\nUsage:\n  ado-to-mp3 <audio_file_path> [bitrate:128k]\n\nExamples:\n  ado-to-mp3 music.wav\n  -> Converts music.wav to music.mp3 with 128k bitrate\n  ado-to-mp3 music.wav 192k\n  -> Converts with 192k bitrate"

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
  echo -e "Convert audio files in directory to MP3 format.\nUsage:\n  ado-dir-to-mp3 <audio_directory> <source_extension:wav> [bitrate:128k]\n\nExamples:\n  ado-dir-to-mp3 ./music wav\n  -> Converts all wav files in ./music to mp3 with 128k bitrate\n  ado-dir-to-mp3 ./music flac 192k\n  -> Converts all flac files with 192k bitrate"

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
  echo -e "Display detailed information about audio file(s).\nUsage:\n  ado-info <audio_file_path> [audio_file_path2 ...]\n\nExamples:\n  ado-info music.mp3\n  -> Shows detailed info for music.mp3\n  ado-info music.mp3 song.wav\n  -> Shows info for multiple files"

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
  echo -e "Convert audio to WAV format.\nUsage:\n  ado-to-wav <audio_file_path> [sample_rate:44100]\n\nExamples:\n  ado-to-wav music.mp3\n  -> Converts music.mp3 to music.wav with 44100 Hz sample rate\n  ado-to-wav music.mp3 48000\n  -> Converts with 48000 Hz sample rate"

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
  echo -e "Convert audio to OGG format.\nUsage:\n  ado-to-ogg <audio_file_path> [quality:3]\n\nExamples:\n  ado-to-ogg music.mp3\n  -> Converts music.mp3 to music.ogg with quality 3\n  ado-to-ogg music.mp3 6\n  -> Converts with higher quality (6 out of 10)"

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
  echo -e "Trim audio file to specified start and duration.\nUsage:\n  ado-trim <audio_file_path> <start_time> <duration>\n  Time format: hh:mm:ss or seconds (e.g. 00:01:30 or 90)\n\nExamples:\n  ado-trim music.mp3 00:01:30 00:02:00\n  -> Trims from 1:30 for 2 minutes\n  ado-trim music.mp3 90 120\n  -> Trims from 90 seconds for 120 seconds"

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
  echo -e "Merge multiple audio files into one.\nUsage:\n  ado-merge <output_file> <input_file1> <input_file2> [...]\n\nExamples:\n  ado-merge combined.mp3 intro.mp3 main.mp3 outro.mp3\n  -> Merges three files into combined.mp3\n  ado-merge playlist.mp3 song1.mp3 song2.mp3\n  -> Creates playlist from two songs"

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
  echo -e "Change playback speed of audio file without changing pitch.\nUsage:\n  ado-speed <audio_file_path> <speed_factor>\n  Speed factor: 0.5 = half speed, 2.0 = double speed\n\nExamples:\n  ado-speed music.mp3 0.8\n  -> Slows down music to 80% speed\n  ado-speed music.mp3 1.5\n  -> Speeds up music to 150% speed"

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
# Audio Compression
#------------------------------------------------------------------------------

alias ado-compress='() {
  echo -e "Compress audio file with various options.\nUsage:\n  ado-compress <audio_file_path> [--format mp3|aac|ogg] [--quality high|medium|low] [--bitrate 128k]\n\nExamples:\n  ado-compress music.wav\n  -> Compresses music.wav to music_compressed.mp3 with default settings\n  ado-compress music.wav --format aac --quality high\n  -> Compresses to AAC format with high quality\n  ado-compress music.wav --bitrate 96k\n  -> Compresses with specific bitrate"

  if [ $# -eq 0 ]; then
    return 1
  fi

  local input_file="$1"
  local output_format="mp3"
  local quality="medium"
  local bitrate=""
  local custom_bitrate=false

  # Parse options
  shift
  while [ $# -gt 0 ]; do
    case "$1" in
      --format)
        if [ -n "$2" ] && [[ "$2" =~ ^(mp3|aac|ogg)$ ]]; then
          output_format="$2"
          shift 2
        else
          echo "Error: Invalid format. Supported formats: mp3, aac, ogg" >&2
          return 1
        fi
        ;;
      --quality)
        if [ -n "$2" ] && [[ "$2" =~ ^(high|medium|low)$ ]]; then
          quality="$2"
          shift 2
        else
          echo "Error: Invalid quality. Supported qualities: high, medium, low" >&2
          return 1
        fi
        ;;
      --bitrate)
        if [ -n "$2" ] && [[ "$2" =~ ^[0-9]+k?$ ]]; then
          bitrate="$2"
          custom_bitrate=true
          shift 2
        else
          echo "Error: Invalid bitrate format. Use format like 128k or 192" >&2
          return 1
        fi
        ;;
      *)
        echo "Error: Unknown option $1" >&2
        return 1
        ;;
    esac
  done

  _audio_validate_file "$input_file" || return 1
  _audio_check_ffmpeg || return 1

  # Set bitrate based on quality if not custom specified
  if [ "$custom_bitrate" = false ]; then
    case "$quality" in
      high)
        case "$output_format" in
          mp3) bitrate="192k" ;;
          aac) bitrate="256k" ;;
          ogg) bitrate="192k" ;;
        esac
        ;;
      medium)
        case "$output_format" in
          mp3) bitrate="128k" ;;
          aac) bitrate="128k" ;;
          ogg) bitrate="128k" ;;
        esac
        ;;
      low)
        case "$output_format" in
          mp3) bitrate="96k" ;;
          aac) bitrate="96k" ;;
          ogg) bitrate="96k" ;;
        esac
        ;;
    esac
  fi

  local output_file="${input_file%.*}_compressed.${output_format}"

  echo "Compressing $input_file to $output_format format..."
  echo "  Quality: $quality"
  echo "  Bitrate: $bitrate"

  # Set compression options based on format
  local compression_opts=""
  case "$output_format" in
    mp3)
      compression_opts="-c:a libmp3lame -b:a $bitrate"
      ;;
    aac)
      compression_opts="-c:a aac -b:a $bitrate"
      ;;
    ogg)
      # For OGG, convert bitrate to quality if needed
      local ogg_quality=""
      case "$bitrate" in
        96k) ogg_quality="2" ;;
        128k) ogg_quality="4" ;;
        192k) ogg_quality="6" ;;
        *) ogg_quality="4" ;;
      esac
      compression_opts="-c:a libvorbis -q:a $ogg_quality"
      ;;
  esac

  if eval "ffmpeg -i \"$input_file\" $compression_opts \"$output_file\""; then
    echo "✓ Compression complete, exported to $output_file"

    # Show file size comparison
    if command -v stat &> /dev/null; then
      local original_size=$(stat -f%z "$input_file" 2>/dev/null || stat -c%s "$input_file" 2>/dev/null)
      local compressed_size=$(stat -f%z "$output_file" 2>/dev/null || stat -c%s "$output_file" 2>/dev/null)

      if [ -n "$original_size" ] && [ -n "$compressed_size" ]; then
        local compression_ratio=$(( compressed_size * 100 / original_size ))
        echo "  Original size: $(( original_size / 1024 ))KB"
        echo "  Compressed size: $(( compressed_size / 1024 ))KB"
        echo "  Compression ratio: ${compression_ratio}%"
      fi
    fi
  else
    echo "✗ Error: Audio compression failed" >&2
    echo "  Please check if the input file format is supported and try again" >&2
    return 1
  fi
}' # Compress audio file with customizable format, quality and bitrate options

alias ado-batch-compress='() {
  echo -e "Compress all audio files in a directory with various options.\nUsage:\n  ado-batch-compress <audio_directory> <source_extension:mp3> [--format mp3|aac|ogg] [--quality high|medium|low] [--bitrate 128k]\n\nExamples:\n  ado-batch-compress ./music wav\n  -> Compresses all wav files to mp3 with default settings\n  ado-batch-compress ./music flac --format aac --quality high\n  -> Compresses all flac files to AAC with high quality"

  if [ $# -lt 1 ]; then
    return 1
  fi

  local aud_folder="${1:-.}"
  local aud_ext="${2:-mp3}"
  local output_format="mp3"
  local quality="medium"
  local bitrate=""
  local custom_bitrate=false

  # Parse options
  shift 2
  while [ $# -gt 0 ]; do
    case "$1" in
      --format)
        if [ -n "$2" ] && [[ "$2" =~ ^(mp3|aac|ogg)$ ]]; then
          output_format="$2"
          shift 2
        else
          echo "Error: Invalid format. Supported formats: mp3, aac, ogg" >&2
          return 1
        fi
        ;;
      --quality)
        if [ -n "$2" ] && [[ "$2" =~ ^(high|medium|low)$ ]]; then
          quality="$2"
          shift 2
        else
          echo "Error: Invalid quality. Supported qualities: high, medium, low" >&2
          return 1
        fi
        ;;
      --bitrate)
        if [ -n "$2" ] && [[ "$2" =~ ^[0-9]+k?$ ]]; then
          bitrate="$2"
          custom_bitrate=true
          shift 2
        else
          echo "Error: Invalid bitrate format. Use format like 128k or 192" >&2
          return 1
        fi
        ;;
      *)
        echo "Error: Unknown option $1" >&2
        return 1
        ;;
    esac
  done

  _audio_validate_dir "$aud_folder" || return 1
  _audio_check_ffmpeg || return 1

  # Set bitrate based on quality if not custom specified
  if [ "$custom_bitrate" = false ]; then
    case "$quality" in
      high)
        case "$output_format" in
          mp3) bitrate="192k" ;;
          aac) bitrate="256k" ;;
          ogg) bitrate="192k" ;;
        esac
        ;;
      medium)
        case "$output_format" in
          mp3) bitrate="128k" ;;
          aac) bitrate="128k" ;;
          ogg) bitrate="128k" ;;
        esac
        ;;
      low)
        case "$output_format" in
          mp3) bitrate="96k" ;;
          aac) bitrate="96k" ;;
          ogg) bitrate="96k" ;;
        esac
        ;;
    esac
  fi

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

  mkdir -p "${aud_folder}/compressed_${output_format}"
  local errors=0
  local success_count=0
  local total_original_size=0
  local total_compressed_size=0

  echo "Starting batch compression..."
  echo "  Source format: $aud_ext"
  echo "  Output format: $output_format"
  echo "  Quality: $quality"
  echo "  Bitrate: $bitrate"
  echo ""

  # Set compression options based on format
  local compression_opts=""
  case "$output_format" in
    mp3)
      compression_opts="-c:a libmp3lame -b:a $bitrate"
      ;;
    aac)
      compression_opts="-c:a aac -b:a $bitrate"
      ;;
    ogg)
      # For OGG, convert bitrate to quality if needed
      local ogg_quality=""
      case "$bitrate" in
        96k) ogg_quality="2" ;;
        128k) ogg_quality="4" ;;
        192k) ogg_quality="6" ;;
        *) ogg_quality="4" ;;
      esac
      compression_opts="-c:a libvorbis -q:a $ogg_quality"
      ;;
  esac

  # Process each file using array to preserve filenames with special characters
  for file in "${temp_files[@]}"; do
    local base_name=$(basename "$file" .${aud_ext})
    local output_file="$aud_folder/compressed_${output_format}/${base_name}_compressed.${output_format}"

    echo "Compressing: $(basename "$file") -> ${base_name}_compressed.${output_format}"

    if eval "ffmpeg -i \"$file\" $compression_opts \"$output_file\" -loglevel error"; then
      echo "  ✓ Success"
      ((success_count++))

      # Calculate size if possible
      if command -v stat &> /dev/null; then
        local original_size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)
        local compressed_size=$(stat -f%z "$output_file" 2>/dev/null || stat -c%s "$output_file" 2>/dev/null)

        if [ -n "$original_size" ] && [ -n "$compressed_size" ]; then
          total_original_size=$(( total_original_size + original_size ))
          total_compressed_size=$(( total_compressed_size + compressed_size ))
          echo "    Size: $(( original_size / 1024 ))KB -> $(( compressed_size / 1024 ))KB"
        fi
      fi
    else
      echo "  ✗ Error: Failed to compress $(basename "$file")" >&2
      ((errors++))
    fi
    echo ""
  done

  echo "Batch Compression Summary:"
  echo "  Total files processed: $file_count"
  echo "  Successfully compressed: $success_count"
  echo "  Failed compressions: $errors"

  if [ "$total_original_size" -gt 0 ] && [ "$total_compressed_size" -gt 0 ]; then
    local total_compression_ratio=$(( total_compressed_size * 100 / total_original_size ))
    echo "  Total original size: $(( total_original_size / 1024 / 1024 ))MB"
    echo "  Total compressed size: $(( total_compressed_size / 1024 / 1024 ))MB"
    echo "  Overall compression ratio: ${total_compression_ratio}%"
    echo "  Space saved: $(( (total_original_size - total_compressed_size) / 1024 / 1024 ))MB"
  fi

  if [ "$errors" -eq 0 ]; then
    echo "Batch compression complete, exported to $aud_folder/compressed_${output_format}"
    return 0
  else
    echo "Warning: Batch compression completed with $errors errors" >&2
    return 1
  fi
}' # Compress all audio files in a directory with customizable options

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
  echo "Compression Commands:"
  echo "  ado-compress     - Compress audio file with customizable options"
  echo "  ado-batch-compress - Compress all audio files in a directory"
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
