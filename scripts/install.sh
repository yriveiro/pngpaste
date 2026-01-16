#!/usr/bin/env bash

set -euo pipefail

# Project configuration
BINARY_NAME=pngpaste
REPO_NAME=pngpaste
DISPLAY_NAME=pngpaste
GITHUB_USER=yriveiro

# Colors
MUTED='\033[0;2m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[38;5;214m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color
BOLD='\033[1m'
UNDERLINE='\033[4m'

# macOS only - Intel and Apple Silicon
SUPPORTED_TARGETS="x86_64-apple-darwin aarch64-apple-darwin"

print_message() {
  local level=$1
  local message=$2
  local color=""

  case $level in
    info) color="${NC}" ;;
    warning) color="${YELLOW}" ;;
    error) color="${RED}" ;;
    success) color="${GREEN}" ;;
  esac

  echo -e "${color}${message}${NC}"
}

info() {
  echo -e "${MUTED}>${NC} $*"
}

warn() {
  echo -e "${YELLOW}! $*${NC}"
}

error() {
  echo -e "${RED}x $*${NC}" >&2
}

completed() {
  echo -e "${GREEN}✓${NC} $*"
}

has() {
  command -v "$1" 1>/dev/null 2>&1
}

# Make sure user is not using zsh or non-POSIX-mode bash, which can cause issues
verify_shell_is_posix_or_exit() {
  if [[ -n "${ZSH_VERSION+x}" ]]; then
    error "Running installation script with \`zsh\` is known to cause errors."
    error "Please use \`bash\` instead."
    exit 1
  fi
}

# Make sure we're running on macOS
verify_macos_or_exit() {
  if [[ "$(uname -s)" != "Darwin" ]]; then
    error "${DISPLAY_NAME} is only supported on macOS"
    exit 1
  fi
}

# Gets path to a temporary file
get_tmpfile() {
  local suffix="$1"
  if has mktemp; then
    printf "%s.%s" "$(mktemp)" "${suffix}"
  else
    printf "/tmp/%s.%s.%s" "$BINARY_NAME" "$$" "${suffix}"
  fi
}

# Test if a location is writeable by trying to write to it
test_writeable() {
  local path="${1:-}/test.txt"
  if touch "${path}" 2>/dev/null; then
    rm "${path}"
    return 0
  else
    return 1
  fi
}

unbuffered_sed() {
  if echo | sed -u -e "" >/dev/null 2>&1; then
    sed -nu "$@"
  elif echo | sed -l -e "" >/dev/null 2>&1; then
    sed -nl "$@"
  else
    local pad
    pad="$(printf "\n%512s" "")"
    sed -ne "s/$/\\${pad}/" "$@"
  fi
}

print_progress() {
  local bytes="$1"
  local length="$2"
  [[ "$length" -gt 0 ]] || return 0

  local width=50
  local percent=$((bytes * 100 / length))
  [[ "$percent" -gt 100 ]] && percent=100
  local on=$((percent * width / 100))
  local off=$((width - on))

  local filled
  filled=$(printf "%*s" "$on" "")
  filled=${filled// /■}
  local empty
  empty=$(printf "%*s" "$off" "")
  empty=${empty// /･}

  printf "\r${YELLOW}%s%s %3d%%${NC}" "$filled" "$empty" "$percent" >&4
}

download_with_progress() {
  local url="$1"
  local output="$2"

  if [[ -t 2 ]]; then
    exec 4>&2
  else
    exec 4>/dev/null
  fi

  local tmp_dir=${TMPDIR:-/tmp}
  local basename="${tmp_dir}/${BINARY_NAME}_install_$$"
  local tracefile="${basename}.trace"

  rm -f "$tracefile"
  mkfifo "$tracefile"

  # Hide cursor
  printf "\033[?25l" >&4

  trap 'trap - RETURN; rm -f "'"$tracefile"'"; printf '"'"'\033[?25h'"'"' >&4; exec 4>&-' RETURN

  (
    curl --trace-ascii "$tracefile" -fSs -L -o "$output" "$url" 2>/dev/null
  ) &
  local curl_pid=$!

  unbuffered_sed \
    -e 'y/ACDEGHLNORTV/acdeghlnortv/' \
    -e '/^0000: content-length:/p' \
    -e '/^<= recv data/p' \
    "$tracefile" |
    {
      local length=0
      local bytes=0

      while IFS=" " read -r -a line; do
        [[ "${#line[@]}" -lt 2 ]] && continue
        local tag="${line[0]} ${line[1]}"

        if [[ "$tag" == "0000: content-length:" ]]; then
          length="${line[2]}"
          length=$(echo "$length" | tr -d '\r')
          bytes=0
        elif [[ "$tag" == "<= recv" ]]; then
          local size="${line[3]}"
          bytes=$((bytes + size))
          if [[ "$length" -gt 0 ]]; then
            print_progress "$bytes" "$length"
          fi
        fi
      done
    }

  wait $curl_pid
  local ret=$?
  echo "" >&4

  # Verify the download actually produced a valid file
  if [[ $ret -eq 0 ]] && [[ ! -s "$output" ]]; then
    return 1
  fi

  return $ret
}

download() {
  local file="$1"
  local url="$2"

  # Try progress bar first if TTY is available
  if [[ -t 2 ]] && download_with_progress "$url" "$file"; then
    return 0
  fi

  # Fallback to standard download
  local rc=0
  if has curl; then
    curl -fS# -L -o "$file" "$url" 2>/dev/null && return 0 || rc=$?
  elif has wget; then
    wget --quiet --output-document="$file" "$url" 2>/dev/null && return 0 || rc=$?
  elif has fetch; then
    fetch --quiet --output="$file" "$url" 2>/dev/null && return 0 || rc=$?
  else
    error "No HTTP download program (curl, wget, fetch) found"
    return 1
  fi

  error "Download failed"
  echo ""
  info "The release may not exist yet or your platform may not be supported."
  info "Check available releases at:"
  info "${BOLD}${UNDERLINE}https://github.com/${GITHUB_USER}/${REPO_NAME}/releases${NC}"
  echo ""

  return 1
}

unpack() {
  local archive=$1
  local bin_dir=$2
  local sudo=${3-}

  case "$archive" in
    *.tar.gz)
      local flags
      flags=$(test -n "${VERBOSE-}" && echo "-xzvof" || echo "-xzof")
      ${sudo} tar "${flags}" "${archive}" -C "${bin_dir}"
      return 0
      ;;
    *.zip)
      local flags
      flags=$(test -n "${VERBOSE-}" && echo "-o" || echo "-qqo")
      UNZIP="${flags}" ${sudo} unzip "${archive}" -d "${bin_dir}"
      return 0
      ;;
  esac

  error "Unknown package extension."
  echo ""
  info "This almost certainly results from a bug in this script--please file a"
  info "bug report at https://github.com/${GITHUB_USER}/${REPO_NAME}/issues"
  return 1
}

# Verify SHA256 checksum of downloaded archive against checksums.txt from release
verify_checksum() {
  local archive="$1"
  local archive_name="$2"

  local checksums_url="${BASE_URL}/latest/download/checksums.txt"
  local checksums_tmpfile
  checksums_tmpfile=$(get_tmpfile "txt")

  info "Downloading checksums..."
  if ! download "${checksums_tmpfile}" "${checksums_url}" 2>/dev/null; then
    warn "Could not download checksums.txt, skipping verification"
    warn "This may be expected for older releases without checksums"
    rm -f "${checksums_tmpfile}"
    return 0
  fi

  # Extract expected checksum for our archive
  local expected
  expected=$(grep "${archive_name}" "${checksums_tmpfile}" 2>/dev/null | awk '{print $1}')
  rm -f "${checksums_tmpfile}"

  if [[ -z "$expected" ]]; then
    warn "No checksum found for ${archive_name}, skipping verification"
    return 0
  fi

  info "Verifying checksum..."

  # Compute actual checksum (works on macOS and Linux)
  local actual
  if has shasum; then
    actual=$(shasum -a 256 "${archive}" | awk '{print $1}')
  elif has sha256sum; then
    actual=$(sha256sum "${archive}" | awk '{print $1}')
  else
    warn "No SHA256 tool found (shasum or sha256sum), skipping verification"
    return 0
  fi

  if [[ "${actual}" != "${expected}" ]]; then
    error "Checksum verification FAILED!"
    error "Expected: ${expected}"
    error "Actual:   ${actual}"
    error ""
    error "The downloaded file may be corrupted or tampered with."
    error "Please try again or download manually from:"
    error "${BOLD}${UNDERLINE}https://github.com/${GITHUB_USER}/${REPO_NAME}/releases${NC}"
    rm -f "${archive}"
    return 1
  fi

  completed "Checksum verified"
}

usage() {
  cat <<EOF
${DISPLAY_NAME} Installer

Usage: install.sh [options]

Options:
    -h, --help              Display this help message
    -V, --verbose           Enable verbose output for the installer
    -f, -y, --force, --yes  Skip the confirmation prompt during installation
    -p, --platform          Override the platform identified by the installer [default: ${PLATFORM}]
    -b, --bin-dir           Override the bin installation directory [default: ${BIN_DIR}]
    -a, --arch              Override the architecture identified by the installer [default: ${ARCH}]
    -B, --base-url          Override the base URL used for downloading releases [default: ${BASE_URL}]

Examples:
    curl -fsSL https://raw.githubusercontent.com/${GITHUB_USER}/${REPO_NAME}/main/scripts/install.sh | bash
    ./install.sh --bin-dir /opt/bin
EOF
}

elevate_priv() {
  if ! has sudo; then
    error 'Could not find the command "sudo", needed to get permissions for install.'
    info "Please run this script as root, or install sudo."
    exit 1
  fi

  if ! sudo -v; then
    error "Superuser not granted, aborting installation"
    exit 1
  fi
}

install() {
  local ext="$1"
  local archive_name="${BINARY_NAME}-${TARGET}.${ext}"

  local sudo=""
  if test_writeable "${BIN_DIR}"; then
    sudo=""
  else
    warn "Escalated permissions are required to install to ${BIN_DIR}"
    elevate_priv
    sudo="sudo"
  fi

  print_message info "\n${MUTED}Installing ${NC}${DISPLAY_NAME} ${MUTED}to ${NC}${BIN_DIR}"
  local archive
  archive=$(get_tmpfile "$ext")

  # download to the temp file
  download "${archive}" "${URL}"

  # verify checksum before unpacking (fails hard if mismatch)
  verify_checksum "${archive}" "${archive_name}"

  # unpack the temp file to the bin dir, using sudo if required
  unpack "${archive}" "${BIN_DIR}" "${sudo}"

  # cleanup temp file
  rm -f "${archive}"
}

detect_platform() {
  # We've already verified macOS in verify_macos_or_exit
  printf '%s' "apple-darwin"
}

detect_arch() {
  local arch
  arch="$(uname -m | tr '[:upper:]' '[:lower:]')"

  case "${arch}" in
    amd64) arch="x86_64" ;;
    arm64) arch="aarch64" ;;
  esac

  # Check for Rosetta translation on Apple Silicon
  if [[ "$arch" == "x86_64" ]]; then
    local rosetta_flag
    rosetta_flag=$(sysctl -n sysctl.proc_translated 2>/dev/null || echo 0)
    if [[ "$rosetta_flag" == "1" ]]; then
      arch="aarch64"
    fi
  fi

  printf '%s' "${arch}"
}

detect_target() {
  local arch="$1"
  local platform="$2"
  local target="$arch-$platform"

  printf '%s' "${target}"
}

confirm() {
  if [[ -z "${FORCE-}" ]]; then
    printf "${MAGENTA}?${NC} %b ${BOLD}[y/N]${NC} " "$*"
    set +e
    read -r yn </dev/tty
    rc=$?
    set -e
    if [[ $rc -ne 0 ]]; then
      error "Error reading from prompt (please re-run with the '--yes' option)"
      exit 1
    fi
    if [[ "$yn" != "y" ]] && [[ "$yn" != "yes" ]]; then
      error 'Aborting (please answer "yes" to continue)'
      exit 1
    fi
  fi
}

check_bin_dir() {
  local bin_dir="${1%/}"

  if [[ ! -d "$bin_dir" ]]; then
    error "Installation location $bin_dir does not appear to be a directory"
    info "Make sure the location exists and is a directory, then try again."
    usage
    exit 1
  fi

  # https://stackoverflow.com/a/11655875
  local good
  good=$(
    IFS=:
    for path in $PATH; do
      if [[ "${path%/}" == "${bin_dir}" ]]; then
        printf 1
        break
      fi
    done
  )

  if [[ "${good}" != "1" ]]; then
    warn "Bin directory ${bin_dir} is not in your \$PATH"
    info "You may need to add it to your shell profile or use the full path to run ${BINARY_NAME}"
  fi
}

is_build_available() {
  local arch="$1"
  local platform="$2"
  local target="$3"

  local good
  good=$(
    IFS=" "
    for t in $SUPPORTED_TARGETS; do
      if [[ "${t}" == "${target}" ]]; then
        printf 1
        break
      fi
    done
  )

  if [[ "${good}" != "1" ]]; then
    error "${arch} builds for ${platform} are not yet available for ${DISPLAY_NAME}"
    echo "" >&2
    info "If you would like to see a build for your configuration,"
    info "please create an issue requesting a build for ${MAGENTA}${target}${NC}:"
    info "${BOLD}${UNDERLINE}https://github.com/${GITHUB_USER}/${REPO_NAME}/issues/new/${NC}"
    echo ""
    exit 1
  fi
}

# defaults
if [[ -z "${PLATFORM-}" ]]; then
  PLATFORM="$(detect_platform)"
fi

if [[ -z "${BIN_DIR-}" ]]; then
  BIN_DIR=/usr/local/bin
fi

if [[ -z "${ARCH-}" ]]; then
  ARCH="$(detect_arch)"
fi

if [[ -z "${BASE_URL-}" ]]; then
  BASE_URL="https://github.com/${GITHUB_USER}/${REPO_NAME}/releases"
fi

# Non-POSIX shells can break once executing code due to semantic differences
verify_shell_is_posix_or_exit

# Ensure we're on macOS before proceeding
verify_macos_or_exit

# parse argv variables
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    -p | --platform)
      PLATFORM="$2"
      shift 2
      ;;
    -b | --bin-dir)
      BIN_DIR="$2"
      shift 2
      ;;
    -a | --arch)
      ARCH="$2"
      shift 2
      ;;
    -B | --base-url)
      BASE_URL="$2"
      shift 2
      ;;
    -V | --verbose)
      VERBOSE=1
      shift 1
      ;;
    -f | -y | --force | --yes)
      FORCE=1
      shift 1
      ;;
    -h | --help)
      usage
      exit
      ;;
    -p=* | --platform=*)
      PLATFORM="${1#*=}"
      shift 1
      ;;
    -b=* | --bin-dir=*)
      BIN_DIR="${1#*=}"
      shift 1
      ;;
    -a=* | --arch=*)
      ARCH="${1#*=}"
      shift 1
      ;;
    -B=* | --base-url=*)
      BASE_URL="${1#*=}"
      shift 1
      ;;
    -V=* | --verbose=*)
      VERBOSE="${1#*=}"
      shift 1
      ;;
    -f=* | -y=* | --force=* | --yes=*)
      FORCE="${1#*=}"
      shift 1
      ;;
    *)
      echo -e "${YELLOW}Warning: Unknown option '$1'${NC}" >&2
      shift
      ;;
  esac
done

TARGET="$(detect_target "${ARCH}" "${PLATFORM}")"

is_build_available "${ARCH}" "${PLATFORM}" "${TARGET}"

echo ""
echo -e "${UNDERLINE}Configuration${NC}"
echo ""
echo -e "${MUTED}Bin directory:${NC} ${GREEN}${BIN_DIR}${NC}"
echo -e "${MUTED}Platform:${NC}      ${GREEN}${PLATFORM}${NC}"
echo -e "${MUTED}Arch:${NC}          ${GREEN}${ARCH}${NC}"

# non-empty VERBOSE enables verbose untarring
if [[ -n "${VERBOSE-}" ]]; then
  VERBOSE=v
  echo -e "${MUTED}Verbose${NC}: yes"
else
  VERBOSE=
fi

echo ""

EXT=tar.gz
URL="${BASE_URL}/latest/download/${BINARY_NAME}-${TARGET}.${EXT}"
echo -e "${MUTED}Tarball URL:${NC}   ${UNDERLINE}${BLUE}${URL}${NC}"
echo ""
confirm "Install ${DISPLAY_NAME} ${GREEN}latest${NC} to ${BOLD}${GREEN}${BIN_DIR}${NC}?"

install "${EXT}"

check_bin_dir "${BIN_DIR}"

echo -e ""
echo -e "${MUTED}                        ${NC}      ▄     "
echo -e "${MUTED}█▀▀█ █▀▀▄ █▀▀▀ █▀▀█ █▀▀█ ${NC}█▀▀▀ █▀▀█ █▀▀▀"
echo -e "${MUTED}█░░█ █░░█ █░░█ █░░█ █▀▀█ ${NC}▀▀▀█ █░░█ █▀▀▀"
echo -e "${MUTED}█▀▀▀ ▀  ▀ ▀▀▀▀ █▀▀▀ ▀░░▀ ${NC}▀▀▀▀ ▀▀▀▀ ▀▀▀▀"
echo -e ""
echo -e ""
echo -e "${MUTED}To use pngpaste:${NC}"
echo -e ""
echo -e "pngpaste <output.png>  ${MUTED}# Paste clipboard image to file${NC}"
echo -e "pngpaste -             ${MUTED}# Paste to stdout${NC}"
echo -e ""
echo -e "${MUTED}For more information visit ${NC}https://github.com/${GITHUB_USER}/${REPO_NAME}"
echo -e ""
