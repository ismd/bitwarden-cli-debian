# Testing Builds in Clean Environment

This guide explains how to test your Debian package in a clean, isolated environment to ensure it builds correctly on Debian's infrastructure.

## Debian Releases (as of October 2025)

- **unstable** (sid) - rolling development
- **testing** (forky) - next release
- **stable** (trixie / Debian 13) - current stable release

## Why Test in Clean Environment?

Building in your development environment can hide issues:
- ❌ Build depends on locally installed packages not declared in `debian/control`
- ❌ Build uses files from your home directory
- ❌ Build works only because of your specific system configuration

Clean environment testing catches these issues before upload.

---

## Comparison: sbuild vs pbuilder

| Feature | sbuild | pbuilder |
|---------|--------|----------|
| **Used by** | Debian official buildds | Debian developers |
| **Technology** | schroot (lightweight) | chroot (full system) |
| **Speed** | ⚡ Faster | Slower |
| **Disk usage** | Lower (~1GB) | Higher (~2GB+) |
| **Setup complexity** | Moderate | Simple |
| **Recommended** | ✅ **Yes** (modern standard) | Alternative |

**Recommendation:** Use **sbuild** - it's what Debian uses officially.

---

# Option 1: sbuild (Recommended)

## Initial Setup (One-time)

### 1. Install sbuild and dependencies

```bash
sudo apt-get install sbuild schroot debootstrap
```

### 2. Add yourself to sbuild group

```bash
sudo sbuild-adduser $USER
```

**Important:** Log out and log back in (or reboot) for group membership to take effect!

Verify:
```bash
groups | grep sbuild
```

### 3. Create the build chroot

For Debian **unstable** (sid):
```bash
sudo sbuild-createchroot \
  --include=eatmydata,ccache,gnupg \
  unstable \
  /srv/chroot/unstable-amd64-sbuild \
  http://deb.debian.org/debian
```

For Debian **testing**:
```bash
sudo sbuild-createchroot \
  --include=eatmydata,ccache,gnupg \
  testing \
  /srv/chroot/testing-amd64-sbuild \
  http://deb.debian.org/debian
```

For Debian **stable** (trixie):
```bash
sudo sbuild-createchroot \
  --include=eatmydata,ccache,gnupg \
  trixie \
  /srv/chroot/trixie-amd64-sbuild \
  http://deb.debian.org/debian
```

This takes 5-10 minutes and downloads ~500MB.

### 4. Configure sbuild (optional)

**Note:** sbuild works fine without any configuration! This step is completely optional.

If you want to customize sbuild behavior, copy the example configuration:

```bash
cp /usr/share/doc/sbuild/examples/example.sbuildrc ~/.sbuildrc
```

Then edit `~/.sbuildrc` to customize settings if needed. The example file is well-documented with comments explaining each option.

---

## Building with sbuild

### Method 1: Build from Source Package (Recommended)

**IMPORTANT:** For packages with bundled dependencies like bitwarden-cli, you must prepare the orig.tar.gz FIRST.

#### Step 1: Create orig.tar.gz with bundled node_modules

```bash
# Clone upstream and install dependencies in a temporary location
export VERSION=X.Y.Z  # Replace with actual version, e.g., 2025.10.1
cd /tmp  # Use a temporary location for this step
git clone --depth 1 --branch cli-v${VERSION} \
  https://github.com/bitwarden/clients.git \
  bitwarden-cli-${VERSION}-tmp
cd bitwarden-cli-${VERSION}-tmp
npm ci

# Create orig.tar.gz with bundled dependencies
/path/to/debian/helpers/create-orig-tarball.sh

# This creates: ../bitwarden-cli_X.Y.Z.orig.tar.gz
# Move it to your build area
mv ../bitwarden-cli_${VERSION}.orig.tar.gz ~/build/
```

#### Step 2: Extract and add debian/ directory

**Important:** Extract in a DIFFERENT location from where you created it!

```bash
# Go to your build directory
cd ~/build  # Or wherever you want to build

# Extract the orig.tar.gz
tar xzf bitwarden-cli_${VERSION}.orig.tar.gz

# Enter the extracted directory
cd bitwarden-cli-${VERSION}

# Add debian/ directory
cp -r /path/to/bitwarden-cli-debian/debian .
```

#### Step 3: Create source package

**CRITICAL:** The orig.tar.gz MUST be in the parent directory!

```bash
# Verify orig.tar.gz exists
ls -lh ../bitwarden-cli_*.orig.tar.gz

# Now build source package
dpkg-buildpackage -S -us -uc
```

This creates:
- `../bitwarden-cli_VERSION-REVISION.dsc`
- `../bitwarden-cli_VERSION-REVISION.debian.tar.xz`

(The orig.tar.gz already existed from step 1)

#### Step 4: Build in clean chroot

```bash
# For unstable
sbuild -d unstable ../bitwarden-cli_*.dsc

# For testing
sbuild -d testing ../bitwarden-cli_*.dsc

# For stable
sbuild -d trixie ../bitwarden-cli_*.dsc
```

### Method 2: Build from Working Directory

```bash
cd /path/to/bitwarden-cli-source
sbuild -d unstable
```

### Understanding the Output

sbuild will:
1. ✓ Create clean build environment
2. ✓ Install build dependencies
3. ✓ Copy source package into chroot
4. ✓ Build package
5. ✓ Run lintian checks
6. ✓ Report results

**Look for:**
```
┌──────────────────────────────────────────────────────────────────────────────┐
│ Post Build                                                                   │
└──────────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────────┐
│ Cleanup                                                                      │
└──────────────────────────────────────────────────────────────────────────────┘

Status: successful
```

Results in: `~/build/` (if configured) or current directory.

---

## Maintaining the Chroot

### Update the chroot regularly

```bash
# Update unstable
sudo sbuild-update -udcar unstable

# Update testing
sudo sbuild-update -udcar testing

# Update stable
sudo sbuild-update -udcar trixie
```

Run this weekly or before important builds.

### List existing chroots

```bash
schroot -l
```

### Delete a chroot

```bash
sudo rm -rf /srv/chroot/unstable-amd64-sbuild
sudo rm /etc/schroot/chroot.d/unstable-amd64-sbuild-*
```

---

# Option 2: pbuilder (Alternative)

## Initial Setup (One-time)

### 1. Install pbuilder

```bash
sudo apt-get install pbuilder
```

### 2. Create base tarball

For unstable:
```bash
sudo pbuilder create \
  --distribution unstable \
  --mirror http://deb.debian.org/debian
```

For testing:
```bash
sudo pbuilder create \
  --distribution testing \
  --mirror http://deb.debian.org/debian
```

For stable:
```bash
sudo pbuilder create \
  --distribution trixie \
  --mirror http://deb.debian.org/debian
```

Creates: `/var/cache/pbuilder/base.tgz` (~300MB)

### 3. Configure pbuilder (optional)

Create `/etc/pbuilderrc` or `~/.pbuilderrc`:

```bash
sudo tee -a /etc/pbuilderrc << 'EOF'
# Cache directory for faster builds
APTCACHE="/var/cache/pbuilder/aptcache/"
BUILDPLACE="/var/cache/pbuilder/build/"

# Keep build results
BUILDRESULT="$HOME/pbuilder-results/"

# Parallel builds
DEBBUILDOPTS="-j$(nproc)"

# Use eatmydata for speed
EXTRAPACKAGES="eatmydata"
LD_PRELOAD="${LD_PRELOAD:+$LD_PRELOAD:}libeatmydata.so"
EOF
```

Create directories:
```bash
mkdir -p ~/pbuilder-results
sudo mkdir -p /var/cache/pbuilder/aptcache
```

---

## Building with pbuilder

### Create source package first

```bash
cd /path/to/bitwarden-cli-source
dpkg-buildpackage -S -us -uc
```

### Build in clean environment

```bash
sudo pbuilder build ../bitwarden-cli_*.dsc
```

Results in: `~/pbuilder-results/` (if configured) or `/var/cache/pbuilder/result/`

---

## Maintaining pbuilder

### Update base tarball

```bash
sudo pbuilder update
```

### Clean cache

```bash
sudo pbuilder clean
```

---

# Common Issues and Solutions

## Issue: "no upstream tarball found at ../bitwarden-cli_VERSION.orig.tar.{gz,xz,...}"

**Error message:**
```
dpkg-source: error: can't build with source format '3.0 (quilt)':
no upstream tarball found at ../bitwarden-cli_X.Y.Z.orig.tar.{bz2,gz,lzma,xz}
```

**Cause:** You're trying to build a source package but the orig.tar.gz is missing from the parent directory.

**Solution:** Create the orig.tar.gz first!

```bash
# Option 1: If you have the orig.tar.gz elsewhere, copy it
cp /path/to/bitwarden-cli_X.Y.Z.orig.tar.gz ..

# Option 2: Create it from source with node_modules
cd /path/to/source-with-node_modules
/path/to/debian/helpers/create-orig-tarball.sh
# This creates ../bitwarden-cli_VERSION.orig.tar.gz

# Then verify it exists
ls -lh ../bitwarden-cli_*.orig.tar.gz

# Now build source package
dpkg-buildpackage -S -us -uc
```

**Important:** The orig.tar.gz must be in the **parent directory** of your source tree!

## Issue: "cannot represent change to node_modules/.../*.png: binary file contents changed"

**Error message:**
```
dpkg-source: error: cannot represent change to node_modules/some-package/file.png:
binary file contents changed
```

**Cause:** You're building from a source tree that doesn't match the orig.tar.gz.

**Solution:** Always build from freshly extracted tarball:

```bash
# Extract the orig.tar.gz (replace X.Y.Z with your version)
tar xzf bitwarden-cli_X.Y.Z.orig.tar.gz
cd bitwarden-cli-X.Y.Z

# Add debian/ directory
cp -r /path/to/packaging/debian .

# Now build (source tree matches orig.tar.gz exactly)
dpkg-buildpackage -S -us -uc
```

**Never** build source packages from:
- Different machine than where orig.tar.gz was created
- Git checkout with different node_modules
- Directory that was manually modified
- ⚠️ **The same directory where you ran `git clone` and `npm ci`** (create tarball and extract it in separate locations!)

**Common mistake:**
```bash
# ❌ WRONG - extract in same location
cd ~/src
git clone ... bitwarden-cli-X.Y.Z
cd bitwarden-cli-X.Y.Z
npm ci
create-orig-tarball.sh
cd ..
tar xzf bitwarden-cli_X.Y.Z.orig.tar.gz  # Overwrites/merges with existing dir!

# ✅ CORRECT - extract in different location
cd /tmp
git clone ... bitwarden-cli-X.Y.Z-tmp
cd bitwarden-cli-X.Y.Z-tmp
npm ci
create-orig-tarball.sh
mv ../bitwarden-cli_X.Y.Z.orig.tar.gz ~/build/
cd ~/build  # Different location!
tar xzf bitwarden-cli_X.Y.Z.orig.tar.gz
```

## Issue: "E: node_modules not found"

**Cause:** Your orig.tar.gz doesn't include node_modules.

**Solution:** Ensure you create the tarball correctly:
```bash
cd /path/to/source-with-node_modules
/path/to/debian/helpers/create-orig-tarball.sh
```

## Issue: "E: Build-Depends unsatisfied"

**Cause:** `debian/control` missing dependencies.

**Solution:** Check error message for missing package and add to Build-Depends.

## Issue: Network access during build

**Cause:** Build tries to run `npm install` or download files.

**Solution:** Ensure `debian/rules` sets offline mode and uses bundled node_modules.

## Issue: "E: source-is-missing"

**Cause:** Lintian flags minified JavaScript in node_modules.

**Solution:** This is expected for bundled deps. Document in README.

## Issue: Build takes forever

**Cause:** Building with bundled node_modules is slow.

**Solutions:**
- Use eatmydata (already in setup)
- Enable ccache (already in setup)
- Expect 5-10 minute builds

## Issue: Out of disk space

**Cause:** node_modules is large (~500MB+), build needs space.

**Solution:** Ensure at least 5GB free:
```bash
df -h /srv/chroot  # For sbuild
df -h /var/cache   # For pbuilder
```

---

# Testing the Built Package

After successful build:

```bash
# Install in a VM or container
sudo dpkg -i ~/build/bitwarden-cli_*.deb  # sbuild
# or
sudo dpkg -i ~/pbuilder-results/bitwarden-cli_*.deb  # pbuilder

# Test it works
bw --version
bw --help

# Run autopkgtest (optional)
autopkgtest ~/build/bitwarden-cli_*.deb -- schroot unstable-amd64-sbuild
```

---

# Quick Reference

## sbuild

```bash
# Setup (once)
sudo apt-get install sbuild schroot debootstrap
sudo sbuild-adduser $USER
# Log out and back in
sudo sbuild-createchroot unstable /srv/chroot/unstable-amd64-sbuild http://deb.debian.org/debian

# Build (for packages with bundled dependencies)
# 1. Create orig.tar.gz with node_modules (in /tmp)
export VERSION=X.Y.Z  # Replace with actual version, e.g., 2025.10.1
cd /tmp
git clone --depth 1 --branch cli-v${VERSION} \
  https://github.com/bitwarden/clients.git bitwarden-cli-${VERSION}-tmp
cd bitwarden-cli-${VERSION}-tmp
npm ci
/path/to/debian/helpers/create-orig-tarball.sh
mv ../bitwarden-cli_${VERSION}.orig.tar.gz ~/build/

# 2. Extract in DIFFERENT location and add debian/
cd ~/build
tar xzf bitwarden-cli_${VERSION}.orig.tar.gz
cd bitwarden-cli-${VERSION}
cp -r /path/to/packaging/debian .

# 3. Build source package (requires orig.tar.gz in parent dir)
dpkg-buildpackage -S -us -uc

# 4. Build in clean chroot
sbuild -d unstable ../bitwarden-cli_*.dsc

# Update chroot
sudo sbuild-update -udcar unstable
```

## pbuilder

```bash
# Setup (once)
sudo apt-get install pbuilder
sudo pbuilder create --distribution unstable

# Build (same workflow as sbuild)
# 1-3. Create orig.tar.gz, extract, add debian/, build source package
dpkg-buildpackage -S -us -uc

# 4. Build in clean chroot
sudo pbuilder build ../bitwarden-cli_*.dsc

# Update
sudo pbuilder update
```

---

# Recommended Workflow

1. **Develop** in your normal environment
2. **Quick test** with `dpkg-buildpackage -b`
3. **Clean test** with `sbuild`
4. **Fix any issues** revealed by clean build
5. **Final check** with `lintian -EvIL +pedantic`
6. **Ready for upload!**

---

Last updated: 2025-10-28
Maintainer: Vladimir Kosteley <debian@ismd.dev>
