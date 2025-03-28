# Description: Video processing aliases for conversion, compression, merging, and format transformation using ffmpeg.

#------------------------------------------------------------------------------
# Helper Functions
#------------------------------------------------------------------------------

# Helper function to validate file existence
_video_validate_file='() {
  if [[ ! -f "$1" ]]; then
    echo "Error: File \"$1\" does not exist" >&2
    return 1
  fi
  return 0
}'

# Helper function to validate directory existence
_video_validate_dir='() {
  if [[ ! -d "$1" ]]; then
    echo "Error: Directory \"$1\" does not exist" >&2
    return 1
  fi
  return 0
}'

# Helper function to check if ffmpeg is installed
_video_check_ffmpeg='() {
  if ! command -v ffmpeg &> /dev/null; then
    echo "Error: ffmpeg is not installed or not in PATH" >&2
    return 1
  fi
  return 0
}'

#------------------------------------------------------------------------------
# Video File Merging
#------------------------------------------------------------------------------

alias merge_videos='() {
  if [ $# -eq 0 ]; then
    echo "Merge video files in a directory."
    echo "Usage:"
    echo "  merge_videos <source_dir> <video_extension:mp4>"
    return 1
  fi

  vdo_folder="${1:-$(pwd)}"
  vdo_ext="${2:-mp4}"

  _video_validate_dir "$vdo_folder" || return 1
  _video_check_ffmpeg || return 1

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
}'

#------------------------------------------------------------------------------
# Video Format Conversion
#------------------------------------------------------------------------------

alias convert_to_mp4='() {
  if [ $# -eq 0 ]; then
    echo "Convert video to MP4 format."
    echo "Usage:"
    echo "  convert_to_mp4 <video_file_path>"
    return 1
  fi

  input_file="$1"
  _video_validate_file "$input_file" || return 1
  _video_check_ffmpeg || return 1

  output_file="${input_file%.*}.mp4"
  echo "Converting $input_file to MP4 format..."

  if ffmpeg -i "$input_file" -c:v libx264 -crf 18 -preset slow -c:a aac -b:a 256k -ac 2 "$output_file"; then
    echo "Conversion complete, exported to $output_file"
  else
    echo "Error: Video conversion failed" >&2
    return 1
  fi
}'

alias convert_dir_to_mp4='() {
  if [ $# -eq 0 ]; then
    echo "Convert videos in directory to MP4 format."
    echo "Usage:"
    echo "  convert_dir_to_mp4 <video_directory> <source_extension:mp4>"
    return 1
  fi

  vdo_folder="${1:-.}"
  vdo_ext="${2:-mp4}"

  _video_validate_dir "$vdo_folder" || return 1
  _video_check_ffmpeg || return 1

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
}'

#------------------------------------------------------------------------------
# Video to Audio Extraction
#------------------------------------------------------------------------------

alias extract_mp3='() {
  if [ $# -eq 0 ]; then
    echo "Extract audio from video to MP3 format."
    echo "Usage:"
    echo "  extract_mp3 <video_file_path>"
    return 1
  fi

  input_file="$1"
  _video_validate_file "$input_file" || return 1
  _video_check_ffmpeg || return 1

  output_file="${input_file%.*}.mp3"
  echo "Extracting audio from $input_file to MP3 format..."

  if ffmpeg -i "$input_file" -vn -acodec libmp3lame -ab 128k -ar 44100 -y "$output_file"; then
    echo "Extraction complete, exported to $output_file"
  else
    echo "Error: Audio extraction failed" >&2
    return 1
  fi
}'

alias extract_dir_mp3='() {
  if [ $# -eq 0 ]; then
    echo "Extract audio from videos in directory to MP3 format."
    echo "Usage:"
    echo "  extract_dir_mp3 <video_directory> <source_extension:mp4>"
    return 1
  fi

  vdo_folder="${1:-.}"
  vdo_ext="${2:-mp4}"

  _video_validate_dir "$vdo_folder" || return 1
  _video_check_ffmpeg || return 1

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
}'

#------------------------------------------------------------------------------
# Video Compression
#------------------------------------------------------------------------------

alias compress_video='() {
  if [ $# -eq 0 ]; then
    echo "Compress video."
    echo "Usage:"
    echo "  compress_video <video_file_path> [quality:30]"
    echo "Note: Lower quality value means higher quality (18-28 is good range)"
    return 1
  fi

  input_file="$1"
  quality="${2:-30}"

  _video_validate_file "$input_file" || return 1
  _video_check_ffmpeg || return 1

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
}'

alias compress_dir_videos='() {
  if [ $# -eq 0 ]; then
    echo "Compress videos in directory."
    echo "Usage:"
    echo "  compress_dir_videos <video_directory> <source_extension:mp4> [quality:30]"
    echo "Note: Lower quality value means higher quality (18-28 is good range)"
    return 1
  fi

  vdo_folder="${1:-.}"
  vdo_ext="${2:-mp4}"
  quality="${3:-30}"

  _video_validate_dir "$vdo_folder" || return 1
  _video_check_ffmpeg || return 1

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
}'

#------------------------------------------------------------------------------
# Video Resolution Conversion
#------------------------------------------------------------------------------

_video_convert_resolution='() {
  if [ $# -lt 2 ]; then
    echo "Error: Missing required parameters" >&2
    return 1
  fi

  input_file="$1"
  resolution="$2"

  _video_validate_file "$input_file" || return 1
  _video_check_ffmpeg || return 1

  output_file="${input_file%.*}_${resolution}p.mp4"
  echo "Converting $input_file to ${resolution}p resolution..."

  if ffmpeg -i "$input_file" -vf "scale=-2:${resolution}" -c:a copy "$output_file"; then
    echo "Conversion complete, exported to $output_file"
    return 0
  else
    echo "Error: Video resolution conversion failed" >&2
    return 1
  fi
}'

_video_convert_dir_resolution='() {
  if [ $# -lt 2 ]; then
    echo "Error: Missing required parameters" >&2
    return 1
  fi

  vdo_folder="$1"
  resolution="$2"
  vdo_ext="${3:-mp4}"

  _video_validate_dir "$vdo_folder" || return 1
  _video_check_ffmpeg || return 1

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
}'

# Resolution specific aliases
alias convert_to_320p='() {
  if [ $# -eq 0 ]; then
    echo "Convert video to 320p resolution."
    echo "Usage:"
    echo "  convert_to_320p <video_file_path>"
    return 1
  fi
  _video_convert_resolution "$1" "320"
}'

alias convert_to_480p='() {
  if [ $# -eq 0 ]; then
    echo "Convert video to 480p resolution."
    echo "Usage:"
    echo "  convert_to_480p <video_file_path>"
    return 1
  fi
  _video_convert_resolution "$1" "480"
}'

alias convert_to_720p='() {
  if [ $# -eq 0 ]; then
    echo "Convert video to 720p resolution."
    echo "Usage:"
    echo "  convert_to_720p <video_file_path>"
    return 1
  fi
  _video_convert_resolution "$1" "720"
}'

alias convert_to_1080p='() {
  if [ $# -eq 0 ]; then
    echo "Convert video to 1080p resolution."
    echo "Usage:"
    echo "  convert_to_1080p <video_file_path>"
    return 1
  fi
  _video_convert_resolution "$1" "1080"
}'

# Directory resolution conversion aliases
alias convert_dir_to_320p='() {
  if [ $# -eq 0 ]; then
    echo "Convert videos in directory to 320p resolution."
    echo "Usage:"
    echo "  convert_dir_to_320p <video_directory> <source_extension:mp4>"
    return 1
  fi
  _video_convert_dir_resolution "${1:-.}" "320" "${2:-mp4}"
}'

alias convert_dir_to_480p='() {
  if [ $# -eq 0 ]; then
    echo "Convert videos in directory to 480p resolution."
    echo "Usage:"
    echo "  convert_dir_to_480p <video_directory> <source_extension:mp4>"
    return 1
  fi
  _video_convert_dir_resolution "${1:-.}" "480" "${2:-mp4}"
}'

alias convert_dir_to_720p='() {
  if [ $# -eq 0 ]; then
    echo "Convert videos in directory to 720p resolution."
    echo "Usage:"
    echo "  convert_dir_to_720p <video_directory> <source_extension:mp4>"
    return 1
  fi
  _video_convert_dir_resolution "${1:-.}" "720" "${2:-mp4}"
}'

alias convert_dir_to_1080p='() {
  if [ $# -eq 0 ]; then
    echo "Convert videos in directory to 1080p resolution."
    echo "Usage:"
    echo "  convert_dir_to_1080p <video_directory> <source_extension:mp4>"
    return 1
  fi
  _video_convert_dir_resolution "${1:-.}" "1080" "${2:-mp4}"
}'

#------------------------------------------------------------------------------
# Mobile Device Optimization
#------------------------------------------------------------------------------

alias optimize_for_mobile='() {
  if [ $# -eq 0 ]; then
    echo "Optimize video for mobile devices."
    echo "Usage:"
    echo "  optimize_for_mobile <video_file_path>"
    return 1
  fi

  input_file="$1"
  _video_validate_file "$input_file" || return 1
  _video_check_ffmpeg || return 1

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
}'


#------------------------------------------------------------------------------
# M3U8 Stream Processing
#------------------------------------------------------------------------------

alias convert_m3u8_to_mp4='() {
  if [ $# -eq 0 ]; then
    echo "Convert M3U8 stream to MP4 video."
    echo "Usage:"
    echo "  convert_m3u8_to_mp4 <m3u8_url> [output_filename]"
    return 1
  fi

  _video_check_ffmpeg || return 1

  url="$1"
  output="${2:-output_$(date +%Y%m%d%H%M%S).mp4}"

  echo "Converting M3U8 stream $url to MP4 format..."

  if ffmpeg -i "$url" -c copy "${output}"; then
    echo "Conversion complete, exported to ${output}"
  else
    echo "Error: M3U8 conversion failed" >&2
    return 1
  fi
}'

#------------------------------------------------------------------------------
# YouTube Downloads
#------------------------------------------------------------------------------

_video_check_youtube_dl='() {
  if ! command -v youtube-dl &> /dev/null; then
    echo "Error: youtube-dl is not installed or not in PATH" >&2
    return 1
  fi
  return 0
}'

alias download_youtube_best='() {
  _video_check_youtube_dl || return 1
  youtube-dl -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/bestvideo+bestaudio" --merge-output-format mp4 "$@"
}'

alias download_youtube_complete='() {
  _video_check_youtube_dl || return 1
  youtube-dl -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/bestvideo+bestaudio" --merge-output-format mp4 --all-subs --embed-subs --embed-thumbnail -o "%(title)s.%(ext)s" "$@"
}'

alias download_youtube_720p='() {
  _video_check_youtube_dl || return 1
  youtube-dl -f "bestvideo[height<=720][ext=mp4]+bestaudio[ext=m4a]/bestvideo[height<=720]+bestaudio" --merge-output-format mp4 "$@"
}'

alias download_youtube_1080p='() {
  _video_check_youtube_dl || return 1
  youtube-dl -f "bestvideo[height<=1080][ext=mp4]+bestaudio[ext=m4a]/bestvideo[height<=1080]+bestaudio" --merge-output-format mp4 "$@"
}'

alias download_youtube_mp3='() {
  _video_check_youtube_dl || return 1
  youtube-dl -f bestaudio --extract-audio --audio-format mp3 "$@"
}'

alias download_youtube_mp3_128='() {
  _video_check_youtube_dl || return 1
  youtube-dl -f bestaudio --extract-audio --audio-format mp3 --audio-quality 128K "$@"
}'

alias download_youtube_mp3_320='() {
  _video_check_youtube_dl || return 1
  youtube-dl -f bestaudio --extract-audio --audio-format mp3 --audio-quality 320K "$@"
}'
