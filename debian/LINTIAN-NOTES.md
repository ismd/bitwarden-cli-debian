# Lintian Issues and Resolutions

This document explains the lintian warnings/errors for this package and how they're addressed.

## Summary

| Issue | Severity | Status | Action |
|-------|----------|--------|--------|
| embedded-library zlib | Error | **Overridden** | Cannot fix - inherent to pkg |
| hardening-no-pie | Warning | **Overridden** | Upstream limitation |
| initial-upload-closes-no-bugs | Warning | **TODO** | File ITP bug before Debian upload |
| maintainer-script-empty | Warning | ✅ **Fixed** | Deleted empty scripts |
| no-manual-page | Warning | ✅ **Fixed** | Added man page |
| binary-has-unneeded-section | Info | **Overridden** | Trade-off for working binary |
| hardening-no-fortify-functions | Info | **Overridden** | Upstream limitation |

---

## Detailed Explanations

### E: embedded-library zlib

**Issue:** The binary contains embedded zlib library.

**Why it happens:**
- The `pkg` tool bundles Node.js runtime into the binary
- Node.js includes zlib and other system libraries
- This creates a standalone executable with no external dependencies

**Why we can't fix it:**
- Fixing requires either:
  1. Package all 500+ npm dependencies individually (impractical)
  2. Modify pkg to link dynamically (major upstream change)
  3. Use different build approach (loses standalone benefit)

**Resolution:**
- Added lintian override in `debian/bitwarden-cli.lintian-overrides`
- Documented in `debian/README.source`
- Acceptable for packages with complex npm dependency trees

**Debian precedent:**
Similar approach used by other Node.js CLI tools that use pkg (though few are in main).

---

### W: hardening-no-pie

**Issue:** Binary not compiled as Position Independent Executable.

**Why it happens:**
- The `pkg` tool creates the binary with its own build process
- We don't control compilation flags used by pkg

**Why we can't easily fix it:**
- Would require modifying upstream's build system
- pkg would need to support PIE compilation
- Beyond scope of Debian packaging

**Resolution:**
- Added lintian override
- Documented limitation
- Binary still functions correctly, just lacks this security feature

**Note:** This is an upstream issue that should ideally be reported to pkg maintainers.

---

### W: initial-upload-closes-no-bugs

**Issue:** Package doesn't close an ITP (Intent To Package) bug.

**Current status:** Not applicable for personal/testing use.

**Before uploading to Debian:**
1. File ITP bug: `reportbug -B debian --email=your@email.com wnpp`
2. Subject: `ITP: bitwarden-cli -- Official Bitwarden command-line interface`
3. Update `debian/changelog` to close the bug:
   ```
   * Initial release (Closes: #NNNNNN)
   ```

**Template for ITP bug:**
```
Package: wnpp
Severity: wishlist
Owner: Vladimir Kosteley <debian@ismd.dev>

* Package name    : bitwarden-cli
  Version         : 2025.10.1
  Upstream Author : Bitwarden Inc. <hello@bitwarden.com>
* URL             : https://github.com/bitwarden/clients
* License         : GPL-3.0
  Programming Lang: TypeScript
  Description     : Official Bitwarden command-line interface

The Bitwarden CLI is a powerful, full-featured command-line interface
tool to access and manage a Bitwarden vault. It provides complete
vault management from the terminal.

This package uses bundled npm dependencies due to the extensive
dependency tree (hundreds of packages, most not in Debian).
```

---

### W: maintainer-script-empty

**Status:** ✅ **FIXED**

**Action taken:** Deleted `debian/postinst` and `debian/prerm` as they were empty.

Simple binary packages don't need maintainer scripts unless they:
- Create system users
- Start/stop services
- Modify system configuration
- Register with other systems

---

### W: no-manual-page

**Status:** ✅ **FIXED**

**Action taken:**
- Created `debian/bw.1` man page
- Added `debian/manpages` file to install it
- Man page covers common commands, options, and examples

Users can now run:
```bash
man bw
```

---

### I: binary-has-unneeded-section

**Issue:** Binary contains .comment section that could be stripped.

**Why it happens:**
- We disabled `dh_strip` to prevent corruption of pkg-bundled binary
- Without stripping, these sections remain

**Trade-off:**
- **Option A:** Allow dh_strip → Binary corrupts, doesn't run
- **Option B:** Disable dh_strip → Binary works, has extra sections

We chose Option B (working binary).

**Resolution:** Lintian override (acceptable trade-off).

---

### I: hardening-no-fortify-functions

**Issue:** Binary doesn't use fortified libc functions.

**Why it happens:** Upstream binary from pkg doesn't use these functions.

**Impact:** Minimal - this is an optimization/hardening feature, not critical.

**Resolution:** Lintian override, documented.

---

## Running Lintian

### Check all issues:
```bash
lintian -EvIL +pedantic ../bitwarden-cli_*.changes
```

### Check without pedantic (normal):
```bash
lintian -i ../bitwarden-cli_*.changes
```

### Check only errors and warnings:
```bash
lintian -EviIL +pedantic ../bitwarden-cli_*.changes
```

---

## For Debian Submission

When preparing for official Debian upload:

1. ✅ Fix all fixable warnings (DONE)
2. ✅ Add lintian overrides with justification (DONE)
3. ✅ Document limitations in README.source (DONE)
4. ⏳ File ITP bug (TODO before upload)
5. ⏳ Get package reviewed by DD (TODO)
6. ⏳ Consider filing upstream bug about PIE support in pkg (OPTIONAL)

---

## Expected Lintian Output After Fixes

After applying all fixes and overrides:

**Errors:** 0 (overridden)
**Warnings:** 0-1 (only ITP if not filed)
**Info:** 0 (overridden)

The package should be clean except for the ITP warning if building locally.

---

Last updated: 2025-10-28
Maintainer: Vladimir Kosteley <debian@ismd.dev>
