# Bitwarden CLI - Debian Package

This repository maintains the Debian packaging for Bitwarden CLI.

## Repository Structure

This is a **mixed repository** containing both upstream sources and Debian packaging:

```
bitwarden-cli-debian/
├── debian/              # Debian packaging files
├── .github/             # Our packaging automation workflows
├── .packaging/          # Scripts for upstream sync automation
├── apps/                # Upstream: Application sources (auto-imported)
├── libs/                # Upstream: Shared libraries (auto-imported)
├── scripts/             # Upstream: Build scripts (auto-imported)
├── package.json         # Upstream: Dependencies (auto-imported)
├── *.upstream.*         # Upstream configs (renamed to avoid conflicts)
└── README.md            # This file (packaging documentation)
```

## Upstream Documentation

For upstream Bitwarden CLI documentation, see:
- [README.upstream.md](README.upstream.md) (auto-imported from upstream)
- [CONTRIBUTING.upstream.md](CONTRIBUTING.upstream.md) (auto-imported from upstream)
- Official upstream: https://github.com/bitwarden/clients

## Quick Start - Building the Package

### Prerequisites

```bash
sudo apt-get install debhelper-compat nodejs npm
```

### Build from Source

```bash
# Install dependencies (uses bundled node_modules approach)
npm ci

# Build the package
dpkg-buildpackage -b -us -uc
```

The resulting `.deb` file will be in the parent directory.

## Testing in Clean Environment

See [debian/TESTING-CLEAN-BUILD.md](debian/TESTING-CLEAN-BUILD.md) for instructions on testing with sbuild.

## Upstream Source Management

### Current Upstream Version

The current imported upstream version is tracked in `.packaging/current-version.txt`.

### Updating Upstream Sources

#### Automated Updates

GitHub Actions automatically monitors for new Bitwarden CLI releases and creates pull requests with updated sources.

See: `.github/workflows/check-upstream.yml`

#### Manual Update

To manually import a specific upstream version:

```bash
.packaging/import-upstream.sh cli-v2025.10.1
```

This will:
1. Fetch the specified version from upstream
2. Import sources while preserving our packaging files
3. Rename conflicting config files with `.upstream` suffix
4. Update version tracking

#### What Gets Imported

- ✅ **Imported as-is:** Source code (apps/, libs/), package.json, LICENSE files
- 📝 **Renamed with .upstream:** README.md, CONTRIBUTING.md, editor configs
- 🚫 **Never imported:** debian/, .github/, .packaging/, our README.md & .gitignore

See `.packaging/import-upstream.sh` for the complete import logic.

## Debian Packaging Documentation

- [debian/README.source](debian/README.source) - Build approach and workflow
- [debian/TESTING-CLEAN-BUILD.md](debian/TESTING-CLEAN-BUILD.md) - Clean environment testing
- [debian/LINTIAN-NOTES.md](debian/LINTIAN-NOTES.md) - Lintian issues and resolutions

## Package Information

- **Package name:** bitwarden-cli
- **Binary name:** bw
- **Upstream:** https://github.com/bitwarden/clients
- **Debian package maintainer:** Vladimir Kosteley <debian@ismd.dev>

## Contributing to Packaging

If you want to contribute to the **Debian packaging** (not upstream):

1. Fork this repository
2. Make changes in `debian/` directory
3. Test with sbuild
4. Submit pull request

For contributing to **upstream Bitwarden**, see [CONTRIBUTING.upstream.md](CONTRIBUTING.upstream.md) or visit https://github.com/bitwarden/clients

## License

- **Upstream sources:** GPL-3.0 (see LICENSE_GPL.txt and LICENSE_BITWARDEN.txt)
- **Debian packaging:** GPL-3.0
- **Bundled npm dependencies:** Various DFSG-compatible licenses (see debian/copyright)

See [debian/copyright](debian/copyright) for complete license information.

## Useful Commands

```bash
# Check package for policy compliance
lintian -i ../bitwarden-cli_*.changes

# Build source package
dpkg-buildpackage -S -us -uc

# List current upstream version
cat .packaging/current-version.txt

# Check for upstream updates (manual)
.packaging/check-upstream-version.sh
```

## Links

- Bitwarden website: https://bitwarden.com/
- Upstream repository: https://github.com/bitwarden/clients
- Debian package tracker: (will be available after upload)
- Bug reports: (will be available after upload)

---

Last updated: 2025-10-29
Maintainer: Vladimir Kosteley <debian@ismd.dev>
