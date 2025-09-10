# Bitwarden CLI Debian Package

Official Debian package for the Bitwarden Command-line Interface (CLI). This repository provides packaging scripts and automation to build `.deb` packages for easy installation on Debian-based systems.

## 📦 Installation

### From GitHub Releases (Recommended)

```bash
# Download the latest release
wget https://github.com/ismd/bitwarden-cli-debian/releases/latest/download/bitwarden-cli_2025.8.0_all.deb

# Install the package
sudo dpkg -i bitwarden-cli_2025.8.0_all.deb

# Fix any dependency issues (if needed)
sudo apt-get install -f
```

### Build from Source

```bash
# Clone the repository
git clone https://github.com/ismd/bitwarden-cli-debian.git
cd bitwarden-cli-debian

# Build the package (VERSION is required)
VERSION=2025.8.0 make build

# Install locally
VERSION=2025.8.0 make install
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

# Build the package (VERSION environment variable required)
VERSION=2025.8.0 make build

# Validate the package
VERSION=2025.8.0 make validate

# Clean build artifacts
make clean
```

### Available Make Targets

**Note:** All targets except `clean`, `help`, and `uninstall` require the `VERSION` environment variable.

- `VERSION=X.Y.Z make build` - Build the .deb package
- `VERSION=X.Y.Z make install` - Build and install package locally
- `make uninstall` - Remove installed package
- `make clean` - Remove build artifacts
- `VERSION=X.Y.Z make check` - Verify package structure
- `VERSION=X.Y.Z make validate` - Validate built package with lintian
- `VERSION=X.Y.Z make info` - Show package information
- `make help` - Show all available commands

**Example usage:**
```bash
VERSION=2025.8.0 make build
VERSION=2025.9.0 make install
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
   git tag v2025.8.0
   git push origin v2025.8.0
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
