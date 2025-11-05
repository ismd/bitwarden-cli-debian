#!/bin/bash
# Check for latest Bitwarden CLI version from upstream
# Usage: ./check-upstream-version.sh [--json]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION_FILE="${SCRIPT_DIR}/current-version.txt"
UPSTREAM_API="https://api.github.com/repos/bitwarden/clients/releases"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Parse arguments
JSON_OUTPUT=false
if [ "$1" = "--json" ]; then
    JSON_OUTPUT=true
fi

# Get current version
if [ -f "${VERSION_FILE}" ]; then
    CURRENT_VERSION=$(cat "${VERSION_FILE}")
else
    CURRENT_VERSION="none"
fi

# Fetch latest CLI release from GitHub API
# Filter for tags starting with "cli-v"
if ! LATEST_RELEASE=$(curl -s "${UPSTREAM_API}" | jq -r '[.[] | select(.tag_name | startswith("cli-v"))] | .[0]'); then
    echo "Error: Failed to fetch releases from GitHub API" >&2
    exit 1
fi

LATEST_TAG=$(echo "${LATEST_RELEASE}" | jq -r '.tag_name')
LATEST_NAME=$(echo "${LATEST_RELEASE}" | jq -r '.name')
LATEST_URL=$(echo "${LATEST_RELEASE}" | jq -r '.html_url')
LATEST_DATE=$(echo "${LATEST_RELEASE}" | jq -r '.published_at')

if [ "${LATEST_TAG}" = "null" ] || [ -z "${LATEST_TAG}" ]; then
    echo "Error: Could not determine latest CLI version" >&2
    exit 1
fi

# Check if update available
UPDATE_AVAILABLE=false
if [ "${CURRENT_VERSION}" != "${LATEST_TAG}" ] && [ "${CURRENT_VERSION}" != "none" ]; then
    UPDATE_AVAILABLE=true
fi

# Output results
if [ "${JSON_OUTPUT}" = true ]; then
    # JSON output for GitHub Actions
    cat <<EOF
{
  "current_version": "${CURRENT_VERSION}",
  "latest_version": "${LATEST_TAG}",
  "latest_name": "${LATEST_NAME}",
  "latest_url": "${LATEST_URL}",
  "latest_date": "${LATEST_DATE}",
  "update_available": ${UPDATE_AVAILABLE}
}
EOF
else
    # Human-readable output
    echo -e "${BLUE}Current version:${NC} ${CURRENT_VERSION}"
    echo -e "${BLUE}Latest version:${NC}  ${LATEST_TAG}"
    echo -e "${BLUE}Release name:${NC}    ${LATEST_NAME}"
    echo -e "${BLUE}Release date:${NC}    ${LATEST_DATE}"
    echo -e "${BLUE}Release URL:${NC}     ${LATEST_URL}"
    echo

    if [ "${UPDATE_AVAILABLE}" = true ]; then
        echo -e "${YELLOW}⚠ Update available!${NC}"
        echo
        echo "To update, run:"
        echo "  ${SCRIPT_DIR}/import-upstream.sh ${LATEST_TAG}"
    elif [ "${CURRENT_VERSION}" = "none" ]; then
        echo -e "${YELLOW}⚠ No version imported yet${NC}"
        echo
        echo "To import, run:"
        echo "  ${SCRIPT_DIR}/import-upstream.sh ${LATEST_TAG}"
    else
        echo -e "${GREEN}✓ Up to date${NC}"
    fi
fi

exit 0
