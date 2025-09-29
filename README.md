# Bitwarden CLI Debian Package

Debian package for the Bitwarden Command-line Interface (CLI).

## Installation

### From GitHub Releases
```bash
wget https://github.com/ismd/bitwarden-cli-debian/releases/latest/download/bitwarden-cli_2025.9.0-1_all.deb
sudo apt install ./bitwarden-cli_2025.9.0-1_all.deb
```

### Build from Source
```bash
git clone https://github.com/ismd/bitwarden-cli-debian.git
cd bitwarden-cli-debian
UPSTREAM_VERSION=2025.9.0 make build
UPSTREAM_VERSION=2025.9.0 make install
```

## Development

### Requirements
```bash
sudo apt-get install dpkg-dev lintian
```

### Build Commands
```bash
UPSTREAM_VERSION=2025.9.0 make build     # Build package
UPSTREAM_VERSION=2025.9.0 make validate  # Validate package
make clean                               # Clean artifacts
make help                                # Show all commands
```

## Automated Builds

Tagged releases automatically build packages via GitHub Actions:
```bash
git tag v2025.9.0-1
git push origin v2025.9.0-1
```

## Links

- [Bitwarden CLI Documentation](https://bitwarden.com/help/cli/)
- [Bitwarden CLI Source](https://github.com/bitwarden/clients/tree/main/apps/cli)
