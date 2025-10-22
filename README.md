# Bitwarden CLI Debian Package

Debian packaging files for building Bitwarden CLI from source for submission to the Debian repository.

## Quick Start

Build source package for Debian upload:

```bash
make source-package VERSION=2025.8.0
debsign ../bitwarden-cli_2025.8.0-1_source.changes
dput ../bitwarden-cli_2025.8.0-1_source.changes
```

## Documentation

See [DEBIAN_PACKAGING.md](DEBIAN_PACKAGING.md) for detailed instructions.

## Workflow

1. **Fetch sources from git submodule and select required tag:**
   ```bash
   make prepare-source VERSION=2025.8.0
   ```

2. **Build package for uploading to Debian:**
   ```bash
   make source-package VERSION=2025.8.0
   ```

## Repository Structure

- `debian/` - Debian packaging files
- `upstream-source/` - Git submodule pointing to bitwarden/clients
- `Makefile` - Build helper for creating source packages
- `DEBIAN_PACKAGING.md` - Detailed documentation

## Links

- [Bitwarden CLI Documentation](https://bitwarden.com/help/cli/)
- [Bitwarden CLI Source](https://github.com/bitwarden/clients/tree/main/apps/cli)
- [Debian New Maintainers' Guide](https://www.debian.org/doc/manuals/maint-guide/)
