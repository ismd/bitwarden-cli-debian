#!/bin/bash
# Import upstream Bitwarden CLI sources into packaging repository
# Usage: ./import-upstream.sh <version-tag>
# Example: ./import-upstream.sh cli-v2025.10.1

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
UPSTREAM_REPO="https://github.com/bitwarden/clients.git"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TEMP_DIR="${SCRIPT_DIR}/temp-upstream-import"
VERSION_FILE="${SCRIPT_DIR}/current-version.txt"
MANIFEST_FILE="${SCRIPT_DIR}/imported-manifest.txt"

# ============================================================================
# Tier 1: NEVER import (protected files/directories)
# ============================================================================
PROTECTED_PATHS=(
    ".git"
    ".github"
    "debian"
    ".packaging"
    "README.md"
    ".gitignore"
)

# ============================================================================
# Tier 2: Rename with .upstream suffix (config files that conflict)
# ============================================================================
RENAME_UPSTREAM=(
    # Documentation
    "CONTRIBUTING.md"
    "SECURITY.md"

    # Editor/IDE configs
    ".editorconfig"
    ".vscode"

    # Git hooks
    ".husky"

    # Node.js configs
    ".npmrc"
    ".nvmrc"

    # Code formatting/linting
    ".prettierrc.json"
    ".prettierignore"
    ".browserslistrc"

    # UI documentation
    ".storybook"

    # Other configs that might conflict
    ".checkmarx"
    ".codescene"
    ".git-blame-ignore-revs"
    ".gitattributes"
)

# ============================================================================
# Functions
# ============================================================================

print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}============================================${NC}"
}

print_info() {
    echo -e "${GREEN}➜${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

usage() {
    cat <<EOF
Usage: $0 <version-tag>

Import upstream Bitwarden CLI sources into this packaging repository.

Arguments:
  version-tag    Git tag from upstream (e.g., cli-v2025.10.1)

Example:
  $0 cli-v2025.10.1

This script will:
  1. Clone upstream repository to temporary directory
  2. Checkout the specified tag
  3. Import sources using three-tier strategy:
     - Protected files (.github/, debian/) - never imported
     - Config files (.editorconfig, etc.) - renamed with .upstream suffix
     - Everything else - imported as-is
  4. Update version tracking file
  5. Generate import manifest

Protected paths (never imported):
$(printf '  - %s\n' "${PROTECTED_PATHS[@]}")

Renamed paths (imported with .upstream suffix):
$(printf '  - %s\n' "${RENAME_UPSTREAM[@]}")

EOF
}

cleanup() {
    if [ -d "${TEMP_DIR}" ]; then
        print_info "Cleaning up temporary directory..."
        rm -rf "${TEMP_DIR}"
    fi
}

trap cleanup EXIT

# ============================================================================
# Main Script
# ============================================================================

# Parse arguments
if [ $# -ne 1 ]; then
    print_error "Error: Version tag required"
    echo
    usage
    exit 1
fi

VERSION_TAG="$1"

# Validate version tag format
if [[ ! "${VERSION_TAG}" =~ ^cli-v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    print_warning "Warning: Version tag '${VERSION_TAG}' doesn't match expected format 'cli-vX.Y.Z'"
    read -p "Continue anyway? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

print_header "Importing Bitwarden CLI ${VERSION_TAG}"

# Check if already at this version
if [ -f "${VERSION_FILE}" ]; then
    CURRENT_VERSION=$(cat "${VERSION_FILE}")
    if [ "${CURRENT_VERSION}" = "${VERSION_TAG}" ]; then
        print_warning "Already at version ${VERSION_TAG}"
        read -p "Re-import anyway? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 0
        fi
    else
        print_info "Current version: ${CURRENT_VERSION}"
        print_info "New version: ${VERSION_TAG}"
    fi
else
    print_info "No previous version found (first import)"
fi

# Step 1: Clone upstream
print_header "Step 1: Cloning upstream repository"
print_info "Repository: ${UPSTREAM_REPO}"
print_info "Destination: ${TEMP_DIR}"

if [ -d "${TEMP_DIR}" ]; then
    print_warning "Temporary directory exists, removing..."
    rm -rf "${TEMP_DIR}"
fi

git clone --depth 1 --branch "${VERSION_TAG}" "${UPSTREAM_REPO}" "${TEMP_DIR}"

if [ $? -ne 0 ]; then
    print_error "Failed to clone repository or tag not found"
    exit 1
fi

print_info "Clone successful"

# Step 2: Remove upstream's .git directory
print_header "Step 2: Cleaning upstream clone"
rm -rf "${TEMP_DIR}/.git"
print_info "Removed .git directory from upstream clone"

# Step 3: Build rsync exclude pattern for protected paths
print_header "Step 3: Preparing import (protecting our files)"
RSYNC_EXCLUDES=()
for path in "${PROTECTED_PATHS[@]}"; do
    RSYNC_EXCLUDES+=(--exclude="${path}")
    print_info "Protecting: ${path}"
done

# Step 4: Rename Tier 2 files (add .upstream suffix) BEFORE importing
print_header "Step 4: Renaming conflicting config files"

for file in "${RENAME_UPSTREAM[@]}"; do
    SOURCE_PATH="${TEMP_DIR}/${file}"
    DEST_PATH="${TEMP_DIR}/${file}.upstream"

    # Check if file/directory exists in upstream sources
    if [ -e "${SOURCE_PATH}" ]; then
        # Rename to .upstream in temp directory
        mv "${SOURCE_PATH}" "${DEST_PATH}"
        print_info "Renamed: ${file} → ${file}.upstream"
    fi
done

# Step 5: Import everything except protected paths
print_header "Step 5: Importing upstream sources"
print_info "Copying from ${TEMP_DIR}"
print_info "Copying to ${REPO_ROOT}"
print_warning "Files deleted upstream will be removed from repository"

# Use rsync for efficient copying with excludes
# --delete removes files in destination that don't exist in source
# --exclude patterns protect our packaging files from being deleted
rsync -av --delete "${RSYNC_EXCLUDES[@]}" "${TEMP_DIR}/" "${REPO_ROOT}/"

if [ $? -ne 0 ]; then
    print_error "Failed to import sources"
    exit 1
fi

print_info "Import complete"

# Step 6: Handle upstream README specially
print_header "Step 6: Handling upstream README"

UPSTREAM_README="${REPO_ROOT}/README.upstream.md"

# Remove old upstream README if exists
if [ -f "${UPSTREAM_README}" ]; then
    rm -f "${UPSTREAM_README}"
fi

# Copy upstream's README as README.upstream.md
if [ -f "${TEMP_DIR}/README.md" ]; then
    cp "${TEMP_DIR}/README.md" "${UPSTREAM_README}"
    print_info "Created: README.upstream.md (from upstream's README.md)"
else
    print_warning "No README.md found in upstream sources"
fi

# Step 7: Update version tracking
print_header "Step 7: Updating version tracking"

echo "${VERSION_TAG}" > "${VERSION_FILE}"
print_info "Updated ${VERSION_FILE}"

# Step 8: Generate import manifest
print_header "Step 8: Generating import manifest"

cat > "${MANIFEST_FILE}" <<EOF
# Import Manifest
# Generated: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
# Upstream version: ${VERSION_TAG}
# Upstream repository: ${UPSTREAM_REPO}

## Protected Files (not imported)

$(printf '%s\n' "${PROTECTED_PATHS[@]}" | sed 's/^/- /')

## Renamed Files (imported with .upstream suffix)

$(printf '%s\n' "${RENAME_UPSTREAM[@]}" | sed 's/^/- /')

## Imported Files and Directories

$(cd "${REPO_ROOT}" && find . -maxdepth 1 -not -path . -not -path './debian' -not -path './.packaging' -not -path './.git' -not -path './.github' -not -path './README.md' -not -path './.gitignore' | sort | sed 's/^/- /')

## Import Statistics

- Upstream tag: ${VERSION_TAG}
- Import date: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
- Import script: $0

EOF

print_info "Generated ${MANIFEST_FILE}"

# Step 9: Summary
print_header "Import Complete"
print_info "Upstream version: ${VERSION_TAG}"
print_info "Version file: ${VERSION_FILE}"
print_info "Manifest file: ${MANIFEST_FILE}"
echo
print_info "Next steps:"
echo "  1. Review changes: git status"
echo "  2. Check imported files: git diff"
echo "  3. Test build: dpkg-buildpackage -b -us -uc"
echo "  4. Commit: git add . && git commit -m 'chore: import upstream ${VERSION_TAG}'"
echo

exit 0
