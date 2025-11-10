#!/bin/bash
# Helper script to create the orig.tar.gz with bundled dependencies
#
# Usage:
#   From inside source tree:  debian/helpers/create-orig-tarball.sh [VERSION] [OUTPUT_DIR]
#   From outside source tree: /path/to/debian/helpers/create-orig-tarball.sh SOURCE_DIR [VERSION] [OUTPUT_DIR]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRUNE_BIN_SCRIPT="${SCRIPT_DIR}/prune-binary-blobs.sh"

# Detect if first argument is a directory (source tree path)
if [ -d "$1" ] && [ -f "$1/package.json" ]; then
    SOURCE_DIR="$1"
    shift
else
    SOURCE_DIR="."
fi

# Configuration
PACKAGE_NAME="bitwarden-cli"
VERSION=${1}
OUTPUT_DIR=${2:-$(dirname "$(realpath "${SOURCE_DIR}")")}

# Convert to absolute path
OUTPUT_DIR=$(realpath "${OUTPUT_DIR}")

# Auto-detect version if not provided
if [ -z "$VERSION" ]; then
    if [ -f "${SOURCE_DIR}/debian/changelog" ]; then
        VERSION=$(cd "${SOURCE_DIR}" && dpkg-parsechangelog -S Version | cut -d- -f1)
    elif [ -f "${SOURCE_DIR}/apps/cli/package.json" ]; then
        VERSION=$(jq -r '.version' "${SOURCE_DIR}/apps/cli/package.json")
    else
        echo "ERROR: Could not auto-detect version. Please provide VERSION as argument."
        exit 1
    fi
fi

echo "=== Creating orig tarball for ${PACKAGE_NAME} ${VERSION} ==="
echo "Source directory: ${SOURCE_DIR}"
echo "Output directory: ${OUTPUT_DIR}"
echo ""

# Check if source directory has required files
if [ ! -f "${SOURCE_DIR}/package.json" ]; then
    echo "ERROR: ${SOURCE_DIR} does not look like Bitwarden clients source (no package.json)"
    exit 1
fi

# Check if node_modules exists
if [ ! -d "${SOURCE_DIR}/node_modules" ]; then
    echo "ERROR: node_modules/ not found in ${SOURCE_DIR}!"
    echo ""
    echo "Please run first:"
    echo "  cd ${SOURCE_DIR} && npm ci"
    echo ""
    exit 1
fi

echo "✓ Found node_modules/ directory"

# Check if .pkg-cache exists (required for offline build)
if [ ! -d "${SOURCE_DIR}/.pkg-cache" ]; then
    echo "WARNING: .pkg-cache/ not found!"
    echo ""
    echo "The pkg tool needs to download Node.js base binaries on first build."
    echo "To create a fully offline-buildable tarball:"
    echo "  1. cd ${SOURCE_DIR}"
    echo "  2. export PKG_CACHE_PATH=\$(pwd)/.pkg-cache"
    echo "  3. cd apps/cli && npm run dist:oss:lin"
    echo "  4. cd ../.."
    echo "  5. Then re-run this script"
    echo ""
    echo "The .pkg-cache will be populated and included in the tarball."
    echo ""
    read -p "Continue without .pkg-cache? (build will require internet) [y/N]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    echo "✓ Found .pkg-cache/ directory"
fi

echo ""

# Create temporary directory for tarball creation
TEMP_DIR=$(mktemp -d)
TARBALL_DIR="${TEMP_DIR}/${PACKAGE_NAME}-${VERSION}"
TARBALL_NAME="${PACKAGE_NAME}_${VERSION}.orig.tar.gz"

echo "Creating tarball structure in: ${TARBALL_DIR}"
mkdir -p "${TARBALL_DIR}"

echo "Copying source files..."

# Copy all source files except debian/ and version control
# Note: .pkg-cache is included if it exists (required for offline builds)
rsync -av \
    --exclude='.git' \
    --exclude='.github' \
    --exclude='debian' \
    --exclude='.gitignore' \
    --exclude='.gitattributes' \
    --exclude='.git-blame-ignore-revs' \
    --exclude='*.log' \
    --exclude='build.log' \
    --exclude='lintian.log' \
    --exclude='apps/cli/build' \
    --exclude='apps/cli/dist' \
    --exclude='.npm' \
    --exclude='.cache' \
    "${SOURCE_DIR}/" "${TARBALL_DIR}/"

echo ""
echo "Pruning Windows-specific binary blobs (lintian compliance)..."
"${PRUNE_BIN_SCRIPT}" "${TARBALL_DIR}"

REQUIRED_NOTICES=(
    "node_modules/playwright-core/NOTICE"
    "node_modules/playwright/NOTICE"
)

for notice in "${REQUIRED_NOTICES[@]}"; do
    if [ ! -f "${TARBALL_DIR}/${notice}" ]; then
        echo "ERROR: Required Apache NOTICE file missing: ${notice}"
        echo "Please ensure 'npm ci' has populated node_modules correctly."
        exit 1
    fi
done

echo ""
echo "Checking tarball contents..."
du -sh "${TARBALL_DIR}"
echo "  Source files: $(find "${TARBALL_DIR}" -type f | wc -l) files"
echo "  node_modules: $(find "${TARBALL_DIR}/node_modules" -type f 2>/dev/null | wc -l) files"
if [ -d "${TARBALL_DIR}/.pkg-cache" ]; then
    echo "  .pkg-cache: $(find "${TARBALL_DIR}/.pkg-cache" -type f 2>/dev/null | wc -l) files (for offline build)"
fi

echo ""
echo "Creating tarball: ${OUTPUT_DIR}/${TARBALL_NAME}"
tar czf "${OUTPUT_DIR}/${TARBALL_NAME}" \
    -C "${TEMP_DIR}" \
    "${PACKAGE_NAME}-${VERSION}"

# Cleanup
rm -rf "${TEMP_DIR}"

echo ""
echo "✓ Tarball created successfully!"
echo ""
echo "File: ${OUTPUT_DIR}/${TARBALL_NAME}"
echo "Size: $(du -h "${OUTPUT_DIR}/${TARBALL_NAME}" | cut -f1)"
echo ""
echo "Next steps:"
echo "  1. Extract and test: cd ${OUTPUT_DIR} && tar xzf ${TARBALL_NAME} && cd ${PACKAGE_NAME}-${VERSION}"
echo "  2. Copy debian dir: cp -r <path-to>/debian ."
echo "  3. Build package: dpkg-buildpackage -us -uc -b"
