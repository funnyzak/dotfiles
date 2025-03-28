# Description: Audio conversion and manipulation aliases

#------------------------------------------------------------------------------
# Audio Conversion
#------------------------------------------------------------------------------

alias convert_audio_to_mp3='() {
  if [ $# -eq 0 ]; then
    echo "Convert audio to MP3 format."
    echo "Usage:"
    echo "  convert_audio_to_mp3 <audio_file_path> [bitrate:128k]"
    return 1
  fi

  input_file="$1"
  bitrate="${2:-128k}"

  _video_validate_file "$input_file" || return 1
  _video_check_ffmpeg || return 1

  output_file="${input_file%.*}.mp3"

  echo "Converting $input_file to MP3 format with bitrate $bitrate..."

  if ffmpeg -i "$input_file" -c:a libmp3lame -b:a "$bitrate" "$output_file"; then
    echo "Conversion complete, exported to $output_file"
  else
    echo "Error: Audio conversion failed" >&2
    return 1
  fi
}'

alias convert_dir_audio_to_mp3='() {
  if [ $# -eq 0 ]; then
    echo "Convert audio files in directory to MP3 format."
    echo "Usage:"
    echo "  convert_dir_audio_to_mp3 <audio_directory> <source_extension:wav> [bitrate:128k]"
    return 1
  fi

  aud_folder="${1:-.}"
  aud_ext="${2:-wav}"
  bitrate="${3:-128k}"

  _video_validate_dir "$aud_folder" || return 1
  _video_check_ffmpeg || return 1

  # Check if source files exist
  file_count=$(find "$aud_folder" -maxdepth 1 -type f -name "*.${aud_ext}" | wc -l)
  if [ "$file_count" -eq 0 ]; then
    echo "Error: No ${aud_ext} files found in $aud_folder" >&2
    return 1
  fi

  mkdir -p "${aud_folder}/mp3"
  errors=0

  find "$aud_folder" -maxdepth 1 -type f -name "*.${aud_ext}" | while read -r file; do
    output_file="$aud_folder/mp3/$(basename "$file" .${aud_ext}).mp3"
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
}'
