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

# ---------- model-specific character limits ----------
set_max_chars_for_model() {
  local model="$1"

  case "$model" in
    LOCAL)
      DIFFSENSE_MAX_CHARS=8000
      ;;
    PRIVATE)
      DIFFSENSE_MAX_CHARS=256000
      ;;
    CHATGPT)
      DIFFSENSE_MAX_CHARS=1194000
      ;;
    *)
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

  for raw_arg in "$@"; do
    local arg="${raw_arg#--}"

    case "$arg" in
      default|verbose|minimal)
        message_style="$arg"
        ;;
      afm|pcc|gpt)
        ai_model="$arg"
        ;;
      nopopup)
        nopopup_suffix="_NOPOPUP"
        ;;
      *)
        echo "❌ Error: Command '$raw_arg' does not exist." >&2
        return 1
        ;;
    esac
  done

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

# ---------- build prompt ----------
# ---------- build prompt ----------
build_prompt() {
  case "$1" in
    verbose)
      echo "You are a git commit message generator.
Input: A git diff where:
- Lines starting with '+' are ADDITIONS.
- Lines starting with '-' are DELETIONS.
- All other lines are UNCHANGED CONTEXT.

Task: Write a standard git commit message.
Format:
1. Summary line (max 50 chars, imperative mood).
2. One blank line.
3. Bullet points ('- ') describing the logic changes.

Constraints:
- Start the summary with a verb (e.g., Fix, Add, Update).
- Summarize exactly WHAT changed in the '+' and '-' lines (other lines are for your context).
- DO NOT output file names, numbers, or statistics like '(+62 -9)'.
- Output strictly in plain text (NO Markdown, NO backticks, NO **bold**).
- RETURN ONLY THE COMMIT MESSAGE."
      ;;

    minimal)
      echo "Task: Write exactly one line describing this change.
Constraints:
- Max length: 50 characters.
- Start with a verb (Imperative mood).
- Summarize exactly WHAT changed in the '+' and '-' lines (other lines are for your context).
- DO NOT output file names, numbers, or statistics like '(+62 -9)'.
- NO filenames, NO explanations, NO Markdown.
- RETURN ONLY THE MESSAGE."
      ;;

    default)
      echo "Task: Write a single-line git commit message.
Constraints:
- Max length: 72 characters.
- Start with a verb (Imperative mood).
- Summarize exactly WHAT changed in the '+' and '-' lines (other lines are for your context).
- DO NOT output file names, numbers, or statistics like '(+62 -9)'.
- NO Markdown, NO backticks.
- RETURN ONLY THE MESSAGE."
      ;;
  esac
}


# ---------- build exclude args ----------
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

  while IFS= read -r line; do
    exclude_args+=( "$line" )
  done < <(build_diff_excludes)

  local name_status
  name_status=$(git diff --cached --name-status -- "${exclude_args[@]}" || true)

  local numstat
  numstat=$(git diff --cached --numstat -- "${exclude_args[@]}" || true)

  local status path rest
  while IFS=$'\t' read -r status path rest; do
    [[ -z "$path" ]] && continue

    local action
    case "$status" in
      A) action="Added" ;;
      M) action="Modified" ;;
      D) action="Deleted" ;;
      R*) action="Renamed" ;;
      *) action="Changed" ;;
    esac

    local add="-"
    local remove="-"

    local ns_line
    while IFS= read -r ns_line; do
      case "$ns_line" in
        *$'\t'"$path")
          add=${ns_line%%$'\t'*}
          local rest_stats=${ns_line#*$'\t'}
          remove=${rest_stats%%$'\t'*}
          break
          ;;
      esac
    done <<< "$numstat"

    echo "$action $path (+${add} -${remove})"
  done <<< "$name_status"
}

# ---------- get diff for a single file ----------
get_file_diff() {
  local file="$1"
  git --no-pager diff --cached --no-color -- "$file" 2>/dev/null | sed -E '
    /^diff --git/d
    /^index /d
    /^--- /d
    s|^\+\+\+ b/.*|FILE: '"$file"'|
  '
}

# ---------- hunk-aware truncation by character budget ----------
truncate_hunks_by_budget() {
  local budget="$1"
  local output=""
  local current_len=0

  local hunk_header=""
  local hunk_lines=()

  flush_hunk() {
    [[ -z "$hunk_header" ]] && return

    local hunk_content=""
    local line_count=${#hunk_lines[@]}

    hunk_content="$hunk_header"$'\n'
    for line in "${hunk_lines[@]}"; do
      hunk_content+="$line"$'\n'
    done

    local hunk_len=${#hunk_content}

    if (( current_len + hunk_len <= budget )); then
      output+="$hunk_content"
      current_len=$((current_len + hunk_len))
    else
      local remaining=$((budget - current_len))
      local header_len=${#hunk_header}

      if (( remaining > header_len + 50 )); then
        output+="$hunk_header"$'\n'
        current_len=$((current_len + header_len + 1))

        local kept=0
        for line in "${hunk_lines[@]}"; do
          local line_len=$(( ${#line} + 1 ))
          if (( current_len + line_len + 40 <= budget )); then
            output+="$line"$'\n'
            current_len=$((current_len + line_len))
            ((kept++))
          else
            break
          fi
        done

        local truncated=$((line_count - kept))
        if (( truncated > 0 )); then
          local placeholder="... [truncated $truncated lines]"$'\n'
          output+="$placeholder"
          current_len=$((current_len + ${#placeholder}))
        fi
      fi
    fi

    hunk_header=""
    hunk_lines=()
  }

  while IFS= read -r line; do
    (( current_len >= budget )) && break

    case "$line" in
      "FILE: "*)
        flush_hunk
        local file_line="$line"$'\n'
        if (( current_len + ${#file_line} <= budget )); then
          output+="$file_line"
          current_len=$((current_len + ${#file_line}))
        fi
        ;;
      @@*)
        flush_hunk
        hunk_header="$line"
        ;;
      *)
        if [[ -n "$hunk_header" ]]; then
          hunk_lines+=("$line")
        fi
        ;;
    esac
  done

  flush_hunk
  printf '%s' "$output"
}

# ---------- budget allocation and diff assembly ----------
build_allocated_diff() {
  local header="$1"
  local prompt="$2"
  local file_summary="$3"

  local preamble="NEVER RETURN THE RESPONSE IN RICHTEXT, RETURN SIMPLE TEXTS"$'\n\n'
  local files_header="Files changed (staged):"$'\n'
  local diff_header=$'\n'"Diff (filtered):"$'\n'

  local fixed_len=$(( ${#preamble} + ${#files_header} + ${#file_summary} + ${#diff_header} + ${#header} + ${#prompt} + 30 ))

  local diff_budget=$(( DIFFSENSE_MAX_CHARS - fixed_len ))

  if (( diff_budget <= 0 )); then
    echo "❌ Error: No budget left for diff content." >&2
    return 1
  fi

  local exclude_args=()
  while IFS= read -r line; do
    exclude_args+=( "$line" )
  done < <(build_diff_excludes)

  local files=()
  while IFS= read -r f; do
    [[ -n "$f" ]] && files+=("$f")
  done < <(git diff --cached --name-only -- . "${exclude_args[@]}")

  local file_count=${#files[@]}
  if (( file_count == 0 )); then
    echo "${preamble}${files_header}${file_summary}${diff_header}(no files after filtering)"
    return 0
  fi

  # Use indexed arrays instead of associative arrays
  local file_diffs=()
  local file_sizes=()

  local i
  for (( i = 0; i < file_count; i++ )); do
    file_diffs[i]=$(get_file_diff "${files[i]}")
    file_sizes[i]=${#file_diffs[i]}
  done

  local base_alloc=$(( diff_budget / file_count ))
  local file_allocs=()
  local surplus=0
  local needy_indices=()

  for (( i = 0; i < file_count; i++ )); do
    local needed=${file_sizes[i]}
    if (( needed <= base_alloc )); then
      file_allocs[i]=$needed
      surplus=$(( surplus + base_alloc - needed ))
    else
      file_allocs[i]=$base_alloc
      needy_indices+=("$i")
    fi
  done

  if (( ${#needy_indices[@]} > 0 && surplus > 0 )); then
    local extra_per=$(( surplus / ${#needy_indices[@]} ))
    for i in "${needy_indices[@]}"; do
      local current=${file_allocs[i]}
      local needed=${file_sizes[i]}
      local new_alloc=$(( current + extra_per ))

      if (( new_alloc > needed )); then
        file_allocs[i]=$needed
      else
        file_allocs[i]=$new_alloc
      fi
    done
  fi

  local final_diff=""
  for (( i = 0; i < file_count; i++ )); do
    local alloc=${file_allocs[i]}
    local truncated_diff
    truncated_diff=$(truncate_hunks_by_budget "$alloc" <<< "${file_diffs[i]}")
    final_diff+="$truncated_diff"
  done

  echo "${preamble}${files_header}${file_summary}${diff_header}${final_diff}"
}


# ---------- prepare diff ----------
prepare_diff() {
  local header="$1"
  local prompt="$2"

  local file_summary
  file_summary=$(build_file_summary)

  build_allocated_diff "$header" "$prompt" "$file_summary"
}

# ---------- shortcut ----------
invoke_shortcut() {
  local output

  if ! output=$(shortcuts run "Diffsense" 2>&1 <<< "$1"); then
    if grep -qiE "couldn.?t find shortcut" <<< "$output"; then
      echo "❌ Couldn't find the 'Diffsense' shortcut. Please install it from https://edgeleap.github.io/" >&2
      return 1
    fi

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

  if [[ "$#" -gt 0 ]]; then
    case "$1" in
      -h|--help)
        print_help
        exit 0
        ;;
    esac
  fi

  if ! parsed=$(parse_args "$@"); then
    exit 1
  fi

  ai_model=$(awk '{print $1}' <<< "$parsed")
  message_style=$(awk '{print $2}' <<< "$parsed")
  nopopup_suffix=$(awk '{print $3}' <<< "$parsed")

  set_max_chars_for_model "$ai_model"

  check_platform_and_arch || exit 1
  check_is_git_repo
  check_git_state

  prompt=$(build_prompt "$message_style")
  header="@@DIFFSENSE_META=${ai_model}${nopopup_suffix}"

  # Main diff strategy
  diff=$(prepare_diff "$header" "$prompt") || exit 1

  payload="${header}"$'\n'"${prompt}"$'\n\n'"${diff}"

 # SAFETY: Final truncation to guarantee we never exceed the limit
  if (( ${#payload} > DIFFSENSE_MAX_CHARS )); then
    payload="${payload:0:DIFFSENSE_MAX_CHARS}"
  fi

  commit_msg=$(invoke_shortcut "$payload") || exit 1
  commit_changes "$commit_msg"
}

diffsense "$@"