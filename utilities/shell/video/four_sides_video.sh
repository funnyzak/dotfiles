#!/bin/bash

set -euo pipefail

show_help() {
  cat <<'EOF'
Create a square video with one video duplicated or four videos assigned to the four sides.

Usage:
  four_sides_video.sh [options] <input_video>
  four_sides_video.sh [options] <top_video> <right_video> <bottom_video> <left_video>
  four_sides_video.sh [options] <input_directory>

Provide exactly one or four input videos, or one directory. Directory mode processes
supported videos in the directory's first level and writes one output per input.

Options:
  -o, --output PATH             Output file path.
      --output-dir PATH         Batch output directory (default: INPUT/four_sides_output).
  -s, --resolution WIDTHxHEIGHT Square output resolution (default: 1080x1080).
  -b, --background COLOR       FFmpeg color name or RGB hex (default: black).
      --element-percent VALUE  Side element size as canvas percent, 1-33 (default: 30).
      --margin PIXELS          Distance from each canvas edge (default: 0).
      --fps VALUE              Output frame rate, 1-120 (default: 30).
      --fit MODE               contain or cover (default: contain).
      --orientation MODE       inward or none (default: inward).
      --auto-crop              Remove solid-color borders before scaling.
      --crop-threshold VALUE   Background similarity, 0.00001-1 (default: 0.08).
      --crop-padding-percent N Add background around the crop, 0-100 (default: 10).
      --format FORMAT          mp4, mov, or webm (default: output extension or mp4).
  -f, --force                  Overwrite an existing output file.
  -h, --help                   Show this help message.
EOF
}

require_option_value() {
  local option_name="$1"
  local option_value="${2:-}"

  if [ -z "$option_value" ]; then
    echo "Error: Missing value for $option_name." >&2
    return 2
  fi
}

normalize_background_color() {
  local color_value="$1"

  if [[ "$color_value" =~ ^#[0-9A-Fa-f]{6}$ ]]; then
    echo "0x${color_value:1}"
    return 0
  fi

  if [[ "$color_value" =~ ^0x[0-9A-Fa-f]{6}$ ]] || [[ "$color_value" =~ ^[A-Za-z]+$ ]]; then
    echo "$color_value"
    return 0
  fi

  echo "Error: Background must be a color name or a six-digit RGB hex value." >&2
  return 2
}

normalize_media_path() {
  local path_value="$1"

  case "$path_value" in
    /*|./*|../*)
      echo "$path_value"
      ;;
    *)
      echo "./$path_value"
      ;;
  esac
}

probe_duration() {
  local input_path="$1"
  local duration_value

  if ! duration_value=$(ffprobe -v error -show_entries format=duration \
    -of default=noprint_wrappers=1:nokey=1 "$input_path"); then
    echo "Error: Could not read video duration: $input_path" >&2
    return 1
  fi

  if ! [[ "$duration_value" =~ ^[0-9]+([.][0-9]+)?$ ]] || \
    ! awk -v duration="$duration_value" 'BEGIN { exit !(duration > 0) }'; then
    echo "Error: Input video has no usable duration: $input_path" >&2
    return 1
  fi

  echo "$duration_value"
}

detect_foreground_crop() {
  local input_path="$1"
  local background_color="$2"
  local crop_threshold="$3"
  local bbox_output
  local crop_value

  if ! bbox_output=$(ffmpeg -hide_banner -loglevel info -i "$input_path" \
    -vf "fps=2,format=rgba,colorkey=color=${background_color}:similarity=${crop_threshold}:blend=0,alphaextract,bbox=min_val=16" \
    -an -f null - 2>&1); then
    echo "Error: FFmpeg could not analyze the solid background: $input_path" >&2
    return 1
  fi

  crop_value=$(printf "%s\n" "$bbox_output" \
    | sed -n '/^\[Parsed_bbox_/s/.*crop=\([0-9][0-9]*:[0-9][0-9]*:[0-9][0-9]*:[0-9][0-9]*\).*/\1/p' \
    | awk -F: '
        {
          right = $3 + $1
          bottom = $4 + $2
          if (!seen) {
            min_x = $3
            min_y = $4
            max_x = right
            max_y = bottom
            seen = 1
          } else {
            if ($3 < min_x) min_x = $3
            if ($4 < min_y) min_y = $4
            if (right > max_x) max_x = right
            if (bottom > max_y) max_y = bottom
          }
        }
        END {
          if (seen) {
            printf "%d:%d:%d:%d", max_x - min_x, max_y - min_y, min_x, min_y
          }
        }')

  if [ -z "$crop_value" ]; then
    echo "Error: Auto crop could not find foreground content in: $input_path" >&2
    echo "Adjust --crop-threshold or disable --auto-crop." >&2
    return 1
  fi

  echo "$crop_value"
}

run_batch() {
  local input_directory="$1"
  local output_directory="$2"
  local output_format="$3"
  shift 3
  local -a common_arguments=("$@")
  local -a batch_inputs=()
  local candidate_path
  local candidate_basename
  local candidate_extension
  local input_basename
  local input_stem
  local source_extension
  local output_path
  local output_timestamp
  local input_physical_path
  local output_physical_path
  local batch_index=0
  local success_count=0
  local failure_count=0

  if [ ! -d "$input_directory" ] || [ ! -r "$input_directory" ]; then
    echo "Error: Input directory is missing or unreadable: $input_directory" >&2
    return 2
  fi

  if ! input_physical_path=$(cd "$input_directory" 2>/dev/null && pwd -P); then
    echo "Error: Could not access input directory: $input_directory" >&2
    return 2
  fi
  if [ -d "$output_directory" ]; then
    if ! output_physical_path=$(cd "$output_directory" 2>/dev/null && pwd -P); then
      echo "Error: Could not access batch output directory: $output_directory" >&2
      return 2
    fi
    if [ "$input_physical_path" = "$output_physical_path" ]; then
      echo "Error: Batch output directory must differ from the input directory." >&2
      return 2
    fi
  fi

  if ! mkdir -p "$output_directory"; then
    echo "Error: Could not create batch output directory: $output_directory" >&2
    return 1
  fi

  for candidate_path in \
    "$input_directory"/* \
    "$input_directory"/.[!.]* \
    "$input_directory"/..?*; do
    [ -f "$candidate_path" ] || continue
    candidate_basename=$(basename "$candidate_path")
    candidate_extension="${candidate_basename##*.}"
    candidate_extension=$(printf "%s" "$candidate_extension" | tr '[:upper:]' '[:lower:]')
    case "$candidate_extension" in
      mp4|mov|webm|mkv|avi|m4v)
        batch_inputs+=("$candidate_path")
        ;;
    esac
  done

  if [ "${#batch_inputs[@]}" -eq 0 ]; then
    echo "Error: No supported videos found in directory: $input_directory" >&2
    echo "Supported extensions: mp4, mov, webm, mkv, avi, m4v." >&2
    return 2
  fi

  output_timestamp=$(date "+%Y%m%d_%H%M%S")
  for candidate_path in "${batch_inputs[@]}"; do
    batch_index=$((batch_index + 1))
    input_basename=$(basename "$candidate_path")
    input_stem="${input_basename%.*}"
    source_extension="${input_basename##*.}"
    source_extension=$(printf "%s" "$source_extension" | tr '[:upper:]' '[:lower:]')
    output_path="${output_directory}/${input_stem}_${source_extension}_four_sides_${output_timestamp}_$$_${batch_index}.${output_format}"

    if main "${common_arguments[@]}" --format "$output_format" \
      --output "$output_path" -- "$candidate_path"; then
      success_count=$((success_count + 1))
    else
      failure_count=$((failure_count + 1))
      echo "Batch item failed: $candidate_path" >&2
    fi
  done

  echo "Batch complete: $success_count succeeded, $failure_count failed"
  echo "Output directory: $output_directory"

  if [ "$failure_count" -gt 0 ]; then
    return 1
  fi
}

main() {
  local resolution="1080x1080"
  local background="black"
  local element_percent=30
  local margin=0
  local fps=30
  local fit_mode="contain"
  local orientation_mode="inward"
  local auto_crop="false"
  local crop_threshold="0.08"
  local crop_padding_percent=10
  local output_format=""
  local output_path=""
  local batch_output_dir=""
  local force_flag="false"
  local -a input_videos=()
  local input_path
  local input_index
  local canvas_width
  local canvas_height
  local canvas_size
  local element_size
  local center_position
  local far_position
  local duration
  local candidate_duration
  local detected_crop
  local scale_filter
  local top_rotation=""
  local right_rotation=""
  local bottom_rotation=""
  local left_rotation=""
  local filter_graph
  local output_directory
  local output_basename
  local output_extension
  local input_directory
  local input_basename
  local input_stem
  local output_timestamp
  local overwrite_flag="-n"
  local -a input_arguments=()
  local -a input_crop_filters=()
  local -a side_crop_filters=()
  local -a source_labels=()
  local -a codec_arguments=()
  local -a ffmpeg_command=()

  if [ $# -eq 0 ]; then
    show_help
    return 0
  fi

  while [ $# -gt 0 ]; do
    case "$1" in
      -h|--help)
        show_help
        return 0
        ;;
      -o|--output)
        require_option_value "$1" "${2:-}" || return $?
        output_path="$2"
        shift 2
        ;;
      --output-dir)
        require_option_value "$1" "${2:-}" || return $?
        batch_output_dir="$2"
        shift 2
        ;;
      -s|--resolution)
        require_option_value "$1" "${2:-}" || return $?
        resolution="$2"
        shift 2
        ;;
      -b|--background)
        require_option_value "$1" "${2:-}" || return $?
        background="$2"
        shift 2
        ;;
      --element-percent)
        require_option_value "$1" "${2:-}" || return $?
        element_percent="$2"
        shift 2
        ;;
      --margin)
        require_option_value "$1" "${2:-}" || return $?
        margin="$2"
        shift 2
        ;;
      --fps)
        require_option_value "$1" "${2:-}" || return $?
        fps="$2"
        shift 2
        ;;
      --fit)
        require_option_value "$1" "${2:-}" || return $?
        fit_mode="$2"
        shift 2
        ;;
      --orientation)
        require_option_value "$1" "${2:-}" || return $?
        orientation_mode="$2"
        shift 2
        ;;
      --auto-crop)
        auto_crop="true"
        shift
        ;;
      --crop-threshold)
        require_option_value "$1" "${2:-}" || return $?
        crop_threshold="$2"
        shift 2
        ;;
      --crop-padding-percent)
        require_option_value "$1" "${2:-}" || return $?
        crop_padding_percent="$2"
        shift 2
        ;;
      --format)
        require_option_value "$1" "${2:-}" || return $?
        output_format="$2"
        shift 2
        ;;
      -f|--force)
        force_flag="true"
        shift
        ;;
      --)
        shift
        input_videos+=("$@")
        break
        ;;
      -*)
        echo "Error: Unknown option: $1" >&2
        return 2
        ;;
      *)
        input_videos+=("$1")
        shift
        ;;
    esac
  done

  if [ "${#input_videos[@]}" -ne 1 ] && [ "${#input_videos[@]}" -ne 4 ]; then
    echo "Error: Provide exactly one or four input videos." >&2
    return 2
  fi

  if ! command -v ffmpeg >/dev/null 2>&1 || ! command -v ffprobe >/dev/null 2>&1; then
    echo "Error: ffmpeg and ffprobe must be installed and available in PATH." >&2
    return 127
  fi

  for ((input_index = 0; input_index < ${#input_videos[@]}; input_index++)); do
    input_videos[$input_index]=$(normalize_media_path "${input_videos[$input_index]}")
  done
  if [ -n "$output_path" ]; then
    output_path=$(normalize_media_path "$output_path")
  fi
  if [ -n "$batch_output_dir" ]; then
    batch_output_dir=$(normalize_media_path "$batch_output_dir")
  fi

  if [ -n "$output_format" ]; then
    output_format=$(printf "%s" "$output_format" | tr '[:upper:]' '[:lower:]')
    case "$output_format" in
      mp4|mov|webm) ;;
      *)
        echo "Error: --format must be mp4, mov, or webm." >&2
        return 2
        ;;
    esac
  fi

  if [ "${#input_videos[@]}" -eq 1 ] && [ -d "${input_videos[0]}" ]; then
    local -a batch_common_arguments=(
      --resolution "$resolution"
      --background "$background"
      --element-percent "$element_percent"
      --margin "$margin"
      --fps "$fps"
      --fit "$fit_mode"
      --orientation "$orientation_mode"
      --crop-threshold "$crop_threshold"
      --crop-padding-percent "$crop_padding_percent"
    )

    if [ -n "$output_path" ]; then
      echo "Error: --output cannot be used with a directory input. Use --output-dir." >&2
      return 2
    fi
    if [ "$auto_crop" = "true" ]; then
      batch_common_arguments+=(--auto-crop)
    fi
    if [ "$force_flag" = "true" ]; then
      batch_common_arguments+=(--force)
    fi

    output_format="${output_format:-mp4}"
    batch_output_dir="${batch_output_dir:-${input_videos[0]}/four_sides_output}"
    run_batch "${input_videos[0]}" "$batch_output_dir" "$output_format" \
      "${batch_common_arguments[@]}"
    return $?
  fi

  if [ -n "$batch_output_dir" ]; then
    echo "Error: --output-dir can only be used with a directory input." >&2
    return 2
  fi

  for input_path in "${input_videos[@]}"; do
    if [ ! -f "$input_path" ] || [ ! -r "$input_path" ]; then
      echo "Error: Input video is missing or unreadable: $input_path" >&2
      return 2
    fi
  done

  if [[ ! "$resolution" =~ ^([0-9]+)x([0-9]+)$ ]]; then
    echo "Error: Resolution must use WIDTHxHEIGHT, for example 1080x1080." >&2
    return 2
  fi
  canvas_width="${BASH_REMATCH[1]}"
  canvas_height="${BASH_REMATCH[2]}"
  if [ "${#canvas_width}" -gt 10 ] || [ "${#canvas_height}" -gt 10 ]; then
    echo "Error: Resolution values are too large." >&2
    return 2
  fi
  canvas_width=$((10#$canvas_width))
  canvas_height=$((10#$canvas_height))

  if [ "$canvas_width" -ne "$canvas_height" ]; then
    echo "Error: Resolution must be square." >&2
    return 2
  fi
  if [ "$canvas_width" -lt 64 ] || [ "$canvas_width" -gt 8192 ] || [ $((canvas_width % 2)) -ne 0 ]; then
    echo "Error: Resolution must be an even value between 64x64 and 8192x8192." >&2
    return 2
  fi
  canvas_size="$canvas_width"

  if ! [[ "$element_percent" =~ ^[0-9]+$ ]]; then
    echo "Error: --element-percent must be an integer from 1 to 33." >&2
    return 2
  fi
  if [ "${#element_percent}" -gt 10 ]; then
    echo "Error: --element-percent must be an integer from 1 to 33." >&2
    return 2
  fi
  element_percent=$((10#$element_percent))
  if [ "$element_percent" -lt 1 ] || [ "$element_percent" -gt 33 ]; then
    echo "Error: --element-percent must be an integer from 1 to 33." >&2
    return 2
  fi
  if ! [[ "$margin" =~ ^[0-9]+$ ]]; then
    echo "Error: --margin must be a non-negative integer." >&2
    return 2
  fi
  if [ "${#margin}" -gt 10 ]; then
    echo "Error: --margin must be a non-negative integer." >&2
    return 2
  fi
  margin=$((10#$margin))
  if ! [[ "$fps" =~ ^[0-9]+$ ]]; then
    echo "Error: --fps must be an integer from 1 to 120." >&2
    return 2
  fi
  if [ "${#fps}" -gt 10 ]; then
    echo "Error: --fps must be an integer from 1 to 120." >&2
    return 2
  fi
  fps=$((10#$fps))
  if [ "$fps" -lt 1 ] || [ "$fps" -gt 120 ]; then
    echo "Error: --fps must be an integer from 1 to 120." >&2
    return 2
  fi
  if [ "$fit_mode" != "contain" ] && [ "$fit_mode" != "cover" ]; then
    echo "Error: --fit must be contain or cover." >&2
    return 2
  fi
  if [ "$orientation_mode" != "inward" ] && [ "$orientation_mode" != "none" ]; then
    echo "Error: --orientation must be inward or none." >&2
    return 2
  fi
  if ! [[ "$crop_threshold" =~ ^[0-9]+([.][0-9]+)?$ ]] || \
    [ "${#crop_threshold}" -gt 20 ] || \
    ! awk -v threshold="$crop_threshold" 'BEGIN { exit !(threshold >= 0.00001 && threshold <= 1) }'; then
    echo "Error: --crop-threshold must be from 0.00001 to 1." >&2
    return 2
  fi
  if ! [[ "$crop_padding_percent" =~ ^[0-9]+$ ]] || \
    [ "${#crop_padding_percent}" -gt 10 ]; then
    echo "Error: --crop-padding-percent must be an integer from 0 to 100." >&2
    return 2
  fi
  crop_padding_percent=$((10#$crop_padding_percent))
  if [ "$crop_padding_percent" -lt 0 ] || [ "$crop_padding_percent" -gt 100 ]; then
    echo "Error: --crop-padding-percent must be an integer from 0 to 100." >&2
    return 2
  fi

  background=$(normalize_background_color "$background") || return $?

  element_size=$((canvas_size * element_percent / 100))
  element_size=$((element_size / 2 * 2))
  if [ "$element_size" -lt 2 ]; then
    echo "Error: Element size is too small for the selected resolution." >&2
    return 2
  fi
  # Four square slots sit at the edge midpoints; this bound prevents adjacent slots from intersecting.
  if [ $((3 * element_size + 2 * margin)) -gt "$canvas_size" ]; then
    echo "Error: Element size and margin would make side video boxes overlap." >&2
    echo "Reduce --element-percent or --margin." >&2
    return 2
  fi

  if [ -z "$output_path" ]; then
    output_format="${output_format:-mp4}"
    input_directory=$(dirname "${input_videos[0]}")
    input_basename=$(basename "${input_videos[0]}")
    input_stem="${input_basename%.*}"
    if [ -z "$input_stem" ]; then
      input_stem="$input_basename"
    fi
    output_timestamp=$(date "+%Y%m%d_%H%M%S")
    output_path="${input_directory}/${input_stem}_four_sides_${output_timestamp}_$$.${output_format}"
  else
    output_basename=$(basename "$output_path")
    if [[ "$output_basename" == *.* ]]; then
      output_extension="${output_basename##*.}"
      output_extension=$(printf "%s" "$output_extension" | tr '[:upper:]' '[:lower:]')
    fi

    if [ -z "$output_format" ]; then
      case "$output_extension" in
        mp4|mov|webm)
          output_format="$output_extension"
          ;;
        "")
          output_format="mp4"
          output_path="${output_path}.mp4"
          ;;
        *)
          echo "Error: Could not infer output format. Use --format mp4, mov, or webm." >&2
          return 2
          ;;
      esac
    elif [ -z "$output_extension" ]; then
      output_path="${output_path}.${output_format}"
    elif [ "$output_extension" != "$output_format" ]; then
      echo "Error: Output extension .$output_extension does not match --format $output_format." >&2
      return 2
    fi
  fi

  if [ -e "$output_path" ]; then
    for input_path in "${input_videos[@]}"; do
      if [ "$output_path" -ef "$input_path" ]; then
        echo "Error: Output file must differ from every input video." >&2
        return 2
      fi
    done
  fi

  if [ -e "$output_path" ] && [ "$force_flag" != "true" ]; then
    echo "Error: Output file already exists. Use --force to overwrite it: $output_path" >&2
    return 2
  fi

  output_directory=$(dirname "$output_path")
  if ! mkdir -p "$output_directory"; then
    echo "Error: Could not create output directory: $output_directory" >&2
    return 1
  fi

  duration=""
  for input_path in "${input_videos[@]}"; do
    candidate_duration=$(probe_duration "$input_path") || return $?
    if [ -z "$duration" ] || awk -v candidate="$candidate_duration" -v current="$duration" \
      'BEGIN { exit !(candidate < current) }'; then
      duration="$candidate_duration"
    fi
    input_arguments+=(-i "$input_path")
    if [ "$auto_crop" = "true" ]; then
      detected_crop=$(detect_foreground_crop "$input_path" "$background" \
        "$crop_threshold") || return $?
      if [ "$crop_padding_percent" -gt 0 ]; then
        input_crop_filters+=("crop=${detected_crop},pad=ceil(iw*(100+2*${crop_padding_percent})/100/2)*2:ceil(ih*(100+2*${crop_padding_percent})/100/2)*2:(ow-iw)/2:(oh-ih)/2:color=${background},")
      else
        input_crop_filters+=("crop=${detected_crop},")
      fi
    else
      input_crop_filters+=("")
    fi
  done

  center_position=$(((canvas_size - element_size) / 2))
  far_position=$((canvas_size - element_size - margin))

  if [ "$fit_mode" = "contain" ]; then
    scale_filter="scale=${element_size}:${element_size}:force_original_aspect_ratio=decrease,pad=${element_size}:${element_size}:(ow-iw)/2:(oh-ih)/2:color=${background}"
  else
    scale_filter="scale=${element_size}:${element_size}:force_original_aspect_ratio=increase,crop=${element_size}:${element_size}"
  fi

  if [ "$orientation_mode" = "inward" ]; then
    # Bottom keeps the source orientation; the other sides rotate so the same subject faces the center.
    top_rotation=",hflip,vflip"
    right_rotation=",transpose=2"
    left_rotation=",transpose=1"
  fi

  if [ "${#input_videos[@]}" -eq 1 ]; then
    filter_graph="[0:v]split=4[src_top][src_right][src_bottom][src_left];"
    source_labels=(src_top src_right src_bottom src_left)
    side_crop_filters=(
      "${input_crop_filters[0]}" "${input_crop_filters[0]}"
      "${input_crop_filters[0]}" "${input_crop_filters[0]}"
    )
  else
    filter_graph=""
    source_labels=(0:v 1:v 2:v 3:v)
    side_crop_filters=("${input_crop_filters[@]}")
  fi

  # Normalize each source into one square slot, then overlay the slots clockwise on a generated canvas.
  filter_graph+="[${source_labels[0]}]fps=${fps},setpts=PTS-STARTPTS,${side_crop_filters[0]}${scale_filter}${top_rotation}[top];"
  filter_graph+="[${source_labels[1]}]fps=${fps},setpts=PTS-STARTPTS,${side_crop_filters[1]}${scale_filter}${right_rotation}[right];"
  filter_graph+="[${source_labels[2]}]fps=${fps},setpts=PTS-STARTPTS,${side_crop_filters[2]}${scale_filter}${bottom_rotation}[bottom];"
  filter_graph+="[${source_labels[3]}]fps=${fps},setpts=PTS-STARTPTS,${side_crop_filters[3]}${scale_filter}${left_rotation}[left];"
  filter_graph+="color=c=${background}:s=${canvas_size}x${canvas_size}:r=${fps}:d=${duration}[base];"
  filter_graph+="[base][top]overlay=${center_position}:${margin}:shortest=1[layer1];"
  filter_graph+="[layer1][right]overlay=${far_position}:${center_position}:shortest=1[layer2];"
  filter_graph+="[layer2][bottom]overlay=${center_position}:${far_position}:shortest=1[layer3];"
  filter_graph+="[layer3][left]overlay=${margin}:${center_position}:shortest=1,format=yuv420p[outv]"

  if [ "$force_flag" = "true" ]; then
    overwrite_flag="-y"
  fi

  case "$output_format" in
    mp4)
      codec_arguments=(-c:v libx264 -preset medium -crf 18 -pix_fmt yuv420p -movflags +faststart -f mp4)
      ;;
    mov)
      codec_arguments=(-c:v libx264 -preset medium -crf 18 -pix_fmt yuv420p -movflags +faststart -f mov)
      ;;
    webm)
      codec_arguments=(-c:v libvpx-vp9 -crf 28 -b:v 0 -row-mt 1 -pix_fmt yuv420p -f webm)
      ;;
  esac

  ffmpeg_command=(
    ffmpeg -hide_banner -loglevel error
    "${input_arguments[@]}"
    -filter_complex "$filter_graph"
    -map "[outv]" -an
    -r "$fps" -t "$duration"
    "${codec_arguments[@]}"
    "$overwrite_flag" "$output_path"
  )

  if ! "${ffmpeg_command[@]}"; then
    echo "Error: FFmpeg failed to create the output video." >&2
    return 1
  fi

  echo "Created: $output_path"
}

main "$@"
