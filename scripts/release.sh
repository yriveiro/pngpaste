#!/usr/bin/env bash
#
# release.sh - Create and publish GitHub releases for pngpaste
#
# This script builds binaries for all supported architectures, generates
# checksums, creates a GitHub release as a draft, uploads all assets,
# and then publishes the release.
#
# Usage:
#   ./scripts/release.sh <version>
#   ./scripts/release.sh v1.0.0
#   ./scripts/release.sh v1.0.0 --dry-run
#
# Requirements:
#   - macOS (for building)
#   - Swift 6.0+
#   - gh CLI (preferred) or GITHUB_TOKEN environment variable
#

set -euo pipefail

# =============================================================================
# Configuration
# =============================================================================

BINARY_NAME="pngpaste"
REPO="yriveiro/pngpaste"

# Build targets: architecture name and Swift arch flag
declare -A TARGETS=(
  ["aarch64-apple-darwin"]="arm64"
  ["x86_64-apple-darwin"]="x86_64"
)

# Output directory for release artifacts
DIST_DIR="dist"

# =============================================================================
# Terminal Colors
# =============================================================================

if [[ -t 1 ]]; then
  BOLD=$(tput bold)
  RED=$(tput setaf 1)
  GREEN=$(tput setaf 2)
  YELLOW=$(tput setaf 3)
  BLUE=$(tput setaf 4)
  RESET=$(tput sgr0)
else
  BOLD=""
  RED=""
  GREEN=""
  YELLOW=""
  BLUE=""
  RESET=""
fi

# =============================================================================
# Logging Functions
# =============================================================================

info() {
  echo "${BOLD}${BLUE}==>${RESET} $*"
}

success() {
  echo "${GREEN}✓${RESET} $*"
}

warn() {
  echo "${YELLOW}!${RESET} $*"
}

error() {
  echo "${RED}✗${RESET} $*" >&2
}

fatal() {
  error "$@"
  exit 1
}

# =============================================================================
# Helper Functions
# =============================================================================

usage() {
  cat <<EOF
Usage: $(basename "$0") <version> [options]

Create a GitHub release for ${BINARY_NAME}.

Arguments:
    version         Version tag (e.g., v1.0.0)

Options:
    --dry-run       Build and package but don't create release
    --skip-build    Skip build step (use existing binaries)
    --help          Show this help message

Examples:
    $(basename "$0") v1.0.0
    $(basename "$0") v1.0.0 --dry-run
    GITHUB_TOKEN=ghp_xxx $(basename "$0") v1.0.0

EOF
}

check_prerequisites() {
  info "Checking prerequisites..."

  # Check we're on macOS
  if [[ "$(uname -s)" != "Darwin" ]]; then
    fatal "This script must be run on macOS"
  fi

  # Check Swift is available
  if ! command -v swift &>/dev/null; then
    fatal "Swift is not installed"
  fi

  # Check Swift version (need 6.0+)
  local swift_version
  swift_version=$(swift --version 2>&1 | grep -oE 'Swift version [0-9]+\.[0-9]+' | grep -oE '[0-9]+\.[0-9]+' || echo "0.0")
  local major_version="${swift_version%%.*}"
  if [[ "$major_version" -lt 6 ]]; then
    fatal "Swift 6.0+ required, found $swift_version"
  fi
  success "Swift $swift_version"

  # Check for gh CLI or GITHUB_TOKEN
  if [[ "$DRY_RUN" == "false" ]]; then
    if command -v gh &>/dev/null; then
      # Verify gh is authenticated
      if ! gh auth status &>/dev/null; then
        fatal "gh CLI is not authenticated. Run 'gh auth login' first."
      fi
      USE_GH_CLI=true
      success "gh CLI authenticated"
    elif [[ -n "${GITHUB_TOKEN:-}" ]]; then
      USE_GH_CLI=false
      success "GITHUB_TOKEN found"
    else
      fatal "Neither gh CLI nor GITHUB_TOKEN available. Install gh CLI or set GITHUB_TOKEN."
    fi
  fi

  # Check git status
  if [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then
    warn "Working directory has uncommitted changes"
  fi

  success "Prerequisites OK"
}

validate_version() {
  local version="$1"

  # Check version format (vX.Y.Z)
  if [[ ! "$version" =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?$ ]]; then
    fatal "Invalid version format: $version (expected vX.Y.Z or vX.Y.Z-suffix)"
  fi

  # Check if tag exists locally
  if ! git rev-parse "$version" &>/dev/null; then
    warn "Tag $version does not exist locally"
    read -rp "Create tag $version now? [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
      git tag "$version"
      success "Created tag $version"
    else
      fatal "Tag $version required. Create it with: git tag $version"
    fi
  fi

  success "Version $version validated"
}

build_binary() {
  local arch="$1"
  local target="$2"

  info "Building for $target ($arch)..."

  swift build \
    -c release \
    --arch "$arch" \
    --quiet

  # Find the binary (Swift may put it in architecture-specific dir)
  local binary_path
  if [[ -f ".build/release/${BINARY_NAME}" ]]; then
    binary_path=".build/release/${BINARY_NAME}"
  elif [[ -f ".build/arm64-apple-macosx/release/${BINARY_NAME}" ]]; then
    binary_path=".build/arm64-apple-macosx/release/${BINARY_NAME}"
  elif [[ -f ".build/x86_64-apple-macosx/release/${BINARY_NAME}" ]]; then
    binary_path=".build/x86_64-apple-macosx/release/${BINARY_NAME}"
  else
    fatal "Could not find built binary for $target"
  fi

  # Copy to dist with target name
  cp "$binary_path" "${DIST_DIR}/${BINARY_NAME}-${target}"
  success "Built ${BINARY_NAME}-${target}"
}

create_archives() {
  info "Creating release archives..."

  for target in "${!TARGETS[@]}"; do
    local archive="${BINARY_NAME}-${target}.tar.gz"
    local binary="${BINARY_NAME}-${target}"

    # Create tarball with just the binary (renamed to BINARY_NAME)
    (
      cd "$DIST_DIR"
      # Copy binary to standard name for archive
      cp "$binary" "$BINARY_NAME"
      tar -czf "$archive" "$BINARY_NAME"
      rm "$BINARY_NAME"
    )

    success "Created $archive"
  done
}

generate_checksums() {
  info "Generating checksums..."

  (
    cd "$DIST_DIR"
    shasum -a 256 "${BINARY_NAME}"-*.tar.gz >checksums.txt
  )

  success "Generated checksums.txt"
  cat "${DIST_DIR}/checksums.txt"
}

create_release() {
  local version="$1"

  info "Creating GitHub release $version (draft)..."

  if [[ "$USE_GH_CLI" == "true" ]]; then
    gh release create "$version" \
      --repo "$REPO" \
      --title "$version" \
      --draft \
      --generate-notes
  else
    # Fallback to curl + GitHub API
    local response
    response=$(curl -s -X POST \
      -H "Authorization: token ${GITHUB_TOKEN}" \
      -H "Accept: application/vnd.github.v3+json" \
      "https://api.github.com/repos/${REPO}/releases" \
      -d "{
                \"tag_name\": \"${version}\",
                \"name\": \"${version}\",
                \"draft\": true,
                \"generate_release_notes\": true
            }")

    RELEASE_ID=$(echo "$response" | grep -o '"id": [0-9]*' | head -1 | grep -o '[0-9]*')
    if [[ -z "$RELEASE_ID" ]]; then
      error "API response: $response"
      fatal "Failed to create release"
    fi
  fi

  success "Created draft release $version"
}

upload_assets() {
  local version="$1"

  info "Uploading release assets..."

  local assets=(
    "${DIST_DIR}/checksums.txt"
  )

  # Add all tar.gz files
  for target in "${!TARGETS[@]}"; do
    assets+=("${DIST_DIR}/${BINARY_NAME}-${target}.tar.gz")
  done

  if [[ "$USE_GH_CLI" == "true" ]]; then
    for asset in "${assets[@]}"; do
      local filename
      filename=$(basename "$asset")
      info "  Uploading $filename..."
      gh release upload "$version" "$asset" --repo "$REPO" --clobber
      success "  Uploaded $filename"
    done
  else
    # Fallback to curl + GitHub API
    local upload_url="https://uploads.github.com/repos/${REPO}/releases/${RELEASE_ID}/assets"

    for asset in "${assets[@]}"; do
      local filename
      filename=$(basename "$asset")
      local content_type="application/octet-stream"
      [[ "$filename" == "checksums.txt" ]] && content_type="text/plain"

      info "  Uploading $filename..."
      curl -s -X POST \
        -H "Authorization: token ${GITHUB_TOKEN}" \
        -H "Content-Type: ${content_type}" \
        "${upload_url}?name=${filename}" \
        --data-binary "@${asset}" >/dev/null

      success "  Uploaded $filename"
    done
  fi

  success "All assets uploaded"
}

publish_release() {
  local version="$1"

  info "Publishing release $version..."

  if [[ "$USE_GH_CLI" == "true" ]]; then
    gh release edit "$version" --repo "$REPO" --draft=false
  else
    curl -s -X PATCH \
      -H "Authorization: token ${GITHUB_TOKEN}" \
      -H "Accept: application/vnd.github.v3+json" \
      "https://api.github.com/repos/${REPO}/releases/${RELEASE_ID}" \
      -d '{"draft": false}' >/dev/null
  fi

  success "Release $version published!"
  echo ""
  echo "View at: ${BOLD}https://github.com/${REPO}/releases/tag/${version}${RESET}"
}

cleanup() {
  if [[ -d "$DIST_DIR" ]]; then
    info "Cleaning up..."
    rm -rf "$DIST_DIR"
    success "Cleanup complete"
  fi
}

# =============================================================================
# Main
# =============================================================================

main() {
  local version=""
  DRY_RUN=false
  SKIP_BUILD=false
  USE_GH_CLI=false
  RELEASE_ID=""

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run)
        DRY_RUN=true
        shift
        ;;
      --skip-build)
        SKIP_BUILD=true
        shift
        ;;
      --help | -h)
        usage
        exit 0
        ;;
      -*)
        fatal "Unknown option: $1"
        ;;
      *)
        if [[ -z "$version" ]]; then
          version="$1"
        else
          fatal "Unexpected argument: $1"
        fi
        shift
        ;;
    esac
  done

  if [[ -z "$version" ]]; then
    usage
    fatal "Version argument required"
  fi

  echo ""
  echo "${BOLD}${BINARY_NAME} Release Script${RESET}"
  echo "================================"
  echo ""

  # Setup trap for cleanup on error
  trap 'cleanup' EXIT

  check_prerequisites
  validate_version "$version"

  # Create dist directory
  mkdir -p "$DIST_DIR"

  if [[ "$SKIP_BUILD" == "false" ]]; then
    # Build for each target
    for target in "${!TARGETS[@]}"; do
      build_binary "${TARGETS[$target]}" "$target"
    done
  fi

  create_archives
  generate_checksums

  if [[ "$DRY_RUN" == "true" ]]; then
    warn "Dry run mode - skipping release creation"
    echo ""
    echo "Artifacts in ${DIST_DIR}/:"
    ls -la "$DIST_DIR"
    # Don't cleanup in dry-run so user can inspect
    trap - EXIT
    exit 0
  fi

  create_release "$version"
  upload_assets "$version"
  publish_release "$version"

  echo ""
  success "Release $version completed successfully!"
}

main "$@"
