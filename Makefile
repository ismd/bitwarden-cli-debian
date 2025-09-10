#!/usr/bin/make -f

# Require UPSTREAM_VERSION environment variable
ifndef UPSTREAM_VERSION
$(error UPSTREAM_VERSION environment variable is required. Usage: UPSTREAM_VERSION=2025.9.0 DEBIAN_REVISION=1 make build)
endif

# Default Debian revision to 1 if not specified
DEBIAN_REVISION ?= 1

# Construct full Debian version
PACKAGE_VERSION := $(UPSTREAM_VERSION)-$(DEBIAN_REVISION)
PACKAGE_NAME := bitwarden-cli
ARCHITECTURE := all
DEB_FILE := $(PACKAGE_NAME)_$(PACKAGE_VERSION)_$(ARCHITECTURE).deb

.PHONY: all build clean install check help update-version

# Default target
all: build

# Update version in control file
update-version:
	@echo "Updating version to $(PACKAGE_VERSION) in deb/DEBIAN/control..."
	@sed -i 's/^Version:.*/Version: $(PACKAGE_VERSION)/' deb/DEBIAN/control
	@echo "Version updated successfully ($(UPSTREAM_VERSION)-$(DEBIAN_REVISION))"

# Build the .deb package
build: update-version check
	@echo "Building $(DEB_FILE)..."
	dpkg-deb --build deb $(DEB_FILE)
	@echo "Package built successfully: $(DEB_FILE)"

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	rm -f *.deb
	@echo "Clean complete"

# Install the package locally
install: build
	@echo "Installing $(DEB_FILE)..."
	sudo dpkg -i $(DEB_FILE)
	@echo "Package installed successfully"

# Uninstall the package
uninstall:
	@echo "Uninstalling $(PACKAGE_NAME)..."
	sudo dpkg -r $(PACKAGE_NAME)
	@echo "Package uninstalled successfully"

# Check package structure and dependencies
check:
	@echo "Checking package structure..."
	@if [ ! -f deb/DEBIAN/control ]; then \
		echo "Error: deb/DEBIAN/control not found"; \
		exit 1; \
	fi
	@if [ ! -f deb/usr/local/bin/bw ]; then \
		echo "Error: deb/usr/local/bin/bw not found"; \
		exit 1; \
	fi
	@echo "Package structure OK"

# Validate the built package
validate: build
	@echo "Validating $(DEB_FILE)..."
	lintian $(DEB_FILE) || true
	dpkg-deb --info $(DEB_FILE)
	dpkg-deb --contents $(DEB_FILE)

# Show package information
info:
	@echo "Package: $(PACKAGE_NAME)"
	@echo "Upstream Version: $(UPSTREAM_VERSION)"
	@echo "Debian Revision: $(DEBIAN_REVISION)"
	@echo "Full Version: $(PACKAGE_VERSION)"
	@echo "Architecture: $(ARCHITECTURE)"
	@echo "Output file: $(DEB_FILE)"

# Show help
help:
	@echo "Available targets:"
	@echo "  build        - Build the .deb package"
	@echo "  clean        - Remove build artifacts"
	@echo "  install      - Build and install package locally"
	@echo "  uninstall    - Remove installed package"
	@echo "  check        - Verify package structure"
	@echo "  validate     - Validate built package with lintian"
	@echo "  info         - Show package information"
	@echo "  update-version - Update version in control file"
	@echo "  help         - Show this help message"
	@echo ""
	@echo "REQUIRED: UPSTREAM_VERSION environment variable must be set"
	@echo "OPTIONAL: DEBIAN_REVISION environment variable (defaults to 1)"
	@echo ""
	@echo "Usage examples:"
	@echo "  UPSTREAM_VERSION=2025.9.0 make build                    # Creates 2025.9.0-1"
	@echo "  UPSTREAM_VERSION=2025.9.0 DEBIAN_REVISION=2 make build  # Creates 2025.9.0-2"
