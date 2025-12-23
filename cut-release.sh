#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Print colored messages
info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    error "Not in a git repository"
    exit 1
fi

# Check if we're on main branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" != "main" ]; then
    error "Not on main branch (current: $CURRENT_BRANCH)"
    read -p "Do you want to switch to main? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git checkout main
    else
        exit 1
    fi
fi

info "Pulling latest changes from origin/main..."
git pull origin main

# Check for uncommitted changes
if ! git diff-index --quiet HEAD --; then
    error "You have uncommitted changes. Please commit or stash them first."
    git status --short
    exit 1
fi

# Verify required files exist
info "Checking required release files..."
REQUIRED_FILES=("resources/diffsense.sh" "resources/Diffsense.shortcut")
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        error "Required file missing: $file"
        exit 1
    fi
    info "✓ Found: $file"
done

# Capture short SHA
SHORT_SHA=$(git rev-parse --short HEAD)
TAG_NAME="diffsense@${SHORT_SHA}"

info "Release tag will be: ${TAG_NAME}"
echo

# Confirm before proceeding
warn "This will create and push tag: ${TAG_NAME}"
warn "This will trigger the GitHub Actions release workflow"
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    info "Release cancelled"
    exit 0
fi

# Create annotated tag
info "Creating annotated tag..."
if git tag -a "${TAG_NAME}" -m "Release diffsense @ ${SHORT_SHA}"; then
    info "✓ Tag created: ${TAG_NAME}"
else
    error "Failed to create tag"
    exit 1
fi

# Push tag to trigger release
info "Pushing tag to origin..."
if git push origin "${TAG_NAME}"; then
    info "✓ Tag pushed successfully"
    echo
    info "GitHub Actions will now create the release automatically"
    info "Check status at: https://github.com/edgeleap/diffsense/actions"
    info "Release will appear at: https://github.com/edgeleap/diffsense/releases/tag/${TAG_NAME}"
else
    error "Failed to push tag"
    warn "Rolling back local tag..."
    git tag -d "${TAG_NAME}"
    exit 1
fi
