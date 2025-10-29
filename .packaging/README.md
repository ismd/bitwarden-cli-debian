# Packaging Automation Scripts

This directory contains scripts for automating upstream source synchronization.

## Files

### Scripts

- **`import-upstream.sh`** - Import upstream sources for a specific version
- **`check-upstream-version.sh`** - Check for new upstream releases

### Tracking Files

- **`current-version.txt`** - Currently imported upstream version (e.g., `cli-v2025.10.1`)
- **`imported-manifest.txt`** - Manifest of last import (generated automatically)

### Temporary Files (Ignored)

- `temp-*/` - Temporary directories during import
- `*.tmp` - Temporary files
- `upstream-clone/` - Cloned upstream repository (temporary)

## Usage

### Check for Updates

Check if a new upstream version is available:

```bash
./check-upstream-version.sh
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

JSON output (for scripting):
```bash
./check-upstream-version.sh --json
```

### Import Upstream Version

Import a specific upstream version:

```bash
./import-upstream.sh cli-v2025.10.1
```

This will:
1. Clone upstream repository to temporary directory
2. Check out the specified tag
3. Import sources using three-tier strategy:
   - **Protected** (.github/, debian/) - never imported
   - **Renamed** (config files) - imported with .upstream suffix
   - **Direct** (everything else) - imported as-is
4. Update `current-version.txt`
5. Generate `imported-manifest.txt`

After import:
```bash
# Review changes
git status
git diff

# Update changelog
dch -v 2025.10.1-1 "New upstream release"

# Test build
dpkg-buildpackage -b -us -uc

# Commit
git add .
git commit -m "chore: import upstream cli-v2025.10.1"
```

## Three-Tier Import Strategy

### Tier 1: Protected (Never Imported)

These files/directories are never overwritten:

```
.git/              # Git metadata
.github/           # Our workflows
debian/            # Our packaging
.packaging/        # These scripts
README.md          # Our README
.gitignore         # Our gitignore
```

### Tier 2: Renamed (Imported with .upstream suffix)

Config files that might conflict are renamed:

```
CONTRIBUTING.md    → CONTRIBUTING.upstream.md
SECURITY.md        → SECURITY.upstream.md
.editorconfig      → .editorconfig.upstream
.prettierrc.json   → .prettierrc.json.upstream
.vscode/           → .vscode.upstream/
.husky/            → .husky.upstream/
```

### Tier 3: Direct Import (Imported as-is)

Everything else is imported directly:

```
apps/              # Application sources
libs/              # Shared libraries
scripts/           # Build scripts
package.json       # Dependencies
LICENSE*.txt       # License files
```

## Script Details

### import-upstream.sh

**Syntax:**
```bash
./import-upstream.sh <version-tag>
```

**Arguments:**
- `version-tag` - Git tag from upstream (e.g., `cli-v2025.10.1`)

**Exit codes:**
- `0` - Success
- `1` - Error (invalid arguments, clone failed, etc.)

**Environment variables:**
- None required

**Dependencies:**
- `git` - For cloning
- `rsync` - For efficient copying
- `bash` - Shell

### check-upstream-version.sh

**Syntax:**
```bash
./check-upstream-version.sh [--json]
```

**Options:**
- `--json` - Output results as JSON (for scripting)

**Exit codes:**
- `0` - Success
- `1` - Error (API request failed, etc.)

**Dependencies:**
- `curl` - For API requests
- `jq` - For JSON parsing

## GitHub Actions Integration

These scripts are used by GitHub Actions workflows:

### check-upstream.yml

Runs daily (6:00 AM UTC) to check for new releases:

1. Runs `check-upstream-version.sh --json`
2. Parses output to detect updates
3. Triggers `update-upstream.yml` if new version found

### update-upstream.yml

Creates PR for upstream updates:

1. Validates version format
2. Creates branch `upstream-update/cli-vX.Y.Z`
3. Runs `import-upstream.sh`
4. Updates `debian/changelog`
5. Commits and pushes
6. Creates pull request

### test-build.yml

Tests builds on pull requests:

1. Installs dependencies
2. Builds package
3. Runs lintian
4. Reports results on PR

## Troubleshooting

### Error: "tag not found"

The version tag doesn't exist upstream.

**Solution:** Check available tags:
```bash
git ls-remote --tags https://github.com/bitwarden/clients.git | grep cli-v
```

### Error: "No previous version found"

This is normal for first import.

**Solution:** Continue with import, it's not an error.

### Import succeeds but no changes

You're already at this version.

**Solution:** Import a different version or force re-import.

### Import conflicts

You've modified upstream files locally.

**Solution:**
- Option A: Resolve conflicts manually
- Option B: Use `debian/patches/` instead of direct modifications
- Option C: Stash changes, import, then reapply

## Maintenance

### Adding Protected Paths

To protect additional files from import, edit `import-upstream.sh`:

```bash
PROTECTED_PATHS=(
    ".git"
    ".github"
    "debian"
    ".packaging"
    "README.md"
    ".gitignore"
    "your-new-file"  # Add here
)
```

### Adding Renamed Paths

To rename additional config files, edit `import-upstream.sh`:

```bash
RENAME_UPSTREAM=(
    "CONTRIBUTING.md"
    "SECURITY.md"
    # ... existing ...
    ".your-config"  # Add here
)
```

### Changing Upstream Repository

To import from a different repository, edit `import-upstream.sh`:

```bash
UPSTREAM_REPO="https://github.com/your-fork/clients.git"
```

## Testing Scripts

### Test check-upstream-version.sh

```bash
# Test normal output
./check-upstream-version.sh

# Test JSON output
./check-upstream-version.sh --json | jq .

# Test API failure handling
# (temporarily break network and run)
```

### Test import-upstream.sh

```bash
# Test with non-existent version (should fail)
./import-upstream.sh cli-v99999.99.99

# Test with valid version
./import-upstream.sh cli-v2025.10.1

# Verify:
git status
cat current-version.txt
cat imported-manifest.txt
```

## Security Considerations

### API Rate Limits

GitHub API has rate limits:
- Unauthenticated: 60 requests/hour
- Authenticated: 5000 requests/hour

For automated workflows, consider using `GITHUB_TOKEN` to increase limits.

### Cloning Risks

The import script clones from upstream. Risks:
- Malicious upstream changes could affect imports
- Always review PRs from automated imports

### Script Permissions

Scripts are executable (`chmod +x`). Review before running:
```bash
cat import-upstream.sh  # Review first
./import-upstream.sh cli-v2025.10.1
```

## Related Documentation

- [debian/UPSTREAM-SYNC.md](../debian/UPSTREAM-SYNC.md) - Complete sync documentation
- [debian/README.source](../debian/README.source) - Build documentation
- [README.md](../README.md) - Main packaging README

---

Last updated: 2025-10-29
Maintainer: Vladimir Kosteley <debian@ismd.dev>
