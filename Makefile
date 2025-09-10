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
ARCHITECTURE := amd64
DEB_FILE := $(PACKAGE_NAME)_$(PACKAGE_VERSION)_$(ARCHITECTURE).deb

.PHONY: all build clean install check help update-version build-cli

# Default target
all: build

# Clone and build real Bitwarden CLI
build-cli:
	@echo "Building real Bitwarden CLI..."
	@if [ ! -d "clients" ]; then \
		echo "Cloning Bitwarden clients repository..."; \
		git clone https://github.com/bitwarden/clients.git; \
	fi
	@echo "Installing dependencies..."
	cd clients && npm ci
	@echo "Building CLI..."
	cd clients/apps/cli && npm run build:oss:prod
	@echo "Copying built CLI to package..."
	mkdir -p deb/usr/bin
	cp clients/apps/cli/build/bw.js deb/usr/bin/bw
	chmod +x deb/usr/bin/bw
	@echo "Real Bitwarden CLI built successfully"

# Update version in control file
update-version:
	@echo "Updating version to $(PACKAGE_VERSION) in deb/DEBIAN/control..."
	@sed -i 's/^Version:.*/Version: $(PACKAGE_VERSION)/' deb/DEBIAN/control
	@echo "Version updated successfully ($(UPSTREAM_VERSION)-$(DEBIAN_REVISION))"

# Build the .deb package
build: build-cli update-version check
	@echo "Building $(DEB_FILE)..."
	dpkg-deb --build deb $(DEB_FILE)
	@echo "Package built successfully: $(DEB_FILE)"

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	rm -f *.deb
	rm -rf clients
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
	@if [ ! -f deb/usr/bin/bw ]; then \
		echo "Error: deb/usr/bin/bw not found"; \
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
	@echo "  build        - Build the .deb package (includes building real CLI)"
	@echo "  build-cli    - Build real Bitwarden CLI from source"
	@echo "  clean        - Remove build artifacts and cloned repository"
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
