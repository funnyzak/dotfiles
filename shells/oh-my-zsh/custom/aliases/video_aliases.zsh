# Description: Video processing aliases for conversion, compression, merging, and format transformation using ffmpeg.

#------------------------------------------------------------------------------
# Helper Functions
#------------------------------------------------------------------------------

# Helper function to validate file existence
_vdo_validate_file() {
  if [[ ! -f "$1" ]]; then
    echo "Error: File \"$1\" does not exist" >&2
    return 1
  fi
  return 0
}

# Helper function to validate directory existence
_vdo_validate_dir() {
  if [[ ! -d "$1" ]]; then
    echo "Error: Directory \"$1\" does not exist" >&2
    return 1
  fi
  return 0
}

# Helper function to check if ffmpeg is installed
_vdo_check_ffmpeg() {
  if ! command -v ffmpeg &> /dev/null; then
    echo "Error: ffmpeg is not installed or not in PATH" >&2
    return 1
  fi
  return 0
}

#------------------------------------------------------------------------------
# Video File Merging
#------------------------------------------------------------------------------

alias vdo-merge='() {
  if [ $# -eq 0 ]; then
    echo "Merge video files in a directory."
    echo "Usage:"
    echo "  vdo-merge <source_dir> <video_extension:mp4>"
    return 1
  fi

  vdo_folder="${1:-$(pwd)}"
  vdo_ext="${2:-mp4}"

  _vdo_validate_dir "$vdo_folder" || return 1
  _vdo_check_ffmpeg || return 1

  # Check if source files exist
  file_count=$(find "$vdo_folder" -maxdepth 1 -type f -name "*.${vdo_ext}" | wc -l)
  if [ "$file_count" -eq 0 ]; then
    echo "Error: No ${vdo_ext} files found in $vdo_folder" >&2
    return 1
  fi

  # Create a temporary file list
  temp_list=$(mktemp)
  find "$vdo_folder" -maxdepth 1 -type f -name "*.${vdo_ext}" | sort | while read -r f; do
    echo "file \"$f\"" >> "$temp_list"
  done

  # Execute merge
  output_file="${vdo_folder}/merged_video.${vdo_ext}"
  echo "Merging videos into ${output_file}..."

  if ffmpeg -f concat -safe 0 -i "$temp_list" -c copy "$output_file"; then
    echo "Video merge complete, exported to ${output_file}"
  else
    echo "Error: Video merge failed" >&2
    rm "$temp_list"
    return 1
  fi

  # Clean up temporary file
  rm "$temp_list"
}' # Merge multiple videos into one file

alias vdo-merge-audio='() {
  echo -e "Merge video and audio files into one MP4 file.\nUsage:\n  vdo-merge-audio <video_file_path> [audio_file_path]\n\nExamples:\n  vdo-merge-audio video.mp4 audio.mp3\n  vdo-merge-audio video.mp4  # Automatically finds matching audio file"

  if [ $# -eq 0 ]; then
    return 1
  fi

  local video_file="$1"
  local audio_file="$2"
  local video_basename
  local video_dir
  local output_file

  _vdo_validate_file "$video_file" || return 1
  _vdo_check_ffmpeg || return 1

  # Extract video basename and directory
  video_basename=$(basename "$video_file")
  video_name="${video_basename%.*}"
  video_dir=$(dirname "$video_file")

  # If audio file not specified, try to find matching audio file
  if [ -z "$audio_file" ]; then
    echo "No audio file specified, searching for matching audio files..."

    # Try to find audio files with same name but different extension
    for ext in mp3 wav aac m4a ogg flac; do
      potential_audio="$video_dir/$video_name.$ext"
      if [ -f "$potential_audio" ]; then
        audio_file="$potential_audio"
        echo "Found matching audio file: $audio_file"
        break
      fi
    done

    if [ -z "$audio_file" ]; then
      echo "Error: No matching audio file found for $video_file" >&2
      echo "Please specify an audio file or ensure a matching one exists in the same directory" >&2
      return 1
    fi
  else
    _vdo_validate_file "$audio_file" || return 1
  fi

  # Create output filename
  output_file="${video_dir}/${video_name}_merged.mp4"

  echo "Merging video $video_file with audio $audio_file..."

  if ffmpeg -i "$video_file" -i "$audio_file" -c:v copy -c:a aac -b:a 192k -map 0:v:0 -map 1:a:0 "$output_file"; then
    echo "Audio-video merge complete, exported to $output_file"
  else
    echo "Error: Audio-video merge failed" >&2
    return 1
  fi
}' # Merge a video with an audio file

alias vdo-batch-merge-audio='() {
  echo -e "Batch merge video and audio files from directories.\nUsage:\n  vdo-batch-merge-audio <video_directory> [options]\n\nOptions:\n  -ad, --audio_dir DIR    : Directory containing audio files (default: same as video dir)\n  -ve, --video_ext EXT    : Video file extension (default: mp4)\n  -ae, --audio_ext EXT    : Audio file extension (default: mp3)\n  -q,  --quality VALUE    : Audio quality in kbps (default: 192)\n  -o,  --output_dir DIR   : Output directory (default: video_dir/merged)\n  -h,  --help             : Show this help message\n\nExamples:\n  vdo-batch-merge-audio videos/ --audio_dir audios/ --video_ext mp4 --audio_ext wav\n  vdo-batch-merge-audio videos/ -ad audios/ -ve mp4 -ae wav"

  # Variables with default values
  local video_dir=""
  local audio_dir=""
  local video_ext="mp4"
  local audio_ext="mp3"
  local audio_quality="192"
  local output_dir=""
  local show_help=false

  # Parse all arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -ad|--audio_dir)
        audio_dir="$2"
        shift 2
        ;;
      -ve|--video_ext)
        video_ext="$2"
        shift 2
        ;;
      -ae|--audio_ext)
        audio_ext="$2"
        shift 2
        ;;
      -q|--quality)
        audio_quality="$2"
        shift 2
        ;;
      -o|--output_dir)
        output_dir="$2"
        shift 2
        ;;
      -h|--help)
        show_help=true
        shift
        ;;
      *)
        # First non-option argument is the video directory
        if [ -z "$video_dir" ]; then
          video_dir="$1"
        else
          echo "Error: Unexpected argument \"$1\"" >&2
          show_help=true
        fi
        shift
        ;;
    esac
  done

  # Show help if requested or no video_dir provided
  if $show_help || [ -z "$video_dir" ]; then
    return 1
  fi

  # Use video_dir as audio_dir if not specified
  if [ -z "$audio_dir" ]; then
    audio_dir="$video_dir"
  fi

  # Set default output_dir if not specified
  if [ -z "$output_dir" ]; then
    output_dir="${video_dir}/merged"
  fi

  _vdo_validate_dir "$video_dir" || return 1
  _vdo_validate_dir "$audio_dir" || return 1
  _vdo_check_ffmpeg || return 1

  # Check if video files exist
  local file_count=$(find "$video_dir" -maxdepth 1 -type f -name "*.${video_ext}" | wc -l)
  if [ "$file_count" -eq 0 ]; then
    echo "Error: No ${video_ext} files found in $video_dir" >&2
    return 1
  fi

  # Create output directory
  mkdir -p "$output_dir"

  local success_count=0
  local error_count=0
  local skipped_count=0

  # Process each video file
  find "$video_dir" -maxdepth 1 -type f -name "*.${video_ext}" | while read -r video_file; do
    local base_name=$(basename "$video_file" .${video_ext})
    local audio_file="${audio_dir}/${base_name}.${audio_ext}"
    local output_file="${output_dir}/${base_name}.mp4"

    # Check if audio file exists
    if [ ! -f "$audio_file" ]; then
      echo "Warning: No matching audio file found for $video_file, skipping..." >&2
      ((skipped_count++))
      continue
    fi

    echo "Merging video $video_file with audio $audio_file..."

    if ffmpeg -i "$video_file" -i "$audio_file" -c:v copy -c:a aac -b:a "${audio_quality}k" -map 0:v:0 -map 1:a:0 -y "$output_file"; then
      echo "Merge complete for $base_name"
      ((success_count++))
    else
      echo "Error: Failed to merge $base_name" >&2
      ((error_count++))
    fi
  done

  # Print summary
  echo "Batch merge summary:"
  echo "  Successfully merged: $success_count files"
  echo "  Failed to merge: $error_count files"
  echo "  Skipped (no audio): $skipped_count files"
  echo "Output files saved to: $output_dir"

  # Return error if any errors occurred
  if [ "$error_count" -gt 0 ]; then
    return 1
  fi

  return 0
}' # Batch merge videos with audio files from directories

#------------------------------------------------------------------------------
# Video Format Conversion
#------------------------------------------------------------------------------

alias vdo-to-mp4='() {
  if [ $# -eq 0 ]; then
    echo "Convert video to MP4 format."
    echo "Usage:"
    echo "  vdo-to-mp4 <video_file_path> [video_file_path2] [video_file_path3]..."
    return 1
  fi

  _vdo_check_ffmpeg || return 1
  input_files=("$@")

  for input_file in "${input_files[@]}"; do
    _vdo_validate_file "$input_file" || return 1

    output_file="${input_file%.*}.mp4"
    echo "Converting $input_file to MP4 format..."

    if ffmpeg -i "$input_file" -c:v libx264 -crf 18 -preset slow -c:a aac -b:a 256k -ac 2 "$output_file"; then
      echo "Conversion complete, exported to $output_file"
    else
      echo "Error: Video conversion failed" >&2
      return 1
    fi
  done
}' # Convert video to MP4 format

alias vdo-batch-to-mp4='() {
  if [ $# -eq 0 ]; then
    echo "Convert videos in directory to MP4 format."
    echo "Usage:"
    echo "  vdo-batch-to-mp4 <video_directory> <source_extension:mp4>"
    return 1
  fi

  vdo_folder="${1:-.}"
  vdo_ext="${2:-mp4}"

  _vdo_validate_dir "$vdo_folder" || return 1
  _vdo_check_ffmpeg || return 1

  # Check if source files exist
  file_count=$(find "$vdo_folder" -maxdepth 1 -type f -name "*.${vdo_ext}" | wc -l)
  if [ "$file_count" -eq 0 ]; then
    echo "Error: No ${vdo_ext} files found in $vdo_folder" >&2
    return 1
  fi

  mkdir -p "${vdo_folder}/mp4"
  errors=0

  find "$vdo_folder" -maxdepth 1 -type f -name "*.${vdo_ext}" | while read -r file; do
    output_file="$vdo_folder/mp4/$(basename "$file" .${vdo_ext}).mp4"
    echo "Converting $file to $output_file..."
    if ! ffmpeg -i "$file" -c:v libx264 -crf 18 -preset slow -c:a aac -b:a 256k -ac 2 "$output_file"; then
      echo "Error: Failed to convert $file" >&2
      ((errors++))
    fi
  done

  if [ "$errors" -eq 0 ]; then
    echo "Directory video conversion complete, exported to $vdo_folder/mp4"
  else
    echo "Warning: Conversion completed with $errors errors" >&2
    return 1
  fi
}' # Convert batch of videos to MP4 format

#------------------------------------------------------------------------------
# Video to Audio Extraction
#------------------------------------------------------------------------------

alias vdo-extract-mp3='() {
  if [ $# -eq 0 ]; then
    echo "Extract audio from video to MP3 format."
    echo "Usage:"
    echo "  vdo-extract-mp3 <video_file_path>"
    return 1
  fi

  input_file="$1"
  _vdo_validate_file "$input_file" || return 1
  _vdo_check_ffmpeg || return 1

  output_file="${input_file%.*}.mp3"
  echo "Extracting audio from $input_file to MP3 format..."

  if ffmpeg -i "$input_file" -vn -acodec libmp3lame -ab 128k -ar 44100 -y "$output_file"; then
    echo "Extraction complete, exported to $output_file"
  else
    echo "Error: Audio extraction failed" >&2
    return 1
  fi
}' # Extract audio from video to MP3 format

alias vdo-extract-dir-mp3='() {
  if [ $# -eq 0 ]; then
    echo "Extract audio from videos in directory to MP3 format."
    echo "Usage:"
    echo "  vdo-extract-dir-mp3 <video_directory> <source_extension:mp4>"
    return 1
  fi

  vdo_folder="${1:-.}"
  vdo_ext="${2:-mp4}"

  _vdo_validate_dir "$vdo_folder" || return 1
  _vdo_check_ffmpeg || return 1

  # Check if source files exist
  file_count=$(find "$vdo_folder" -maxdepth 1 -type f -name "*.${vdo_ext}" | wc -l)
  if [ "$file_count" -eq 0 ]; then
    echo "Error: No ${vdo_ext} files found in $vdo_folder" >&2
    return 1
  fi

  mkdir -p "${vdo_folder}/mp3"
  errors=0

  find "$vdo_folder" -maxdepth 1 -type f -name "*.${vdo_ext}" | while read -r file; do
    output_file="$vdo_folder/mp3/$(basename "$file" .${vdo_ext}).mp3"
    echo "Extracting audio from $file to $output_file..."
    if ! ffmpeg -i "$file" -vn -acodec libmp3lame -ab 128k -ar 44100 -y "$output_file"; then
      echo "Error: Failed to extract audio from $file" >&2
      ((errors++))
    fi
  done

  if [ "$errors" -eq 0 ]; then
    echo "Directory audio extraction complete, exported to $vdo_folder/mp3"
  else
    echo "Warning: Audio extraction completed with $errors errors" >&2
    return 1
  fi
}' # Extract audio from videos in directory to MP3 format

#------------------------------------------------------------------------------
# Video Compression
#------------------------------------------------------------------------------

alias vdo-compress='() {
  if [ $# -eq 0 ]; then
    echo "Compress video."
    echo "Usage:"
    echo "  vdo-compress <video_file_path> [quality:30]"
    echo "Note: Lower quality value means higher quality (18-28 is good range)"
    return 1
  fi

  input_file="$1"
  quality="${2:-30}"

  _vdo_validate_file "$input_file" || return 1
  _vdo_check_ffmpeg || return 1

  # Validate quality parameter
  if ! [[ "$quality" =~ ^[0-9]+$ ]] || [ "$quality" -lt 0 ] || [ "$quality" -gt 51 ]; then
    echo "Error: Quality must be a number between 0 and 51" >&2
    return 1
  fi

  output_file="${input_file%.*}_compressed.mp4"
  echo "Compressing $input_file with quality factor $quality..."

  if ffmpeg -i "$input_file" -c:v libx264 -tag:v avc1 -movflags faststart -crf "$quality" -preset superfast "$output_file"; then
    echo "Compression complete, exported to $output_file"
  else
    echo "Error: Video compression failed" >&2
    return 1
  fi
}' # Compress video with specified quality

alias vdo-compress-dir='() {
  if [ $# -eq 0 ]; then
    echo "Compress videos in directory."
    echo "Usage:"
    echo "  vdo-compress-dir <video_directory> <source_extension:mp4> [quality:30]"
    echo "Note: Lower quality value means higher quality (18-28 is good range)"
    return 1
  fi

  vdo_folder="${1:-.}"
  vdo_ext="${2:-mp4}"
  quality="${3:-30}"

  _vdo_validate_dir "$vdo_folder" || return 1
  _vdo_check_ffmpeg || return 1

  # Validate quality parameter
  if ! [[ "$quality" =~ ^[0-9]+$ ]] || [ "$quality" -lt 0 ] || [ "$quality" -gt 51 ]; then
    echo "Error: Quality must be a number between 0 and 51" >&2
    return 1
  fi

  # Check if source files exist
  file_count=$(find "$vdo_folder" -maxdepth 1 -type f -name "*.${vdo_ext}" | wc -l)
  if [ "$file_count" -eq 0 ]; then
    echo "Error: No ${vdo_ext} files found in $vdo_folder" >&2
    return 1
  fi

  mkdir -p "${vdo_folder}/compressed"
  errors=0

  find "$vdo_folder" -maxdepth 1 -type f -name "*.${vdo_ext}" | while read -r file; do
    output_file="$vdo_folder/compressed/$(basename "$file" .${vdo_ext})_compressed.mp4"
    echo "Compressing $file to $output_file with quality factor $quality..."
    if ! ffmpeg -i "$file" -c:v libx264 -tag:v avc1 -movflags faststart -crf "$quality" -preset superfast "$output_file"; then
      echo "Error: Failed to compress $file" >&2
      ((errors++))
    fi
  done

  if [ "$errors" -eq 0 ]; then
    echo "Directory video compression complete, exported to $vdo_folder/compressed"
  else
    echo "Warning: Compression completed with $errors errors" >&2
    return 1
  fi
}' # Compress videos in directory

#------------------------------------------------------------------------------
# Video Resolution Conversion
#------------------------------------------------------------------------------

# Helper functions for resolution conversion
_vdo_convert_resolution='() {
  if [ $# -lt 2 ]; then
    echo "Error: Missing required parameters" >&2
    return 1
  fi

  input_file="$1"
  resolution="$2"

  _vdo_validate_file "$input_file" || return 1
  _vdo_check_ffmpeg || return 1

  output_file="${input_file%.*}_${resolution}p.mp4"
  echo "Converting $input_file to ${resolution}p resolution..."

  if ffmpeg -i "$input_file" -vf "scale=-2:${resolution}" -c:a copy "$output_file"; then
    echo "Conversion complete, exported to $output_file"
    return 0
  else
    echo "Error: Video resolution conversion failed" >&2
    return 1
  fi
}' # Convert video to specified resolution

_vdo_convert_dir_resolution='() {
  if [ $# -lt 2 ]; then
    echo "Error: Missing required parameters" >&2
    return 1
  fi

  vdo_folder="$1"
  resolution="$2"
  vdo_ext="${3:-mp4}"

  _vdo_validate_dir "$vdo_folder" || return 1
  _vdo_check_ffmpeg || return 1

  # Check if source files exist
  file_count=$(find "$vdo_folder" -maxdepth 1 -type f -name "*.${vdo_ext}" | wc -l)
  if [ "$file_count" -eq 0 ]; then
    echo "Error: No ${vdo_ext} files found in $vdo_folder" >&2
    return 1
  fi

  mkdir -p "${vdo_folder}/${resolution}p"
  errors=0

  find "$vdo_folder" -maxdepth 1 -type f -name "*.${vdo_ext}" | while read -r file; do
    output_file="$vdo_folder/${resolution}p/$(basename "$file" .${vdo_ext})_${resolution}p.mp4"
    echo "Converting $file to ${resolution}p resolution..."
    if ! ffmpeg -i "$file" -vf "scale=-2:${resolution}" -c:a copy "$output_file"; then
      echo "Error: Failed to convert $file" >&2
      ((errors++))
    fi
  done

  if [ "$errors" -eq 0 ]; then
    echo "Directory video resolution conversion complete, exported to $vdo_folder/${resolution}p"
    return 0
  else
    echo "Warning: Resolution conversion completed with $errors errors" >&2
    return 1
  fi
}' # Convert videos in directory to specified resolution

# Resolution specific aliases
alias vdo-to-320p='() {
  if [ $# -eq 0 ]; then
    echo "Convert video to 320p resolution."
    echo "Usage:"
    echo "  vdo-to-320p <video_file_path>"
    return 1
  fi
  _vdo_convert_resolution "$1" "320"
}' # Convert video to 320p resolution

alias vdo-to-480p='() {
  if [ $# -eq 0 ]; then
    echo "Convert video to 480p resolution."
    echo "Usage:"
    echo "  vdo-to-480p <video_file_path>"
    return 1
  fi
  _vdo_convert_resolution "$1" "480"
}' # Convert video to 480p resolution

alias vdo-to-720p='() {
  if [ $# -eq 0 ]; then
    echo "Convert video to 720p resolution."
    echo "Usage:"
    echo "  vdo-to-720p <video_file_path>"
    return 1
  fi
  _vdo_convert_resolution "$1" "720"
}' # Convert video to 720p resolution

alias vdo-to-1080p='() {
  if [ $# -eq 0 ]; then
    echo "Convert video to 1080p resolution."
    echo "Usage:"
    echo "  vdo-to-1080p <video_file_path>"
    return 1
  fi
  _vdo_convert_resolution "$1" "1080"
}' # Convert video to 1080p resolution

# Directory resolution conversion aliases
alias vdo-dir-to-320p='() {
  if [ $# -eq 0 ]; then
    echo "Convert videos in directory to 320p resolution."
    echo "Usage:"
    echo "  vdo-dir-to-320p <video_directory> <source_extension:mp4>"
    return 1
  fi
  _vdo_convert_dir_resolution "${1:-.}" "320" "${2:-mp4}"
}' # Convert videos in directory to 320p resolution

alias vdo-dir-to-480p='() {
  if [ $# -eq 0 ]; then
    echo "Convert videos in directory to 480p resolution."
    echo "Usage:"
    echo "  vdo-dir-to-480p <video_directory> <source_extension:mp4>"
    return 1
  fi
  _vdo_convert_dir_resolution "${1:-.}" "480" "${2:-mp4}"
}' # Convert videos in directory to 480p resolution

alias vdo-dir-to-720p='() {
  if [ $# -eq 0 ]; then
    echo "Convert videos in directory to 720p resolution."
    echo "Usage:"
    echo "  vdo-dir-to-720p <video_directory> <source_extension:mp4>"
    return 1
  fi
  _vdo_convert_dir_resolution "${1:-.}" "720" "${2:-mp4}"
}' # Convert videos in directory to 720p resolution

alias vdo-dir-to-1080p='() {
  if [ $# -eq 0 ]; then
    echo "Convert videos in directory to 1080p resolution."
    echo "Usage:"
    echo "  vdo-dir-to-1080p <video_directory> <source_extension:mp4>"
    return 1
  fi
  _vdo_convert_dir_resolution "${1:-.}" "1080" "${2:-mp4}"
}' # Convert videos in directory to 1080p resolution

#------------------------------------------------------------------------------
# Mobile Device Optimization
#------------------------------------------------------------------------------

alias vdo-optimize-for-mobile='() {
  if [ $# -eq 0 ]; then
    echo "Optimize video for mobile devices."
    echo "Usage:"
    echo "  vdo-optimize-for-mobile <video_file_path> [video_file_path2] [video_file_path3]..."
    return 1
  fi

  input_files=("$@")
  _vdo_check_ffmpeg || return 1

  for input_file in "${input_files[@]}"; do
    _vdo_validate_file "${input_files[@]}" || return 1
    temp_file="${input_file%.*}_320p_temp.mp4"
    output_file="${input_file%.*}_mobile.mp4"
    echo "Converting $input_file to mobile-optimized format..."

    # First convert to 320p
    if ! ffmpeg -i "$input_file" -vf "scale=-2:320" -c:a copy "$temp_file"; then
      echo "Error: Failed to convert to 320p resolution" >&2
      return 1
    fi

    # Then compress
    if ffmpeg -i "$temp_file" -c:v libx264 -tag:v avc1 -movflags faststart -crf 28 -preset superfast "$output_file"; then
      echo "Mobile optimization complete, exported to $output_file"
      # Delete intermediate file
      rm "$temp_file"
    else
      echo "Error: Video compression failed" >&2
      rm "$temp_file"
      return 1
    fi
  done
}' # Optimize video for mobile devices

#------------------------------------------------------------------------------
# M3U8 Stream Processing
#------------------------------------------------------------------------------

alias vdo-convert-m3u8-to-mp4='() {
  if [ $# -eq 0 ]; then
    echo "Convert M3U8 stream to MP4 video."
    echo "Usage:"
    echo "  vdo-convert-m3u8-to-mp4 <m3u8_url> [output_filename]"
    return 1
  fi

  _vdo_check_ffmpeg || return 1

  url="$1"
  output="${2:-output_$(date +%Y%m%d%H%M%S).mp4}"

  echo "Converting M3U8 stream $url to MP4 format..."

  if ffmpeg -i "$url" -c copy "${output}"; then
    echo "Conversion complete, exported to ${output}"
  else
    echo "Error: M3U8 conversion failed" >&2
    return 1
  fi
}' # Convert M3U8 stream to MP4 video

#------------------------------------------------------------------------------
# Video Information & Metadata
#------------------------------------------------------------------------------

alias vdo-info='() {
  echo "Show detailed information about a video file."
  echo "Usage:"
  echo "  vdo-info <video_file_path>"

  if [ $# -eq 0 ]; then
    return 1
  fi

  input_file="$1"
  _vdo_validate_file "$input_file" || return 1
  _vdo_check_ffmpeg || return 1

  echo "Getting detailed information for $input_file..."
  ffmpeg -i "$input_file" -hide_banner 2>&1 | grep -v "^ffmpeg version"
}' # Show detailed video information

alias vdo-stream-info='() {
  echo "Show stream information about a video file."
  echo "Usage:"
  echo "  vdo-stream-info <video_file_path>"

  if [ $# -eq 0 ]; then
    return 1
  fi

  input_file="$1"
  _vdo_validate_file "$input_file" || return 1
  _vdo_check_ffmpeg || return 1

  echo "Getting stream information for $input_file..."
  ffprobe -v error -show_entries stream=index,codec_name,codec_type,width,height,bit_rate,duration -of compact=p=0:nk=1 "$input_file"
}' # Display codec and stream details

alias vdo-duration='() {
  echo "Show the duration of a video file."
  echo "Usage:"
  echo "  vdo-duration <video_file_path>"

  if [ $# -eq 0 ]; then
    return 1
  fi

  input_file="$1"
  _vdo_validate_file "$input_file" || return 1
  _vdo_check_ffmpeg || return 1

  duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$input_file")
  hours=$(echo "$duration/3600" | bc)
  minutes=$(echo "($duration%3600)/60" | bc)
  seconds=$(echo "$duration%60" | bc)

  printf "Duration of %s: %02d:%02d:%05.2f\n" "$input_file" "$hours" "$minutes" "$seconds"
}' # Show video duration in hours:minutes:seconds

#------------------------------------------------------------------------------
# Video Trimming & Splitting
#------------------------------------------------------------------------------

alias vdo-trim-video='() {
  echo "Trim a video file between start and end time."
  echo "Usage:"
  echo "  vdo-trim-video <video_file_path> <start_time> <duration>"
  echo "Time format examples: 00:01:30 (1m30s), 00:00:45 (45s)"

  if [ $# -lt 3 ]; then
    return 1
  fi

  input_file="$1"
  start_time="$2"
  duration="$3"

  _vdo_validate_file "$input_file" || return 1
  _vdo_check_ffmpeg || return 1

  output_file="${input_file%.*}_trimmed.mp4"
  echo "Trimming $input_file from $start_time for $duration..."

  if ffmpeg -ss "$start_time" -i "$input_file" -t "$duration" -c:v copy -c:a copy "$output_file"; then
    echo "Trimming complete, exported to $output_file"
  else
    echo "Error: Video trimming failed" >&2
    return 1
  fi
}' # Trim video to specified start time and duration

alias vdo-split-video='() {
  echo "Split a video file into segments of specified duration."
  echo "Usage:"
  echo "  vdo-split-video <video_file_path> <segment_duration>"
  echo "Duration format examples: 00:10:00 (10min), 00:30:00 (30min)"

  if [ $# -lt 2 ]; then
    return 1
  fi

  input_file="$1"
  segment_duration="$2"

  _vdo_validate_file "$input_file" || return 1
  _vdo_check_ffmpeg || return 1

  output_pattern="${input_file%.*}_part%03d.mp4"
  echo "Splitting $input_file into segments of $segment_duration..."

  if ffmpeg -i "$input_file" -c copy -f segment -segment_time "$segment_duration" -reset_timestamps 1 "$output_pattern"; then
    echo "Splitting complete, segments saved with pattern: ${output_pattern}"
  else
    echo "Error: Video splitting failed" >&2
    return 1
  fi
}' # Split video into equal segments

#------------------------------------------------------------------------------
# Video Frame Extraction
#------------------------------------------------------------------------------

alias vdo-extract-frame='() {
  echo -e "Extract a single frame from a video at specified time.\nUsage:\n  vdo-extract-frame <video_file_path> <time_position>\nTime format examples: 00:01:30 (1m30s), 00:00:45 (45s)\n\nExamples:\n  vdo-extract-frame video.mp4 00:01:30\n  vdo-extract-frame movie.mkv 00:45:22"

  if [ $# -lt 2 ]; then
    return 1
  fi

  local input_file="$1"
  local time_pos="$2"

  _vdo_validate_file "$input_file" || return 1
  _vdo_check_ffmpeg || return 1

  local output_file="${input_file%.*}_frame_${time_pos//:/}.jpg"
  echo "Extracting frame from $input_file at position $time_pos..."

  if ffmpeg -ss "$time_pos" -i "$input_file" -vframes 1 -q:v 2 "$output_file"; then
    echo "Frame extraction complete, saved to $output_file"
  else
    echo "Error: Frame extraction failed" >&2
    return 1
  fi
}' # Extract single frame at specified time position

alias vdo-extract-frames='() {
  echo -e "Extract frames from a video at specified interval.\nUsage:\n  vdo-extract-frames <video_file_path> <interval_in_seconds:1>\n\nExamples:\n  vdo-extract-frames video.mp4 2\n  -> Extracts a frame every 2 seconds from video.mp4"

  if [ $# -lt 1 ]; then
    return 1
  fi

  local input_file="$1"
  local interval="${2:-1}"

  _vdo_validate_file "$input_file" || return 1
  _vdo_check_ffmpeg || return 1

  # Create output directory
  local output_dir="${input_file%.*}_frames"
  mkdir -p "$output_dir"

  echo "Extracting frames from $input_file every $interval seconds..."

  if ffmpeg -i "$input_file" -vf "fps=1/${interval}" "$output_dir/frame_%04d.jpg"; then
    echo "Frame extraction complete, saved to $output_dir/"
  else
    echo "Error: Frame extraction failed" >&2
    return 1
  fi
}' # Extract frames at regular intervals

alias vdo-batch-extract-frame='() {
  echo -e "Extract a frame at the same time position from multiple videos.\nUsage:\n  vdo-batch-extract-frame <time_position> <video_directory> <file_extension:mp4>\n\nExamples:\n  vdo-batch-extract-frame 00:01:30 ./videos mp4\n  -> Extracts a frame at 1m30s from all mp4 files in ./videos directory"

  if [ $# -lt 2 ]; then
    return 1
  fi

  local time_pos="$1"
  local vdo_folder="${2:-.}"
  local vdo_ext="${3:-mp4}"

  _vdo_validate_dir "$vdo_folder" || return 1
  _vdo_check_ffmpeg || return 1

  # Check if source files exist
  local file_count=$(find "$vdo_folder" -maxdepth 1 -type f -name "*.${vdo_ext}" | wc -l)
  if [ "$file_count" -eq 0 ]; then
    echo "Error: No ${vdo_ext} files found in $vdo_folder" >&2
    return 1
  fi

  # Create output directory
  local output_dir="${vdo_folder}/frames_${time_pos//:/}"
  mkdir -p "$output_dir"
  local errors=0

  find "$vdo_folder" -maxdepth 1 -type f -name "*.${vdo_ext}" | while read -r file; do
    local base_name=$(basename "$file" .${vdo_ext})
    local output_file="$output_dir/${base_name}_frame_${time_pos//:/}.jpg"
    echo "Extracting frame from $file at position $time_pos..."
    if ! ffmpeg -ss "$time_pos" -i "$file" -vframes 1 -q:v 2 "$output_file"; then
      echo "Error: Failed to extract frame from $file" >&2
      ((errors++))
    fi
  done

  if [ "$errors" -eq 0 ]; then
    echo "Batch frame extraction complete, exported to $output_dir"
  else
    echo "Warning: Frame extraction completed with $errors errors" >&2
    return 1
  fi
}' # Extract frames at specified time from multiple videos

#------------------------------------------------------------------------------
# Video Speed Modification
#------------------------------------------------------------------------------

alias vdo-speed-up='() {
  echo "Speed up a video by specified factor."
  echo "Usage:"
  echo "  vdo-speed-up <video_file_path> <speed_factor:2>"
  echo "Example: speed-up-video input.mp4 2  # Double the speed"

  if [ $# -lt 1 ]; then
    return 1
  fi

  input_file="$1"
  speed_factor="${2:-2}"

  _vdo_validate_file "$input_file" || return 1
  _vdo_check_ffmpeg || return 1

  # Validate speed factor
  if ! [[ "$speed_factor" =~ ^[0-9]+(\.[0-9]+)?$ ]] || (( $(echo "$speed_factor <= 0" | bc -l) )); then
    echo "Error: Speed factor must be a positive number" >&2
    return 1
  fi

  output_file="${input_file%.*}_${speed_factor}x.mp4"
  # Calculate tempo (inverse of speed for audio)
  tempo=$(echo "scale=2; 1/$speed_factor" | bc)

  echo "Speeding up $input_file by ${speed_factor}x..."

  if ffmpeg -i "$input_file" -filter_complex "[0:v]setpts=PTS/${speed_factor}[v];[0:a]atempo=${tempo}[a]" -map "[v]" -map "[a]" "$output_file"; then
    echo "Speed modification complete, saved to $output_file"
  else
    echo "Error: Video speed modification failed" >&2
    return 1
  fi
}' # Speed up video playback

alias vdo-slow-down='() {
  echo "Slow down a video by specified factor."
  echo "Usage:"
  echo "  vdo-slow-down <video_file_path> <slow_factor:2>"
  echo "Example: slow-down-video input.mp4 2  # Half the speed"

  if [ $# -lt 1 ]; then
    return 1
  fi

  input_file="$1"
  slow_factor="${2:-2}"

  _vdo_validate_file "$input_file" || return 1
  _vdo_check_ffmpeg || return 1

  # Validate slow factor
  if ! [[ "$slow_factor" =~ ^[0-9]+(\.[0-9]+)?$ ]] || (( $(echo "$slow_factor <= 0" | bc -l) )); then
    echo "Error: Slow factor must be a positive number" >&2
    return 1
  fi

  output_file="${input_file%.*}_${slow_factor}x_slow.mp4"
  # Calculate tempo (inverse of slow factor for audio)
  tempo=$(echo "scale=2; 1/$slow_factor" | bc)

  echo "Slowing down $input_file by ${slow_factor}x..."

  if ffmpeg -i "$input_file" -filter_complex "[0:v]setpts=PTS*${slow_factor}[v];[0:a]atempo=${tempo}[a]" -map "[v]" -map "[a]" "$output_file"; then
    echo "Speed modification complete, saved to $output_file"
  else
    echo "Error: Video speed modification failed" >&2
    return 1
  fi
}' # Slow down video playback

#------------------------------------------------------------------------------
# Video Watermark & Overlay
#------------------------------------------------------------------------------

alias vdo-add-watermark='() {
  echo "Add a watermark image to a video."
  echo "Usage:"
  echo "  vdo-add-watermark <video_file_path> <watermark_image> <position:bottomright>"
  echo "Positions: topleft, topright, bottomleft, bottomright, center"

  if [ $# -lt 2 ]; then
    return 1
  fi

  input_file="$1"
  watermark_image="$2"
  position="${3:-bottomright}"

  _vdo_validate_file "$input_file" || return 1
  _vdo_validate_file "$watermark_image" || return 1
  _vdo_check_ffmpeg || return 1

  output_file="${input_file%.*}_watermarked.mp4"

  # Set position coordinates based on input position
  case "$position" in
    topleft)
      overlay_position="10:10"
      ;;
    topright)
      overlay_position="main_w-overlay_w-10:10"
      ;;
    bottomleft)
      overlay_position="10:main_h-overlay_h-10"
      ;;
    bottomright)
      overlay_position="main_w-overlay_w-10:main_h-overlay_h-10"
      ;;
    center)
      overlay_position="(main_w-overlay_w)/2:(main_h-overlay_h)/2"
      ;;
    *)
      echo "Error: Invalid position. Use topleft, topright, bottomleft, bottomright, or center" >&2
      return 1
      ;;
  esac

  echo "Adding watermark to $input_file at position $position..."

  if ffmpeg -i "$input_file" -i "$watermark_image" -filter_complex "overlay=$overlay_position" -codec:a copy "$output_file"; then
    echo "Watermark added, saved to $output_file"
  else
    echo "Error: Adding watermark failed" >&2
    return 1
  fi
}' # Add image watermark to video

alias vdo-add-text='() {
  echo "Add a text watermark to a video."
  echo "Usage:"
  echo "  vdo-add-text <video_file_path> <text> <position:bottomright> <font_size:24> <color:white>"
  echo "Positions: topleft, topright, bottomleft, bottomright, center"
  echo "Colors: white, black, red, green, blue, yellow"

  if [ $# -lt 2 ]; then
    return 1
  fi

  input_file="$1"
  text="$2"
  position="${3:-bottomright}"
  font_size="${4:-24}"
  color="${5:-white}"

  _vdo_validate_file "$input_file" || return 1
  _vdo_check_ffmpeg || return 1

  output_file="${input_file%.*}_text_watermarked.mp4"

  # Set position coordinates based on input position
  case "$position" in
    topleft)
      text_position="x=10:y=10"
      ;;
    topright)
      text_position="x=w-tw-10:y=10"
      ;;
    bottomleft)
      text_position="x=10:y=h-th-10"
      ;;
    bottomright)
      text_position="x=w-tw-10:y=h-th-10"
      ;;
    center)
      text_position="x=(w-tw)/2:y=(h-th)/2"
      ;;
    *)
      echo "Error: Invalid position. Use topleft, topright, bottomleft, bottomright, or center" >&2
      return 1
      ;;
  esac

  echo "Adding text watermark \"$text\" to $input_file at position $position..."

  if ffmpeg -i "$input_file" -vf "drawtext=fontfile=/System/Library/Fonts/Helvetica.ttc:text='$text':fontcolor=$color:fontsize=$font_size:$text_position" -codec:a copy "$output_file"; then
    echo "Text watermark added, saved to $output_file"
  else
    echo "Error: Adding text watermark failed" >&2
    return 1
  fi
}' # Add text watermark to video

#------------------------------------------------------------------------------
# Video Audio Processing
#------------------------------------------------------------------------------

alias vdo-remove-audio='() {
  echo "Remove audio from video."
  echo "Usage:"
  echo "  vdo-remove-audio <video_file_path>"

  if [ $# -lt 1 ]; then
    return 1
  fi

  input_file="$1"
  _vdo_validate_file "$input_file" || return 1
  _vdo_check_ffmpeg || return 1

  output_file="${input_file%.*}_no_audio.mp4"
  echo "Removing audio from $input_file..."

  if ffmpeg -i "$input_file" -c:v copy -an "$output_file"; then
    echo "Audio removal complete, saved to $output_file"
  else
    echo "Error: Audio removal failed" >&2
    return 1
  fi
}' # Remove audio track from video

alias vdo-replace-audio='() {
  echo "Replace video audio with another audio file."
  echo "Usage:"
  echo "  vdo-replace-audio <video_file_path> <audio_file_path>"

  if [ $# -lt 2 ]; then
    return 1
  fi

  video_file="$1"
  audio_file="$2"

  _vdo_validate_file "$video_file" || return 1
  _vdo_validate_file "$audio_file" || return 1
  _vdo_check_ffmpeg || return 1

  output_file="${video_file%.*}_new_audio.mp4"
  echo "Replacing audio in $video_file with $audio_file..."

  if ffmpeg -i "$video_file" -i "$audio_file" -c:v copy -map 0:v:0 -map 1:a:0 -shortest "$output_file"; then
    echo "Audio replacement complete, saved to $output_file"
  else
    echo "Error: Audio replacement failed" >&2
    return 1
  fi
}' # Replace video audio track with another audio file

alias vdo-adjust-volume='() {
  echo "Adjust video audio volume."
  echo "Usage:"
  echo "  vdo-adjust-volume <video_file_path> <volume_factor:1.5>"
  echo "Examples: 0.5 (half volume), 1.5 (50% louder), 2.0 (double volume)"

  if [ $# -lt 2 ]; then
    return 1
  fi

  input_file="$1"
  volume="${2:-1.5}"

  _vdo_validate_file "$input_file" || return 1
  _vdo_check_ffmpeg || return 1

  # Validate volume factor
  if ! [[ "$volume" =~ ^[0-9]+(\.[0-9]+)?$ ]] || (( $(echo "$volume < 0" | bc -l) )); then
    echo "Error: Volume factor must be a positive number" >&2
    return 1
  fi

  output_file="${input_file%.*}_vol_${volume}.mp4"
  echo "Adjusting volume of $input_file by factor $volume..."

  if ffmpeg -i "$input_file" -filter:a "volume=$volume" -c:v copy "$output_file"; then
    echo "Volume adjustment complete, saved to $output_file"
  else
    echo "Error: Volume adjustment failed" >&2
    return 1
  fi
}' # Adjust audio volume in video

#------------------------------------------------------------------------------
# Video Screenshot Series
#------------------------------------------------------------------------------

alias vdo-create-thumbnails='() {
  echo "Create thumbnail images from video at regular intervals."
  echo "Usage:"
  echo "  vdo-create-thumbnails <video_file_path> <interval_in_seconds:60> <thumbnail_width:320>"

  if [ $# -lt 1 ]; then
    return 1
  fi

  input_file="$1"
  interval="${2:-60}"
  width="${3:-320}"

  _vdo_validate_file "$input_file" || return 1
  _vdo_check_ffmpeg || return 1

  # Create output directory
  output_dir="${input_file%.*}_thumbnails"
  mkdir -p "$output_dir"

  echo "Creating thumbnails from $input_file every $interval seconds..."

  if ffmpeg -i "$input_file" -vf "fps=1/$interval,scale=$width:-1" -q:v 2 "$output_dir/thumb_%04d.jpg"; then
    echo "Thumbnail creation complete, saved to $output_dir/"
  else
    echo "Error: Thumbnail creation failed" >&2
    return 1
  fi
}' # Create thumbnails at regular intervals

alias vdo-create-preview-grid='() {
  echo "Create a preview grid of video screenshots."
  echo "Usage:"
  echo "  vdo-create-preview-grid <video_file_path> <columns:4> <rows:4>"

  if [ $# -lt 1 ]; then
    return 1
  fi

  input_file="$1"
  columns="${2:-4}"
  rows="${3:-4}"

  _vdo_validate_file "$input_file" || return 1
  _vdo_check_ffmpeg || return 1

  output_file="${input_file%.*}_preview.jpg"
  total_frames=$((columns * rows))

  # Get video duration
  duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$input_file")

  # Calculate interval between frames
  interval=$(echo "scale=2; $duration / ($total_frames + 1)" | bc)

  echo "Creating $columns×$rows preview grid from $input_file..."

  if ffmpeg -i "$input_file" -vf "fps=1/$interval,scale=320:-1,tile=${columns}x${rows}" -frames:v 1 -q:v 2 "$output_file"; then
    echo "Preview grid created, saved to $output_file"
  else
    echo "Error: Preview grid creation failed" >&2
    return 1
  fi
}' # Create a grid of screenshots from the video

#------------------------------------------------------------------------------
# Video Screenshot Functions
#------------------------------------------------------------------------------

alias vdo-screenshot='() {
  echo -e "Capture screenshots from a video.\nUsage:\n  vdo-screenshot <video_file_path> [options]\n\nOptions:\n  -m, --mode MODE        : Capture mode: \"time\" or \"count\" (default: time)\n  -t, --timestamps LIST  : Comma-separated list of timestamps (default: 00:00:00)\n                           Format: HH:MM:SS or MM:SS or SS\n  -c, --count NUMBER     : Number of screenshots to capture (default: 3)\n  -w, --width WIDTH      : Width of screenshots (default: 1280, aspect ratio preserved)\n  -q, --quality VALUE    : JPEG quality (1-31, lower is better quality, default: 2)\n  -o, --output_dir DIR   : Output directory (default: video_name_screenshots)\n  -f, --filename FORMAT  : Output filename format (default: \"screenshot_%03d\")\n  -h, --help             : Show this help message\n\nExamples:\n  vdo-screenshot video.mp4 --mode time --timestamps 00:05:00,00:10:00,00:15:00\n  vdo-screenshot video.mp4 -m count -c 5 -w 800 -o ./screenshots"

  # Variables with default values
  local input_file=""
  local mode="time"
  local timestamps="00:00:00"
  local count=3
  local width=1280
  local quality=2
  local output_dir=""
  local filename_format="screenshot_%03d"
  local show_help=false

  # Parse all arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -m|--mode)
        mode="$2"
        shift 2
        ;;
      -t|--timestamps)
        timestamps="$2"
        shift 2
        ;;
      -c|--count)
        count="$2"
        shift 2
        ;;
      -w|--width)
        width="$2"
        shift 2
        ;;
      -q|--quality)
        quality="$2"
        shift 2
        ;;
      -o|--output_dir)
        output_dir="$2"
        shift 2
        ;;
      -f|--filename)
        filename_format="$2"
        shift 2
        ;;
      -h|--help)
        show_help=true
        shift
        ;;
      *)
        # First non-option argument is the input file
        if [ -z "$input_file" ]; then
          input_file="$1"
        else
          echo "Error: Unexpected argument \"$1\"" >&2
          show_help=true
        fi
        shift
        ;;
    esac
  done

  # Show help if requested or no input_file provided
  if $show_help || [ -z "$input_file" ]; then
    return 1
  fi

  _vdo_validate_file "$input_file" || return 1
  _vdo_check_ffmpeg || return 1

  # Validate mode parameter
  if [[ "$mode" != "time" && "$mode" != "count" ]]; then
    echo "Error: Mode must be either \"time\" or \"count\"" >&2
    return 1
  fi

  # Set default output_dir if not specified
  if [ -z "$output_dir" ]; then
    output_dir="${input_file%.*}_screenshots"
  fi

  # Create output directory
  mkdir -p "$output_dir"

  # Get video duration
  local duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$input_file")
  duration=${duration%.*} # Remove decimal part

  # Process based on mode
  if [ "$mode" = "time" ]; then
    echo "Capturing screenshots from $input_file at specified timestamps..."

    # Split timestamps by comma (zsh-compatible way)
    local timestamp_array=("${(@s/,/)timestamps}")
    local i=1

    for ts in "${timestamp_array[@]}"; do
      # Validate timestamp is not empty
      if [[ -z "$ts" ]]; then
        echo "Error: Empty timestamp detected" >&2
        continue
      fi

      local output_file="${output_dir}/${filename_format}.jpg"
      output_file=$(printf "$output_file" $i)

      echo "Taking screenshot at $ts -> $output_file"

      if ! ffmpeg -ss "$ts" -i "$input_file" -vframes 1 -q:v "$quality" -vf "scale=$width:-1" "$output_file"; then
        echo "Error: Failed to capture screenshot at $ts" >&2
        return 1
      fi

      ((i++))
    done

    echo "Captured ${#timestamp_array[@]} screenshots from $input_file"
  else
    # Count mode - captures evenly spaced screenshots
    echo "Capturing $count evenly spaced screenshots from $input_file..."

    if (( count <= 0 )); then
      echo "Error: Count must be greater than 0" >&2
      return 1
    fi

    # Calculate interval based on duration and count
    local interval=$(( duration / (count + 1) ))

    for ((i=1; i<=count; i++)); do
      local time_pos=$((interval * i))
      # Format timestamp in HH:MM:SS format (cross-platform compatible)
      local hours=$((time_pos/3600))
      local minutes=$(((time_pos%3600)/60))
      local seconds=$((time_pos%60))
      local timestamp=$(printf "%02d:%02d:%02d" $hours $minutes $seconds)

      local output_file="${output_dir}/${filename_format}.jpg"
      output_file=$(printf "$output_file" $i)

      echo "Taking screenshot at $timestamp -> $output_file"

      if ! ffmpeg -ss "$timestamp" -i "$input_file" -vframes 1 -q:v "$quality" -vf "scale=$width:-1" "$output_file"; then
        echo "Error: Failed to capture screenshot at $timestamp" >&2
        return 1
      fi
    done

    echo "Captured $count screenshots from $input_file"
  fi

  echo "Screenshots saved to $output_dir"
  return 0
}' # Capture screenshots from a video

alias vdo-batch-screenshot='() {
  echo -e "Capture screenshots from videos in a directory.\nUsage:\n  vdo-batch-screenshot <video_directory> [options]\n\nOptions:\n  -m, --mode MODE        : Capture mode: \"time\" or \"count\" (default: time)\n  -t, --timestamps LIST  : Comma-separated list of timestamps (default: 00:00:00)\n                           Format: HH:MM:SS or MM:SS or SS\n  -c, --count NUMBER     : Number of screenshots to capture (default: 3)\n  -w, --width WIDTH      : Width of screenshots (default: 1280, aspect ratio preserved)\n  -q, --quality VALUE    : JPEG quality (1-31, lower is better quality, default: 2)\n  -o, --output_dir DIR   : Output directory (default: video_dir/screenshots)\n  -e, --extension EXT    : Video file extension to process (default: mp4)\n  -f, --filename FORMAT  : Output filename format (default: \"%s_screenshot_%03d\")\n  -h, --help             : Show this help message\n\nExamples:\n  vdo-batch-screenshot videos/ --mode time --timestamps 00:05:00,00:10:00\n  vdo-batch-screenshot videos/ -m count -c 5 -e mkv -o ./screenshots"

  # Variables with default values
  local video_dir=""
  local mode="time"
  local timestamps="00:00:00"
  local count=3
  local width=1280
  local quality=2
  local output_dir=""
  local video_ext="mp4"
  local filename_format="%s_screenshot_%03d"
  local show_help=false

  # Parse all arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -m|--mode)
        mode="$2"
        shift 2
        ;;
      -t|--timestamps)
        timestamps="$2"
        shift 2
        ;;
      -c|--count)
        count="$2"
        shift 2
        ;;
      -w|--width)
        width="$2"
        shift 2
        ;;
      -q|--quality)
        quality="$2"
        shift 2
        ;;
      -o|--output_dir)
        output_dir="$2"
        shift 2
        ;;
      -e|--extension)
        video_ext="$2"
        shift 2
        ;;
      -f|--filename)
        filename_format="$2"
        shift 2
        ;;
      -h|--help)
        show_help=true
        shift
        ;;
      *)
        # First non-option argument is the video directory
        if [ -z "$video_dir" ]; then
          video_dir="$1"
        else
          echo "Error: Unexpected argument \"$1\"" >&2
          show_help=true
        fi
        shift
        ;;
    esac
  done

  # Show help if requested or no video_dir provided
  if $show_help || [ -z "$video_dir" ]; then
    return 1
  fi

  _vdo_validate_dir "$video_dir" || return 1
  _vdo_check_ffmpeg || return 1

  # Validate mode parameter
  if [[ "$mode" != "time" && "$mode" != "count" ]]; then
    echo "Error: Mode must be either \"time\" or \"count\"" >&2
    return 1
  fi

  # Set default output_dir if not specified
  if [ -z "$output_dir" ]; then
    output_dir="${video_dir}/screenshots"
  fi

  # Create output directory
  mkdir -p "$output_dir"

  # Check if video files exist
  local file_count=$(find "$video_dir" -maxdepth 1 -type f -name "*.${video_ext}" | wc -l)
  if [ "$file_count" -eq 0 ]; then
    echo "Error: No ${video_ext} files found in $video_dir" >&2
    return 1
  fi

  local success_count=0
  local error_count=0
  local processed_videos=0

  # Process each video file
  find "$video_dir" -maxdepth 1 -type f -name "*.${video_ext}" | while read -r video_file; do
    local base_name=$(basename "$video_file" .${video_ext})
    echo "Processing $video_file..."
    ((processed_videos++))

    # Get video duration
    local duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$video_file")
    duration=${duration%.*} # Remove decimal part

    # Process based on mode
    if [ "$mode" = "time" ]; then
      # Split timestamps by comma (zsh-compatible way)
      local timestamp_array=("${(@s/,/)timestamps}")
      local i=1

      for ts in "${timestamp_array[@]}"; do
        # Validate timestamp is not empty
        if [[ -z "$ts" ]]; then
          echo "Error: Empty timestamp detected" >&2
          continue
        fi

        local actual_filename=$(printf "$filename_format" "$base_name" $i)
        local output_file="${output_dir}/${actual_filename}.jpg"

        echo "  Taking screenshot at $ts -> $output_file"

        if ffmpeg -ss "$ts" -i "$video_file" -vframes 1 -q:v "$quality" -vf "scale=$width:-1" "$output_file"; then
          ((success_count++))
        else
          echo "  Error: Failed to capture screenshot at $ts from $video_file" >&2
          ((error_count++))
        fi

        ((i++))
      done
    else
      # Count mode - captures evenly spaced screenshots
      if (( count <= 0 )); then
        echo "Error: Count must be greater than 0" >&2
        return 1
      fi

      # Calculate interval based on duration and count
      local interval=$(( duration / (count + 1) ))

      for ((i=1; i<=count; i++)); do
        local time_pos=$((interval * i))
        # Format timestamp in HH:MM:SS format (cross-platform compatible)
        local hours=$((time_pos/3600))
        local minutes=$(((time_pos%3600)/60))
        local seconds=$((time_pos%60))
        local timestamp=$(printf "%02d:%02d:%02d" $hours $minutes $seconds)

        local actual_filename=$(printf "$filename_format" "$base_name" $i)
        local output_file="${output_dir}/${actual_filename}.jpg"

        echo "  Taking screenshot at $timestamp -> $output_file"

        if ffmpeg -ss "$timestamp" -i "$video_file" -vframes 1 -q:v "$quality" -vf "scale=$width:-1" "$output_file"; then
          ((success_count++))
        else
          echo "  Error: Failed to capture screenshot at $timestamp from $video_file" >&2
          ((error_count++))
        fi
      done
    fi
  done

  # Print summary
  echo "Batch screenshot summary:"
  echo "  Processed: $processed_videos videos"
  echo "  Successfully captured: $success_count screenshots"
  echo "  Failed: $error_count screenshots"
  echo "Screenshots saved to $output_dir"

  # Return error if any errors occurred
  if [ "$error_count" -gt 0 ]; then
    return 1
  fi

  return 0
}' # Capture screenshots from videos in a directory

#------------------------------------------------------------------------------
# Video Cropping
#------------------------------------------------------------------------------

# Helper function to get video dimensions
_vdo_get_dimensions() {
  local input_file="$1"
  local width=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of default=noprint_wrappers=1:nokey=1 "$input_file")
  local height=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of default=noprint_wrappers=1:nokey=1 "$input_file")
  echo "$width $height"
}

# Helper function to calculate crop parameters
_vdo_calculate_crop_params() {
  local input_file="$1"
  local position="$2"
  local size="$3"

  # Get video dimensions
  local dimensions=$(_vdo_get_dimensions "$input_file")
  local video_width=$(echo "$dimensions" | awk '{print $1}')
  local video_height=$(echo "$dimensions" | awk '{print $2}')

  local pos_x=0
  local pos_y=0
  local crop_width="$video_width"
  local crop_height="$video_height"

  # Parse position
  if [ -n "$position" ]; then
    local pos_x_val=$(echo "$position" | cut -d',' -f1)
    local pos_y_val=$(echo "$position" | cut -d',' -f2)

    # Check if percentage or absolute value
    if [[ "$position" == *"%"* ]]; then
      # Position in percentage
      pos_x_val=$(echo "$pos_x_val" | tr -d '%')
      pos_y_val=$(echo "$pos_y_val" | tr -d '%')
      pos_x=$(echo "scale=0; $video_width * $pos_x_val / 100" | bc)
      pos_y=$(echo "scale=0; $video_height * $pos_y_val / 100" | bc)
    else
      # Position in absolute pixels
      pos_x="$pos_x_val"
      pos_y="$pos_y_val"
    fi
  fi

  # Parse size
  if [ -n "$size" ]; then
    local size_width=$(echo "$size" | cut -d',' -f1)
    local size_height=$(echo "$size" | cut -d',' -f2)

    # Check if percentage or absolute value
    if [[ "$size" == *"%"* ]]; then
      # Size in percentage
      size_width=$(echo "$size_width" | tr -d '%')
      size_height=$(echo "$size_height" | tr -d '%')
      crop_width=$(echo "scale=0; $video_width * $size_width / 100" | bc)
      crop_height=$(echo "scale=0; $video_height * $size_height / 100" | bc)
    else
      # Size in absolute pixels
      crop_width="$size_width"
      crop_height="$size_height"
    fi
  else
    # If size not specified, crop from position to end of video
    crop_width=$((video_width - pos_x))
    crop_height=$((video_height - pos_y))
  fi

  # Ensure we don't crop outside video bounds
  if (( pos_x + crop_width > video_width )); then
    crop_width=$((video_width - pos_x))
  fi

  if (( pos_y + crop_height > video_height )); then
    crop_height=$((video_height - pos_y))
  fi

  printf "%s %s %s %s" "$crop_width" "$crop_height" "$pos_x" "$pos_y"
}

alias vdo-crop='() {
  echo -e "Crop a video file by position and size.\nUsage:\n  vdo-crop <video_file_path> [options]\n\nOptions:\n  -p, --position POS     : Start position for cropping, format: \"x,y\" or \"x%,y%\"\n                           (default: 0,0)\n  -s, --size SIZE        : Size of the cropped area, format: \"width,height\" or \"width%,height%\"\n                           (default: full width/height from position)\n  -o, --output PATH      : Output file path (default: input_cropped.mp4)\n  -q, --quality VALUE    : Output quality (0-51, lower is better, default: 23)\n  -h, --help             : Show this help message\n\nExamples:\n  vdo-crop video.mp4 -p 100,200 -s 500,400\n  -> Crop from position x=100,y=200 with width=500,height=400\n  vdo-crop video.mp4 -p 10%,20% -s 60%,50%\n  -> Crop from 10% width and 20% height, with size 60% of width and 50% of height"

  # Variables with default values
  local input_file=""
  local position="0,0"
  local size=""
  local output_file=""
  local quality=23
  local show_help=false

  # Parse all arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -p|--position)
        position="$2"
        shift 2
        ;;
      -s|--size)
        size="$2"
        shift 2
        ;;
      -o|--output)
        output_file="$2"
        shift 2
        ;;
      -q|--quality)
        quality="$2"
        shift 2
        ;;
      -h|--help)
        show_help=true
        shift
        ;;
      *)
        # First non-option argument is the input file
        if [ -z "$input_file" ]; then
          input_file="$1"
        else
          echo "Error: Unexpected argument \"$1\"" >&2
          show_help=true
        fi
        shift
        ;;
    esac
  done

  # Show help if requested or no input_file provided
  if $show_help || [ -z "$input_file" ]; then
    return 1
  fi

  _vdo_validate_file "$input_file" || return 1
  _vdo_check_ffmpeg || return 1

  # Validate position format
  if ! [[ "$position" =~ ^[0-9%]+,[0-9%]+$ ]]; then
    echo "Error: Position must be in format \"x,y\" or \"x%,y%\"" >&2
    return 1
  fi

  # Validate size format if provided
  if [ -n "$size" ] && ! [[ "$size" =~ ^[0-9%]+,[0-9%]+$ ]]; then
    echo "Error: Size must be in format \"width,height\" or \"width%,height%\"" >&2
    return 1
  fi

  # Set default output file if not specified
  if [ -z "$output_file" ]; then
    output_file="${input_file%.*}_cropped.mp4"
  fi

  # Calculate crop parameters
  local crop_params=$(_vdo_calculate_crop_params "$input_file" "$position" "$size")
  read -r crop_width crop_height crop_x crop_y <<< "$crop_params"

  echo "Cropping $input_file..."
  echo "  From position: x=$crop_x, y=$crop_y"
  echo "  With size: width=$crop_width, height=$crop_height"
  echo "  Output: $output_file"

  # Apply the crop
  if ffmpeg -i "$input_file" -vf "crop=$crop_width:$crop_height:$crop_x:$crop_y" -c:v libx264 -crf "$quality" -c:a copy "$output_file"; then
    echo "Video cropping complete, saved to $output_file"
  else
    echo "Error: Video cropping failed" >&2
    return 1
  fi

  return 0
}' # Crop a video file by position and size

alias vdo-batch-crop='() {
  echo -e "Crop multiple video files in a directory by position and size.\nUsage:\n  vdo-batch-crop <video_directory> [options]\n\nOptions:\n  -p, --position POS     : Start position for cropping, format: \"x,y\" or \"x%,y%\"\n                           (default: 0,0)\n  -s, --size SIZE        : Size of the cropped area, format: \"width,height\" or \"width%,height%\"\n                           (default: full width/height from position)\n  -o, --output-dir DIR   : Output directory (default: video_dir/cropped)\n  -e, --extension EXT    : Video file extension to process (default: mp4)\n  -q, --quality VALUE    : Output quality (0-51, lower is better, default: 23)\n  -h, --help             : Show this help message\n\nExamples:\n  vdo-batch-crop videos/ -p 100,200 -s 500,400\n  -> Crop all videos from x=100,y=200 with width=500,height=400\n  vdo-batch-crop videos/ -p 10%,20% -s 60%,50% -e mkv -o ./cropped_videos\n  -> Crop all mkv videos from 10% width and 20% height, with size 60% of width and 50% of height"

  # Variables with default values
  local video_dir=""
  local position="0,0"
  local size=""
  local output_dir=""
  local video_ext="mp4"
  local quality=23
  local show_help=false

  # Parse all arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -p|--position)
        position="$2"
        shift 2
        ;;
      -s|--size)
        size="$2"
        shift 2
        ;;
      -o|--output-dir)
        output_dir="$2"
        shift 2
        ;;
      -e|--extension)
        video_ext="$2"
        shift 2
        ;;
      -q|--quality)
        quality="$2"
        shift 2
        ;;
      -h|--help)
        show_help=true
        shift
        ;;
      *)
        # First non-option argument is the video directory
        if [ -z "$video_dir" ]; then
          video_dir="$1"
        else
          echo "Error: Unexpected argument \"$1\"" >&2
          show_help=true
        fi
        shift
        ;;
    esac
  done

  # Show help if requested or no video_dir provided
  if $show_help || [ -z "$video_dir" ]; then
    return 1
  fi

  _vdo_validate_dir "$video_dir" || return 1
  _vdo_check_ffmpeg || return 1

  # Validate position format
  if ! [[ "$position" =~ ^[0-9%]+,[0-9%]+$ ]]; then
    echo "Error: Position must be in format \"x,y\" or \"x%,y%\"" >&2
    return 1
  fi

  # Validate size format if provided
  if [ -n "$size" ] && ! [[ "$size" =~ ^[0-9%]+,[0-9%]+$ ]]; then
    echo "Error: Size must be in format \"width,height\" or \"width%,height%\"" >&2
    return 1
  fi

  # Set default output_dir if not specified
  if [ -z "$output_dir" ]; then
    output_dir="${video_dir}/cropped"
  fi

  # Create output directory
  mkdir -p "$output_dir"

  # Check if video files exist
  local file_count=$(find "$video_dir" -maxdepth 1 -type f -name "*.${video_ext}" | wc -l)
  if [ "$file_count" -eq 0 ]; then
    echo "Error: No ${video_ext} files found in $video_dir" >&2
    return 1
  fi

  local success_count=0
  local error_count=0
  local processed_videos=0

  # Process each video file
  find "$video_dir" -maxdepth 1 -type f -name "*.${video_ext}" | while read -r video_file; do
    local base_name=$(basename "$video_file" .${video_ext})
    local output_file="$output_dir/${base_name}_cropped.mp4"

    echo "Processing $video_file..."
    ((processed_videos++))

    # Calculate crop parameters for this video
    local crop_params=$(_vdo_calculate_crop_params "$video_file" "$position" "$size")
    read -r crop_width crop_height crop_x crop_y <<< "$crop_params"

    echo "  Cropping from position: x=$crop_x, y=$crop_y"
    echo "  With size: width=$crop_width, height=$crop_height"
    echo "  Output: $output_file"

    # Apply the crop
    if ffmpeg -i "$video_file" -vf "crop=$crop_width:$crop_height:$crop_x:$crop_y" -c:v libx264 -crf "$quality" -c:a copy "$output_file"; then
      echo "  Cropping complete"
      ((success_count++))
    else
      echo "  Error: Cropping failed" >&2
      ((error_count++))
    fi
  done

  # Print summary
  echo "Batch cropping summary:"
  echo "  Processed: $processed_videos videos"
  echo "  Successfully cropped: $success_count videos"
  echo "  Failed: $error_count videos"
  echo "Output files saved to: $output_dir"

  # Return error if any errors occurred
  if [ "$error_count" -gt 0 ]; then
    return 1
  fi

  return 0
}' # Crop multiple video files in a directory

#------------------------------------------------------------------------------
# Video Help Function
#------------------------------------------------------------------------------

alias vdo-help='() {
  echo "Video Processing Aliases Help"
  echo "============================"
  echo "Information & Metadata:"
  echo "  vdo-info <file>                - Show detailed information about a video file"
  echo "  vdo-stream-info <file>         - Show stream information about a video file"
  echo "  vdo-duration <file>            - Show the duration of a video file"
  echo ""
  echo "Trimming & Splitting:"
  echo "  vdo-trim-video <file> <start> <duration> - Trim video between start and duration"
  echo "  vdo-split-video <file> <segment_duration> - Split video into segments of specified duration"
  echo ""
  echo "Frame Extraction:"
  echo "  vdo-extract-frame <file> <time>      - Extract a single frame at specified time"
  echo "  vdo-extract-frames <file> <interval> - Extract frames at regular intervals"
  echo "  vdo-batch-extract-frame <time> <dir> <ext> - Extract a frame at same time from multiple videos"
  echo ""
  echo "Cropping:"
  echo "  vdo-crop <file> [options]            - Crop a video by position and size"
  echo "  vdo-batch-crop <dir> [options]       - Crop multiple videos in a directory"
  echo ""
  echo "Speed Modification:"
  echo "  vdo-speed-up <file> <factor>   - Speed up video playback"
  echo "  vdo-slow-down <file> <factor>  - Slow down video playback"
  echo ""
  echo "Watermark & Overlay:"
  echo "  vdo-add-watermark <file> <image> <pos> - Add image watermark to video"
  echo "  vdo-add-text <file> <text> <pos> - Add text watermark to video"
  echo ""
  echo "Audio Processing:"
  echo "  vdo-remove-audio <file>              - Remove audio from video"
  echo "  vdo-replace-audio <video> <audio>    - Replace video audio with another audio file"
  echo "  vdo-adjust-volume <file> <factor>    - Adjust audio volume in video"
  echo "  vdo-extract-mp3 <file>               - Extract audio to MP3 format"
  echo "  vdo-extract-dir-mp3 <dir>            - Extract audio from videos in directory to MP3"
  echo "  vdo-merge-audio <video> [audio]      - Merge video and audio into a single file"
  echo "  vdo-batch-merge-audio <vdir> [adir] [vext] [aext] - Batch merge videos with audio files"
  echo ""
  echo "Compression & Conversion:"
  echo "  vdo-compress <file> <quality>        - Compress video with specified quality"
  echo "  vdo-compress-dir <dir> <ext> <quality> - Compress videos in directory"
  echo "  vdo-to-mp4 <file> [file2] [file3]...   - Convert video to MP4 format"
  echo "  vdo-batch-to-mp4 <dir> <ext>          - Convert videos in directory to MP4 format"
  echo "  vdo-optimize-for-mobile <file> [file2] [file3]... - Optimize video for mobile devices"
  echo "  vdo-convert-m3u8-to-mp4 <url>        - Convert M3U8 stream to MP4 video"
  echo ""
  echo "Resolution Conversion:"
  echo "  vdo-to-320p <file>                   - Convert video to 320p resolution"
  echo "  vdo-to-480p <file>                   - Convert video to 480p resolution"
  echo "  vdo-to-720p <file>                   - Convert video to 720p resolution"
  echo "  vdo-to-1080p <file>                  - Convert video to 1080p resolution"
  echo "  vdo-dir-to-720p <dir> <ext>          - Convert videos in directory to 720p resolution"
  echo "  vdo-dir-to-1080p <dir> <ext>         - Convert videos in directory to 1080p resolution"
  echo ""
  echo "Screenshot Series:"
  echo "  vdo-create-thumbnails <file> <interval> - Create thumbnails at regular intervals"
  echo "  vdo-create-preview-grid <file> <cols>   - Create a grid of screenshots"
  echo "  vdo-screenshot <file> [options]         - Capture screenshots from a video"
  echo "  vdo-batch-screenshot <dir> [options]    - Capture screenshots from videos in a directory"
  echo ""
  echo "For more detailed help on any command, run the command without arguments"
}' # Display help information about all video commands

alias video-help='() {
  vdo-help
}' # Alias to call the video help function
