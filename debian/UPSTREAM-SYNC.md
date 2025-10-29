# Upstream Source Synchronization

This document explains how upstream Bitwarden CLI sources are managed and synchronized in this repository.

## Repository Structure

This is a **mixed repository** containing both upstream sources and Debian packaging:

```
bitwarden-cli-debian/
├── debian/              # Debian packaging files (OURS)
├── .github/             # GitHub Actions workflows (OURS)
├── .packaging/          # Sync automation scripts (OURS)
│   ├── import-upstream.sh
│   ├── check-upstream-version.sh
│   ├── current-version.txt
│   └── imported-manifest.txt
├── apps/                # Upstream sources (IMPORTED)
├── libs/                # Upstream sources (IMPORTED)
├── scripts/             # Upstream sources (IMPORTED)
├── package.json         # Upstream sources (IMPORTED)
├── *.upstream.*         # Upstream configs (IMPORTED, renamed)
└── README.md            # Packaging documentation (OURS)
```

## Three-Tier File Management

### Tier 1: Protected Files (Never Imported)

These files/directories are maintained by us and never overwritten during import:

- `.git/` - Git metadata
- `.github/` - Our CI/CD workflows
- `debian/` - Our packaging files
- `.packaging/` - Our sync scripts
- `README.md` - Our packaging documentation
- `.gitignore` - Our gitignore rules

### Tier 2: Renamed Files (Imported with .upstream suffix)

These files are imported but renamed to avoid conflicts:

- `CONTRIBUTING.md` → `CONTRIBUTING.upstream.md`
- `SECURITY.md` → `SECURITY.upstream.md`
- `.editorconfig` → `.editorconfig.upstream`
- `.prettierrc.json` → `.prettierrc.json.upstream`
- `.vscode/` → `.vscode.upstream/`
- `.husky/` → `.husky.upstream/`
- And other configuration files

### Tier 3: Direct Import (Imported as-is)

Everything else from upstream is imported directly:

- `apps/` - Application sources
- `libs/` - Shared libraries
- `scripts/` - Build scripts
- `package.json` - Dependencies
- `package-lock.json` - Dependency lockfile
- `LICENSE*.txt` - License files
- All other source code and assets

## Automated Synchronization

### GitHub Actions Workflows

#### 1. Check Upstream (`check-upstream.yml`)

**Trigger:** Daily at 6:00 AM UTC (or manual)

**What it does:**
1. Checks GitHub API for latest Bitwarden CLI release
2. Compares with `.packaging/current-version.txt`
3. If new version found:
   - Triggers `update-upstream` workflow
   - Optionally creates notification issue

**Manual trigger:**
```bash
# Via GitHub UI: Actions → Check Upstream Version → Run workflow
```

#### 2. Update Upstream (`update-upstream.yml`)

**Trigger:** Automatically by `check-upstream` or manually

**What it does:**
1. Creates branch `upstream-update/cli-vX.Y.Z`
2. Runs `.packaging/import-upstream.sh`
3. Updates `debian/changelog` with template entry
4. Commits changes
5. Creates pull request with:
   - Upstream release notes
   - List of changes
   - Maintainer checklist

**Manual trigger:**
```bash
# Via GitHub UI: Actions → Update Upstream Sources → Run workflow
# Input: cli-v2025.10.1
```

#### 3. Test Build (`test-build.yml`)

**Trigger:** On pull requests

**What it does:**
1. Installs build dependencies
2. Runs `npm ci` to install dependencies
3. Builds package with `dpkg-buildpackage`
4. Runs lintian checks
5. Uploads artifacts (`.deb`, logs)
6. Comments on PR with results

## Manual Synchronization

### Check for Updates

```bash
# Check if new upstream version is available
.packaging/check-upstream-version.sh

# JSON output (for scripting)
.packaging/check-upstream-version.sh --json
```

Example output:
```
Current version: cli-v2025.8.0
Latest version:  cli-v2025.10.1
Release name:    CLI v2025.10.1
Release date:    2025-10-15T14:30:00Z
Release URL:     https://github.com/bitwarden/clients/releases/tag/cli-v2025.10.1

⚠ Update available!

To update, run:
  .packaging/import-upstream.sh cli-v2025.10.1
```

### Import Specific Version

```bash
# Import a specific upstream version
.packaging/import-upstream.sh cli-v2025.10.1
```

The import script will:

1. **Clone upstream repository**
   - Clones to temporary directory
   - Checks out specified tag
   - Removes `.git` directory

2. **Import sources with exclusions**
   - Copies everything except protected paths
   - Uses rsync for efficiency

3. **Rename conflicting files**
   - Adds `.upstream` suffix to config files
   - Preserves our packaging files

4. **Handle README specially**
   - Copies upstream `README.md` as `README.upstream.md`
   - Keeps our `README.md` unchanged

5. **Update tracking files**
   - Updates `.packaging/current-version.txt`
   - Generates `.packaging/imported-manifest.txt`

6. **Output summary**
   - Shows imported version
   - Lists next steps

### After Import

```bash
# Review changes
git status
git diff

# Update debian/changelog properly
dch -v 2025.10.1-1 "New upstream release"
dch -r

# Test build
dpkg-buildpackage -b -us -uc

# Run lintian
lintian -i ../bitwarden-cli_*.changes

# Commit
git add .
git commit -m "chore: import upstream cli-v2025.10.1"
```

## Understanding Import Manifest

After each import, `.packaging/imported-manifest.txt` is generated:

```
# Import Manifest
# Generated: 2025-10-29 12:34:56 UTC
# Upstream version: cli-v2025.10.1
# Upstream repository: https://github.com/bitwarden/clients.git

## Protected Files (not imported)
- .git
- .github
- debian
- .packaging
- README.md
- .gitignore

## Renamed Files (imported with .upstream suffix)
- CONTRIBUTING.md
- .editorconfig
- .vscode
...

## Imported Files and Directories
- apps/
- libs/
- package.json
...
```

This helps track:
- What version is currently imported
- What files came from upstream
- What files are ours

## Version Tracking

`.packaging/current-version.txt` contains the currently imported upstream version:

```
cli-v2025.10.1
```

This file is used by:
- `check-upstream-version.sh` to detect updates
- `update-upstream.yml` workflow to create PRs
- Documentation to show current version

## Handling Merge Conflicts

If you've made local modifications to upstream files, imports may cause conflicts.

### Strategy 1: Avoid Modifying Upstream Files

**Best practice:** Don't modify upstream sources. Instead:

- Put patches in `debian/patches/`
- Use quilt patch system
- Document patches in `debian/patches/series`

### Strategy 2: Resolve Conflicts Manually

If you must modify upstream files:

1. Import will fail with conflict
2. Review conflicted files: `git status`
3. Resolve manually: `git mergetool` or editor
4. Continue: `git add .` and complete commit

### Strategy 3: Use Branches

For experimental changes:

```bash
# Create feature branch
git checkout -b feature/my-changes

# Make changes to upstream files
# ...

# When new upstream comes:
git checkout main
git pull  # Get new upstream import
git checkout feature/my-changes
git rebase main  # Rebase your changes
```

## Debian Changelog Management

The `update-upstream` workflow creates a template changelog entry:

```
bitwarden-cli (2025.10.1-1) UNRELEASED; urgency=medium

  * New upstream release cli-v2025.10.1
  * TODO: Review changes and update this entry before merge

 -- Vladimir Kosteley <debian@ismd.dev>  Tue, 29 Oct 2025 12:00:00 +0100
```

**Before merging, update it to:**

```
bitwarden-cli (2025.10.1-1) unstable; urgency=medium

  * New upstream release cli-v2025.10.1
  * Update bundled dependencies
  * Fix FTBFS with Node.js 20 (if applicable)
  * Other notable changes...

 -- Vladimir Kosteley <debian@ismd.dev>  Tue, 29 Oct 2025 12:00:00 +0100
```

## Testing After Import

### Quick Test (Local)

```bash
# Install dependencies
npm ci

# Build package
dpkg-buildpackage -b -us -uc

# Check package
lintian -i ../bitwarden-cli_*.changes

# Test installation (in VM or container)
sudo dpkg -i ../bitwarden-cli_*.deb
bw --version
```

### Thorough Test (Clean Environment)

```bash
# Build source package
dpkg-buildpackage -S -us -uc

# Build in sbuild
sbuild -d unstable ../bitwarden-cli_*.dsc
```

See [TESTING-CLEAN-BUILD.md](TESTING-CLEAN-BUILD.md) for complete instructions.

## Troubleshooting

### Import script fails with "tag not found"

**Cause:** Version tag doesn't exist upstream

**Solution:** Check available tags:
```bash
git ls-remote --tags https://github.com/bitwarden/clients.git | grep cli-v
```

### Import completes but no changes

**Cause:** Already at this version

**Solution:** Force re-import or import different version

### Build fails after import

**Cause:** Upstream changes broke our build

**Solution:**
1. Review build log
2. Update `debian/rules` if needed
3. Add patches in `debian/patches/`
4. Update `debian/control` dependencies

### Lintian errors after import

**Cause:** New upstream issues or new dependencies

**Solution:**
1. Review lintian output
2. Update `debian/bitwarden-cli.lintian-overrides` if justified
3. Update `debian/copyright` if new licenses
4. Fix if possible, override if unavoidable

## GitHub Actions Secrets

No secrets are required for the automated workflows. They use:

- `${{ github.token }}` - Automatic token for PRs and issues
- Public GitHub API - For checking releases

If you want to use a personal access token (for higher rate limits):

1. Create PAT with `repo` scope
2. Add as repository secret: `UPSTREAM_SYNC_TOKEN`
3. Update workflows to use `${{ secrets.UPSTREAM_SYNC_TOKEN }}`

## Disabling Automation

To disable automated upstream checks:

1. **Disable workflow:** Comment out schedule in `.github/workflows/check-upstream.yml`:
   ```yaml
   on:
     # schedule:
     #   - cron: '0 6 * * *'
     workflow_dispatch:  # Keep manual trigger
   ```

2. **Or delete workflow:** Remove `.github/workflows/check-upstream.yml`

Manual import still works via `.packaging/import-upstream.sh`.

## Best Practices

1. **Review PRs carefully** - Automated imports need human review
2. **Test thoroughly** - Build in clean environment before merging
3. **Update changelog properly** - Don't merge with TODO entries
4. **Check licenses** - Verify no new problematic dependencies
5. **Document changes** - Note breaking changes in changelog
6. **Keep backups** - Tag releases before importing new versions

## Related Documentation

- [README.md](../README.md) - Main packaging documentation
- [README.source](README.source) - Build approach
- [TESTING-CLEAN-BUILD.md](TESTING-CLEAN-BUILD.md) - Clean environment testing
- [LINTIAN-NOTES.md](LINTIAN-NOTES.md) - Lintian issues

---

Last updated: 2025-10-29
Maintainer: Vladimir Kosteley <debian@ismd.dev>
