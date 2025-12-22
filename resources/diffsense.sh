#!/bin/bash

# =========================================
# diffsense — AI-powered git commit generator
# =========================================

DIFFSENSE_MAX_CHARS=1000

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
      
      # Special Flag (nopopup is the only one we keep the dash check for strictness if needed, 
      # but sticking to your logic, checking 'nopopup' after stripping works too)
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

# ---------- prompt ----------
build_prompt() {
  case "$1" in
    verbose)
      echo "You are a senior developer. Write a standard git commit message.
1. First line: A short, imperative summary (max 50 chars).
2. Second line: Blank.
3. Body: Bullet points ('- ') explaining specific changes.
Constraint: Focus on the 'WHY'. Wrap lines at 72 chars. No generic intros like 'This commit...'. 
Output strictly in plain text (NO Markdown, no **bold**, no `code` ticks)."
      ;;
    
    minimal)
      echo "Write a concise, high-level git commit subject (max 50 chars).
Constraint: Use imperative mood. summarize the INTENT, not every file change.
Example: 'Refactor UI styles' is better than 'Update App.css and App.tsx'.
Do not end with a period."
      ;;
    
    default)
      echo "Write a single-line git commit message (max 72 chars).
Constraint: Use imperative mood. Summarize exactly WHAT changed (e.g., 'Add hover effects and remove unused code').
Do not mention filenames unless necessary. Do not end with a period."
      ;;
  esac
}



# ---------- diff ----------
prepare_diff() {
  git --no-pager diff --cached --no-color \
    | sed -E '
      /^diff --git/d
      /^index /d
      /^@@ /d
      /^--- /d
      s/^\+\+\+ b\//FILE: /
    ' \
    | sed '1i\
NEVER RETURN THE RESPONSE IN RICHTEXT, RETURN SIMPLE TEXTS
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
  shortcuts run "Diffsense" <<< "$1"
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