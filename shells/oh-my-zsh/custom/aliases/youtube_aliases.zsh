# Description: YouTube video download aliases using yt-dlp for downloading videos, playlists, subtitles, thumbnails, and extracting audio.

#------------------------------------------------------------------------------
# Helper Functions
#------------------------------------------------------------------------------

# Helper function to validate if a URL is provided
_yt_validate_url() {
  if [[ -z "$1" ]]; then
    echo "Error: No URL provided" >&2
    return 1
  fi

  # Basic URL validation
  if [[ ! "$1" =~ ^https?:// ]]; then
    echo "Error: Invalid URL format. URL must start with http:// or https://" >&2
    return 1
  fi

  return 0
}

# Helper function to validate if a directory exists, create if specified
_yt_validate_dir() {
  local dir="$1"
  local create="$2"

  if [[ ! -d "$dir" ]]; then
    if [[ "$create" == "create" ]]; then
      mkdir -p "$dir" || {
        echo "Error: Failed to create directory \"$dir\"" >&2
        return 1
      }
      echo "Created directory: $dir"
    else
      echo "Error: Directory \"$dir\" does not exist" >&2
      return 1
    fi
  fi

  return 0
}

# Helper function to check if yt-dlp is installed
_yt_check_ytdlp() {
  if ! command -v yt-dlp &> /dev/null; then
    echo "Error: yt-dlp is not installed or not in PATH" >&2
    echo "Install it with: pip install yt-dlp" >&2
    return 1
  fi

  return 0
}

# Helper function to check if ffmpeg is installed
_yt_check_ffmpeg() {
  if ! command -v ffmpeg &> /dev/null; then
    echo "Error: ffmpeg is not installed or not in PATH" >&2
    echo "Install it with brew install ffmpeg (macOS) or apt install ffmpeg (Linux)" >&2
    return 1
  fi

  return 0
}

# Helper function to convert format string to yt-dlp format argument
_youtube_format_arg() {
  # Usage: _youtube_format_arg <format>
  local input_format="$1"
  local format_arg=""
  case "$input_format" in
    best)
      format_arg="bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best"
      ;;
    144p)
      format_arg="bestvideo[height<=144][ext=mp4]+bestaudio[ext=m4a]/best[height<=144][ext=mp4]/best"
      ;;
    240p)
      format_arg="bestvideo[height<=240][ext=mp4]+bestaudio[ext=m4a]/best[height<=240][ext=mp4]/best"
      ;;
    360p)
      format_arg="bestvideo[height<=360][ext=mp4]+bestaudio[ext=m4a]/best[height<=360][ext=mp4]/best"
      ;;
    480p)
      format_arg="bestvideo[height<=480][ext=mp4]+bestaudio[ext=m4a]/best[height<=480][ext=mp4]/best"
      ;;
    720p)
      format_arg="bestvideo[height<=720][ext=mp4]+bestaudio[ext=m4a]/best[height<=720][ext=mp4]/best"
      ;;
    1080p)
      format_arg="bestvideo[height<=1080][ext=mp4]+bestaudio[ext=m4a]/best[height<=1080][ext=mp4]/best"
      ;;
    1440p)
      format_arg="bestvideo[height<=1440][ext=mp4]+bestaudio[ext=m4a]/best[height<=1440][ext=mp4]/best"
      ;;
    2160p)
      format_arg="bestvideo[height<=2160][ext=mp4]+bestaudio[ext=m4a]/best[height<=2160][ext=mp4]/best"
      ;;
    *)
      format_arg="$input_format"
      ;;
  esac
  echo "$format_arg"
}

#------------------------------------------------------------------------------
# Video Download Aliases
#------------------------------------------------------------------------------

alias yt-download='() {
  echo -e "Download a YouTube video.\nUsage:\n  yt-download <video_url> [options]\n\nOptions:\n  -o, --output_dir DIR   : Output directory (default: current directory)\n  -f, --format FORMAT    : Video format/quality (default: best)\n                          Common formats: best, 720p, 1080p, 2160p\n  -s, --subtitles        : Download subtitles if available\n  -t, --thumbnail        : Download thumbnail\n  -i, --info             : Display video info without downloading\n  -h, --help             : Show this help message\n\nExamples:\n  yt-download https://youtu.be/dQw4w9WgXcQ\n  yt-download https://youtu.be/dQw4w9WgXcQ -f 720p -s -t\n  yt-download https://youtu.be/dQw4w9WgXcQ --output_dir ~/Downloads --format 1080p"

  # Variables with default values
  local url=""
  local output_dir="."
  local format="best"
  local download_subs=false
  local download_thumbnail=false
  local show_info_only=false
  local show_help=false
  local ytdlp_args=""

  # Parse all arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -o|--output_dir)
        output_dir="$2"
        shift 2
        ;;
      -f|--format)
        format="$2"
        shift 2
        ;;
      -s|--subtitles)
        download_subs=true
        shift
        ;;
      -t|--thumbnail)
        download_thumbnail=true
        shift
        ;;
      -i|--info)
        show_info_only=true
        shift
        ;;
      -h|--help)
        show_help=true
        shift
        ;;
      *)
        # First non-option argument is the URL
        if [ -z "$url" ]; then
          url="$1"
        else
          echo "Error: Unexpected argument \"$1\"" >&2
          show_help=true
        fi
        shift
        ;;
    esac
  done

  # Show help if requested or no URL provided
  if $show_help || [ -z "$url" ]; then
    return 1
  fi

  # Validate URL and check for yt-dlp
  _yt_validate_url "$url" || return 1
  _yt_check_ytdlp || return 1

  # Validate output directory
  _yt_validate_dir "$output_dir" "create" || return 1

  # Prepare format specification
  local format_arg=""
  format_arg="$(_youtube_format_arg "$format")"

  # Build yt-dlp arguments
  ytdlp_args="$ytdlp_args -f \"$format_arg\" -o \"$output_dir/%(title)s.%(ext)s\""

  if $download_subs; then
    ytdlp_args="$ytdlp_args --write-auto-sub --sub-lang en --convert-subs srt"
  fi

  if $download_thumbnail; then
    ytdlp_args="$ytdlp_args --write-thumbnail"
  fi

  if $show_info_only; then
    echo "Video information for: $url"
    yt-dlp --dump-json "$url" | jq "{id, title, upload_date, uploader, duration, view_count, like_count}"
    return 0
  fi

  # Execute the download
  echo "Downloading video from $url with format: $format"
  eval "yt-dlp $ytdlp_args \"$url\""

  if [ $? -eq 0 ]; then
    echo "Download completed successfully to $output_dir"
  else
    echo "Error: Download failed" >&2
    return 1
  fi
}' # Download a YouTube video with options

alias yt-batch-download='() {
  echo -e "Batch download YouTube videos from a file containing URLs.\nUsage:\n  yt-batch-download <url_file_path> [options]\n\nOptions:\n  -o, --output_dir DIR   : Output directory (default: current directory)\n  -f, --format FORMAT    : Video format/quality (default: best)\n                          Common formats: best, 720p, 1080p, 2160p\n  -s, --subtitles        : Download subtitles if available\n  -t, --thumbnail        : Download thumbnail\n  -h, --help             : Show this help message\n\nExamples:\n  yt-batch-download urls.txt\n  yt-batch-download urls.txt -f 720p -s -t\n  yt-batch-download urls.txt --output_dir ~/Downloads --format 1080p"

  # Variables with default values
  local url_file=""
  local output_dir="."
  local format="best"
  local download_subs=false
  local download_thumbnail=false
  local show_help=false
  local ytdlp_args=""

  # Parse all arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -o|--output_dir)
        output_dir="$2"
        shift 2
        ;;
      -f|--format)
        format="$2"
        shift 2
        ;;
      -s|--subtitles)
        download_subs=true
        shift
        ;;
      -t|--thumbnail)
        download_thumbnail=true
        shift
        ;;
      -h|--help)
        show_help=true
        shift
        ;;
      *)
        # First non-option argument is the URL file
        if [ -z "$url_file" ]; then
          url_file="$1"
        else
          echo "Error: Unexpected argument \"$1\"" >&2
          show_help=true
        fi
        shift
        ;;
    esac
  done

  # Show help if requested or no URL file provided
  if $show_help || [ -z "$url_file" ]; then
    return 1
  fi

  # Check if the URL file exists
  if [ ! -f "$url_file" ]; then
    echo "Error: File \"$url_file\" does not exist" >&2
    return 1
  fi

  # Check for yt-dlp
  _yt_check_ytdlp || return 1

  # Validate output directory
  _yt_validate_dir "$output_dir" "create" || return 1

  # Prepare format specification
  local format_arg=""
  format_arg="$(_youtube_format_arg "$format")"

  # Build yt-dlp arguments
  ytdlp_args="$ytdlp_args -f \"$format_arg\" -o \"$output_dir/%(title)s.%(ext)s\""

  if $download_subs; then
    ytdlp_args="$ytdlp_args --write-auto-sub --sub-lang en --convert-subs srt"
  fi

  if $download_thumbnail; then
    ytdlp_args="$ytdlp_args --write-thumbnail"
  fi

  # Execute the download
  echo "Batch downloading videos from URLs in $url_file with format: $format"

  # Count total URLs
  local total_urls=$(grep -c "^https\?://" "$url_file")
  local success_count=0
  local error_count=0
  local current=0

  while IFS= read -r url || [ -n "$url" ]; do
    # Skip empty lines or comments
    if [[ -z "$url" || "$url" =~ ^# ]]; then
      continue
    fi

    # Skip malformed URLs
    if [[ ! "$url" =~ ^https?:// ]]; then
      echo "Skipping malformed URL: $url"
      continue
    fi

    ((current++))
    echo "Processing [$current/$total_urls]: $url"

    eval "yt-dlp $ytdlp_args \"$url\""

    if [ $? -eq 0 ]; then
      ((success_count++))
      echo "Success: $url"
    else
      ((error_count++))
      echo "Error: Failed to download $url" >&2
    fi

    echo "--------------------"
  done < "$url_file"

  echo "Batch download summary:"
  echo "  Total URLs: $total_urls"
  echo "  Successfully downloaded: $success_count"
  echo "  Failed: $error_count"

  # Return error if any downloads failed
  if [ "$error_count" -gt 0 ]; then
    return 1
  fi

  return 0
}' # Batch download YouTube videos from a file containing URLs

#------------------------------------------------------------------------------
# Playlist Download Aliases
#------------------------------------------------------------------------------

alias yt-playlist='() {
  echo -e "Download a YouTube playlist.\nUsage:\n  yt-playlist <playlist_url> [options]\n\nOptions:\n  -o, --output_dir DIR   : Output directory (default: current directory)\n  -f, --format FORMAT    : Video format/quality (default: best)\n                          Common formats: best, 720p, 1080p, 2160p\n  -s, --subtitles        : Download subtitles if available\n  -t, --thumbnail        : Download thumbnail for each video\n  -i, --items RANGE      : Download specific items (e.g., 1-3,7,10-12)\n  -r, --reverse          : Download playlist in reverse order\n  -l, --limit NUMBER     : Limit number of videos to download\n  -h, --help             : Show this help message\n\nExamples:\n  yt-playlist https://www.youtube.com/playlist?list=PLxxx\n  yt-playlist https://www.youtube.com/playlist?list=PLxxx -f 720p -s -t\n  yt-playlist https://www.youtube.com/playlist?list=PLxxx -i 1-5,10 -o ~/Videos"

  # Variables with default values
  local url=""
  local output_dir="."
  local format="best"
  local download_subs=false
  local download_thumbnail=false
  local playlist_items=""
  local reverse_order=false
  local download_limit=""
  local show_help=false
  local ytdlp_args=""

  # Parse all arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -o|--output_dir)
        output_dir="$2"
        shift 2
        ;;
      -f|--format)
        format="$2"
        shift 2
        ;;
      -s|--subtitles)
        download_subs=true
        shift
        ;;
      -t|--thumbnail)
        download_thumbnail=true
        shift
        ;;
      -i|--items)
        playlist_items="$2"
        shift 2
        ;;
      -r|--reverse)
        reverse_order=true
        shift
        ;;
      -l|--limit)
        download_limit="$2"
        shift 2
        ;;
      -h|--help)
        show_help=true
        shift
        ;;
      *)
        # First non-option argument is the URL
        if [ -z "$url" ]; then
          url="$1"
        else
          echo "Error: Unexpected argument \"$1\"" >&2
          show_help=true
        fi
        shift
        ;;
    esac
  done

  # Show help if requested or no URL provided
  if $show_help || [ -z "$url" ]; then
    return 1
  fi

  # Validate URL and check for yt-dlp
  _yt_validate_url "$url" || return 1
  _yt_check_ytdlp || return 1

  # Validate output directory
  _yt_validate_dir "$output_dir" "create" || return 1

  # Prepare format specification
  local format_arg=""
  format_arg="$(_youtube_format_arg "$format")"

  # Build yt-dlp arguments
  ytdlp_args="$ytdlp_args -f \"$format_arg\" -o \"$output_dir/%(playlist_index)s-%(title)s.%(ext)s\" --yes-playlist"

  if $download_subs; then
    ytdlp_args="$ytdlp_args --write-auto-sub --sub-lang en --convert-subs srt"
  fi

  if $download_thumbnail; then
    ytdlp_args="$ytdlp_args --write-thumbnail"
  fi

  if [ -n "$playlist_items" ]; then
    ytdlp_args="$ytdlp_args --playlist-items \"$playlist_items\""
  fi

  if $reverse_order; then
    ytdlp_args="$ytdlp_args --playlist-reverse"
  fi

  if [ -n "$download_limit" ]; then
    ytdlp_args="$ytdlp_args --max-downloads $download_limit"
  fi

  # Execute the download
  echo "Downloading playlist from $url with format: $format"
  eval "yt-dlp $ytdlp_args \"$url\""

  if [ $? -eq 0 ]; then
    echo "Playlist download completed successfully to $output_dir"
  else
    echo "Error: Playlist download failed" >&2
    return 1
  fi
}' # Download a YouTube playlist with options

#------------------------------------------------------------------------------
# Thumbnail Download Aliases
#------------------------------------------------------------------------------

alias yt-thumbnail='() {
  echo -e "Download thumbnails from YouTube videos.\nUsage:\n  yt-thumbnail <video_url> [options]\n\nOptions:\n  -o, --output_dir DIR   : Output directory (default: current directory)\n  -q, --quality QUALITY  : Thumbnail quality (default: max)\n                          Options: default, medium, high, max\n  -h, --help             : Show this help message\n\nExamples:\n  yt-thumbnail https://youtu.be/dQw4w9WgXcQ\n  yt-thumbnail https://youtu.be/dQw4w9WgXcQ -q high -o ~/Pictures/thumbnails"

  # Variables with default values
  local url=""
  local output_dir="."
  local quality="max"
  local show_help=false
  local ytdlp_args=""

  # Parse all arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -o|--output_dir)
        output_dir="$2"
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
        # First non-option argument is the URL
        if [ -z "$url" ]; then
          url="$1"
        else
          echo "Error: Unexpected argument \"$1\"" >&2
          show_help=true
        fi
        shift
        ;;
    esac
  done

  # Show help if requested or no URL provided
  if $show_help || [ -z "$url" ]; then
    return 1
  fi

  # Validate URL and check for yt-dlp
  _yt_validate_url "$url" || return 1
  _yt_check_ytdlp || return 1

  # Validate output directory
  _yt_validate_dir "$output_dir" "create" || return 1

  # Map quality to corresponding format
  local thumbnail_quality=""
  case "$quality" in
    default)
      thumbnail_quality="0"
      ;;
    medium)
      thumbnail_quality="1"
      ;;
    high)
      thumbnail_quality="2"
      ;;
    max)
      thumbnail_quality="3"
      ;;
    *)
      echo "Error: Invalid quality option. Use default, medium, high, or max" >&2
      return 1
      ;;
  esac

  # Build yt-dlp arguments for downloading only the thumbnail
  ytdlp_args="--write-thumbnail --skip-download -o \"$output_dir/%(title)s.%(ext)s\""

  # Execute the download
  echo "Downloading thumbnail from $url with quality: $quality"
  eval "yt-dlp $ytdlp_args \"$url\""

  if [ $? -eq 0 ]; then
    echo "Thumbnail download completed successfully to $output_dir"

    # Convert webp thumbnails to jpg if available
    find "$output_dir" -name "*.webp" -type f -print0 | while IFS= read -r -d "" webp_file; do
      echo "Converting $webp_file to jpg format"
      jpg_file="${webp_file%.webp}.jpg"

      if command -v convert &> /dev/null; then
        convert "$webp_file" "$jpg_file" && rm "$webp_file"
      elif command -v ffmpeg &> /dev/null; then
        ffmpeg -i "$webp_file" "$jpg_file" -y && rm "$webp_file"
      else
        echo "Warning: Neither ImageMagick nor ffmpeg is available for WebP conversion" >&2
      fi
    done
  else
    echo "Error: Thumbnail download failed" >&2
    return 1
  fi
}' # Download thumbnails from YouTube videos

alias yt-batch-thumbnail='() {
  echo -e "Batch download thumbnails from multiple YouTube videos.\nUsage:\n  yt-batch-thumbnail <url_file_path> [options]\n\nOptions:\n  -o, --output_dir DIR   : Output directory (default: current directory)\n  -q, --quality QUALITY  : Thumbnail quality (default: max)\n                          Options: default, medium, high, max\n  -h, --help             : Show this help message\n\nExamples:\n  yt-batch-thumbnail urls.txt\n  yt-batch-thumbnail urls.txt -q high -o ~/Pictures/thumbnails"

  # Variables with default values
  local url_file=""
  local output_dir="."
  local quality="max"
  local show_help=false
  local ytdlp_args=""

  # Parse all arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -o|--output_dir)
        output_dir="$2"
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
        # First non-option argument is the URL file
        if [ -z "$url_file" ]; then
          url_file="$1"
        else
          echo "Error: Unexpected argument \"$1\"" >&2
          show_help=true
        fi
        shift
        ;;
    esac
  done

  # Show help if requested or no URL file provided
  if $show_help || [ -z "$url_file" ]; then
    return 1
  fi

  # Check if the URL file exists
  if [ ! -f "$url_file" ]; then
    echo "Error: File \"$url_file\" does not exist" >&2
    return 1
  fi

  # Check for yt-dlp
  _yt_check_ytdlp || return 1

  # Validate output directory
  _yt_validate_dir "$output_dir" "create" || return 1

  # Map quality to corresponding format
  local thumbnail_quality=""
  case "$quality" in
    default)
      thumbnail_quality="0"
      ;;
    medium)
      thumbnail_quality="1"
      ;;
    high)
      thumbnail_quality="2"
      ;;
    max)
      thumbnail_quality="3"
      ;;
    *)
      echo "Error: Invalid quality option. Use default, medium, high, or max" >&2
      return 1
      ;;
  esac

  # Build yt-dlp arguments for downloading only the thumbnail
  ytdlp_args="--write-thumbnail --skip-download -o \"$output_dir/%(title)s.%(ext)s\""

  # Count total URLs
  local total_urls=$(grep -c "^https\?://" "$url_file")
  local success_count=0
  local error_count=0
  local current=0

  while IFS= read -r url || [ -n "$url" ]; do
    # Skip empty lines or comments
    if [[ -z "$url" || "$url" =~ ^# ]]; then
      continue
    fi

    # Skip malformed URLs
    if [[ ! "$url" =~ ^https?:// ]]; then
      echo "Skipping malformed URL: $url"
      continue
    fi

    ((current++))
    echo "Processing [$current/$total_urls]: $url"

    eval "yt-dlp $ytdlp_args \"$url\""

    if [ $? -eq 0 ]; then
      ((success_count++))
      echo "Success: $url"
    else
      ((error_count++))
      echo "Error: Failed to download thumbnail from $url" >&2
    fi

    echo "--------------------"
  done < "$url_file"

  # Convert webp thumbnails to jpg if available
  find "$output_dir" -name "*.webp" -type f -print0 | while IFS= read -r -d "" webp_file; do
    echo "Converting $webp_file to jpg format"
    jpg_file="${webp_file%.webp}.jpg"

    if command -v convert &> /dev/null; then
      convert "$webp_file" "$jpg_file" && rm "$webp_file"
    elif command -v ffmpeg &> /dev/null; then
      ffmpeg -i "$webp_file" "$jpg_file" -y && rm "$webp_file"
    else
      echo "Warning: Neither ImageMagick nor ffmpeg is available for WebP conversion" >&2
    fi
  done

  echo "Batch thumbnail download summary:"
  echo "  Total URLs: $total_urls"
  echo "  Successfully downloaded: $success_count"
  echo "  Failed: $error_count"

  # Return error if any downloads failed
  if [ "$error_count" -gt 0 ]; then
    return 1
  fi

  return 0
}' # Batch download thumbnails from multiple YouTube videos

#------------------------------------------------------------------------------
# Audio Extraction Aliases
#------------------------------------------------------------------------------

alias yt-audio='() {
  echo -e "Extract audio from YouTube videos.\nUsage:\n  yt-audio <video_url> [options]\n\nOptions:\n  -o, --output_dir DIR   : Output directory (default: current directory)\n  -f, --format FORMAT    : Audio format (default: mp3)\n                          Options: mp3, m4a, wav, flac, opus, ogg\n  -q, --quality VALUE    : Audio quality (default: 192)\n                          Values: 64, 128, 192, 256, 320 (kbps)\n  -t, --thumbnail        : Embed thumbnail in audio file\n  -h, --help             : Show this help message\n\nExamples:\n  yt-audio https://youtu.be/dQw4w9WgXcQ\n  yt-audio https://youtu.be/dQw4w9WgXcQ -f wav -q 320 -t\n  yt-audio https://youtu.be/dQw4w9WgXcQ --output_dir ~/Music --format mp3"

  # Variables with default values
  local url=""
  local output_dir="."
  local format="mp3"
  local quality="192"
  local embed_thumbnail=false
  local show_help=false
  local ytdlp_args=""

  # Parse all arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -o|--output_dir)
        output_dir="$2"
        shift 2
        ;;
      -f|--format)
        format="$2"
        shift 2
        ;;
      -q|--quality)
        quality="$2"
        shift 2
        ;;
      -t|--thumbnail)
        embed_thumbnail=true
        shift
        ;;
      -h|--help)
        show_help=true
        shift
        ;;
      *)
        # First non-option argument is the URL
        if [ -z "$url" ]; then
          url="$1"
        else
          echo "Error: Unexpected argument \"$1\"" >&2
          show_help=true
        fi
        shift
        ;;
    esac
  done

  # Show help if requested or no URL provided
  if $show_help || [ -z "$url" ]; then
    return 1
  fi

  # Validate URL and check for yt-dlp and ffmpeg
  _yt_validate_url "$url" || return 1
  _yt_check_ytdlp || return 1
  _yt_check_ffmpeg || return 1

  # Validate output directory
  _yt_validate_dir "$output_dir" "create" || return 1

  # Validate format
  case "$format" in
    mp3|m4a|wav|flac|opus|ogg)
      ;;
    *)
      echo "Error: Unsupported audio format. Use mp3, m4a, wav, flac, opus, or ogg" >&2
      return 1
      ;;
  esac

  # Validate quality
  if ! [[ "$quality" =~ ^[0-9]+$ ]] || [ "$quality" -lt 0 ]; then
    echo "Error: Quality must be a positive number" >&2
    return 1
  fi

  # Build yt-dlp arguments for audio extraction
  ytdlp_args="-x --audio-format $format --audio-quality $quality -o \"$output_dir/%(title)s.%(ext)s\""

  if $embed_thumbnail; then
    ytdlp_args="$ytdlp_args --embed-thumbnail"
  fi

  # Execute the audio extraction
  echo "Extracting audio from $url in $format format with ${quality}kbps quality"
  eval "yt-dlp $ytdlp_args \"$url\""

  if [ $? -eq 0 ]; then
    echo "Audio extraction completed successfully to $output_dir"
  else
    echo "Error: Audio extraction failed" >&2
    return 1
  fi
}' # Extract audio from YouTube videos

alias yt-batch-audio='() {
  echo -e "Batch extract audio from multiple YouTube videos.\nUsage:\n  yt-batch-audio <url_file_path> [options]\n\nOptions:\n  -o, --output_dir DIR   : Output directory (default: current directory)\n  -f, --format FORMAT    : Audio format (default: mp3)\n                          Options: mp3, m4a, wav, flac, opus, ogg\n  -q, --quality VALUE    : Audio quality (default: 192)\n                          Values: 64, 128, 192, 256, 320 (kbps)\n  -t, --thumbnail        : Embed thumbnail in audio files\n  -h, --help             : Show this help message\n\nExamples:\n  yt-batch-audio urls.txt\n  yt-batch-audio urls.txt -f wav -q 320 -t\n  yt-batch-audio urls.txt --output_dir ~/Music --format mp3"

  # Variables with default values
  local url_file=""
  local output_dir="."
  local format="mp3"
  local quality="192"
  local embed_thumbnail=false
  local show_help=false
  local ytdlp_args=""

  # Parse all arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -o|--output_dir)
        output_dir="$2"
        shift 2
        ;;
      -f|--format)
        format="$2"
        shift 2
        ;;
      -q|--quality)
        quality="$2"
        shift 2
        ;;
      -t|--thumbnail)
        embed_thumbnail=true
        shift
        ;;
      -h|--help)
        show_help=true
        shift
        ;;
      *)
        # First non-option argument is the URL file
        if [ -z "$url_file" ]; then
          url_file="$1"
        else
          echo "Error: Unexpected argument \"$1\"" >&2
          show_help=true
        fi
        shift
        ;;
    esac
  done

  # Show help if requested or no URL file provided
  if $show_help || [ -z "$url_file" ]; then
    return 1
  fi

  # Check if the URL file exists
  if [ ! -f "$url_file" ]; then
    echo "Error: File \"$url_file\" does not exist" >&2
    return 1
  fi

  # Check for yt-dlp and ffmpeg
  _yt_check_ytdlp || return 1
  _yt_check_ffmpeg || return 1

  # Validate output directory
  _yt_validate_dir "$output_dir" "create" || return 1

  # Validate format
  case "$format" in
    mp3|m4a|wav|flac|opus|ogg)
      ;;
    *)
      echo "Error: Unsupported audio format. Use mp3, m4a, wav, flac, opus, or ogg" >&2
      return 1
      ;;
  esac

  # Validate quality
  if ! [[ "$quality" =~ ^[0-9]+$ ]] || [ "$quality" -lt 0 ]; then
    echo "Error: Quality must be a positive number" >&2
    return 1
  fi

  # Build yt-dlp arguments for audio extraction
  ytdlp_args="-x --audio-format $format --audio-quality $quality -o \"$output_dir/%(title)s.%(ext)s\""

  if $embed_thumbnail; then
    ytdlp_args="$ytdlp_args --embed-thumbnail"
  fi

  # Count total URLs
  local total_urls=$(grep -c "^https\?://" "$url_file")
  local success_count=0
  local error_count=0
  local current=0

  while IFS= read -r url || [ -n "$url" ]; do
    # Skip empty lines or comments
    if [[ -z "$url" || "$url" =~ ^# ]]; then
      continue
    fi

    # Skip malformed URLs
    if [[ ! "$url" =~ ^https?:// ]]; then
      echo "Skipping malformed URL: $url"
      continue
    fi

    ((current++))
    echo "Processing [$current/$total_urls]: $url"

    eval "yt-dlp $ytdlp_args \"$url\""

    if [ $? -eq 0 ]; then
      ((success_count++))
      echo "Success: $url"
    else
      ((error_count++))
      echo "Error: Failed to extract audio from $url" >&2
    fi

    echo "--------------------"
  done < "$url_file"

  echo "Batch audio extraction summary:"
  echo "  Total URLs: $total_urls"
  echo "  Successfully extracted: $success_count"
  echo "  Failed: $error_count"

  # Return error if any extractions failed
  if [ "$error_count" -gt 0 ]; then
    return 1
  fi

  return 0
}' # Batch extract audio from multiple YouTube videos

alias yt-playlist-audio='() {
  echo -e "Extract audio from a YouTube playlist.\nUsage:\n  yt-playlist-audio <playlist_url> [options]\n\nOptions:\n  -o, --output_dir DIR   : Output directory (default: current directory)\n  -f, --format FORMAT    : Audio format (default: mp3)\n                          Options: mp3, m4a, wav, flac, opus, ogg\n  -q, --quality VALUE    : Audio quality (default: 192)\n                          Values: 64, 128, 192, 256, 320 (kbps)\n  -t, --thumbnail        : Embed thumbnail in audio files\n  -i, --items RANGE      : Download specific items (e.g., 1-3,7,10-12)\n  -r, --reverse          : Download playlist in reverse order\n  -l, --limit NUMBER     : Limit number of videos to download\n  -h, --help             : Show this help message\n\nExamples:\n  yt-playlist-audio https://www.youtube.com/playlist?list=PLxxx\n  yt-playlist-audio https://www.youtube.com/playlist?list=PLxxx -f wav -q 320 -t\n  yt-playlist-audio https://www.youtube.com/playlist?list=PLxxx -i 1-5,10 -o ~/Music"

  # Variables with default values
  local url=""
  local output_dir="."
  local format="mp3"
  local quality="192"
  local embed_thumbnail=false
  local playlist_items=""
  local reverse_order=false
  local download_limit=""
  local show_help=false
  local ytdlp_args=""

  # Parse all arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -o|--output_dir)
        output_dir="$2"
        shift 2
        ;;
      -f|--format)
        format="$2"
        shift 2
        ;;
      -q|--quality)
        quality="$2"
        shift 2
        ;;
      -t|--thumbnail)
        embed_thumbnail=true
        shift
        ;;
      -i|--items)
        playlist_items="$2"
        shift 2
        ;;
      -r|--reverse)
        reverse_order=true
        shift
        ;;
      -l|--limit)
        download_limit="$2"
        shift 2
        ;;
      -h|--help)
        show_help=true
        shift
        ;;
      *)
        # First non-option argument is the URL
        if [ -z "$url" ]; then
          url="$1"
        else
          echo "Error: Unexpected argument \"$1\"" >&2
          show_help=true
        fi
        shift
        ;;
    esac
  done

  # Show help if requested or no URL provided
  if $show_help || [ -z "$url" ]; then
    return 1
  fi

  # Validate URL and check for yt-dlp and ffmpeg
  _yt_validate_url "$url" || return 1
  _yt_check_ytdlp || return 1
  _yt_check_ffmpeg || return 1

  # Validate output directory
  _yt_validate_dir "$output_dir" "create" || return 1

  # Validate format
  case "$format" in
    mp3|m4a|wav|flac|opus|ogg)
      ;;
    *)
      echo "Error: Unsupported audio format. Use mp3, m4a, wav, flac, opus, or ogg" >&2
      return 1
      ;;
  esac

  # Validate quality
  if ! [[ "$quality" =~ ^[0-9]+$ ]] || [ "$quality" -lt 0 ]; then
    echo "Error: Quality must be a positive number" >&2
    return 1
  fi

  # Build yt-dlp arguments for audio extraction
  ytdlp_args="-x --audio-format $format --audio-quality $quality -o \"$output_dir/%(playlist_index)s-%(title)s.%(ext)s\" --yes-playlist"

  if $embed_thumbnail; then
    ytdlp_args="$ytdlp_args --embed-thumbnail"
  fi

  if [ -n "$playlist_items" ]; then
    ytdlp_args="$ytdlp_args --playlist-items \"$playlist_items\""
  fi

  if $reverse_order; then
    ytdlp_args="$ytdlp_args --playlist-reverse"
  fi

  if [ -n "$download_limit" ]; then
    ytdlp_args="$ytdlp_args --max-downloads $download_limit"
  fi

  # Execute the audio extraction
  echo "Extracting audio from playlist $url in $format format with ${quality}kbps quality"
  eval "yt-dlp $ytdlp_args \"$url\""

  if [ $? -eq 0 ]; then
    echo "Playlist audio extraction completed successfully to $output_dir"
  else
    echo "Error: Playlist audio extraction failed" >&2
    return 1
  fi
}' # Extract audio from a YouTube playlist

#------------------------------------------------------------------------------
# Video Information Aliases
#------------------------------------------------------------------------------

alias yt-info='() {
  echo -e "Get information about YouTube videos.\nUsage:\n  yt-info <video_url> [options]\n\nOptions:\n  -f, --format           : Show available formats\n  -s, --simple           : Show simplified information\n  -j, --json             : Output in JSON format\n  -h, --help             : Show this help message\n\nExamples:\n  yt-info https://youtu.be/dQw4w9WgXcQ\n  yt-info https://youtu.be/dQw4w9WgXcQ -f\n  yt-info https://youtu.be/dQw4w9WgXcQ --simple"

  # Variables with default values
  local url=""
  local show_formats=false
  local simple_output=false
  local json_output=false
  local show_help=false

  # Parse all arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -f|--format)
        show_formats=true
        shift
        ;;
      -s|--simple)
        simple_output=true
        shift
        ;;
      -j|--json)
        json_output=true
        shift
        ;;
      -h|--help)
        show_help=true
        shift
        ;;
      *)
        # First non-option argument is the URL
        if [ -z "$url" ]; then
          url="$1"
        else
          echo "Error: Unexpected argument \"$1\"" >&2
          show_help=true
        fi
        shift
        ;;
    esac
  done

  # Show help if requested or no URL provided
  if $show_help || [ -z "$url" ]; then
    return 1
  fi

  # Validate URL and check for yt-dlp
  _yt_validate_url "$url" || return 1
  _yt_check_ytdlp || return 1

  # Build yt-dlp arguments based on options
  if $show_formats; then
    echo "Available formats for $url:"
    yt-dlp -F "$url"
    return 0
  elif $json_output; then
    echo "Video information for $url in JSON format:"
    yt-dlp --dump-json "$url"
    return 0
  elif $simple_output; then
    echo "Simple information for $url:"
    yt-dlp --print title --print duration --print view_count --print upload_date --print uploader "$url" | awk "{if(NR==1) print \"Title: \" \$0; if(NR==2) print \"Duration: \" \$0 \" seconds\"; if(NR==3) print \"Views: \" \$0; if(NR==4) print \"Upload date: \" \$0; if(NR==5) print \"Uploader: \" \$0}"
    return 0
  else
    echo "Video information for $url:"
    yt-dlp --print title --print duration --print view_count --print like_count --print upload_date --print uploader --print description "$url" | awk "{if(NR==1) print \"Title: \" \$0; if(NR==2) print \"Duration: \" \$0 \" seconds\"; if(NR==3) print \"Views: \" \$0; if(NR==4) print \"Likes: \" \$0; if(NR==5) print \"Upload date: \" \$0; if(NR==6) print \"Uploader: \" \$0; if(NR>=7) print \"Description: \" \$0}"
    return 0
  fi
}' # Get information about YouTube videos

alias yt-playlist-info='() {
  echo -e "Get information about a YouTube playlist.\nUsage:\n  yt-playlist-info <playlist_url> [options]\n\nOptions:\n  -c, --count            : Show only video count\n  -i, --ids              : Show video IDs\n  -t, --titles           : Show only video titles\n  -d, --durations        : Show videos with durations\n  -s, --simple           : Show simplified information\n  -j, --json             : Output in JSON format\n  -h, --help             : Show this help message\n\nExamples:\n  yt-playlist-info https://www.youtube.com/playlist?list=PLxxx\n  yt-playlist-info https://www.youtube.com/playlist?list=PLxxx -c\n  yt-playlist-info https://www.youtube.com/playlist?list=PLxxx --titles"

  # Variables with default values
  local url=""
  local count_only=false
  local ids_only=false
  local titles_only=false
  local show_durations=false
  local simple_output=false
  local json_output=false
  local show_help=false

  # Parse all arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -c|--count)
        count_only=true
        shift
        ;;
      -i|--ids)
        ids_only=true
        shift
        ;;
      -t|--titles)
        titles_only=true
        shift
        ;;
      -d|--durations)
        show_durations=true
        shift
        ;;
      -s|--simple)
        simple_output=true
        shift
        ;;
      -j|--json)
        json_output=true
        shift
        ;;
      -h|--help)
        show_help=true
        shift
        ;;
      *)
        # First non-option argument is the URL
        if [ -z "$url" ]; then
          url="$1"
        else
          echo "Error: Unexpected argument \"$1\"" >&2
          show_help=true
        fi
        shift
        ;;
    esac
  done

  # Show help if requested or no URL provided
  if $show_help || [ -z "$url" ]; then
    return 1
  fi

  # Validate URL and check for yt-dlp
  _yt_validate_url "$url" || return 1
  _yt_check_ytdlp || return 1

  # Build yt-dlp arguments based on options
  if $count_only; then
    echo "Getting video count in playlist..."
    video_count=$(yt-dlp --flat-playlist --print id "$url" | wc -l)
    echo "Playlist contains $video_count videos"
    return 0
  elif $ids_only; then
    echo "Video IDs in playlist:"
    yt-dlp --flat-playlist --print id "$url"
    return 0
  elif $titles_only; then
    echo "Video titles in playlist:"
    yt-dlp --flat-playlist --print title "$url"
    return 0
  elif $show_durations; then
    echo "Videos in playlist with durations:"
    yt-dlp --flat-playlist --print id --print title --print duration_string "$url" | awk "{if(NR%3==1) id=\$0; if(NR%3==2) title=\$0; if(NR%3==0) print title \" [\" \$0 \"] (https://youtu.be/\" id \")\"}"
    return 0
  elif $json_output; then
    echo "Playlist information in JSON format:"
    yt-dlp --dump-single-json "$url"
    return 0
  elif $simple_output; then
    echo "Simple playlist information:"
    yt-dlp --flat-playlist --print playlist_title --print playlist_count "$url" | awk "{if(NR==1) print \"Title: \" \$0; if(NR==2) print \"Videos: \" \$0}"
    return 0
  else
    echo "Playlist information:"
    playlist_info=$(yt-dlp --flat-playlist --print playlist_title --print playlist_uploader --print playlist_count "$url")
    playlist_title=$(echo "$playlist_info" | head -n 1)
    playlist_uploader=$(echo "$playlist_info" | head -n 2 | tail -n 1)
    playlist_count=$(echo "$playlist_info" | head -n 3 | tail -n 1)

    echo "Title: $playlist_title"
    echo "Uploader: $playlist_uploader"
    echo "Videos: $playlist_count"
    echo "URL: $url"

    echo "First 5 videos in playlist:"
    yt-dlp --flat-playlist --print title --max-downloads 5 "$url" | awk "{print \"- \" \$0}"

    return 0
  fi
}' # Get information about a YouTube playlist

#------------------------------------------------------------------------------
# Subtitle Download Aliases
#------------------------------------------------------------------------------

alias yt-subtitle='() {
  echo -e "Download subtitles from YouTube videos.\nUsage:\n  yt-subtitle <video_url> [options]\n\nOptions:\n  -o, --output_dir DIR   : Output directory (default: current directory)\n  -l, --lang LANG        : Subtitle language (default: en)\n                          Examples: en, fr, es, de, ja, zh\n  -a, --auto             : Download auto-generated subtitles\n  -f, --format FORMAT    : Subtitle format (default: srt)\n                          Options: srt, vtt, ass, lrc\n  -h, --help             : Show this help message\n\nExamples:\n  yt-subtitle https://youtu.be/dQw4w9WgXcQ\n  yt-subtitle https://youtu.be/dQw4w9WgXcQ -l fr -f vtt\n  yt-subtitle https://youtu.be/dQw4w9WgXcQ --auto --lang en"

  # Variables with default values
  local url=""
  local output_dir="."
  local language="en"
  local auto_subs=false
  local format="srt"
  local show_help=false
  local ytdlp_args=""

  # Parse all arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -o|--output_dir)
        output_dir="$2"
        shift 2
        ;;
      -l|--lang)
        language="$2"
        shift 2
        ;;
      -a|--auto)
        auto_subs=true
        shift
        ;;
      -f|--format)
        format="$2"
        shift 2
        ;;
      -h|--help)
        show_help=true
        shift
        ;;
      *)
        # First non-option argument is the URL
        if [ -z "$url" ]; then
          url="$1"
        else
          echo "Error: Unexpected argument \"$1\"" >&2
          show_help=true
        fi
        shift
        ;;
    esac
  done

  # Show help if requested or no URL provided
  if $show_help || [ -z "$url" ]; then
    return 1
  fi

  # Validate URL and check for yt-dlp
  _yt_validate_url "$url" || return 1
  _yt_check_ytdlp || return 1

  # Validate output directory
  _yt_validate_dir "$output_dir" "create" || return 1

  # Validate subtitle format
  case "$format" in
    srt|vtt|ass|lrc)
      ;;
    *)
      echo "Error: Unsupported subtitle format. Use srt, vtt, ass, or lrc" >&2
      return 1
      ;;
  esac

  # Build yt-dlp arguments for subtitle download
  if $auto_subs; then
    ytdlp_args="--skip-download --write-auto-sub --sub-lang $language --convert-subs $format -o \"$output_dir/%(title)s.%(ext)s\""
  else
    ytdlp_args="--skip-download --write-sub --sub-lang $language --convert-subs $format -o \"$output_dir/%(title)s.%(ext)s\""
  fi

  # Execute the subtitle download
  echo "Downloading ${auto_subs:+auto-generated }subtitles in $language language from $url"
  eval "yt-dlp $ytdlp_args \"$url\""

  local status=$?
  if [ $status -eq 0 ]; then
    echo "Subtitle download completed successfully to $output_dir"
    return 0
  elif $auto_subs; then
    echo "No auto-generated subtitles found, trying manual subtitles..."
    ytdlp_args="--skip-download --write-sub --sub-lang $language --convert-subs $format -o \"$output_dir/%(title)s.%(ext)s\""
    eval "yt-dlp $ytdlp_args \"$url\""

    if [ $? -eq 0 ]; then
      echo "Subtitle download completed successfully to $output_dir"
      return 0
    else
      echo "Error: No subtitles found for this video" >&2
      return 1
    fi
  else
    echo "No manual subtitles found, trying auto-generated subtitles..."
    ytdlp_args="--skip-download --write-auto-sub --sub-lang $language --convert-subs $format -o \"$output_dir/%(title)s.%(ext)s\""
    eval "yt-dlp $ytdlp_args \"$url\""

    if [ $? -eq 0 ]; then
      echo "Auto-generated subtitle download completed successfully to $output_dir"
      return 0
    else
      echo "Error: No subtitles found for this video" >&2
      return 1
    fi
  fi
}' # Download subtitles from YouTube videos

alias yt-batch-subtitle='() {
  echo -e "Batch download subtitles from multiple YouTube videos.\nUsage:\n  yt-batch-subtitle <url_file_path> [options]\n\nOptions:\n  -o, --output_dir DIR   : Output directory (default: current directory)\n  -l, --lang LANG        : Subtitle language (default: en)\n                          Examples: en, fr, es, de, ja, zh\n  -a, --auto             : Download auto-generated subtitles\n  -f, --format FORMAT    : Subtitle format (default: srt)\n                          Options: srt, vtt, ass, lrc\n  -h, --help             : Show this help message\n\nExamples:\n  yt-batch-subtitle urls.txt\n  yt-batch-subtitle urls.txt -l fr -f vtt\n  yt-batch-subtitle urls.txt --auto --lang en --output_dir ~/Subtitles"

  # Variables with default values
  local url_file=""
  local output_dir="."
  local language="en"
  local auto_subs=false
  local format="srt"
  local show_help=false
  local ytdlp_args=""

  # Parse all arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -o|--output_dir)
        output_dir="$2"
        shift 2
        ;;
      -l|--lang)
        language="$2"
        shift 2
        ;;
      -a|--auto)
        auto_subs=true
        shift
        ;;
      -f|--format)
        format="$2"
        shift 2
        ;;
      -h|--help)
        show_help=true
        shift
        ;;
      *)
        # First non-option argument is the URL file
        if [ -z "$url_file" ]; then
          url_file="$1"
        else
          echo "Error: Unexpected argument \"$1\"" >&2
          show_help=true
        fi
        shift
        ;;
    esac
  done

  # Show help if requested or no URL file provided
  if $show_help || [ -z "$url_file" ]; then
    return 1
  fi

  # Check if the URL file exists
  if [ ! -f "$url_file" ]; then
    echo "Error: File \"$url_file\" does not exist" >&2
    return 1
  fi

  # Check for yt-dlp
  _yt_check_ytdlp || return 1

  # Validate output directory
  _yt_validate_dir "$output_dir" "create" || return 1

  # Validate subtitle format
  case "$format" in
    srt|vtt|ass|lrc)
      ;;
    *)
      echo "Error: Unsupported subtitle format. Use srt, vtt, ass, or lrc" >&2
      return 1
      ;;
  esac

  # Build yt-dlp arguments for subtitle download
  if $auto_subs; then
    ytdlp_args="--skip-download --write-auto-sub --sub-lang $language --convert-subs $format -o \"$output_dir/%(title)s.%(ext)s\""
  else
    ytdlp_args="--skip-download --write-sub --sub-lang $language --convert-subs $format -o \"$output_dir/%(title)s.%(ext)s\""
  fi

  # Count total URLs
  local total_urls=$(grep -c "^https\?://" "$url_file")
  local success_count=0
  local error_count=0
  local fallback_count=0
  local current=0

  while IFS= read -r url || [ -n "$url" ]; do
    # Skip empty lines or comments
    if [[ -z "$url" || "$url" =~ ^# ]]; then
      continue
    fi

    # Skip malformed URLs
    if [[ ! "$url" =~ ^https?:// ]]; then
      echo "Skipping malformed URL: $url"
      continue
    fi

    ((current++))
    echo "Processing [$current/$total_urls]: $url"

    eval "yt-dlp $ytdlp_args \"$url\""
    local status=$?

    if [ $status -eq 0 ]; then
      ((success_count++))
      echo "Success: $url"
    else
      # Try the other subtitle type if the first one fails
      if $auto_subs; then
        echo "No auto-generated subtitles found, trying manual subtitles..."
        eval "yt-dlp --skip-download --write-sub --sub-lang $language --convert-subs $format -o \"$output_dir/%(title)s.%(ext)s\" \"$url\""
        if [ $? -eq 0 ]; then
          ((fallback_count++))
          echo "Success with fallback: $url"
        else
          ((error_count++))
          echo "Error: No subtitles found for $url" >&2
        fi
      else
        echo "No manual subtitles found, trying auto-generated subtitles..."
        eval "yt-dlp --skip-download --write-auto-sub --sub-lang $language --convert-subs $format -o \"$output_dir/%(title)s.%(ext)s\" \"$url\""
        if [ $? -eq 0 ]; then
          ((fallback_count++))
          echo "Success with fallback: $url"
        else
          ((error_count++))
          echo "Error: No subtitles found for $url" >&2
        fi
      fi
    fi

    echo "--------------------"
  done < "$url_file"

  echo "Batch subtitle download summary:"
  echo "  Total URLs: $total_urls"
  echo "  Successfully downloaded: $success_count"
  echo "  Successfully downloaded with fallback: $fallback_count"
  echo "  Failed: $error_count"

  # Return error if any downloads failed
  if [ "$error_count" -gt 0 ]; then
    return 1
  fi

  return 0
}' # Batch download subtitles from multiple YouTube videos

#------------------------------------------------------------------------------
# Help Function
#------------------------------------------------------------------------------

alias yt-help='() {
  echo "YouTube Aliases Help"
  echo "===================="
  echo ""
  echo "Video Download:"
  echo "  yt-download <url> [options]         - Download a YouTube video"
  echo "  yt-batch-download <file> [options]  - Batch download YouTube videos from a file"
  echo ""
  echo "Playlist Download:"
  echo "  yt-playlist <url> [options]         - Download a YouTube playlist"
  echo ""
  echo "Audio Extraction:"
  echo "  yt-audio <url> [options]            - Extract audio from YouTube videos"
  echo "  yt-batch-audio <file> [options]     - Batch extract audio from multiple YouTube videos"
  echo "  yt-playlist-audio <url> [options]   - Extract audio from a YouTube playlist"
  echo ""
  echo "Video Information:"
  echo "  yt-info <url> [options]             - Get information about YouTube videos"
  echo "  yt-playlist-info <url> [options]    - Get information about a YouTube playlist"
  echo ""
  echo "Thumbnail Download:"
  echo "  yt-thumbnail <url> [options]        - Download thumbnails from YouTube videos"
  echo "  yt-batch-thumbnail <file> [options] - Batch download thumbnails from multiple videos"
  echo ""
  echo "Subtitle Download:"
  echo "  yt-subtitle <url> [options]         - Download subtitles from YouTube videos"
  echo "  yt-batch-subtitle <file> [options]  - Batch download subtitles from multiple videos"
  echo ""
  echo "For more detailed help on any command, run the command without arguments"
}' # Display help information about all YouTube commands

alias youtube-help='() {
  yt-help
}' # Alias to call the YouTube help function
