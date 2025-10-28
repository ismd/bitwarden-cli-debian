#!/bin/bash
# Test script for Bitwarden CLI Debian package build
# This script tests the complete build process with bundled dependencies

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Bitwarden CLI Debian Package Build Test ===${NC}"
echo ""

# Check if we're in the right directory
if [ ! -f "debian/control" ]; then
    echo -e "${RED}ERROR: debian/control not found. Run this from the package root.${NC}"
    exit 1
fi

# Parse version from changelog
VERSION=$(dpkg-parsechangelog -S Version | cut -d- -f1)
DEBIAN_REVISION=$(dpkg-parsechangelog -S Version | cut -d- -f2)

echo "Package version: ${VERSION}-${DEBIAN_REVISION}"
echo ""

# Step 1: Check dependencies
echo -e "${BLUE}Step 1: Checking build dependencies...${NC}"
for cmd in dpkg-buildpackage lintian npm node rsync jq; do
    if command -v $cmd &> /dev/null; then
        echo -e "  ${GREEN}✓${NC} Found: $cmd"
    else
        echo -e "  ${RED}✗${NC} Missing: $cmd"
        MISSING_DEPS=1
    fi
done

if [ "${MISSING_DEPS}" = "1" ]; then
    echo ""
    echo -e "${RED}Please install missing dependencies:${NC}"
    echo "  sudo apt-get install build-essential debhelper devscripts lintian nodejs rsync jq"
    exit 1
fi
echo ""

# Step 2: Check if node_modules exists
echo -e "${BLUE}Step 2: Checking for bundled dependencies...${NC}"
if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}⚠ node_modules/ not found${NC}"
    echo ""
    echo "Installing dependencies..."
    npm ci
    echo -e "${GREEN}✓${NC} Dependencies installed"
else
    echo -e "${GREEN}✓${NC} node_modules/ directory exists"
fi
echo ""

# Step 3: Clean previous builds
echo -e "${BLUE}Step 3: Cleaning previous builds...${NC}"
debian/rules clean || true
rm -f ../bitwarden-cli_*.deb \
      ../bitwarden-cli_*.build \
      ../bitwarden-cli_*.buildinfo \
      ../bitwarden-cli_*.changes \
      build.log \
      lintian.log 2>/dev/null || true
echo -e "${GREEN}✓${NC} Cleaned"
echo ""

# Step 4: Build the package
echo -e "${BLUE}Step 4: Building package...${NC}"
echo "This may take several minutes..."
echo ""
if dpkg-buildpackage -us -uc -b 2>&1 | tee build.log; then
    echo ""
    echo -e "${GREEN}✓ Build successful!${NC}"
else
    echo ""
    echo -e "${RED}✗ Build failed!${NC}"
    echo "Check build.log for details"
    exit 1
fi
echo ""

# Step 5: Check the results
echo -e "${BLUE}Step 5: Examining build results...${NC}"
echo ""

DEB_FILE="../bitwarden-cli_${VERSION}-${DEBIAN_REVISION}_amd64.deb"

if [ ! -f "${DEB_FILE}" ]; then
    echo -e "${RED}ERROR: .deb file not found at ${DEB_FILE}${NC}"
    exit 1
fi

echo "Created files:"
ls -lh ../bitwarden-cli_*.deb ../bitwarden-cli_*.changes ../bitwarden-cli_*.buildinfo 2>/dev/null
echo ""

echo "Package info:"
dpkg-deb --info "${DEB_FILE}"
echo ""

echo "Package contents:"
dpkg-deb --contents "${DEB_FILE}"
echo ""

# Step 6: Run lintian
echo -e "${BLUE}Step 6: Running lintian (Debian policy checker)...${NC}"
if lintian -i ../bitwarden-cli_*.changes 2>&1 | tee lintian.log; then
    echo -e "${GREEN}✓ No lintian errors${NC}"
else
    echo -e "${YELLOW}⚠ Lintian found some issues (see lintian.log)${NC}"
    echo "This is often acceptable for initial packaging"
fi
echo ""

# Summary
echo -e "${GREEN}=== Build Complete ===${NC}"
echo ""
echo "Generated package: ${DEB_FILE}"
echo "Package size: $(du -h "${DEB_FILE}" | cut -f1)"
echo ""
echo "To test installation:"
echo "  sudo dpkg -i ${DEB_FILE}"
echo "  bw --version"
echo ""
echo "To remove:"
echo "  sudo apt-get remove bitwarden-cli"
echo ""
echo "Build logs:"
echo "  - build.log (full build output)"
echo "  - lintian.log (policy check results)"
