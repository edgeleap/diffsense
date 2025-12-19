#!/bin/bash

# =========================================
# diffsense — AI-powered git commit generator
# =========================================

# ---------- configuration ----------
DIFFSENSE_MAX_CHARS=800

# ---------- parse CLI flags ----------
parse_args() {
  local mode_arg="$1"
  local mode="LOCAL"

  case "$mode_arg" in
    --verbose) mode="PRIVATE" ;;
    --minimal) mode="CHATGPT" ;;
  esac

  echo "$mode"
}

# ---------- platform checks ----------
check_platform() {
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

# ---------- git checks ----------
check_git_repo() {
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "❌ Not inside a git repository."
    return 1
  fi
}

check_staged_changes() {
  if git diff --cached --quiet; then
    echo "ℹ️ No staged changes to commit."
    return 1
  fi
}

# ---------- diff preparation ----------
prepare_diff() {
  local diff_body
  diff_body=$(git --no-pager diff --cached --no-color \
    | sed -E '
      /^diff --git/d
      /^index /d
      /^@@ /d
      /^--- /d
      s/^\+\+\+ b\//FILE: /
    ' \
    | sed '1i\
You are given a git diff. Write a concise, human-readable git commit message that accurately describes the actual changes. Summarize it
    ')
  echo "$diff_body"
}

# ---------- enforce size limits ----------
truncate_diff_if_needed() {
  local diff_body="$1"
  local mode="$2"
  local header_len body_limit header

  header="@@DIFFSENSE_MODE=${mode}\n"
  header_len=${#header}
  body_limit=$((DIFFSENSE_MAX_CHARS - header_len))

  if (( body_limit <= 0 )); then
    echo "❌ Internal error: header exceeds character budget."
    return 1
  fi

  if (( ${#diff_body} > body_limit )); then
    diff_body=$(echo "$diff_body" | head -c "$body_limit")

    if [[ "$mode" == "LOCAL" ]]; then
      # TODO: Implement on-device pre-summarization for very long diffs
      :
    fi
  fi

  echo "$diff_body"
}

# ---------- build payload ----------
build_payload() {
  local diff_body="$1"
  local mode="$2"

  local payload="@@DIFFSENSE_MODE=${mode}\n${diff_body}"
  echo "$payload"
}

# ---------- invoke shortcut ----------
invoke_shortcut() {
  local payload="$1"
  local commit_msg

  commit_msg=$(shortcuts run "SummarizeCommit" <<< "$payload")

  if [[ -z "$commit_msg" ]]; then
    echo "❌ Commit message generation failed."
    echo "   • Ensure Apple Intelligence is enabled"
    echo "   • Ensure Shortcut input type = Text"
    echo "   • Ensure Automation permission is granted"
    return 1
  fi

  echo "$commit_msg"
}

# ---------- commit changes ----------
commit_changes() {
  local commit_msg="$1"

  if git commit -m "$commit_msg"; then
    echo "✅ Commit created successfully:"
    echo "   \"$commit_msg\""
  else
    echo "❌ Git commit failed."
    return 1
  fi
}

# ---------- main entry ----------
diffsense() {
  local mode diff_body truncated_diff payload commit_msg

  mode=$(parse_args "$1") || return 1
  check_platform           || return 1
  check_git_repo           || return 1
  check_staged_changes     || return 1

  diff_body=$(prepare_diff) || return 1
  truncated_diff=$(truncate_diff_if_needed "$diff_body" "$mode") || return 1
  payload=$(build_payload "$truncated_diff" "$mode") || return 1
  commit_msg=$(invoke_shortcut "$payload") || return 1
  commit_changes "$commit_msg" || return 1
}

diffsense "$@"