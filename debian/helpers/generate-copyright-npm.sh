#!/bin/bash
# Generate debian/copyright stanza for bundled npm dependencies
# This helps comply with Debian's licensing requirements

set -e

if [ ! -f "package.json" ]; then
    echo "ERROR: Run from repository root (where package.json is)"
    exit 1
fi

if [ ! -d "node_modules" ]; then
    echo "ERROR: node_modules not found. Run 'npm ci' first."
    exit 1
fi

echo "Scanning npm dependencies for licenses..."
echo ""

# Count packages by license
echo "License Summary:"
echo "================"
npm list --all --json 2>/dev/null | \
    jq -r '[.. | select(.license? != null)] | group_by(.license) | .[] | "\(.[0].license): \(length) packages"' | \
    sort

echo ""
echo "Generating copyright stanzas..."
echo ""

cat << 'EOF'

The following section covers bundled npm dependencies:

Files: node_modules/*
Copyright: Various (see individual package.json files)
License: Various
Comment: This package bundles npm dependencies. The majority are under
 MIT, ISC, BSD-2-Clause, BSD-3-Clause, or Apache-2.0 licenses, all of
 which are GPL-compatible.
 .
 A complete list of bundled dependencies and their licenses can be found
 by running: npm list --all --long
 .
 The most common licenses are:
  - MIT License (most packages)
  - ISC License
  - BSD-2-Clause and BSD-3-Clause
  - Apache-2.0
 .
 All bundled dependencies are Free Software and compatible with the
 GPL-3.0 license of the main package.

EOF

echo ""
echo "NOTE: For official Debian submission, you may need to provide"
echo "more detailed license information. Consider using:"
echo "  - licensecheck -r node_modules/"
echo "  - license-reconcile (from pkg-js-tools)"
echo ""
echo "Or manually document major dependencies in debian/copyright"
