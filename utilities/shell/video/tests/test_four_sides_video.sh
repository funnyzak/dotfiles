#!/bin/bash

set -euo pipefail

TEST_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
VIDEO_DIR=$(cd "$TEST_DIR/.." && pwd)
REPO_ROOT=$(cd "$VIDEO_DIR/../../.." && pwd)
SCRIPT_PATH="$VIDEO_DIR/four_sides_video.sh"
PASS_COUNT=0
TEMP_ROOT="$REPO_ROOT/temp_files"
TEST_WORK_DIR=""

cleanup() {
  case "$TEST_WORK_DIR" in
    "$TEMP_ROOT"/four-sides-video-test.*)
      if [ -d "$TEST_WORK_DIR" ]; then
        rm -rf -- "$TEST_WORK_DIR"
      fi
      ;;
  esac
}

trap cleanup EXIT

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

pass() {
  PASS_COUNT=$((PASS_COUNT + 1))
  echo "PASS: $1"
}

assert_contains() {
  local actual_value="$1"
  local expected_value="$2"
  local message="$3"

  if [[ "$actual_value" != *"$expected_value"* ]]; then
    fail "$message (expected to contain: $expected_value)"
  fi
}

assert_equals() {
  local actual_value="$1"
  local expected_value="$2"
  local message="$3"

  if [ "$actual_value" != "$expected_value" ]; then
    fail "$message (expected: $expected_value, actual: $actual_value)"
  fi
}

assert_pixel_color() {
  local video_path="$1"
  local pixel_x="$2"
  local pixel_y="$3"
  local expected_color="$4"
  local sample_time="${5:-0}"
  local pixel_values
  local red_value
  local green_value
  local blue_value

  pixel_values=$(ffmpeg -v error -ss "$sample_time" -i "$video_path" \
    -vf "crop=2:2:$pixel_x:$pixel_y,scale=1:1,format=rgb24" \
    -frames:v 1 -f rawvideo - | od -An -tu1 -N3)
  read -r red_value green_value blue_value <<< "$pixel_values"

  case "$expected_color" in
    red)
      if [ "$red_value" -lt 160 ] || [ "$green_value" -gt 90 ] || [ "$blue_value" -gt 90 ]; then
        fail "pixel $pixel_x,$pixel_y is not red enough: $red_value $green_value $blue_value"
      fi
      ;;
    blue)
      if [ "$blue_value" -lt 160 ] || [ "$red_value" -gt 90 ] || [ "$green_value" -gt 90 ]; then
        fail "pixel $pixel_x,$pixel_y is not blue enough: $red_value $green_value $blue_value"
      fi
      ;;
    green)
      if [ "$green_value" -lt 80 ] || [ "$red_value" -gt 90 ] || [ "$blue_value" -gt 90 ]; then
        fail "pixel $pixel_x,$pixel_y is not green enough: $red_value $green_value $blue_value"
      fi
      ;;
    yellow)
      if [ "$red_value" -lt 160 ] || [ "$green_value" -lt 160 ] || [ "$blue_value" -gt 90 ]; then
        fail "pixel $pixel_x,$pixel_y is not yellow enough: $red_value $green_value $blue_value"
      fi
      ;;
    white)
      if [ "$red_value" -lt 180 ] || [ "$green_value" -lt 180 ] || [ "$blue_value" -lt 180 ]; then
        fail "pixel $pixel_x,$pixel_y is not white enough: $red_value $green_value $blue_value"
      fi
      ;;
    black)
      if [ "$red_value" -gt 40 ] || [ "$green_value" -gt 40 ] || [ "$blue_value" -gt 40 ]; then
        fail "pixel $pixel_x,$pixel_y is not black enough: $red_value $green_value $blue_value"
      fi
      ;;
    *)
      fail "unsupported expected color: $expected_color"
      ;;
  esac
}

setup_work_dir() {
  mkdir -p "$TEMP_ROOT"
  TEST_WORK_DIR=$(mktemp -d "$TEMP_ROOT/four-sides-video-test.XXXXXX")
}

create_orientation_video() {
  local output_path="$1"

  ffmpeg -v error \
    -f lavfi -i "color=c=red:s=100x50:r=10:d=1" \
    -f lavfi -i "color=c=blue:s=100x50:r=10:d=1" \
    -filter_complex "[0:v][1:v]vstack=inputs=2,format=yuv420p[v]" \
    -map "[v]" -an -c:v libx264 -pix_fmt yuv420p -y "$output_path"
}

create_solid_video() {
  local output_path="$1"
  local color_value="$2"
  local duration_value="$3"

  ffmpeg -v error -f lavfi \
    -i "color=c=${color_value}:s=100x100:r=10:d=${duration_value}" \
    -an -c:v libx264 -pix_fmt yuv420p -y "$output_path"
}

create_wide_solid_video() {
  local output_path="$1"
  local color_value="$2"

  ffmpeg -v error -f lavfi \
    -i "color=c=${color_value}:s=120x60:r=10:d=0.3" \
    -an -c:v libx264 -pix_fmt yuv420p -y "$output_path"
}

create_extensionless_video() {
  local output_path="$1"

  ffmpeg -v error -f lavfi \
    -i "color=c=blue:s=100x100:r=10:d=0.3" \
    -an -c:v libx264 -pix_fmt yuv420p -f mp4 -y "$output_path"
}

create_small_foreground_video() {
  local output_path="$1"

  ffmpeg -v error -f lavfi \
    -i "color=c=black:s=200x120:r=10:d=0.5" \
    -vf "drawbox=x=80:y=40:w=40:h=40:color=red:t=fill" \
    -an -c:v libx264 -pix_fmt yuv420p -y "$output_path"
}

create_small_white_foreground_video() {
  local output_path="$1"

  ffmpeg -v error -f lavfi \
    -i "color=c=black:s=200x120:r=10:d=0.5" \
    -vf "drawbox=x=80:y=40:w=40:h=40:color=white:t=fill" \
    -an -c:v libx264 -pix_fmt yuv420p -y "$output_path"
}

create_moving_foreground_video() {
  local output_path="$1"

  ffmpeg -v error -f lavfi \
    -i "color=c=black:s=200x120:r=10:d=5" \
    -vf "drawbox=x=20+120*gte(t\,4):y=40:w=30:h=30:color=red:t=fill" \
    -an -c:v libx264 -pix_fmt yuv420p -y "$output_path"
}

create_odd_sized_video() {
  local output_path="$1"

  ffmpeg -v error -f lavfi -i "color=c=red:s=101x99:r=10:d=0.5" \
    -an -c:v ffv1 -pix_fmt yuv444p -y "$output_path"
}

test_help() {
  local help_output

  if [ ! -x "$SCRIPT_PATH" ]; then
    fail "CLI script is missing or not executable: $SCRIPT_PATH"
  fi

  help_output=$("$SCRIPT_PATH" --help 2>&1) || fail "--help returned a non-zero status"
  assert_contains "$help_output" "Usage:" "help output is missing Usage"
  assert_contains "$help_output" "one or four input videos" "help output is missing the input contract"
  pass "help describes the CLI contract"
}

test_no_arguments_shows_help() {
  local help_output

  help_output=$("$SCRIPT_PATH" 2>&1) || fail "running without arguments should show help successfully"
  assert_contains "$help_output" "Usage:" "no-argument output is missing Usage"
  pass "running without arguments shows help"
}

test_rejects_two_inputs() {
  local error_output

  if error_output=$("$SCRIPT_PATH" first.mp4 second.mp4 2>&1); then
    fail "two input videos should be rejected"
  fi

  assert_contains "$error_output" "Provide exactly one or four input videos" "invalid input count error is unclear"
  pass "invalid input count is rejected"
}

test_single_input_is_duplicated_and_rotated_inward() {
  local input_path="$TEST_WORK_DIR/orientation.mp4"
  local output_path="$TEST_WORK_DIR/single-output.mp4"
  local dimensions
  local codec_name

  create_orientation_video "$input_path"

  "$SCRIPT_PATH" \
    --resolution 300x300 \
    --element-percent 30 \
    --background black \
    --fps 10 \
    --output "$output_path" \
    "$input_path"

  if [ ! -s "$output_path" ]; then
    fail "single-input composition did not create an output video"
  fi

  dimensions=$(ffprobe -v error -select_streams v:0 \
    -show_entries stream=width,height -of csv=s=x:p=0 "$output_path")
  assert_equals "$dimensions" "300x300" "output resolution is incorrect"
  codec_name=$(ffprobe -v error -select_streams v:0 \
    -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$output_path")
  assert_equals "$codec_name" "h264" "MP4 output codec is incorrect"

  assert_pixel_color "$output_path" 150 20 blue
  assert_pixel_color "$output_path" 150 70 red
  assert_pixel_color "$output_path" 220 150 red
  assert_pixel_color "$output_path" 280 150 blue
  assert_pixel_color "$output_path" 150 220 red
  assert_pixel_color "$output_path" 150 280 blue
  assert_pixel_color "$output_path" 20 150 blue
  assert_pixel_color "$output_path" 70 150 red
  assert_pixel_color "$output_path" 150 150 black
  pass "single input is duplicated and rotated toward the center"
}

test_four_inputs_are_assigned_and_webm_uses_shortest_duration() {
  local top_path="$TEST_WORK_DIR/top.mp4"
  local right_path="$TEST_WORK_DIR/right.mp4"
  local bottom_path="$TEST_WORK_DIR/bottom.mp4"
  local left_path="$TEST_WORK_DIR/left.mp4"
  local output_path="$TEST_WORK_DIR/four-output.webm"
  local format_name
  local duration_value
  local codec_name

  create_solid_video "$top_path" red 1.4
  create_solid_video "$right_path" green 1.2
  create_solid_video "$bottom_path" blue 1.0
  create_solid_video "$left_path" yellow 0.8

  "$SCRIPT_PATH" \
    --resolution 300x300 \
    --element-percent 30 \
    --background "#ffffff" \
    --orientation none \
    --fps 10 \
    --format webm \
    --output "$output_path" \
    "$top_path" "$right_path" "$bottom_path" "$left_path"

  format_name=$(ffprobe -v error -show_entries format=format_name \
    -of default=noprint_wrappers=1:nokey=1 "$output_path")
  assert_contains "$format_name" "webm" "four-input output is not WebM"
  codec_name=$(ffprobe -v error -select_streams v:0 \
    -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$output_path")
  assert_equals "$codec_name" "vp9" "WebM output codec is incorrect"

  duration_value=$(ffprobe -v error -show_entries format=duration \
    -of default=noprint_wrappers=1:nokey=1 "$output_path")
  if ! awk -v duration="$duration_value" 'BEGIN { exit !(duration >= 0.7 && duration <= 0.95) }'; then
    fail "four-input output did not stop at the shortest duration: $duration_value"
  fi

  assert_pixel_color "$output_path" 150 45 red
  assert_pixel_color "$output_path" 255 150 green
  assert_pixel_color "$output_path" 150 255 blue
  assert_pixel_color "$output_path" 45 150 yellow
  assert_pixel_color "$output_path" 150 150 white
  pass "four inputs are assigned to sides and WebM stops at the shortest duration"
}

test_mov_export_format() {
  local input_path="$TEST_WORK_DIR/mov-input.mp4"
  local output_path="$TEST_WORK_DIR/single-output.mov"
  local format_name

  create_solid_video "$input_path" red 0.5

  "$SCRIPT_PATH" --resolution 240x240 --format mov \
    --output "$output_path" "$input_path"

  format_name=$(ffprobe -v error -show_entries format=format_name \
    -of default=noprint_wrappers=1:nokey=1 "$output_path")
  assert_contains "$format_name" "mov" "MOV export did not use a MOV container"
  pass "MOV export format is supported"
}

test_rejects_layouts_that_can_overlap() {
  local input_path="$TEST_WORK_DIR/overlap-input.mp4"
  local output_path="$TEST_WORK_DIR/overlap-output.mp4"
  local error_output

  create_solid_video "$input_path" red 0.3

  if error_output=$("$SCRIPT_PATH" --resolution 300x300 \
    --element-percent 33 --margin 10 --output "$output_path" "$input_path" 2>&1); then
    fail "an overlapping side-box layout should be rejected"
  fi

  assert_contains "$error_output" "would make side video boxes overlap" "overlap error is unclear"
  pass "layouts that can overlap are rejected"
}

test_existing_output_requires_force() {
  local input_path="$TEST_WORK_DIR/force-input.mp4"
  local output_path="$TEST_WORK_DIR/force-output.mp4"
  local error_output

  create_solid_video "$input_path" blue 0.3
  "$SCRIPT_PATH" --resolution 180x180 --output "$output_path" "$input_path"

  if error_output=$("$SCRIPT_PATH" --resolution 180x180 \
    --output "$output_path" "$input_path" 2>&1); then
    fail "existing output should require --force"
  fi
  assert_contains "$error_output" "Use --force" "overwrite error is unclear"

  "$SCRIPT_PATH" --resolution 180x180 --force \
    --output "$output_path" "$input_path"
  pass "existing output is protected unless --force is used"
}

test_output_cannot_replace_an_input() {
  local input_path="$TEST_WORK_DIR/same-path-input.mp4"
  local error_output

  create_solid_video "$input_path" red 0.3

  if error_output=$("$SCRIPT_PATH" --resolution 180x180 --force \
    --output "$input_path" "$input_path" 2>&1); then
    fail "output should never be allowed to replace an input video"
  fi

  assert_contains "$error_output" "Output file must differ from every input video" "same-path error is unclear"
  if [ ! -s "$input_path" ]; then
    fail "same-path protection allowed the input video to be damaged"
  fi
  pass "output cannot replace an input video"
}

test_output_without_extension_defaults_to_mp4() {
  local input_path="$TEST_WORK_DIR/default-format-input.mp4"
  local requested_path="$TEST_WORK_DIR/default-format-output"
  local actual_path="${requested_path}.mp4"

  create_solid_video "$input_path" blue 0.3
  "$SCRIPT_PATH" --resolution 180x180 --output "$requested_path" "$input_path"

  if [ ! -s "$actual_path" ]; then
    fail "an extensionless output path should create an MP4 file"
  fi
  pass "output without an extension defaults to MP4"
}

test_cover_fills_each_square_slot() {
  local input_path="$TEST_WORK_DIR/cover-input.mp4"
  local output_path="$TEST_WORK_DIR/cover-output.mp4"

  create_wide_solid_video "$input_path" red
  "$SCRIPT_PATH" --resolution 240x240 --fit cover --orientation none \
    --output "$output_path" "$input_path"

  assert_pixel_color "$output_path" 120 170 red
  pass "cover mode fills the square side slot"
}

test_numeric_options_accept_leading_zeroes_as_decimal() {
  local input_path="$TEST_WORK_DIR/decimal-input.mp4"
  local output_path="$TEST_WORK_DIR/decimal-output.mp4"
  local dimensions

  create_solid_video "$input_path" green 0.3
  "$SCRIPT_PATH" --resolution 0180x0180 --element-percent 030 \
    --margin 00 --fps 010 --output "$output_path" "$input_path"

  dimensions=$(ffprobe -v error -select_streams v:0 \
    -show_entries stream=width,height -of csv=s=x:p=0 "$output_path")
  assert_equals "$dimensions" "180x180" "numeric options were not parsed as decimal values"
  pass "numeric options with leading zeroes are parsed as decimal"
}

test_rejects_oversized_numeric_values() {
  local input_path="$TEST_WORK_DIR/oversized-number-input.mp4"
  local output_path="$TEST_WORK_DIR/oversized-number-output.mp4"
  local error_output

  create_solid_video "$input_path" red 0.3
  if error_output=$("$SCRIPT_PATH" --resolution 180x180 \
    --margin 18446744073709551616 --output "$output_path" "$input_path" 2>&1); then
    fail "oversized numeric values should be rejected"
  fi
  assert_contains "$error_output" "--margin must be a non-negative integer" "oversized number error is unclear"
  pass "oversized numeric values are rejected before shell arithmetic"
}

test_relative_paths_with_option_or_protocol_prefixes() {
  local input_name="-dash:input.mp4"
  local output_name="-dash:output.mp4"

  (
    cd "$TEST_WORK_DIR"
    create_solid_video "./$input_name" blue 0.3
    "$SCRIPT_PATH" --resolution 180x180 --output "$output_name" -- "$input_name"
  )

  if [ ! -s "$TEST_WORK_DIR/$output_name" ]; then
    fail "relative paths starting with a dash or containing a colon were not handled safely"
  fi
  pass "relative paths are protected from option and protocol parsing"
}

test_default_output_name_contains_timestamp() {
  local generated_name

  (
    cd "$TEST_WORK_DIR"
    create_extensionless_video "./timestamp-source"
    "$SCRIPT_PATH" --resolution 180x180 "timestamp-source"
  )

  generated_name=$(find "$TEST_WORK_DIR" -maxdepth 1 -type f \
    -name 'timestamp-source_four_sides_*.mp4' -exec basename {} \; | head -1)
  if ! [[ "$generated_name" =~ ^timestamp-source_four_sides_[0-9]{8}_[0-9]{6}_[0-9]+[.]mp4$ ]]; then
    fail "default output name is missing a timestamp and unique process suffix: $generated_name"
  fi
  pass "default output name contains a timestamp"
}

test_auto_crop_enlarges_a_small_foreground() {
  local input_path="$TEST_WORK_DIR/auto-crop-input.mp4"
  local output_path="$TEST_WORK_DIR/auto-crop-output.mp4"

  create_small_foreground_video "$input_path"
  "$SCRIPT_PATH" --resolution 300x300 --element-percent 30 \
    --background black --auto-crop --crop-threshold 0.08 \
    --crop-padding-percent 10 \
    --orientation none --output "$output_path" "$input_path"

  assert_pixel_color "$output_path" 120 230 red
  assert_pixel_color "$output_path" 150 150 black
  pass "auto crop removes solid borders before slot scaling"
}

test_auto_crop_preserves_white_foreground_on_black() {
  local input_path="$TEST_WORK_DIR/auto-crop-white-input.mp4"
  local output_path="$TEST_WORK_DIR/auto-crop-white-output.mp4"

  create_small_white_foreground_video "$input_path"
  "$SCRIPT_PATH" --resolution 300x300 --element-percent 30 \
    --background black --auto-crop --crop-threshold 0.08 \
    --crop-padding-percent 10 --orientation none \
    --output "$output_path" "$input_path"

  assert_pixel_color "$output_path" 120 230 white
  pass "auto crop preserves a neutral white foreground on black"
}

test_auto_crop_ignores_crop_text_in_filename() {
  local input_path="$TEST_WORK_DIR/Parsed_bbox_crop=10:10:0:0.mp4"
  local output_path="$TEST_WORK_DIR/crop-filename-output.mp4"
  local error_output

  create_solid_video "$input_path" black 0.5
  if error_output=$("$SCRIPT_PATH" --resolution 300x300 --background black \
    --auto-crop --output "$output_path" "$input_path" 2>&1); then
    fail "auto crop should not read crop coordinates from an input filename"
  fi
  assert_contains "$error_output" "could not find foreground content" "filename crop-log protection error is unclear"
  pass "auto crop parses only bbox filter output"
}

test_auto_crop_scans_the_full_video() {
  local input_path="$TEST_WORK_DIR/moving-foreground.mp4"
  local output_path="$TEST_WORK_DIR/moving-foreground-output.mp4"

  create_moving_foreground_video "$input_path"
  "$SCRIPT_PATH" --resolution 300x300 --background black --auto-crop \
    --crop-padding-percent 10 --orientation none \
    --output "$output_path" "$input_path"

  assert_pixel_color "$output_path" 180 255 red 4.5
  pass "auto crop includes foreground positions from the full video"
}

test_auto_crop_handles_odd_source_dimensions() {
  local input_path="$TEST_WORK_DIR/odd-source.mkv"
  local output_path="$TEST_WORK_DIR/odd-source-output.mp4"

  create_odd_sized_video "$input_path"
  "$SCRIPT_PATH" --resolution 300x300 --background black --auto-crop \
    --crop-padding-percent 0 --output "$output_path" "$input_path"

  if [ ! -s "$output_path" ]; then
    fail "auto crop did not export an odd-dimension source"
  fi
  pass "auto crop handles odd source dimensions"
}

test_rejects_crop_threshold_below_ffmpeg_minimum() {
  local input_path="$TEST_WORK_DIR/threshold-input.mp4"
  local output_path="$TEST_WORK_DIR/threshold-output.mp4"
  local error_output

  create_solid_video "$input_path" red 0.3
  if error_output=$("$SCRIPT_PATH" --resolution 180x180 --auto-crop \
    --crop-threshold 0.000001 --output "$output_path" "$input_path" 2>&1); then
    fail "crop thresholds below the FFmpeg minimum should be rejected"
  fi
  assert_contains "$error_output" "must be from 0.00001 to 1" "crop threshold range error is unclear"
  pass "crop threshold follows the FFmpeg supported range"
}

setup_work_dir
test_help
test_no_arguments_shows_help
test_rejects_two_inputs
test_single_input_is_duplicated_and_rotated_inward
test_four_inputs_are_assigned_and_webm_uses_shortest_duration
test_mov_export_format
test_rejects_layouts_that_can_overlap
test_existing_output_requires_force
test_output_cannot_replace_an_input
test_output_without_extension_defaults_to_mp4
test_cover_fills_each_square_slot
test_numeric_options_accept_leading_zeroes_as_decimal
test_rejects_oversized_numeric_values
test_relative_paths_with_option_or_protocol_prefixes
test_default_output_name_contains_timestamp
test_auto_crop_enlarges_a_small_foreground
test_auto_crop_preserves_white_foreground_on_black
test_auto_crop_ignores_crop_text_in_filename
test_auto_crop_scans_the_full_video
test_auto_crop_handles_odd_source_dimensions
test_rejects_crop_threshold_below_ffmpeg_minimum

echo "All $PASS_COUNT tests passed."
