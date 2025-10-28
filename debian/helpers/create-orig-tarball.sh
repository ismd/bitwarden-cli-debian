#!/bin/bash
# Helper script to create the orig.tar.gz with bundled dependencies
# This script should be run from the repository root

set -e

# Configuration
PACKAGE_NAME="bitwarden-cli"
VERSION=${1:-$(dpkg-parsechangelog -S Version | cut -d- -f1)}
OUTPUT_DIR=${2:-..}

echo "=== Creating orig tarball for ${PACKAGE_NAME} ${VERSION} ==="
echo ""

# Check we're in the right place
if [ ! -f "debian/control" ]; then
    echo "ERROR: Must be run from repository root (where debian/ directory is)"
    exit 1
fi

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
    echo "ERROR: node_modules/ not found!"
    echo ""
    echo "Please run first:"
    echo "  npm ci"
    echo ""
    exit 1
fi

echo "✓ Found node_modules/ directory"
echo ""

# Create temporary directory for tarball creation
TEMP_DIR=$(mktemp -d)
TARBALL_DIR="${TEMP_DIR}/${PACKAGE_NAME}-${VERSION}"
TARBALL_NAME="${PACKAGE_NAME}_${VERSION}.orig.tar.gz"

echo "Creating tarball structure in: ${TARBALL_DIR}"
mkdir -p "${TARBALL_DIR}"

echo "Copying source files..."

# Copy all source files except debian/ and version control
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
    ./ "${TARBALL_DIR}/"

echo ""
echo "Checking tarball contents..."
du -sh "${TARBALL_DIR}"
echo "  Source files: $(find "${TARBALL_DIR}" -type f | wc -l) files"
echo "  node_modules: $(find "${TARBALL_DIR}/node_modules" -type f 2>/dev/null | wc -l) files"

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
