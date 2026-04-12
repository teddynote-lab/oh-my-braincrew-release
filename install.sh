#!/usr/bin/env bash
# install.sh — Download and install the latest oh-my-braincrew binary from GitHub Releases
# Usage: curl -fsSL https://raw.githubusercontent.com/teddynote-lab/oh-my-braincrew-release/main/install.sh | bash
set -euo pipefail

REPO="teddynote-lab/oh-my-braincrew-release"
BINARY_NAME="oh-my-braincrew"
INSTALL_DIR="${HOME}/.local/bin"
GITHUB_API="https://api.github.com/repos/${REPO}/releases/latest"

# --- Cleanup on exit ---
TMP_DIR=""
cleanup() {
  if [[ -n "${TMP_DIR}" && -d "${TMP_DIR}" ]]; then
    rm -rf "${TMP_DIR}"
  fi
}
trap cleanup EXIT

# --- Helpers ---
error() {
  echo "ERROR: $*" >&2
  exit 1
}

info() {
  echo "==> $*"
}

# --- OS and architecture detection ---
detect_platform() {
  local os arch

  case "$(uname -s)" in
    Linux)  os="linux" ;;
    Darwin) os="darwin" ;;
    *)      error "Unsupported operating system: $(uname -s). Only linux and darwin are supported." ;;
  esac

  case "$(uname -m)" in
    x86_64 | amd64)  arch="amd64" ;;
    arm64 | aarch64) arch="arm64" ;;
    *)               error "Unsupported architecture: $(uname -m). Only amd64 and arm64 are supported." ;;
  esac

  echo "${os}_${arch}"
}

# --- Fetch latest release tag from GitHub API ---
fetch_latest_tag() {
  local tag
  tag=$(curl -fsSL "${GITHUB_API}" \
    -H "Accept: application/vnd.github+json" \
    | grep '"tag_name"' \
    | head -1 \
    | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')

  if [[ -z "${tag}" ]]; then
    error "Could not fetch latest release tag from ${GITHUB_API}. Check your internet connection."
  fi

  echo "${tag}"
}

# --- Download a file, abort on failure ---
download() {
  local url="$1"
  local dest="$2"
  if ! curl -fsSL --progress-bar -o "${dest}" "${url}"; then
    error "Download failed: ${url}"
  fi
}

# --- Verify SHA-256 checksum ---
verify_checksum() {
  local binary_file="$1"
  local checksum_file="$2"
  local binary_basename
  binary_basename="$(basename "${binary_file}")"

  # Extract the relevant line for this binary only
  local expected_line
  expected_line=$(grep "${binary_basename}" "${checksum_file}" 2>/dev/null || true)

  if [[ -z "${expected_line}" ]]; then
    error "No checksum entry found for '${binary_basename}' in $(basename "${checksum_file}")."
  fi

  # Write a single-line checksum file scoped to the binary
  local single_check="${TMP_DIR}/single.sha256"
  echo "${expected_line}" > "${single_check}"

  local old_dir
  old_dir="$(pwd)"
  cd "${TMP_DIR}"

  if command -v sha256sum &>/dev/null; then
    sha256sum -c "${single_check}" --status \
      || error "SHA-256 checksum mismatch for '${binary_basename}'. Aborting installation."
  elif command -v shasum &>/dev/null; then
    shasum -a 256 -c "${single_check}" --status \
      || error "SHA-256 checksum mismatch for '${binary_basename}'. Aborting installation."
  else
    error "Neither 'sha256sum' nor 'shasum' found. Cannot verify checksum. Install one and retry."
  fi

  cd "${old_dir}"
  info "Checksum verified."
}

# --- Main ---
main() {
  info "Detecting platform..."
  local platform
  platform=$(detect_platform)
  local os arch
  os="${platform%%_*}"
  arch="${platform##*_}"
  info "Platform: ${os}/${arch}"

  info "Fetching latest release..."
  local tag
  tag=$(fetch_latest_tag)
  info "Latest release: ${tag}"

  # Expected asset names follow the pattern: oh-my-braincrew-v0.1.4-linux-amd64
  local asset_name="${BINARY_NAME}-${tag}-${os}-${arch}"
  local base_url="https://github.com/${REPO}/releases/download/${tag}"
  local binary_url="${base_url}/${asset_name}"
  local checksum_url="${base_url}/checksums-sha256.txt"

  info "Downloading binary..."
  TMP_DIR="$(mktemp -d)"
  local binary_path="${TMP_DIR}/${asset_name}"
  local checksum_path="${TMP_DIR}/checksums-sha256.txt"

  download "${binary_url}" "${binary_path}"
  download "${checksum_url}" "${checksum_path}"

  info "Verifying checksum..."
  verify_checksum "${binary_path}" "${checksum_path}"

  info "Installing to ${INSTALL_DIR}..."
  mkdir -p "${INSTALL_DIR}"
  mv "${binary_path}" "${INSTALL_DIR}/${BINARY_NAME}"
  chmod +x "${INSTALL_DIR}/${BINARY_NAME}"

  info "Installation complete: ${INSTALL_DIR}/${BINARY_NAME}"

  # --- PATH check ---
  if [[ ":${PATH}:" != *":${INSTALL_DIR}:"* ]]; then
    echo ""
    echo "WARNING: ${INSTALL_DIR} is not in your PATH."
    echo "Add it to your shell profile to use '${BINARY_NAME}' directly:"
    echo ""
    echo "  For bash:  echo 'export PATH=\"\${HOME}/.local/bin:\${PATH}\"' >> ~/.bashrc && source ~/.bashrc"
    echo "  For zsh:   echo 'export PATH=\"\${HOME}/.local/bin:\${PATH}\"' >> ~/.zshrc && source ~/.zshrc"
    echo ""
  fi

  # --- macOS Gatekeeper note ---
  if [[ "${os}" == "darwin" ]]; then
    echo ""
    echo "NOTE (macOS): If you see a 'cannot be opened because the developer cannot be verified' error, run:"
    echo ""
    echo "  xattr -d com.apple.quarantine ${INSTALL_DIR}/${BINARY_NAME}"
    echo ""
  fi

  info "Run '${BINARY_NAME} --version' to verify the installation."
  echo ""
  # Create or update omb symlink for shorter command
  ln -sf "${BINARY_NAME}" "${INSTALL_DIR}/omb"
  info "Symlink: omb -> ${BINARY_NAME}"

  echo "To set up omb harness files in your project:"
  echo ""
  echo "  cd /path/to/your/project"
  echo "  omb init"
  echo ""
}

main "$@"
