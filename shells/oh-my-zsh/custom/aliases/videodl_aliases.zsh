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
    python3 -c '
import re
import sys

pattern = re.compile(r"https?://[A-Za-z0-9._~:/?#\[\]@!\$&()*+,;=%-]+")
tail_pattern = re.compile(r"[),.;:!?，。！？；：、）】》」』’”]+$")

for line in sys.stdin:
    for match in pattern.finditer(line):
        url = tail_pattern.sub("", match.group(0))
        if url:
            print(url)
'
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

_extract_url_host_videodl_aliases() {
  local url="$1"
  local host="${url#*://}"
  host="${host%%/*}"
  host="${host%%\?*}"
  host="${host%%:*}"
  echo "$host"
}

_apply_auto_client_preferences_videodl_aliases() {
  local url="$1"
  local allowed_sources="$2"
  local common_only="$3"

  typeset -g VDL_EFFECTIVE_ALLOWED_SOURCES="$allowed_sources"
  typeset -g VDL_EFFECTIVE_COMMON_ONLY="$common_only"

  if [ -n "$allowed_sources" ] || [ "$common_only" = "true" ]; then
    return 0
  fi

  local url_host=""
  url_host="$(_extract_url_host_videodl_aliases "$url")"

  case "$url_host" in
    douyin.com|*.douyin.com|iesdouyin.com|*.iesdouyin.com|tiktok.com|*.tiktok.com|kuaishou.com|*.kuaishou.com|xiaohongshu.com|*.xiaohongshu.com|xhslink.com|*.xhslink.com|rednote.com|*.rednote.com)
      VDL_EFFECTIVE_ALLOWED_SOURCES="SnapAnyVideoClient"
      VDL_EFFECTIVE_COMMON_ONLY="true"
      ;;
  esac
}

_resolve_videodl_python_videodl_aliases() {
  _check_command_videodl_aliases videodl || return 1

  local videodl_path=""
  videodl_path="$(command -v videodl)"

  local shebang_line=""
  shebang_line="$(head -n 1 "$videodl_path" 2>/dev/null)"
  case "$shebang_line" in
    '#!'*)
      ;;
    *)
      _show_error_videodl_aliases "Error: Failed to resolve videodl Python interpreter from \"$videodl_path\"."
      return 1
      ;;
  esac

  local python_path="${shebang_line#\#!}"
  python_path="${python_path%% *}"

  if [ -z "$python_path" ] || [ ! -x "$python_path" ]; then
    _show_error_videodl_aliases "Error: Resolved videodl Python interpreter \"$python_path\" is not executable."
    return 1
  fi

  echo "$python_path"
}

_emit_parsed_download_options_videodl_aliases() {
  local raw_input="$1"
  local output_dir="$2"
  local proxy_url="$3"
  local thread_count="$4"
  local download_cover="$5"
  shift 5
  local extra_args=("$@")

  printf "RAW_INPUT=%s\n" "$raw_input"
  printf "OUTPUT_DIR=%s\n" "$output_dir"
  printf "PROXY_URL=%s\n" "$proxy_url"
  printf "THREAD_COUNT=%s\n" "$thread_count"
  printf "DOWNLOAD_COVER=%s\n" "$download_cover"
  printf "__EXTRA_ARGS__\n"
  printf "%s\n" "${extra_args[@]}"
}

_emit_parsed_query_options_videodl_aliases() {
  local raw_input="$1"
  local allowed_sources="$2"
  local common_only="$3"
  local output_dir="$4"
  local proxy_url="$5"
  local thread_count="$6"
  local output_format="$7"
  local include_cover="$8"

  printf "RAW_INPUT=%s\n" "$raw_input"
  printf "ALLOWED_SOURCES=%s\n" "$allowed_sources"
  printf "COMMON_ONLY=%s\n" "$common_only"
  printf "OUTPUT_DIR=%s\n" "$output_dir"
  printf "PROXY_URL=%s\n" "$proxy_url"
  printf "THREAD_COUNT=%s\n" "$thread_count"
  printf "OUTPUT_FORMAT=%s\n" "$output_format"
  printf "INCLUDE_COVER=%s\n" "$include_cover"
}

_parse_single_download_args_videodl_aliases() {
  local raw_input=""
  local output_dir=""
  local proxy_url=""
  local thread_count=""
  local download_cover="true"
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
      --no-cover)
        download_cover="false"
        shift
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

  _emit_parsed_download_options_videodl_aliases "$raw_input" "$output_dir" "$proxy_url" "$thread_count" "$download_cover" "${extra_args[@]}"
}

_parse_single_query_args_videodl_aliases() {
  local raw_input=""
  local allowed_sources=""
  local common_only="false"
  local output_dir=""
  local proxy_url=""
  local thread_count=""
  local output_format="plain"
  local include_cover="false"
  local current_arg=""

  while [ $# -gt 0 ]; do
    current_arg="$1"
    case "$current_arg" in
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
      -j|--json)
        output_format="json"
        shift
        ;;
      -m|--meta)
        output_format="meta"
        shift
        ;;
      --include-cover)
        include_cover="true"
        shift
        ;;
      -*)
        _show_error_videodl_aliases "Error: Unknown option \"$1\"."
        return 1
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

  _emit_parsed_query_options_videodl_aliases "$raw_input" "$allowed_sources" "$common_only" "$output_dir" "$proxy_url" "$thread_count" "$output_format" "$include_cover"
}

_parse_download_options_videodl_aliases() {
  local output_dir=""
  local proxy_url=""
  local thread_count=""
  local download_cover="true"
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
      --no-cover)
        download_cover="false"
        shift
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

  _emit_parsed_download_options_videodl_aliases "" "$output_dir" "$proxy_url" "$thread_count" "$download_cover" "${extra_args[@]}"
}

_read_parsed_download_options_videodl_aliases() {
  local parsed_args="$1"
  local raw_input=""
  local output_dir=""
  local proxy_url=""
  local thread_count=""
  local download_cover="true"
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
        DOWNLOAD_COVER=*)
          download_cover="${line#DOWNLOAD_COVER=}"
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
  typeset -g VDL_PARSED_DOWNLOAD_COVER="$download_cover"
  typeset -ga VDL_PARSED_EXTRA_ARGS
  VDL_PARSED_EXTRA_ARGS=("${extra_args[@]}")
}

_read_parsed_query_options_videodl_aliases() {
  local parsed_args="$1"
  local raw_input=""
  local allowed_sources=""
  local common_only="false"
  local output_dir=""
  local proxy_url=""
  local thread_count=""
  local output_format="plain"
  local include_cover="false"
  local line=""

  while IFS= read -r line; do
    case "$line" in
      RAW_INPUT=*)
        raw_input="${line#RAW_INPUT=}"
        ;;
      ALLOWED_SOURCES=*)
        allowed_sources="${line#ALLOWED_SOURCES=}"
        ;;
      COMMON_ONLY=*)
        common_only="${line#COMMON_ONLY=}"
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
      OUTPUT_FORMAT=*)
        output_format="${line#OUTPUT_FORMAT=}"
        ;;
      INCLUDE_COVER=*)
        include_cover="${line#INCLUDE_COVER=}"
        ;;
    esac
  done <<< "$parsed_args"

  typeset -g VDL_QUERY_RAW_INPUT="$raw_input"
  typeset -g VDL_QUERY_ALLOWED_SOURCES="$allowed_sources"
  typeset -g VDL_QUERY_COMMON_ONLY="$common_only"
  typeset -g VDL_QUERY_OUTPUT_DIR="$output_dir"
  typeset -g VDL_QUERY_PROXY_URL="$proxy_url"
  typeset -g VDL_QUERY_THREAD_COUNT="$thread_count"
  typeset -g VDL_QUERY_OUTPUT_FORMAT="$output_format"
  typeset -g VDL_QUERY_INCLUDE_COVER="$include_cover"
}

_run_preset_videodl_aliases() {
  local allowed_sources="$1"
  local common_only="$2"
  shift 2

  local parsed_args=""
  parsed_args="$(_parse_single_download_args_videodl_aliases "$@")" || return 1
  _read_parsed_download_options_videodl_aliases "$parsed_args"

  _run_videodl_videodl_aliases "$VDL_PARSED_RAW_INPUT" "$allowed_sources" "$common_only" "$VDL_PARSED_OUTPUT_DIR" "$VDL_PARSED_PROXY_URL" "$VDL_PARSED_THREAD_COUNT" "$VDL_PARSED_DOWNLOAD_COVER" "${VDL_PARSED_EXTRA_ARGS[@]}"
}

_run_videodl_videodl_aliases() {
  local url="$1"
  local allowed_sources="$2"
  local common_only="$3"
  local output_dir="$4"
  local proxy_url="$5"
  local thread_count="$6"
  local download_cover="$7"
  shift 7
  local extra_args=("$@")

  url="$(_resolve_url_input_videodl_aliases "$url")"
  _validate_url_videodl_aliases "$url" || return 1
  _check_command_videodl_aliases videodl || return 1
  _apply_auto_client_preferences_videodl_aliases "$url" "$allowed_sources" "$common_only"
  allowed_sources="$VDL_EFFECTIVE_ALLOWED_SOURCES"
  common_only="$VDL_EFFECTIVE_COMMON_ONLY"

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

  local cover_metadata_json=""
  if [ "$download_cover" = "true" ]; then
    cover_metadata_json="$(_run_videodl_url_query_videodl_aliases "$url" "$allowed_sources" "$common_only" "$output_dir" "$proxy_url" "$thread_count" "json-compact" "false" 2>/dev/null)" || cover_metadata_json=""
  fi

  echo "videodl => $url"
  if ! videodl "${args[@]}"; then
    return 1
  fi

  if [ "$download_cover" = "true" ] && [ -n "$cover_metadata_json" ]; then
    _download_videodl_covers_videodl_aliases "$cover_metadata_json" "$proxy_url" || true
  fi
}

_download_videodl_covers_videodl_aliases() {
  local metadata_json="$1"
  local proxy_url="$2"

  if [ -z "$metadata_json" ]; then
    return 0
  fi

  local videodl_python=""
  videodl_python="$(_resolve_videodl_python_videodl_aliases)" || return 1

  local metadata_file=""
  metadata_file="$(mktemp)" || {
    _show_error_videodl_aliases "Error: Failed to create temporary metadata file for cover download."
    return 1
  }
  trap 'rm -f "$metadata_file"' EXIT INT TERM
  printf "%s" "$metadata_json" > "$metadata_file"

  "$videodl_python" - "$metadata_file" "$proxy_url" <<\PY
import json
import mimetypes
import os
import shutil
import sys
import tempfile
import urllib.parse
import urllib.request


IMAGE_EXTS = {"jpg", "jpeg", "png", "webp", "gif", "bmp", "avif", "heic", "heif"}
CONTENT_TYPE_EXTS = {
    "image/jpeg": "jpg",
    "image/jpg": "jpg",
    "image/png": "png",
    "image/webp": "webp",
    "image/gif": "gif",
    "image/bmp": "bmp",
    "image/x-ms-bmp": "bmp",
    "image/avif": "avif",
    "image/heic": "heic",
    "image/heif": "heif",
}


def normalize_text(value):
    if value is None:
        return ""
    return str(value)


def infer_ext_from_url(url):
    path = urllib.parse.urlparse(url).path
    _, ext = os.path.splitext(path)
    ext = ext.lower().lstrip(".")
    return ext if ext in IMAGE_EXTS else ""


def infer_ext_from_headers(response):
    content_type = normalize_text(response.headers.get("Content-Type", "")).split(";")[0].strip().lower()
    if content_type in CONTENT_TYPE_EXTS:
        return CONTENT_TYPE_EXTS[content_type]
    guessed = mimetypes.guess_extension(content_type)
    if guessed:
        guessed = guessed.lower().lstrip(".")
        if guessed in IMAGE_EXTS:
            return guessed
    return ""


def infer_ext_from_file(file_path):
    with open(file_path, "rb") as handle:
        header = handle.read(32)
    if header.startswith(b"\x89PNG\r\n\x1a\n"):
        return "png"
    if header.startswith(b"\xff\xd8\xff"):
        return "jpg"
    if header[:6] in {b"GIF87a", b"GIF89a"}:
        return "gif"
    if header.startswith(b"BM"):
        return "bmp"
    if header.startswith(b"RIFF") and header[8:12] == b"WEBP":
        return "webp"
    if len(header) >= 12 and header[4:12] == b"ftypavif":
        return "avif"
    if len(header) >= 12 and header[4:12] in {b"ftypheic", b"ftypheif"}:
        return "heic"
    return ""


def derive_cover_base_path(item):
    save_path = normalize_text(item.get("save_path"))
    audio_save_path = normalize_text(item.get("audio_save_path"))
    base_path = save_path or audio_save_path
    if not base_path:
        return ""
    stem, _ = os.path.splitext(base_path)
    return stem + ".cover"


def should_download_cover(item):
    cover_url = normalize_text(item.get("cover_url"))
    if not cover_url:
        return False
    if not (normalize_text(item.get("download_url")) or normalize_text(item.get("audio_download_url"))):
        return False
    return bool(derive_cover_base_path(item))


def build_opener(proxy_url):
    handlers = []
    if proxy_url:
        handlers.append(urllib.request.ProxyHandler({"http": proxy_url, "https": proxy_url}))
    return urllib.request.build_opener(*handlers)


def download_cover(item, opener):
    cover_url = normalize_text(item.get("cover_url"))
    cover_base_path = derive_cover_base_path(item)
    if not cover_url or not cover_base_path:
        return ("skip", "")

    url_ext = infer_ext_from_url(cover_url)
    final_path = f"{cover_base_path}.{url_ext or 'jpg'}"
    if os.path.exists(final_path) and os.path.getsize(final_path) > 0:
        return ("exists", final_path)

    os.makedirs(os.path.dirname(final_path), exist_ok=True)

    headers = {"User-Agent": "Mozilla/5.0"}
    request = urllib.request.Request(cover_url, headers=headers)
    temp_handle = tempfile.NamedTemporaryFile(delete=False, dir=os.path.dirname(final_path), suffix=".cover.tmp")
    temp_handle.close()
    temp_path = temp_handle.name

    try:
        with opener.open(request, timeout=60) as response, open(temp_path, "wb") as output_handle:
            shutil.copyfileobj(response, output_handle)
            header_ext = infer_ext_from_headers(response)

        file_ext = infer_ext_from_file(temp_path)
        final_ext = url_ext or header_ext or file_ext or "jpg"
        final_path = f"{cover_base_path}.{final_ext}"

        if os.path.exists(final_path):
          os.remove(final_path)
        os.replace(temp_path, final_path)
        return ("downloaded", final_path)
    finally:
        if os.path.exists(temp_path):
            os.remove(temp_path)


with open(sys.argv[1], encoding="utf-8") as handle:
    items = json.load(handle)

proxy_url = normalize_text(sys.argv[2])
opener = build_opener(proxy_url)
printed_header = False

for item in items:
    if not should_download_cover(item):
        continue
    try:
        status, path = download_cover(item, opener)
    except Exception as exc:
        if not printed_header:
            print("Cover download results:")
            printed_header = True
        print(f"  warning: {normalize_text(item.get('title')) or normalize_text(item.get('identifier')) or item.get('cover_url')} -> {exc}")
        continue

    if status not in {"downloaded", "exists"}:
        continue
    if not printed_header:
        print("Cover download results:")
        printed_header = True
    action = "saved" if status == "downloaded" else "exists"
    print(f"  {action}: {path}")
PY
  local exit_code=$?
  rm -f "$metadata_file"
  trap - EXIT INT TERM
  return $exit_code
}

_run_videodl_url_query_videodl_aliases() {
  local url="$1"
  local allowed_sources="$2"
  local common_only="$3"
  local output_dir="$4"
  local proxy_url="$5"
  local thread_count="$6"
  local output_format="$7"
  local include_cover="$8"

  url="$(_resolve_url_input_videodl_aliases "$url")"
  _validate_url_videodl_aliases "$url" || return 1
  _check_command_videodl_aliases videodl || return 1
  _apply_auto_client_preferences_videodl_aliases "$url" "$allowed_sources" "$common_only"
  allowed_sources="$VDL_EFFECTIVE_ALLOWED_SOURCES"
  common_only="$VDL_EFFECTIVE_COMMON_ONLY"

  local videodl_python=""
  videodl_python="$(_resolve_videodl_python_videodl_aliases)" || return 1

  local clients_csv="$allowed_sources"
  if [ -z "$clients_csv" ]; then
    clients_csv="$(_known_clients_csv_videodl_aliases)"
  fi

  local init_cfg=""
  local requests_cfg=""
  local threadings_cfg=""

  if [ -n "$output_dir" ] || [ -n "$proxy_url" ] || [ -n "$thread_count" ]; then
    _check_command_videodl_aliases python3 || return 1
  fi

  if [ -n "$output_dir" ]; then
    local output_dir_abs=""
    output_dir_abs="$(_resolve_output_dir_videodl_aliases "$output_dir")" || return 1
    init_cfg="$(_build_work_dir_cfg_videodl_aliases "$output_dir_abs" "$clients_csv")" || {
      _show_error_videodl_aliases "Error: Failed to build videodl work_dir config."
      return 1
    }
  fi

  if [ -n "$proxy_url" ]; then
    requests_cfg="$(_build_requests_overrides_videodl_aliases "$proxy_url" "$clients_csv")" || {
      _show_error_videodl_aliases "Error: Failed to build proxy config."
      return 1
    }
  fi

  if [ -n "$thread_count" ]; then
    _validate_threads_videodl_aliases "$thread_count" || return 1
    threadings_cfg="$(_build_threadings_cfg_videodl_aliases "$thread_count" "$clients_csv")" || {
      _show_error_videodl_aliases "Error: Failed to build threading config."
      return 1
    }
  fi

  "$videodl_python" - "$url" "$allowed_sources" "$common_only" "$init_cfg" "$requests_cfg" "$threadings_cfg" "$output_format" "$include_cover" <<\PY
import json
import sys

from videodl.videodl import VideoClient


def normalize_url(value):
    if not value:
        return ""
    if isinstance(value, str):
        return value
    url_attr = getattr(value, "url", None)
    if isinstance(url_attr, str) and url_attr:
        return url_attr
    return str(value)


def load_json(value):
    return json.loads(value) if value else {}


def normalize_text(value):
    if value is None:
        return ""
    return str(value)


def normalize_http_url(value):
    normalized = normalize_url(value)
    if normalized.startswith(("http://", "https://")):
        return normalized
    return ""


def derive_cover_url(video_info):
    cover_url = normalize_http_url(getattr(video_info, "cover_url", ""))
    if cover_url:
        return cover_url

    raw_data = getattr(video_info, "raw_data", None)
    if not isinstance(raw_data, dict):
        return ""

    for key in ("preview_url", "cover_url", "thumbnail", "image", "poster"):
        candidate = normalize_http_url(raw_data.get(key))
        if candidate:
            return candidate

    medias = raw_data.get("medias")
    if not isinstance(medias, list):
        return ""

    media_preview_candidates = []
    for media in medias:
        if not isinstance(media, dict):
            continue
        media_type = normalize_text(media.get("media_type")).lower()
        if media_type == "image":
            for key in ("resource_url", "preview_url", "image", "thumbnail", "cover"):
                candidate = normalize_http_url(media.get(key))
                if candidate:
                    return candidate
        else:
            for key in ("preview_url", "image", "thumbnail", "cover"):
                candidate = normalize_http_url(media.get(key))
                if candidate:
                    media_preview_candidates.append(candidate)

    return media_preview_candidates[0] if media_preview_candidates else ""


def detect_media_kind(item):
    image_exts = {"jpg", "jpeg", "png", "webp", "gif", "bmp", "avif", "heic", "heif"}
    ext = normalize_text(item.get("ext")).lower().lstrip(".")
    if item.get("download_url") and ext in image_exts:
        return "image"
    if item.get("download_url") and item.get("audio_download_url"):
        return "video_with_audio"
    if item.get("download_url"):
        return "video"
    if item.get("audio_download_url"):
        return "audio_only"
    if item.get("cover_url"):
        return "cover_only"
    return "unknown"


index_url = sys.argv[1]
allowed_sources_csv = sys.argv[2]
common_only = sys.argv[3] == "true"
init_cfg = load_json(sys.argv[4])
requests_overrides = load_json(sys.argv[5])
clients_threadings = load_json(sys.argv[6])
output_format = sys.argv[7]
include_cover = sys.argv[8] == "true"

allowed_sources = [item.strip() for item in allowed_sources_csv.split(",") if item.strip()]
video_client = VideoClient(
    allowed_video_sources=allowed_sources,
    init_video_clients_cfg=init_cfg,
    clients_threadings=clients_threadings,
    requests_overrides=requests_overrides,
    apply_common_video_clients_only=common_only,
)

video_infos = video_client.parsefromurl(url=index_url) or []
items = []

for video_info in video_infos:
    item = {
        "source": normalize_text(getattr(video_info, "source", "")),
        "title": normalize_text(getattr(video_info, "title", "")),
        "download_url": normalize_url(getattr(video_info, "download_url", "")),
        "audio_download_url": normalize_url(getattr(video_info, "audio_download_url", "")),
        "ext": normalize_text(getattr(video_info, "ext", "")),
        "audio_ext": normalize_text(getattr(video_info, "audio_ext", "")),
        "cover_url": derive_cover_url(video_info),
        "identifier": normalize_text(getattr(video_info, "identifier", "")),
        "save_path": normalize_text(getattr(video_info, "save_path", "")),
        "audio_save_path": normalize_text(getattr(video_info, "audio_save_path", "")),
        "download_with_ffmpeg": bool(getattr(video_info, "download_with_ffmpeg", False)),
        "enable_nm3u8dlre": getattr(video_info, "enable_nm3u8dlre", None),
    }
    item["media_kind"] = detect_media_kind(item)
    if item["download_url"] or item["audio_download_url"] or item["cover_url"]:
        items.append(item)

if not items:
    print(f"Error: No downloadable or cover resources resolved for {index_url}.", file=sys.stderr)
    sys.exit(1)

if output_format == "json":
    print(json.dumps(items, ensure_ascii=False, indent=2))
    sys.exit(0)

if output_format == "json-compact":
    print(json.dumps(items, ensure_ascii=False))
    sys.exit(0)

if output_format == "meta":
    for idx, item in enumerate(items, start=1):
        print(f"[{idx}] media_kind={item['media_kind']} source={item['source']} title={item['title']}")
        if item["download_url"]:
            print(f"download_url={item['download_url']}")
        if item["audio_download_url"]:
            print(f"audio_download_url={item['audio_download_url']}")
        if item["cover_url"]:
            print(f"cover_url={item['cover_url']}")
        if item["ext"]:
            print(f"ext={item['ext']}")
        if item["audio_ext"] and item["audio_download_url"]:
            print(f"audio_ext={item['audio_ext']}")
        if item["save_path"]:
            print(f"save_path={item['save_path']}")
        if item["audio_save_path"] and item["audio_download_url"]:
            print(f"audio_save_path={item['audio_save_path']}")
    sys.exit(0)

seen = set()
for item in items:
    emit_urls = []
    if item["download_url"]:
        emit_urls.append(item["download_url"])
    elif item["cover_url"]:
        emit_urls.append(item["cover_url"])
    elif item["audio_download_url"]:
        emit_urls.append(item["audio_download_url"])

    if include_cover and item["cover_url"] and item["cover_url"] not in emit_urls:
        emit_urls.append(item["cover_url"])

    for current_url in emit_urls:
        if current_url in seen:
            continue
        print(current_url)
        seen.add(current_url)
PY
}

_run_videodl_url_query_batch_videodl_aliases() {
  local input_mode="$1"
  shift

  local input_file=""
  local allowed_sources=""
  local common_only="false"
  local output_dir=""
  local proxy_url=""
  local thread_count=""
  local output_format="plain"
  local include_cover="false"

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
      -j|--json)
        output_format="json"
        shift
        ;;
      -m|--meta)
        output_format="meta"
        shift
        ;;
      --include-cover)
        include_cover="true"
        shift
        ;;
      *)
        _show_error_videodl_aliases "Error: Unknown option \"$1\"."
        return 1
        ;;
    esac
  done

  (
    local temp_urls_file=""
    local temp_jsonl_file=""
    local temp_error_file=""
    temp_urls_file="$(mktemp)" || {
      _show_error_videodl_aliases "Error: Failed to create temporary file."
      exit 1
    }
    temp_jsonl_file="$(mktemp)" || {
      rm -f "$temp_urls_file"
      _show_error_videodl_aliases "Error: Failed to create temporary JSON file."
      exit 1
    }
    temp_error_file="$(mktemp)" || {
      rm -f "$temp_urls_file" "$temp_jsonl_file"
      _show_error_videodl_aliases "Error: Failed to create temporary error file."
      exit 1
    }
    trap 'rm -f "$temp_urls_file" "$temp_jsonl_file" "$temp_error_file"' EXIT INT TERM

    if [ "$input_mode" = "file" ]; then
      cat "$input_file" | _extract_urls_from_text_videodl_aliases | awk "!seen[\$0]++" > "$temp_urls_file"
    else
      cat | _extract_urls_from_text_videodl_aliases | awk "!seen[\$0]++" > "$temp_urls_file"
    fi

    local url_count=""
    url_count="$(wc -l < "$temp_urls_file" | tr -d " ")"

    if [ -z "$url_count" ] || [ "$url_count" -eq 0 ]; then
      _show_error_videodl_aliases "Error: No valid URLs found in batch input."
      exit 1
    fi

    local current_index=0
    local success_count=0
    local failure_count=0
    local current_url=""
    local query_output=""
    local error_message=""
    local json_entry=""

    while IFS= read -r current_url; do
      [ -z "$current_url" ] && continue
      current_index=$((current_index + 1))
      : > "$temp_error_file"

      if query_output="$(_run_videodl_url_query_videodl_aliases "$current_url" "$allowed_sources" "$common_only" "$output_dir" "$proxy_url" "$thread_count" "$([ "$output_format" = "json" ] && echo "json-compact" || echo "$output_format")" "$include_cover" 2>"$temp_error_file")"; then
        success_count=$((success_count + 1))
        if [ "$output_format" = "json" ]; then
          json_entry="$(python3 - "$current_url" "$query_output" <<\PY
import json
import sys

input_url = sys.argv[1]
results = json.loads(sys.argv[2])
print(json.dumps({
    "input_url": input_url,
    "success": True,
    "results": results,
}, ensure_ascii=False))
PY
)"
          printf "%s\n" "$json_entry" >> "$temp_jsonl_file"
        else
          echo "[$current_index/$url_count] $current_url"
          while IFS= read -r output_line; do
            [ -n "$output_line" ] && printf "  %s\n" "$output_line"
          done <<< "$query_output"
        fi
      else
        failure_count=$((failure_count + 1))
        error_message="$(tr '\n' ' ' < "$temp_error_file" | sed -E 's/[[:space:]]+/ /g; s/^ //; s/ $//')"
        [ -z "$error_message" ] && error_message="Unknown error."

        if [ "$output_format" = "json" ]; then
          json_entry="$(python3 - "$current_url" "$error_message" <<\PY
import json
import sys

print(json.dumps({
    "input_url": sys.argv[1],
    "success": False,
    "error": sys.argv[2],
    "results": [],
}, ensure_ascii=False))
PY
)"
          printf "%s\n" "$json_entry" >> "$temp_jsonl_file"
        else
          echo "[$current_index/$url_count] $current_url"
          echo "  Error: $error_message" >&2
        fi
      fi
    done < "$temp_urls_file"

    if [ "$output_format" = "json" ]; then
      python3 - "$temp_jsonl_file" "$url_count" "$success_count" "$failure_count" <<\PY
import json
import sys

items = []
with open(sys.argv[1], encoding="utf-8") as handle:
    for line in handle:
        line = line.strip()
        if line:
            items.append(json.loads(line))

print(json.dumps({
    "total": int(sys.argv[2]),
    "success": int(sys.argv[3]),
    "failed": int(sys.argv[4]),
    "items": items,
}, ensure_ascii=False, indent=2))
PY
    else
      echo "Batch finished. Total: $url_count, Success: $success_count, Failed: $failure_count"
    fi

    if [ "$failure_count" -gt 0 ]; then
      exit 1
    fi
    exit 0
  )
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
  local download_cover="true"
  local extra_args=()

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
      --no-cover)
        download_cover="false"
        shift
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

  (
    local temp_urls_file=""
    temp_urls_file="$(mktemp)" || {
      _show_error_videodl_aliases "Error: Failed to create temporary file."
      exit 1
    }
    trap 'rm -f "$temp_urls_file"' EXIT INT TERM

    if [ "$input_mode" = "file" ]; then
      cat "$input_file" | _extract_urls_from_text_videodl_aliases | awk "!seen[\$0]++" > "$temp_urls_file"
    else
      cat | _extract_urls_from_text_videodl_aliases | awk "!seen[\$0]++" > "$temp_urls_file"
    fi

    local url_count=""
    url_count="$(wc -l < "$temp_urls_file" | tr -d " ")"

    if [ -z "$url_count" ] || [ "$url_count" -eq 0 ]; then
      _show_error_videodl_aliases "Error: No valid URLs found in batch input."
      exit 1
    fi

    local current_index=0
    local success_count=0
    local failure_count=0
    local current_url=""

    while IFS= read -r current_url; do
      [ -z "$current_url" ] && continue
      current_index=$((current_index + 1))
      echo "[$current_index/$url_count] $current_url"
      if _run_videodl_videodl_aliases "$current_url" "$allowed_sources" "$common_only" "$output_dir" "$proxy_url" "$thread_count" "$download_cover" "${extra_args[@]}"; then
        success_count=$((success_count + 1))
      else
        failure_count=$((failure_count + 1))
        echo "Warning: Failed to download \"$current_url\"." >&2
      fi
    done < "$temp_urls_file"

    echo "Batch finished. Total: $url_count, Success: $success_count, Failed: $failure_count"

    if [ "$failure_count" -gt 0 ]; then
      exit 1
    fi
    exit 0
  )
}

_vdl_help_videodl_aliases() {
  echo "Videodl aliases help"
  echo ""
  echo "Core:"
  echo "  vdl <url_or_share_text> [--dir DIR] [--proxy URL] [--threads N] [--no-cover] [-- extra videodl args]"
  echo "  vdl-ui [extra videodl args]"
  echo "  vdl-url <url_or_share_text> [--client CLIENTS] [--common] [--dir DIR] [--proxy URL] [--threads N] [--json|--meta] [--include-cover]"
  echo "  vdl-url-batch <text_file> [--client CLIENTS] [--common] [--dir DIR] [--proxy URL] [--threads N] [--json|--meta] [--include-cover]"
  echo "  vdl-url-batch-stdin [--client CLIENTS] [--common] [--dir DIR] [--proxy URL] [--threads N] [--json|--meta] [--include-cover]"
  echo "  vdl-client <client1[,client2]> <url_or_share_text> [--dir DIR] [--proxy URL] [--threads N] [--no-cover] [-- extra args]"
  echo "  vdl-common <url_or_share_text> [--dir DIR] [--proxy URL] [--threads N] [--no-cover] [-- extra args]"
  echo "  vdl-url can expose media_kind, cover_url, and audio_download_url; some results may be m3u8, cover-only, or ffmpeg-oriented resources."
  echo "  Download aliases save related video covers by default; use --no-cover to disable the extra cover fetch step."
  echo "  Generic vdl/vdl-batch commands auto prefer SnapAnyVideoClient for Douyin/TikTok/Kuaishou/Rednote links unless you explicitly pass --client or --common."
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
    echo -e "Download a video with videodl.\nUsage:\n vdl <url_or_share_text> [--dir DIR] [--proxy URL] [--threads N] [--no-cover] [-- extra videodl args]\n\nExamples:\n vdl \"https://www.bilibili.com/video/BV13x41117TL\"\n vdl \"8.99 复制打开抖音，看看... https://v.douyin.com/abc123/ ...\"\n vdl \"https://www.douyin.com/jingxuan?modal_id=7569541184671974899\" --dir ~/Downloads/videos\n vdl \"https://example.com/video\" --proxy http://127.0.0.1:7890 --threads 8 --no-cover -- --version\n\nNotes:\n Download aliases save the related video cover in the same directory by default.\n Generic mode auto prefers SnapAnyVideoClient for Douyin/TikTok/Kuaishou/Rednote links unless you explicitly pass --client or --common."
    return 0
  fi

  local parsed_args=""
  parsed_args="$(_parse_single_download_args_videodl_aliases "$@")" || return 1
  _read_parsed_download_options_videodl_aliases "$parsed_args"

  _run_videodl_videodl_aliases "$VDL_PARSED_RAW_INPUT" "" "false" "$VDL_PARSED_OUTPUT_DIR" "$VDL_PARSED_PROXY_URL" "$VDL_PARSED_THREAD_COUNT" "$VDL_PARSED_DOWNLOAD_COVER" "${VDL_PARSED_EXTRA_ARGS[@]}"
}' # Generic videodl wrapper

alias vdl-ui='() {
  if [ $# -gt 0 ] && { [ "$1" = "-h" ] || [ "$1" = "--help" ]; }; then
    echo -e "Start videodl interactive mode.\nUsage:\n vdl-ui [extra videodl args]"
    return 0
  fi

  _check_command_videodl_aliases videodl || return 1
  videodl "$@"
}' # Start videodl interactive mode

alias vdl-url='() {
  if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo -e "Resolve parsed media resources with videodl without downloading.\nUsage:\n vdl-url <url_or_share_text> [--client CLIENTS] [--common] [--dir DIR] [--proxy URL] [--threads N] [--json|--meta] [--include-cover]\n\nExamples:\n vdl-url \"https://www.bilibili.com/video/BV13x41117TL\"\n vdl-url \"8.99 复制打开抖音，看看... https://v.douyin.com/abc123/ ...\" --client \"SnapAnyVideoClient\" --meta\n vdl-url \"https://example.com/video\" --proxy http://127.0.0.1:7890 --json\n\nNotes:\n JSON output includes media_kind. Plain output defaults to the main downloadable resource, falls back to cover_url when only cover data exists, and can optionally append cover_url with --include-cover."
    return 0
  fi

  local parsed_args=""
  parsed_args="$(_parse_single_query_args_videodl_aliases "$@")" || return 1
  _read_parsed_query_options_videodl_aliases "$parsed_args"

  _run_videodl_url_query_videodl_aliases "$VDL_QUERY_RAW_INPUT" "$VDL_QUERY_ALLOWED_SOURCES" "$VDL_QUERY_COMMON_ONLY" "$VDL_QUERY_OUTPUT_DIR" "$VDL_QUERY_PROXY_URL" "$VDL_QUERY_THREAD_COUNT" "$VDL_QUERY_OUTPUT_FORMAT" "$VDL_QUERY_INCLUDE_COVER"
}' # Resolve parsed download URLs only

alias vdl-url-batch='() {
  if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo -e "Batch resolve parsed media resources from a text file.\nUsage:\n vdl-url-batch <text_file> [--client CLIENTS] [--common] [--dir DIR] [--proxy URL] [--threads N] [--json|--meta] [--include-cover]\n\nExamples:\n vdl-url-batch urls.txt\n vdl-url-batch notes.txt --client \"BilibiliVideoClient\" --json\n vdl-url-batch mixed.txt --common --proxy http://127.0.0.1:7890 --meta\n\nNotes:\n The batch command extracts all URLs from the input, removes duplicates, then resolves each URL without downloading. JSON output aggregates per-input results with media_kind metadata."
    return 0
  fi

  _run_videodl_url_query_batch_videodl_aliases "file" "$@"
}' # Batch resolve parsed download URLs from a text file

alias vdl-url-batch-stdin='() {
  if [ $# -gt 0 ] && { [ "$1" = "-h" ] || [ "$1" = "--help" ]; }; then
    echo -e "Batch resolve parsed media resources from stdin.\nUsage:\n vdl-url-batch-stdin [--client CLIENTS] [--common] [--dir DIR] [--proxy URL] [--threads N] [--json|--meta] [--include-cover]\n\nExamples:\n cat urls.txt | vdl-url-batch-stdin\n rg -o \"https://[^ ]+\" notes.md | vdl-url-batch-stdin --json\n printf \"share https://example.com/video\" | vdl-url-batch-stdin --common --meta"
    return 0
  fi

  _run_videodl_url_query_batch_videodl_aliases "stdin" "$@"
}' # Batch resolve parsed download URLs from stdin

alias vdl-client='() {
  if [ $# -lt 2 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo -e "Download using specified videodl client names.\nUsage:\n vdl-client <client1[,client2]> <url_or_share_text> [--dir DIR] [--proxy URL] [--threads N] [--no-cover] [-- extra args]\n\nExamples:\n vdl-client \"BilibiliVideoClient\" \"https://www.bilibili.com/video/BV13x41117TL\"\n vdl-client \"SnapAnyVideoClient\" \"8.99 复制打开抖音，看看... https://v.douyin.com/abc123/ ...\"\n vdl-client \"SnapAnyVideoClient,VideoFKVideoClient\" \"https://www.tiktok.com/@user/video/123\" --dir ~/Downloads"
    return 0
  fi

  local allowed_sources="$1"
  shift
  local parsed_args=""
  parsed_args="$(_parse_single_download_args_videodl_aliases "$@")" || return 1
  _read_parsed_download_options_videodl_aliases "$parsed_args"

  _run_videodl_videodl_aliases "$VDL_PARSED_RAW_INPUT" "$allowed_sources" "false" "$VDL_PARSED_OUTPUT_DIR" "$VDL_PARSED_PROXY_URL" "$VDL_PARSED_THREAD_COUNT" "$VDL_PARSED_DOWNLOAD_COVER" "${VDL_PARSED_EXTRA_ARGS[@]}"
}' # Download using specified client names

alias vdl-common='() {
  if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo -e "Download using common videodl parsers only.\nUsage:\n vdl-common <url_or_share_text> [--dir DIR] [--proxy URL] [--threads N] [--no-cover] [-- extra args]\n\nExamples:\n vdl-common \"https://www.douyin.com/jingxuan?modal_id=7569541184671974899\"\n vdl-common \"8.99 复制打开抖音，看看... https://v.douyin.com/abc123/ ...\"\n vdl-common \"https://v.qq.com/x/cover/xxx.html\" --dir ~/Downloads"
    return 0
  fi

  local parsed_args=""
  parsed_args="$(_parse_single_download_args_videodl_aliases "$@")" || return 1
  _read_parsed_download_options_videodl_aliases "$parsed_args"

  _run_videodl_videodl_aliases "$VDL_PARSED_RAW_INPUT" "" "true" "$VDL_PARSED_OUTPUT_DIR" "$VDL_PARSED_PROXY_URL" "$VDL_PARSED_THREAD_COUNT" "$VDL_PARSED_DOWNLOAD_COVER" "${VDL_PARSED_EXTRA_ARGS[@]}"
}' # Download using common parsers only

# Preset aliases
alias vdl-dy='() {
  if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo -e "Short-video preset for Douyin, TikTok, Kuaishou, and Rednote style links.\nUsage:\n vdl-dy <url_or_share_text> [--dir DIR] [--proxy URL] [--threads N] [--no-cover] [-- extra args]"
    return 0
  fi

  _run_preset_videodl_aliases "SnapAnyVideoClient" "true" "$@"
}' # Short-video preset via SnapAnyVideoClient

alias vdl-bili='() {
  if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo -e "Bilibili native preset.\nUsage:\n vdl-bili <url_or_share_text> [--dir DIR] [--proxy URL] [--threads N] [--no-cover] [-- extra args]"
    return 0
  fi

  _run_preset_videodl_aliases "BilibiliVideoClient" "false" "$@"
}' # Bilibili preset

alias vdl-film='() {
  if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo -e "Long-video preset for common film and TV platforms.\nUsage:\n vdl-film <url_or_share_text> [--dir DIR] [--proxy URL] [--threads N] [--no-cover] [-- extra args]"
    return 0
  fi

  _run_preset_videodl_aliases "IM1907VideoClient" "true" "$@"
}' # Long-video preset via IM1907VideoClient

alias vdl-social='() {
  if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo -e "Social-media preset with multiple common parsers.\nUsage:\n vdl-social <url_or_share_text> [--dir DIR] [--proxy URL] [--threads N] [--no-cover] [-- extra args]"
    return 0
  fi

  _run_preset_videodl_aliases "SnapAnyVideoClient,VideoFKVideoClient,AnyFetcherVideoClient,GVVideoClient" "true" "$@"
}' # Social-media preset with fallback common parsers

# Batch aliases
alias vdl-batch='() {
  if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo -e "Batch download videodl links from a text file.\nUsage:\n vdl-batch <text_file> [--client CLIENTS] [--common] [--dir DIR] [--proxy URL] [--threads N] [--no-cover] [-- extra args]\n\nExamples:\n vdl-batch urls.txt\n vdl-batch notes.txt --client \"BilibiliVideoClient\" --dir ~/Downloads/videos\n vdl-batch mixed.txt --common --proxy http://127.0.0.1:7890"
    return 0
  fi

  _run_videodl_batch_videodl_aliases "file" "$@"
}' # Batch download from a text file

alias vdl-batch-stdin='() {
  if [ $# -gt 0 ] && { [ "$1" = "-h" ] || [ "$1" = "--help" ]; }; then
    echo -e "Batch download videodl links from stdin.\nUsage:\n vdl-batch-stdin [--client CLIENTS] [--common] [--dir DIR] [--proxy URL] [--threads N] [--no-cover] [-- extra args]\n\nExamples:\n cat urls.txt | vdl-batch-stdin\n rg -o \"https://[^ ]+\" notes.md | vdl-batch-stdin --common"
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
