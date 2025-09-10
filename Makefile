#!/usr/bin/make -f

# Require VERSION environment variable
ifndef VERSION
$(error VERSION environment variable is required. Usage: VERSION=2025.9.0 make build)
endif

PACKAGE_VERSION := $(VERSION)
PACKAGE_NAME := bitwarden-cli
ARCHITECTURE := all
DEB_FILE := $(PACKAGE_NAME)_$(PACKAGE_VERSION)_$(ARCHITECTURE).deb

.PHONY: all build clean install check help update-version

# Default target
all: build

# Update version in control file
update-version:
	@echo "Updating version to $(VERSION) in deb/DEBIAN/control..."
	@sed -i 's/^Version:.*/Version: $(VERSION)/' deb/DEBIAN/control
	@echo "Version updated successfully"

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
	@echo "Version: $(PACKAGE_VERSION)"
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
	@echo "REQUIRED: VERSION environment variable must be set"
	@echo "Usage: VERSION=2025.9.0 make <target>"
