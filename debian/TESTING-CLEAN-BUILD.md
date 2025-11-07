# Testing Builds in Clean Environment

This guide explains how to test your Debian package in a clean, isolated environment to ensure it builds correctly on Debian's infrastructure.

## Debian Releases (as of October 2025)

- **unstable** (sid) - rolling development
- **testing** (forky) - next release
- **stable** (trixie / Debian 13) - current stable release
- **oldstable** (bookworm / Debian 12) - previous stable release

## Why Test in Clean Environment?

Building in your development environment can hide issues:
- ❌ Build depends on locally installed packages not declared in `debian/control`
- ❌ Build uses files from your home directory
- ❌ Build works only because of your specific system configuration

Clean environment testing catches these issues before upload.

---

# sbuild - Clean Build Environment

**sbuild** is the official tool used by Debian's build infrastructure (buildds). Using sbuild ensures your package will build correctly on Debian's servers. It uses schroot for lightweight, fast builds while maintaining proper isolation.

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

For Debian **oldstable** (bookworm):
```bash
sudo sbuild-createchroot \
  --include=eatmydata,ccache,gnupg \
  bookworm \
  /srv/chroot/bookworm-amd64-sbuild \
  http://deb.debian.org/debian
```

### 4. Configure sbuild (optional)

**Note:** sbuild works fine without any configuration! This step is completely optional.

If you want to customize sbuild behavior, copy the example configuration:

```bash
cp /usr/share/doc/sbuild/examples/example.sbuildrc ~/.sbuildrc
```

Then edit `~/.sbuildrc` to customize settings if needed. The example file is well-documented with comments explaining each option.

---

## Building with sbuild

### Building from Source Package

**IMPORTANT:** For packages with bundled dependencies like bitwarden-cli, you must prepare the orig.tar.gz FIRST.

#### Step 1: Create orig.tar.gz with bundled node_modules and pkg cache

```bash
# Clone repository in a temporary location
cd /tmp
git clone --depth 1 https://github.com/ismd/bitwarden-cli-debian.git bitwarden-cli-tmp
cd bitwarden-cli-tmp

# Install dependencies
npm ci

# CRITICAL: Pre-fetch Node.js binaries for pkg (requires internet, one-time)
# This step is REQUIRED because Debian build infrastructure has NO internet access
export PKG_CACHE_PATH=$(pwd)/.pkg-cache
cd apps/cli && npm run dist:oss:lin && cd ../..

# Create tarball (will include node_modules/ and .pkg-cache/)
debian/helpers/create-orig-tarball.sh

# Move tarball to build directory
mv ../bitwarden-cli_*.orig.tar.gz ~/build/
```

**What this does:**
- `npm ci` - Installs all dependencies into node_modules/
- `npm run dist:oss:lin` - Builds the app, packages it with pkg, AND downloads Node.js base binary (~50MB) into .pkg-cache/
- `create-orig-tarball.sh` - Creates tarball including both node_modules/ and .pkg-cache/

The .pkg-cache is essential for offline builds on Debian's buildd infrastructure!

#### Step 2: Extract and add debian/ directory

**Important:** Extract in a DIFFERENT location from where you created it!

```bash
# Go to your build directory
cd ~/build

# Extract the orig.tar.gz
tar xzf bitwarden-cli_*.orig.tar.gz

# Enter the extracted directory (will be bitwarden-cli-VERSION)
cd bitwarden-cli-*/

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

# For oldstable
sbuild -d bookworm ../bitwarden-cli_*.dsc
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

# Update oldstable
sudo sbuild-update -udcar bookworm
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

# Testing the Built Package

After successful build:

```bash
# Install in a VM or container
sudo dpkg -i ~/build/bitwarden-cli_*.deb

# Test it works
bw --version
bw --help

# Run autopkgtest (optional)
autopkgtest ~/build/bitwarden-cli_*.deb -- schroot unstable-amd64-sbuild
```
