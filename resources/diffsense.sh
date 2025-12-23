#!/bin/bash

# =========================================
# diffsense — AI-powered git commit generator
# =========================================

# ---------- noise patterns for diff filtering ----------
NOISE_PATTERNS=(
  # Package / lock files
  "yarn.lock"
  "package-lock.json"
  "pnpm-lock.yaml"
  "npm-shrinkwrap.json"
  "Cargo.lock"
  "Pipfile.lock"
  "poetry.lock"
  "composer.lock"
  "Gemfile.lock"
  "go.sum"
  "mix.lock"
  "Podfile.lock"
  "packages.lock.json"

  # Dependency / vendor directories
  "node_modules/"
  "vendor/"
  "Pods/"
  ".venv/"
  "venv/"
  ".pipenv/"
  ".m2/"
  "target/"
  "packages/"
  "deps/"

  # Build / dist / cache dirs
  "dist/"
  "build/"
  "out/"
  "bin/"
  "obj/"
  ".next/"
  ".nuxt/"
  ".angular/"
  ".svelte-kit/"
  ".cache/"
  ".turbo/"
  ".parcel-cache/"
  ".rollup-cache/"
  ".vite/"
  ".gradle/"
  "DerivedData/"

  # Coverage / reports
  "coverage/"
  "htmlcov/"
  "lcov-report/"
  "coverage-final.json"
  "jacoco.exec"

  # Logs / temp / misc
  "logs/"
  "log/"
  "*.log"
  "*.tmp"
  "*.temp"

  # Binary / media assets
  "*.png"
  "*.jpg"
  "*.jpeg"
  "*.gif"
  "*.svg"
  "*.ico"
  "*.webp"
  "*.bmp"
  "*.tiff"
  "*.psd"
  "*.ai"
  "*.sketch"
  "*.fig"
  "*.pdf"
  "*.mp3"
  "*.wav"
  "*.ogg"
  "*.flac"
  "*.mp4"
  "*.mov"
  "*.avi"
  "*.mkv"

  # Fonts
  "*.ttf"
  "*.otf"
  "*.woff"
  "*.woff2"

  # Archives / bundles
  "*.zip"
  "*.tar"
  "*.tar.gz"
  "*.tgz"
  "*.rar"
  "*.7z"

  # IDE / editor / tooling artifacts
  ".idea/"
  ".vscode/"
  ".vs/"
  ".DS_Store"
  "*.iml"

  # Data dumps / DBs
  "*.csv"
  "*.tsv"
  "*.sqlite"
  "*.db"
  "*.mdb"
  "*.bak"
  "*.bak.*"

  # Compiled artifacts
  "*.class"
  "*.jar"
  "*.war"
  "*.ear"
  "*.dll"
  "*.exe"
  "*.so"
  "*.dylib"
  "*.o"
  "*.obj"
  "*.a"
  "*.lib"
)
set_max_chars_for_model() {
  local model="$1"

  case "$model" in
    LOCAL)
      DIFFSENSE_MAX_CHARS=13144
      ;;
    PRIVATE)
      DIFFSENSE_MAX_CHARS=256000
      ;;
    CHATGPT)
      DIFFSENSE_MAX_CHARS=1194000
      ;;
    *)
      # Fallback (should not happen): keep a safe small default
      DIFFSENSE_MAX_CHARS=10000
      ;;
  esac

}

# ---------- help ----------
print_help() {
  cat <<'EOF'
Usage: diffsense [MESSAGE STYLE] [AI MODEL] [OPTIONS]

STYLE:
  default           Default style. Works when nothing is specified
  verbose           Detailed multi-line commit message
  minimal           Single-line, 72-char max subject

MODEL:
  afm               On-device (LOCAL) model. [DEFAULT MODEL]
  pcc               Perplexity (PRIVATE) model
  gpt               ChatGPT / OpenAI model

OPTIONS:
  --nopopup         Disable popup editor in the Shortcut
  -h, --help        Show this help message and exit

Examples:
  diffsense
  diffsense --verbose
  diffsense --verbose --gpt
  diffsense --nopopup
  diffsense --minimal --nopopup
EOF
}

# ---------- parse CLI args ----------
parse_args() {
  local message_style="default"
  local ai_model="afm"
  local nopopup_suffix=""
  
  # Iterate over all provided arguments
  for raw_arg in "$@"; do
    # Remove leading dashes (e.g., --verbose -> verbose) to support both formats
    local arg="${raw_arg#--}"

    case "$arg" in

      # Message Styles
      default|verbose|minimal)
        message_style="$arg"
        ;;
      
      # AI Models
      afm|pcc|gpt)
        ai_model="$arg"
        ;;
      
      # Special Flag
      nopopup)
        nopopup_suffix="_NOPOPUP"
        ;;
      
      *)
        echo "❌ Error: Command '$raw_arg' does not exist." >&2
        return 1
        ;;
    esac
  done

  # Internal Mapping
  local ai_model_internal
  case "$ai_model" in
    afm) ai_model_internal="LOCAL" ;;
    pcc) ai_model_internal="PRIVATE" ;;
    gpt) ai_model_internal="CHATGPT" ;;
  esac

  echo "$ai_model_internal $message_style $nopopup_suffix"
}

# ---------- platform ----------
check_platform_and_arch() {
  local arch os_major
  arch=$(uname -m)

  if [[ "$arch" != "arm64" ]]; then
    echo "❌ diffsense requires Apple Silicon (M-series Macs)."
    return 1
  fi

  os_major=$(sw_vers -productVersion | cut -d. -f1)
  # STRICT REQUIREMENT: Only work on macOS 26+
  if (( os_major < 26 )); then
    echo "❌ diffsense requires macOS 26 or newer."
    echo "   Current version: $(sw_vers -productVersion)"
    return 1
  fi
}

# ---------- git validation ----------
check_is_git_repo() {
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "❌ Not inside a git repository."
    exit 1
  fi
}

# ---------- git state ----------
check_git_state() {
  local staged unstaged
  staged=$(git diff --cached --name-only)
  unstaged=$(git diff --name-only)

  if [[ -z "$staged" && -z "$unstaged" ]]; then
    echo "ℹ️ No changes to commit."
    exit 0
  fi

  if [[ -z "$staged" && -n "$unstaged" ]]; then
    echo "ℹ️ No staged changes."
    echo "   Stage your changes using: git add ."
    exit 0
  fi

  if [[ -n "$staged" && -n "$unstaged" ]]; then
    echo -n "⚠️ There are unstaged changes. Commit only staged changes? [y/N] "
    read -r ans
    [[ "$ans" =~ ^[Yy]$ ]] || exit 0
  fi
}

build_prompt() {
  case "$1" in
    verbose)
      echo "You are a senior developer. Write a standard git commit message.
- '-' lines were removed, '+' lines were added.
- Other lines are unchanged context.
Follow the rules given below:
1) First line: short imperative summary (<=50 chars).
2) Blank line.
3) Bullet list ('- ') explaining main changes and reasons.
Focus on what changed in '+' and '-' lines, not only on unchanged context. No generic intros like 'This commit...'.
Output strictly in plain text (NO Markdown, no **bold**, no \`code\` ticks)."
      ;;

    minimal)
      echo "Write a concise, high-level git commit subject (max 50 chars).
Constraint: Use imperative mood. summarize the INTENT, not every file change. Give the best concise message."
      ;;

    default)
      echo "Write a single-line git commit message (max 72 chars).
Constraint: Use imperative mood. Summarize exactly WHAT changed (e.g., 'Add hover effects and remove unused code').
Do not mention filenames unless necessary. Do not end with a period."
      ;;
  esac
}

# noise patterns array here...

build_diff_excludes() {
  local args=()
  for p in "${NOISE_PATTERNS[@]}"; do
    args+=( ":(exclude)$p" )
  done
  printf '%s\n' "${args[@]}"
}

# ---------- per-file summary (name, status, stats) ----------
build_file_summary() {
  local exclude_args=()

  # Reuse the same excludes for stats so we don't summarize skipped files
  while IFS= read -r line; do
    exclude_args+=( "$line" )
  done < <(build_diff_excludes)

  # Get name + status (A/M/D/R...) for staged changes
  # Format: "M<TAB>path/to/file"
  local name_status
  name_status=$(git diff --cached --name-status -- "${exclude_args[@]}" || true)

  # Get added/removed line counts per file
  # Format: "35<TAB>10<TAB>path/to/file"
  local numstat
  numstat=$(git diff --cached --numstat -- "${exclude_args[@]}" || true)

  # For each status line, find matching stats line by path
  local status path rest
  while IFS=$'\t' read -r status path rest; do
    [[ -z "$path" ]] && continue

    # Map one-letter status to words
    local action
    case "$status" in
      A) action="Added" ;;
      M) action="Modified" ;;
      D) action="Deleted" ;;
      R*) action="Renamed" ;; # R100, R090 etc.
      *) action="Changed" ;;
    esac

    # Default stats in case we don't find a match (e.g. binary)
    local add="-"
    local remove="-"

    # Search numstat lines for this path
    local ns_line
    while IFS= read -r ns_line; do
      # numstat line format: "<add>\t<remove>\t<path>"
      # Use pattern match to check if it ends with TAB + path
      case "$ns_line" in
        *$'\t'"$path")
          add=${ns_line%%$'\t'*}                # text before first TAB
          local rest_stats=${ns_line#*$'\t'}    # after first TAB
          remove=${rest_stats%%$'\t'*}          # text before second TAB
          break
          ;;
      esac
    done <<< "$numstat"

    echo "$action $path (+${add} -${remove})"
  done <<< "$name_status"
}

# ---------- diff ----------
prepare_diff() {
  # Build exclude arguments from patterns
  local exclude_args=()
  while IFS= read -r line; do
    exclude_args+=( "$line" )
  done < <(build_diff_excludes)

 {
  # Per-file summary
  echo "Files changed (staged):"
  build_file_summary
  echo
  echo "Diff (filtered):"

  # Actual filtered diff
  git --no-pager diff --cached --no-color -- \
    . \
    "${exclude_args[@]}" \
  | sed -E '
      /^diff --git/d
      /^index /d
      /^--- /d
      s/^\+\+\+ b\//FILE: /
    '
} | sed '1i\
NEVER RETURN THE RESPONSE IN RICHTEXT, RETURN SIMPLE TEXTS\
\
'
}

# ---------- truncate ----------
truncate_diff() {
  local diff="$1"
  local header="$2"
  local prompt="$3"

  local body_limit=$((DIFFSENSE_MAX_CHARS - ${#header} - ${#prompt} - 5))

  if (( body_limit <= 0 )); then
    echo "❌ Internal error: header exceeds character budget."
    return 1
  fi

  echo "$diff" | head -c "$body_limit"
}

# ---------- shortcut ----------
invoke_shortcut() {
  local output

  if ! output=$(shortcuts run "Diffsense" 2>&1 <<< "$1"); then
    if grep -qiE "couldn.?t find shortcut" <<< "$output"; then
      echo "❌ Couldn't find the 'Diffsensee' shortcut. Please install it from [https://edgeleap.github.io/](https://edgeleap.github.io/) 🚀" >&2
      return 1
    fi

    # Any other error: show original message
    echo "$output" >&2
    return 1
  fi

  printf '%s\n' "$output"
}

# ---------- commit changes ----------
commit_changes() {
  local commit_msg="$1"

  if [[ -z "$commit_msg" ]]; then
    echo "❌ Error: Received empty commit message."
    return 1
  fi

  if git commit -m "$commit_msg"; then
    echo "✅ Commit created successfully."
  else
    echo "❌ Git commit failed."
    return 1
  fi
}

# ---------- main ----------
diffsense() {
  local parsed ai_model message_style nopopup_suffix
  local diff header prompt payload commit_msg

  # 0. Early help check BEFORE anything else
  if [[ "$#" -gt 0 ]]; then
    case "$1" in
      -h|--help)
        print_help
        exit 0
        ;;
    esac
  fi

  # 1. Parse arguments (Errors print to stderr and exit)
  if ! parsed=$(parse_args "$@"); then
    exit 1
  fi

  ai_model=$(awk '{print $1}' <<< "$parsed")
  message_style=$(awk '{print $2}' <<< "$parsed")
  nopopup_suffix=$(awk '{print $3}' <<< "$parsed")

  set_max_chars_for_model "$ai_model"

  # 2. Checks
  check_platform_and_arch || exit 1
  check_is_git_repo
  check_git_state

  # 3. Build Components
  prompt=$(build_prompt "$message_style")
  diff=$(prepare_diff)

  # 4. Build Header
  header="@@DIFFSENSE_META=${ai_model}${nopopup_suffix}"

  # 5. Truncate
  diff=$(truncate_diff "$diff" "$header" "$prompt") || exit 1

  # 6. Build Payload
  payload="${header}"$'\n'"${prompt}"$'\n\n'"${diff}"
  
  # 7. Execute
  commit_msg=$(invoke_shortcut "$payload") || exit 1
  commit_changes "$commit_msg"
}

diffsense "$@"