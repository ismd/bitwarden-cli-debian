# Debian Packaging for Bitwarden CLI

This repository contains Debian packaging files for building Bitwarden CLI from source for submission to the Debian repository.

## Quick Start

```bash
# Build source package for version 2025.8.0
make source-package VERSION=2025.8.0

# Sign and upload to Debian
debsign ../bitwarden-cli_2025.8.0-1_source.changes
dput ../bitwarden-cli_2025.8.0-1_source.changes
```

## Workflow

### 1. Fetch Sources from Git Submodule

```bash
make prepare-source VERSION=2025.8.0
```

This will:
- Update the `upstream-source` git submodule
- Checkout tag `cli-v2025.8.0`
- Create `bitwarden-cli_2025.8.0.orig.tar.gz`

### 2. Build Source Package for Debian

```bash
make source-package VERSION=2025.8.0 REVISION=1
```

This will:
- Extract the orig.tar.gz
- Copy `debian/` directory into the source
- Update `debian/changelog` with version `2025.8.0-1`
- Build source package using `dpkg-buildpackage -S -sa`

Creates in parent directory:
- `bitwarden-cli_2025.8.0-1.dsc`
- `bitwarden-cli_2025.8.0-1.debian.tar.xz`
- `bitwarden-cli_2025.8.0-1_source.changes`
- `bitwarden-cli_2025.8.0.orig.tar.gz`

### 3. Sign and Upload to Debian

```bash
# Sign the package
debsign ../bitwarden-cli_2025.8.0-1_source.changes

# Upload to Debian (requires DD/DM account)
dput ../bitwarden-cli_2025.8.0-1_source.changes
```

## Repository Structure

```
bitwarden-cli-debian/
├── debian/              # Debian packaging files
│   ├── control         # Package metadata
│   ├── rules           # Build instructions
│   ├── changelog       # Version history
│   ├── copyright       # License information
│   ├── postinst        # Post-installation script
│   ├── prerm           # Pre-removal script
│   └── source/format   # Source format
├── upstream-source/     # Git submodule (bitwarden/clients)
├── Makefile            # Build helper
└── DEBIAN_PACKAGING.md # This file
```

## Build Dependencies

From `debian/control`:

```
Build-Depends: debhelper-compat (= 13),
               nodejs (>= 18),
               npm
```

## Important: NPM Dependency Issue

⚠️ **The package will build locally but will FAIL in Debian's buildd.**

### The Problem

Building from source requires:
```bash
npm ci  # Downloads 500+ packages from npmjs.com
```

Debian's buildd has no network access, so this will fail.

### Solutions

1. **Vendor dependencies** - Include `node_modules/` in orig.tar.gz
2. **Package all npm deps** - Create .deb for each npm package (months of work)
3. **Pre-built binary** - Package the compiled binary instead of source
4. **Work with Bitwarden** - Get official Debian packages from upstream

### Recommendation

Before submitting to Debian:
- Contact **pkg-javascript team** (debian-js@lists.debian.org)
- File **ITP (Intent To Package)** bug explaining the npm issue
- Discuss solutions with Debian mentors

## Testing Locally

Test build locally (requires network for npm):

```bash
# Prepare source
make prepare-source VERSION=2025.8.0

# Extract and enter build directory
cd ../bitwarden-cli-2025.8.0

# Build binary package for testing
dpkg-buildpackage -us -uc -b

# Install
sudo dpkg -i ../bitwarden-cli_2025.8.0-1_amd64.deb

# Test
bw --version
```

## Clean Up

```bash
make clean
```

Removes all build artifacts from parent directory.

## Makefile Targets

- `make help` - Show usage information
- `make prepare-source VERSION=x.y.z` - Fetch sources and create orig.tar.gz
- `make source-package VERSION=x.y.z [REVISION=n]` - Build source package
- `make clean` - Remove build artifacts

## References

- [Debian New Maintainers' Guide](https://www.debian.org/doc/manuals/maint-guide/)
- [Debian Policy Manual](https://www.debian.org/doc/debian-policy/)
- [Debian JavaScript Team](https://wiki.debian.org/Javascript/Nodejs)
- [npm2deb Documentation](https://wiki.debian.org/Javascript/Nodejs/Npm2Deb)

## Getting Help

- **Debian Mentors**: https://mentors.debian.net/
- **pkg-javascript mailing list**: debian-js@lists.debian.org
- **IRC**: #debian-js on OFTC
