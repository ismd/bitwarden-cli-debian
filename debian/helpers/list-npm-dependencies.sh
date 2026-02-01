#!/bin/bash
# Helper script to list all npm dependencies with licenses
# This information is needed for debian/copyright file

set -e

echo "=== NPM Dependencies Report for debian/copyright ==="
echo ""

if [ ! -f "package.json" ]; then
    echo "ERROR: package.json not found. Run from repository root."
    exit 1
fi

if [ ! -d "node_modules" ]; then
    echo "ERROR: node_modules/ not found. Run 'npm ci' first."
    exit 1
fi

OUTPUT_FILE="debian/npm-dependencies-report.txt"

echo "Generating dependency report..."
echo "This may take a minute..."
echo ""

# Create the report header
cat > "${OUTPUT_FILE}" << 'EOF'
NPM Dependencies for Bitwarden CLI
===================================

This file lists all npm dependencies bundled in the orig.tar.gz.
It is used to document licenses in debian/copyright.

Generated on: $(date)

---

SUMMARY BY LICENSE
==================

EOF

# Get license summary
echo "License Summary:" | tee -a "${OUTPUT_FILE}"
npm list --all --json 2>/dev/null | \
    jq -r '
        .. |
        select(.license? != null) |
        .license
    ' | sort | uniq -c | sort -rn | tee -a "${OUTPUT_FILE}"

echo "" | tee -a "${OUTPUT_FILE}"
echo "---" | tee -a "${OUTPUT_FILE}"
echo "" | tee -a "${OUTPUT_FILE}"

# Detailed list
cat >> "${OUTPUT_FILE}" << 'EOF'
DETAILED DEPENDENCY LIST
========================

Format: Package Name | Version | License | Repository

EOF

npm list --all --json 2>/dev/null | \
    jq -r '
        [.. | select(.name? != null and .version? != null) | {
            name: .name,
            version: .version,
            license: (.license // "UNKNOWN"),
            repository: ((.repository.url // .repository // "N/A") | tostring)
        }] |
        unique_by(.name) |
        sort_by(.name) |
        .[] |
        "\(.name) | \(.version) | \(.license) | \(.repository)"
    ' >> "${OUTPUT_FILE}"

echo "" >> "${OUTPUT_FILE}"
echo "---" >> "${OUTPUT_FILE}"
echo "" >> "${OUTPUT_FILE}"
echo "Total unique packages: $(npm list --all --json 2>/dev/null | jq '[.. | select(.name? != null)] | unique_by(.name) | length')" >> "${OUTPUT_FILE}"

echo "✓ Report saved to: ${OUTPUT_FILE}"
echo ""
echo "Package statistics:"
echo "  Total dependencies: $(npm list --all --json 2>/dev/null | jq '[.. | select(.name? != null)] | unique_by(.name) | length')"
echo "  Direct dependencies: $(jq '.dependencies | length' package.json)"
echo "  Dev dependencies: $(jq '.devDependencies | length' package.json)"
echo ""
echo "IMPORTANT for debian/copyright:"
echo "  1. Review ${OUTPUT_FILE} for all licenses"
echo "  2. Common licenses in Node.js ecosystem:"
echo "     - MIT (most common, GPL-compatible)"
echo "     - BSD-2-Clause, BSD-3-Clause (GPL-compatible)"
echo "     - Apache-2.0 (GPL-3 compatible)"
echo "     - ISC (GPL-compatible)"
echo "  3. Watch out for:"
echo "     - Non-free licenses"
echo "     - Missing/unknown licenses"
echo "     - License conflicts"
echo "  4. Consider using 'debian/copyright_hints' from license-reconcile"
echo ""
echo "To check for potential license issues:"
echo "  npm install -g license-checker"
echo "  license-checker --summary"
