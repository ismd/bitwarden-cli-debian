#!/usr/bin/make -f

# Makefile for preparing Debian source package

PACKAGE_NAME := bitwarden-cli
VERSION ?= 2025.8.0
REVISION ?= 1
FULL_VERSION := $(VERSION)-$(REVISION)

ORIG_TARBALL := ../bitwarden-cli_$(VERSION).orig.tar.gz
BUILD_DIR := ../bitwarden-cli-$(VERSION)

.PHONY: help prepare-source source-package clean

help:
	@echo "Debian Package Build Helper"
	@echo ""
	@echo "Usage:"
	@echo "  make prepare-source VERSION=2025.8.0 [REVISION=1]"
	@echo "    - Fetch sources from git submodule"
	@echo "    - Checkout tag cli-v\$${VERSION}"
	@echo "    - Create orig.tar.gz"
	@echo ""
	@echo "  make source-package VERSION=2025.8.0 [REVISION=1]"
	@echo "    - Prepare source package for Debian upload"
	@echo "    - Creates .dsc, .debian.tar.xz, .changes files"
	@echo ""
	@echo "  make clean"
	@echo "    - Remove build artifacts"
	@echo ""
	@echo "Example workflow:"
	@echo "  make prepare-source VERSION=2025.8.0"
	@echo "  make source-package VERSION=2025.8.0"
	@echo ""

prepare-source:
	@echo "==> Preparing source for version $(VERSION)"

	@# Initialize/update submodule
	@echo "Updating git submodule..."
	git submodule update --init upstream-source

	@# Checkout specific tag
	@echo "Checking out tag cli-v$(VERSION)..."
	cd upstream-source && git fetch --tags && git checkout cli-v$(VERSION)

	@# Create orig.tar.gz
	@echo "Creating $(ORIG_TARBALL)..."
	tar czf $(ORIG_TARBALL) \
		--transform "s,^upstream-source,bitwarden-cli-$(VERSION)," \
		--exclude='.git' \
		upstream-source/

	@echo "==> Source prepared successfully!"
	@echo "Created: $(ORIG_TARBALL)"

source-package: prepare-source
	@echo "==> Building source package $(FULL_VERSION)"

	@# Extract orig tarball
	@echo "Extracting source..."
	cd .. && tar xzf bitwarden-cli_$(VERSION).orig.tar.gz

	@# Copy debian directory
	@echo "Copying debian/ directory..."
	cp -r debian $(BUILD_DIR)/

	@# Update changelog
	@echo "Updating debian/changelog..."
	cd $(BUILD_DIR) && \
		dch -v $(FULL_VERSION) -D unstable "New upstream release $(VERSION)"

	@# Build source package
	@echo "Building source package..."
	cd $(BUILD_DIR) && dpkg-buildpackage -S -sa

	@echo ""
	@echo "==> Source package built successfully!"
	@echo ""
	@echo "Files created in parent directory:"
	@ls -lh ../bitwarden-cli_$(FULL_VERSION)*
	@echo ""
	@echo "To upload to Debian:"
	@echo "  1. Sign: debsign ../bitwarden-cli_$(FULL_VERSION)_source.changes"
	@echo "  2. Upload: dput ../bitwarden-cli_$(FULL_VERSION)_source.changes"

clean:
	@echo "Cleaning build artifacts..."
	rm -rf $(BUILD_DIR)
	rm -f ../bitwarden-cli_*.orig.tar.gz
	rm -f ../bitwarden-cli_*.debian.tar.xz
	rm -f ../bitwarden-cli_*.dsc
	rm -f ../bitwarden-cli_*.changes
	rm -f ../bitwarden-cli_*.buildinfo
	rm -f ../bitwarden-cli_*.deb
	@echo "Clean complete"
