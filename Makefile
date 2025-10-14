#!/usr/bin/make -f

# Simplified Makefile for building with Debian tooling

PACKAGE_NAME := bitwarden-cli

.PHONY: all build clean install uninstall help

# Default target
all: build

# Build the .deb package using Debian tooling
build:
	@echo "Building package using dpkg-buildpackage..."
	dpkg-buildpackage -us -uc -b
	@echo "Package built successfully"
	@echo "Moving .deb file to current directory..."
	@mv ../*.deb . 2>/dev/null || true

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	rm -f *.deb *.changes *.buildinfo
	rm -rf clients node_modules debian/bitwarden-cli debian/.debhelper debian/files
	rm -rf debian/debhelper-build-stamp
	@echo "Clean complete"

# Install the package locally
install:
	@echo "Installing $(PACKAGE_NAME)..."
	@if [ ! -f *.deb ]; then \
		echo "Error: No .deb file found. Run 'make build' first."; \
		exit 1; \
	fi
	sudo dpkg -i *.deb
	@echo "Package installed successfully"

# Uninstall the package
uninstall:
	@echo "Uninstalling $(PACKAGE_NAME)..."
	sudo dpkg -r $(PACKAGE_NAME)
	@echo "Package uninstalled successfully"

# Validate the built package
validate:
	@echo "Validating package with lintian..."
	@if [ ! -f *.deb ]; then \
		echo "Error: No .deb file found. Run 'make build' first."; \
		exit 1; \
	fi
	lintian --info *.deb || true
	dpkg-deb --info *.deb
	dpkg-deb --contents *.deb

# Show help
help:
	@echo "Available targets:"
	@echo "  build        - Build the .deb package using dpkg-buildpackage"
	@echo "  clean        - Remove build artifacts"
	@echo "  install      - Install the built package locally"
	@echo "  uninstall    - Remove installed package"
	@echo "  validate     - Validate built package with lintian"
	@echo "  help         - Show this help message"
	@echo ""
	@echo "Note: Version is now managed in debian/changelog"
	@echo "Edit debian/changelog to change the package version"
