#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if tag name provided
if [ $# -eq 0 ]; then
    error "Usage: $0 <tag-name>"
    error "Example: $0 diffsense@a1b2c3d"
    exit 1
fi

TAG_NAME="$1"

# Verify tag exists locally
if ! git rev-parse "$TAG_NAME" >/dev/null 2>&1; then
    error "Tag '$TAG_NAME' does not exist locally"
    exit 1
fi

warn "This will delete tag: ${TAG_NAME}"
warn "Both locally and remotely"
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    info "Rollback cancelled"
    exit 0
fi

# Delete local tag
info "Deleting local tag..."
git tag -d "$TAG_NAME"

# Delete remote tag
info "Deleting remote tag..."
if git push origin --delete "$TAG_NAME"; then
    info "✓ Tag deleted successfully"
    info "The GitHub release will be automatically removed"
else
    warn "Failed to delete remote tag (it may not exist remotely)"
fi
