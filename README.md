# Bitwarden CLI Debian Package

Official Debian package for the Bitwarden Command-line Interface (CLI). This repository provides packaging scripts and automation to build `.deb` packages for easy installation on Debian-based systems.

## 📦 Installation

### From GitHub Releases (Recommended)

```bash
# Download the latest release
wget https://github.com/ismd/bitwarden-cli-debian/releases/latest/download/bitwarden-cli_2025.9.0-1_all.deb

# Install the package
sudo dpkg -i bitwarden-cli_2025.9.0-1_all.deb

# Fix any dependency issues (if needed)
sudo apt-get install -f
```

### Build from Source

```bash
# Clone the repository
git clone https://github.com/ismd/bitwarden-cli-debian.git
cd bitwarden-cli-debian

# Build the package (UPSTREAM_VERSION is required)
UPSTREAM_VERSION=2025.9.0 make build

# Install locally
UPSTREAM_VERSION=2025.9.0 make install
```

## 🚀 Usage

After installation, the `bw` command will be available:

```bash
# Get help
bw --help

# Login to Bitwarden
bw login

# List items
bw list items

# Get a specific item
bw get item <item-id>
```

## 🔧 Development

### Requirements

- `dpkg-dev` - Debian package development tools
- `lintian` - Debian package checker
- `make` - Build automation

### Building

```bash
# Install build dependencies
sudo apt-get install dpkg-dev lintian

# Build the package (UPSTREAM_VERSION environment variable required)
UPSTREAM_VERSION=2025.9.0 make build

# Validate the package
UPSTREAM_VERSION=2025.9.0 make validate

# Clean build artifacts
make clean
```

### Available Make Targets

**Note:** All targets except `clean`, `help`, and `uninstall` require the `UPSTREAM_VERSION` environment variable.

- `UPSTREAM_VERSION=X.Y.Z make build` - Build the .deb package (creates X.Y.Z-1)
- `UPSTREAM_VERSION=X.Y.Z make install` - Build and install package locally
- `make uninstall` - Remove installed package
- `make clean` - Remove build artifacts
- `UPSTREAM_VERSION=X.Y.Z make check` - Verify package structure
- `UPSTREAM_VERSION=X.Y.Z make validate` - Validate built package with lintian
- `UPSTREAM_VERSION=X.Y.Z make info` - Show package information
- `make help` - Show all available commands

**Debian Version Format:**
The package follows Debian versioning: `upstream-revision` (e.g., `2025.9.0-1`)

**Example usage:**
```bash
# Build version 2025.9.0-1 (first packaging of upstream 2025.9.0)
UPSTREAM_VERSION=2025.9.0 make build

# Build version 2025.9.0-2 (second packaging revision, same upstream)
UPSTREAM_VERSION=2025.9.0 DEBIAN_REVISION=2 make build

# Build version 2025.9.0-1 (new upstream version)
UPSTREAM_VERSION=2025.9.0 make build
```

## 🔄 Automated Builds

This repository uses GitHub Actions to automatically:

- Build packages on git tags
- Validate packages with lintian
- Create GitHub releases
- Upload .deb files as release assets

### Triggering a Build

1. **Tag-based release:**
   ```bash
   # Create first packaging of upstream version 2025.9.0
   git tag v2025.9.0-1
   git push origin v2025.9.0-1
   
   # Or use short form (defaults to revision 1)
   git tag v2025.9.0
   git push origin v2025.9.0
   
   # Create packaging revision 2 for same upstream
   git tag v2025.9.0-2  
   git push origin v2025.9.0-2
   ```

2. **Manual trigger:** Use the "Actions" tab in GitHub to manually run the workflow

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test the package build
5. Submit a pull request

### Reporting Issues

Please report issues at: https://github.com/ismd/bitwarden-cli-debian/issues

## 📄 License

This packaging work is provided as-is for the community. Please refer to the official Bitwarden CLI license for the actual software being packaged.

## 🔗 Related Links

- [Bitwarden Official Website](https://bitwarden.com/)
- [Bitwarden CLI Documentation](https://bitwarden.com/help/cli/)
- [Bitwarden CLI Source Code](https://github.com/bitwarden/clients/tree/main/apps/cli)
