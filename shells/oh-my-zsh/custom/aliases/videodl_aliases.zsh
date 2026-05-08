# Description: Videodl related aliases for video parsing and downloading with simple presets, diagnostics, and batch helpers.

# Helper functions for videodl aliases
_show_error_videodl_aliases() {
  echo "$1" >&2
  return 1
}

_check_command_videodl_aliases() {
  if ! command -v "$1" >/dev/null 2>&1; then
    _show_error_videodl_aliases "Error: Required command \"$1\" not found."
    return 1
  fi
  return 0
}

_validate_url_videodl_aliases() {
  if [ -z "$1" ]; then
    _show_error_videodl_aliases "Error: Missing video URL."
    return 1
  fi

  case "$1" in
    http://*|https://*)
      return 0
      ;;
    *)
      _show_error_videodl_aliases "Error: Invalid URL \"$1\". URL must start with http:// or https://."
      return 1
      ;;
  esac
}

_validate_file_videodl_aliases() {
  if [ -z "$1" ]; then
    _show_error_videodl_aliases "Error: Missing input file path."
    return 1
  fi

  if [ ! -f "$1" ]; then
    _show_error_videodl_aliases "Error: File \"$1\" does not exist."
    return 1
  fi

  return 0
}

_validate_threads_videodl_aliases() {
  if [ -z "$1" ]; then
    return 0
  fi

  case "$1" in
    *[!0-9]*|"")
      _show_error_videodl_aliases "Error: Thread count must be a positive integer."
      return 1
      ;;
    *)
      if [ "$1" -le 0 ]; then
        _show_error_videodl_aliases "Error: Thread count must be greater than 0."
        return 1
      fi
      ;;
  esac

  return 0
}

_resolve_output_dir_videodl_aliases() {
  local output_dir="$1"

  if [ -z "$output_dir" ]; then
    return 0
  fi

  if ! mkdir -p "$output_dir"; then
    _show_error_videodl_aliases "Error: Failed to create output directory \"$output_dir\"."
    return 1
  fi

  if ! (cd "$output_dir" >/dev/null 2>&1); then
    _show_error_videodl_aliases "Error: Failed to access output directory \"$output_dir\"."
    return 1
  fi

  (cd "$output_dir" >/dev/null 2>&1 && pwd)
}

_known_clients_csv_videodl_aliases() {
  local clients_csv=""

  if command -v python3 >/dev/null 2>&1; then
    clients_csv="$(python3 - <<\PY 2>/dev/null
try:
    from videodl.modules import VideoClientBuilder, CommonVideoClientBuilder
    clients = list(VideoClientBuilder.REGISTERED_MODULES.keys())
    clients += list(CommonVideoClientBuilder.REGISTERED_MODULES.keys())
    clients += ["WebMediaGrabber"]
    print(",".join(clients))
except Exception:
    print("")
PY
)"
  fi

  if [ -n "$clients_csv" ]; then
    echo "$clients_csv"
    return 0
  fi

  echo "AcFunVideoClient,BilibiliVideoClient,CCTVVideoClient,DouyinVideoClient,IQiyiVideoClient,KuaishouVideoClient,M1905VideoClient,MGTVVideoClient,RednoteVideoClient,TencentVideoClient,WeiboVideoClient,XiguaVideoClient,XinpianchangVideoClient,YoukuVideoClient,YouTubeVideoClient,AnyFetcherVideoClient,GVVideoClient,IM1907VideoClient,SnapAnyVideoClient,VideoFKVideoClient,WebMediaGrabber"
}

_build_work_dir_cfg_videodl_aliases() {
  local output_dir="$1"
  local clients_csv="$2"

  python3 - "$output_dir" "$clients_csv" <<\PY
import json
import sys

work_dir = sys.argv[1]
clients = [item.strip() for item in sys.argv[2].split(",") if item.strip()]
payload = {name: {"work_dir": work_dir} for name in clients}
print(json.dumps(payload, ensure_ascii=False))
PY
}

_build_requests_overrides_videodl_aliases() {
  local proxy_url="$1"
  local clients_csv="$2"

  python3 - "$proxy_url" "$clients_csv" <<\PY
import json
import sys

proxy_url = sys.argv[1]
clients = [item.strip() for item in sys.argv[2].split(",") if item.strip()]
payload = {
    name: {
        "proxies": {
            "http": proxy_url,
            "https": proxy_url,
        }
    }
    for name in clients
}
print(json.dumps(payload, ensure_ascii=False))
PY
}

_build_threadings_cfg_videodl_aliases() {
  local thread_count="$1"
  local clients_csv="$2"

  python3 - "$thread_count" "$clients_csv" <<\PY
import json
import sys

thread_count = int(sys.argv[1])
clients = [item.strip() for item in sys.argv[2].split(",") if item.strip()]
payload = {name: thread_count for name in clients}
print(json.dumps(payload, ensure_ascii=False))
PY
}

_extract_urls_from_text_videodl_aliases() {
  if command -v perl >/dev/null 2>&1; then
    perl -ne "while (m{https?://[A-Za-z0-9._~:/?#\\[\\]@!\\\$&()*+,;=%-]+}g) { my \$url = \$&; \$url =~ s/[),.;:!?，。！？；：、）】》」』’”]+\$//; print qq{\$url\\n} if length \$url; }"
    return 0
  fi

  if command -v python3 >/dev/null 2>&1; then
    python3 - <<\PY
import re
import sys

pattern = re.compile(r"https?://[A-Za-z0-9._~:/?#\[\]@!\$&()*+,;=%-]+")
tail_pattern = re.compile(r"[),.;:!?，。！？；：、）】》」』’”]+$")

for line in sys.stdin:
    for match in pattern.finditer(line):
        url = tail_pattern.sub("", match.group(0))
        if url:
            print(url)
PY
    return 0
  fi

  sed -nE "s#.*(https?://[^[:space:]，。！？；：、）】》」』’”<>\"[:cntrl:]]+).*#\\1#p" | sed -E "s/[),.;:!?]+$//"
}

_resolve_url_input_videodl_aliases() {
  local raw_input="$1"

  if [ -z "$raw_input" ]; then
    echo ""
    return 0
  fi

  local extracted_url=""
  extracted_url="$(printf "%s\n" "$raw_input" | _extract_urls_from_text_videodl_aliases | head -n 1)"

  if [ -n "$extracted_url" ]; then
    echo "$extracted_url"
    return 0
  fi

  echo "$raw_input"
}

_emit_parsed_download_options_videodl_aliases() {
  local raw_input="$1"
  local output_dir="$2"
  local proxy_url="$3"
  local thread_count="$4"
  shift 4
  local extra_args=("$@")

  printf "RAW_INPUT=%s\n" "$raw_input"
  printf "OUTPUT_DIR=%s\n" "$output_dir"
  printf "PROXY_URL=%s\n" "$proxy_url"
  printf "THREAD_COUNT=%s\n" "$thread_count"
  printf "__EXTRA_ARGS__\n"
  printf "%s\n" "${extra_args[@]}"
}

_parse_single_download_args_videodl_aliases() {
  local raw_input=""
  local output_dir=""
  local proxy_url=""
  local thread_count=""
  local extra_args=()
  local current_arg=""

  while [ $# -gt 0 ]; do
    current_arg="$1"
    case "$current_arg" in
      -d|--dir)
        if [ -z "$2" ]; then
          _show_error_videodl_aliases "Error: Missing output directory after $1."
          return 1
        fi
        output_dir="$2"
        shift 2
        ;;
      -p|--proxy)
        if [ -z "$2" ]; then
          _show_error_videodl_aliases "Error: Missing proxy URL after $1."
          return 1
        fi
        proxy_url="$2"
        shift 2
        ;;
      -t|--threads)
        if [ -z "$2" ]; then
          _show_error_videodl_aliases "Error: Missing thread count after $1."
          return 1
        fi
        thread_count="$2"
        shift 2
        ;;
      --)
        shift
        extra_args=("$@")
        break
        ;;
      *)
        if [ -z "$raw_input" ]; then
          raw_input="$current_arg"
        else
          raw_input="$raw_input $current_arg"
        fi
        shift
        ;;
    esac
  done

  _emit_parsed_download_options_videodl_aliases "$raw_input" "$output_dir" "$proxy_url" "$thread_count" "${extra_args[@]}"
}

_parse_download_options_videodl_aliases() {
  local output_dir=""
  local proxy_url=""
  local thread_count=""
  local extra_args=()

  while [ $# -gt 0 ]; do
    case "$1" in
      -d|--dir)
        if [ -z "$2" ]; then
          _show_error_videodl_aliases "Error: Missing output directory after $1."
          return 1
        fi
        output_dir="$2"
        shift 2
        ;;
      -p|--proxy)
        if [ -z "$2" ]; then
          _show_error_videodl_aliases "Error: Missing proxy URL after $1."
          return 1
        fi
        proxy_url="$2"
        shift 2
        ;;
      -t|--threads)
        if [ -z "$2" ]; then
          _show_error_videodl_aliases "Error: Missing thread count after $1."
          return 1
        fi
        thread_count="$2"
        shift 2
        ;;
      --)
        shift
        extra_args=("$@")
        break
        ;;
      -*)
        _show_error_videodl_aliases "Error: Unknown option \"$1\"."
        return 1
        ;;
      *)
        _show_error_videodl_aliases "Error: Unexpected argument \"$1\"."
        return 1
        ;;
    esac
  done

  _emit_parsed_download_options_videodl_aliases "" "$output_dir" "$proxy_url" "$thread_count" "${extra_args[@]}"
}

_read_parsed_download_options_videodl_aliases() {
  local parsed_args="$1"
  local raw_input=""
  local output_dir=""
  local proxy_url=""
  local thread_count=""
  local extra_args=()
  local parse_mode="header"
  local line=""

  while IFS= read -r line; do
    if [ "$line" = "__EXTRA_ARGS__" ]; then
      parse_mode="extra"
      continue
    fi

    if [ "$parse_mode" = "header" ]; then
      case "$line" in
        RAW_INPUT=*)
          raw_input="${line#RAW_INPUT=}"
          ;;
        OUTPUT_DIR=*)
          output_dir="${line#OUTPUT_DIR=}"
          ;;
        PROXY_URL=*)
          proxy_url="${line#PROXY_URL=}"
          ;;
        THREAD_COUNT=*)
          thread_count="${line#THREAD_COUNT=}"
          ;;
      esac
      continue
    fi

    [ -n "$line" ] && extra_args+=("$line")
  done <<< "$parsed_args"

  REPLY="$raw_input"
  typeset -g VDL_PARSED_RAW_INPUT="$raw_input"
  typeset -g VDL_PARSED_OUTPUT_DIR="$output_dir"
  typeset -g VDL_PARSED_PROXY_URL="$proxy_url"
  typeset -g VDL_PARSED_THREAD_COUNT="$thread_count"
  typeset -ga VDL_PARSED_EXTRA_ARGS
  VDL_PARSED_EXTRA_ARGS=("${extra_args[@]}")
}

_run_preset_videodl_aliases() {
  local allowed_sources="$1"
  local common_only="$2"
  shift 2

  local parsed_args=""
  parsed_args="$(_parse_single_download_args_videodl_aliases "$@")" || return 1
  _read_parsed_download_options_videodl_aliases "$parsed_args"

  _run_videodl_videodl_aliases "$VDL_PARSED_RAW_INPUT" "$allowed_sources" "$common_only" "$VDL_PARSED_OUTPUT_DIR" "$VDL_PARSED_PROXY_URL" "$VDL_PARSED_THREAD_COUNT" "${VDL_PARSED_EXTRA_ARGS[@]}"
}

_run_videodl_videodl_aliases() {
  local url="$1"
  local allowed_sources="$2"
  local common_only="$3"
  local output_dir="$4"
  local proxy_url="$5"
  local thread_count="$6"
  shift 6
  local extra_args=("$@")

  url="$(_resolve_url_input_videodl_aliases "$url")"
  _validate_url_videodl_aliases "$url" || return 1
  _check_command_videodl_aliases videodl || return 1

  local args=()
  args+=("-i" "$url")

  if [ -n "$allowed_sources" ]; then
    args+=("-a" "$allowed_sources")
  fi

  if [ "$common_only" = "true" ]; then
    args+=("-g")
  fi

  local needs_python_json=false
  if [ -n "$output_dir" ] || [ -n "$proxy_url" ] || [ -n "$thread_count" ]; then
    needs_python_json=true
  fi

  if [ "$needs_python_json" = "true" ]; then
    _check_command_videodl_aliases python3 || return 1
    local clients_csv="$allowed_sources"
    if [ -z "$clients_csv" ]; then
      clients_csv="$(_known_clients_csv_videodl_aliases)"
    fi

    if [ -n "$output_dir" ]; then
      local output_dir_abs=""
      output_dir_abs="$(_resolve_output_dir_videodl_aliases "$output_dir")" || return 1
      local work_dir_cfg=""
      work_dir_cfg="$(_build_work_dir_cfg_videodl_aliases "$output_dir_abs" "$clients_csv")" || {
        _show_error_videodl_aliases "Error: Failed to build videodl work_dir config."
        return 1
      }
      args+=("-c" "$work_dir_cfg")
    fi

    if [ -n "$proxy_url" ]; then
      local requests_cfg=""
      requests_cfg="$(_build_requests_overrides_videodl_aliases "$proxy_url" "$clients_csv")" || {
        _show_error_videodl_aliases "Error: Failed to build proxy config."
        return 1
      }
      args+=("-r" "$requests_cfg")
    fi

    if [ -n "$thread_count" ]; then
      _validate_threads_videodl_aliases "$thread_count" || return 1
      local threadings_cfg=""
      threadings_cfg="$(_build_threadings_cfg_videodl_aliases "$thread_count" "$clients_csv")" || {
        _show_error_videodl_aliases "Error: Failed to build threading config."
        return 1
      }
      args+=("-t" "$threadings_cfg")
    fi
  fi

  if [ ${#extra_args[@]} -gt 0 ]; then
    args+=("${extra_args[@]}")
  fi

  echo "videodl => $url"
  videodl "${args[@]}"
}

_run_videodl_batch_videodl_aliases() {
  local input_mode="$1"
  shift

  local input_file=""
  local allowed_sources=""
  local common_only="false"
  local output_dir=""
  local proxy_url=""
  local thread_count=""
  local extra_args=()
  local temp_urls_file=""

  _cleanup_temp_urls_file_videodl_aliases() {
    if [ -n "$temp_urls_file" ] && [ -f "$temp_urls_file" ]; then
      rm -f "$temp_urls_file"
    fi
  }

  if [ "$input_mode" = "file" ]; then
    input_file="$1"
    shift
    _validate_file_videodl_aliases "$input_file" || return 1
  fi

  while [ $# -gt 0 ]; do
    case "$1" in
      -a|--client)
        if [ -z "$2" ]; then
          _show_error_videodl_aliases "Error: Missing client name after $1."
          return 1
        fi
        allowed_sources="$2"
        shift 2
        ;;
      -g|--common)
        common_only="true"
        shift
        ;;
      -d|--dir)
        if [ -z "$2" ]; then
          _show_error_videodl_aliases "Error: Missing output directory after $1."
          return 1
        fi
        output_dir="$2"
        shift 2
        ;;
      -p|--proxy)
        if [ -z "$2" ]; then
          _show_error_videodl_aliases "Error: Missing proxy URL after $1."
          return 1
        fi
        proxy_url="$2"
        shift 2
        ;;
      -t|--threads)
        if [ -z "$2" ]; then
          _show_error_videodl_aliases "Error: Missing thread count after $1."
          return 1
        fi
        thread_count="$2"
        shift 2
        ;;
      --)
        shift
        extra_args=("$@")
        break
        ;;
      *)
        _show_error_videodl_aliases "Error: Unknown option \"$1\"."
        return 1
        ;;
    esac
  done

  temp_urls_file="$(mktemp)" || {
    _show_error_videodl_aliases "Error: Failed to create temporary file."
    return 1
  }

  if [ "$input_mode" = "file" ]; then
    cat "$input_file" | _extract_urls_from_text_videodl_aliases | awk "!seen[\$0]++" > "$temp_urls_file"
  else
    cat | _extract_urls_from_text_videodl_aliases | awk "!seen[\$0]++" > "$temp_urls_file"
  fi

  local url_count=""
  url_count="$(wc -l < "$temp_urls_file" | tr -d " ")"

  if [ -z "$url_count" ] || [ "$url_count" -eq 0 ]; then
    _cleanup_temp_urls_file_videodl_aliases
    _show_error_videodl_aliases "Error: No valid URLs found in batch input."
    return 1
  fi

  local current_index=0
  local success_count=0
  local failure_count=0
  local current_url=""

  while IFS= read -r current_url; do
    [ -z "$current_url" ] && continue
    current_index=$((current_index + 1))
    echo "[$current_index/$url_count] $current_url"
    if _run_videodl_videodl_aliases "$current_url" "$allowed_sources" "$common_only" "$output_dir" "$proxy_url" "$thread_count" "${extra_args[@]}"; then
      success_count=$((success_count + 1))
    else
      failure_count=$((failure_count + 1))
      echo "Warning: Failed to download \"$current_url\"." >&2
    fi
  done < "$temp_urls_file"

  _cleanup_temp_urls_file_videodl_aliases

  echo "Batch finished. Total: $url_count, Success: $success_count, Failed: $failure_count"

  if [ "$failure_count" -gt 0 ]; then
    return 1
  fi
  return 0
}

_vdl_help_videodl_aliases() {
  echo "Videodl aliases help"
  echo ""
  echo "Core:"
  echo "  vdl <url_or_share_text> [--dir DIR] [--proxy URL] [--threads N] [-- extra videodl args]"
  echo "  vdl-ui [extra videodl args]"
  echo "  vdl-client <client1[,client2]> <url_or_share_text> [--dir DIR] [--proxy URL] [--threads N] [-- extra args]"
  echo "  vdl-common <url_or_share_text> [--dir DIR] [--proxy URL] [--threads N] [-- extra args]"
  echo ""
  echo "Presets:"
  echo "  vdl-dy <url_or_share_text>      : Short-video preset via SnapAnyVideoClient"
  echo "  vdl-bili <url_or_share_text>    : Bilibili native client preset"
  echo "  vdl-film <url_or_share_text>    : Long-video preset via IM1907VideoClient"
  echo "  vdl-social <url_or_share_text>  : Social-media preset with multiple common parsers"
  echo ""
  echo "Batch:"
  echo "  vdl-batch <text_file> [--client CLIENTS] [--common] [--dir DIR] [--proxy URL] [--threads N] [-- extra args]"
  echo "  vdl-batch-stdin [--client CLIENTS] [--common] [--dir DIR] [--proxy URL] [--threads N] [-- extra args]"
  echo "  Single URL mode extracts the first URL from shared text. Batch mode extracts all URLs per line, removes duplicates, then downloads them one by one."
  echo ""
  echo "Utility:"
  echo "  vdl-doctor"
  echo "  vdl-help"
}

# Core aliases
alias vdl='() {
  if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo -e "Download a video with videodl.\nUsage:\n vdl <url_or_share_text> [--dir DIR] [--proxy URL] [--threads N] [-- extra videodl args]\n\nExamples:\n vdl \"https://www.bilibili.com/video/BV13x41117TL\"\n vdl \"8.99 复制打开抖音，看看... https://v.douyin.com/abc123/ ...\"\n vdl \"https://www.douyin.com/jingxuan?modal_id=7569541184671974899\" --dir ~/Downloads/videos\n vdl \"https://example.com/video\" --proxy http://127.0.0.1:7890 --threads 8 -- --version"
    return 0
  fi

  local parsed_args=""
  parsed_args="$(_parse_single_download_args_videodl_aliases "$@")" || return 1
  _read_parsed_download_options_videodl_aliases "$parsed_args"

  _run_videodl_videodl_aliases "$VDL_PARSED_RAW_INPUT" "" "false" "$VDL_PARSED_OUTPUT_DIR" "$VDL_PARSED_PROXY_URL" "$VDL_PARSED_THREAD_COUNT" "${VDL_PARSED_EXTRA_ARGS[@]}"
}' # Generic videodl wrapper

alias vdl-ui='() {
  if [ $# -gt 0 ] && { [ "$1" = "-h" ] || [ "$1" = "--help" ]; }; then
    echo -e "Start videodl interactive mode.\nUsage:\n vdl-ui [extra videodl args]"
    return 0
  fi

  _check_command_videodl_aliases videodl || return 1
  videodl "$@"
}' # Start videodl interactive mode

alias vdl-client='() {
  if [ $# -lt 2 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo -e "Download using specified videodl client names.\nUsage:\n vdl-client <client1[,client2]> <url_or_share_text> [--dir DIR] [--proxy URL] [--threads N] [-- extra args]\n\nExamples:\n vdl-client \"BilibiliVideoClient\" \"https://www.bilibili.com/video/BV13x41117TL\"\n vdl-client \"SnapAnyVideoClient\" \"8.99 复制打开抖音，看看... https://v.douyin.com/abc123/ ...\"\n vdl-client \"SnapAnyVideoClient,VideoFKVideoClient\" \"https://www.tiktok.com/@user/video/123\" --dir ~/Downloads"
    return 0
  fi

  local allowed_sources="$1"
  shift
  local parsed_args=""
  parsed_args="$(_parse_single_download_args_videodl_aliases "$@")" || return 1
  _read_parsed_download_options_videodl_aliases "$parsed_args"

  _run_videodl_videodl_aliases "$VDL_PARSED_RAW_INPUT" "$allowed_sources" "false" "$VDL_PARSED_OUTPUT_DIR" "$VDL_PARSED_PROXY_URL" "$VDL_PARSED_THREAD_COUNT" "${VDL_PARSED_EXTRA_ARGS[@]}"
}' # Download using specified client names

alias vdl-common='() {
  if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo -e "Download using common videodl parsers only.\nUsage:\n vdl-common <url_or_share_text> [--dir DIR] [--proxy URL] [--threads N] [-- extra args]\n\nExamples:\n vdl-common \"https://www.douyin.com/jingxuan?modal_id=7569541184671974899\"\n vdl-common \"8.99 复制打开抖音，看看... https://v.douyin.com/abc123/ ...\"\n vdl-common \"https://v.qq.com/x/cover/xxx.html\" --dir ~/Downloads"
    return 0
  fi

  local parsed_args=""
  parsed_args="$(_parse_single_download_args_videodl_aliases "$@")" || return 1
  _read_parsed_download_options_videodl_aliases "$parsed_args"

  _run_videodl_videodl_aliases "$VDL_PARSED_RAW_INPUT" "" "true" "$VDL_PARSED_OUTPUT_DIR" "$VDL_PARSED_PROXY_URL" "$VDL_PARSED_THREAD_COUNT" "${VDL_PARSED_EXTRA_ARGS[@]}"
}' # Download using common parsers only

# Preset aliases
alias vdl-dy='() {
  if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo -e "Short-video preset for Douyin, TikTok, Kuaishou, and Rednote style links.\nUsage:\n vdl-dy <url_or_share_text> [--dir DIR] [--proxy URL] [--threads N] [-- extra args]"
    return 0
  fi

  _run_preset_videodl_aliases "SnapAnyVideoClient" "true" "$@"
}' # Short-video preset via SnapAnyVideoClient

alias vdl-bili='() {
  if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo -e "Bilibili native preset.\nUsage:\n vdl-bili <url_or_share_text> [--dir DIR] [--proxy URL] [--threads N] [-- extra args]"
    return 0
  fi

  _run_preset_videodl_aliases "BilibiliVideoClient" "false" "$@"
}' # Bilibili preset

alias vdl-film='() {
  if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo -e "Long-video preset for common film and TV platforms.\nUsage:\n vdl-film <url_or_share_text> [--dir DIR] [--proxy URL] [--threads N] [-- extra args]"
    return 0
  fi

  _run_preset_videodl_aliases "IM1907VideoClient" "true" "$@"
}' # Long-video preset via IM1907VideoClient

alias vdl-social='() {
  if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo -e "Social-media preset with multiple common parsers.\nUsage:\n vdl-social <url_or_share_text> [--dir DIR] [--proxy URL] [--threads N] [-- extra args]"
    return 0
  fi

  _run_preset_videodl_aliases "SnapAnyVideoClient,VideoFKVideoClient,AnyFetcherVideoClient,GVVideoClient" "true" "$@"
}' # Social-media preset with fallback common parsers

# Batch aliases
alias vdl-batch='() {
  if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo -e "Batch download videodl links from a text file.\nUsage:\n vdl-batch <text_file> [--client CLIENTS] [--common] [--dir DIR] [--proxy URL] [--threads N] [-- extra args]\n\nExamples:\n vdl-batch urls.txt\n vdl-batch notes.txt --client \"BilibiliVideoClient\" --dir ~/Downloads/videos\n vdl-batch mixed.txt --common --proxy http://127.0.0.1:7890"
    return 0
  fi

  _run_videodl_batch_videodl_aliases "file" "$@"
}' # Batch download from a text file

alias vdl-batch-stdin='() {
  if [ $# -gt 0 ] && { [ "$1" = "-h" ] || [ "$1" = "--help" ]; }; then
    echo -e "Batch download videodl links from stdin.\nUsage:\n vdl-batch-stdin [--client CLIENTS] [--common] [--dir DIR] [--proxy URL] [--threads N] [-- extra args]\n\nExamples:\n cat urls.txt | vdl-batch-stdin\n rg -o \"https://[^ ]+\" notes.md | vdl-batch-stdin --common"
    return 0
  fi

  _run_videodl_batch_videodl_aliases "stdin" "$@"
}' # Batch download from stdin

# Utility aliases
alias vdl-doctor='() {
  echo "Check videodl runtime dependencies."
  echo "Usage:"
  echo " vdl-doctor"

  local has_error=false
  local dep_name=""

  for dep_name in python3 videodl ffmpeg; do
    if command -v "$dep_name" >/dev/null 2>&1; then
      echo "[OK] $dep_name => $(command -v "$dep_name")"
    else
      echo "[MISSING] $dep_name"
      has_error=true
    fi
  done

  for dep_name in N_m3u8DL-RE aria2c; do
    if command -v "$dep_name" >/dev/null 2>&1; then
      echo "[OK] $dep_name => $(command -v "$dep_name")"
    else
      echo "[RECOMMENDED] $dep_name"
    fi
  done

  if command -v videodl >/dev/null 2>&1; then
    videodl --version 2>/dev/null || true
  fi

  if [ "$has_error" = "true" ]; then
    echo "videodl doctor found required dependencies missing." >&2
    return 1
  fi
}' # Check videodl runtime dependencies

alias vdl-help='() {
  _vdl_help_videodl_aliases
}' # Show help for videodl aliases
