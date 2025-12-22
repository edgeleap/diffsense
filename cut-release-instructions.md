# DiffSense Release Instructions

Use `diffsense@<short-git-sha>` everywhere, no SemVer.

## Prerequisites

- Ensure all changes are committed and pushed to `main`
- Verify that `resources/diffsense.sh` and `resources/Diffsense.shortcut` are present and up to date
- Test the installation locally if possible

## Tag format

- Tag pattern: `diffsense@<short-git-sha>` (for example: `diffsense@a1b2c3d`)
- No `vX.Y.Z` or mixed formats; all releases are identified solely by commit hash

## Release flow

```bash
# 1. Switch to main branch and ensure it's up to date
git checkout main
git pull origin main

# 2. Ensure all release changes are committed
git status

# 3. Capture short SHA of the release commit
SHORT_SHA=$(git rev-parse --short HEAD)
echo "Release SHA: ${SHORT_SHA}"

# 4. Create an annotated release tag
git tag -a "diffsense@${SHORT_SHA}" -m "Release diffsense @ ${SHORT_SHA}"

# 5. Push the tag to trigger GitHub Actions release
git push origin "diffsense@${SHORT_SHA}"
```

## What happens after pushing the tag

The GitHub Actions workflow (`.github/workflows/create-release.yml`) will automatically:

1. Create a new GitHub release with the tag name
2. Upload the following assets to the release:
   - `diffsense.sh` - The installation script
   - `Diffsense.shortcut` - The macOS Shortcut file

## Verification

After the workflow completes (usually within a few minutes):

1. Check the [Releases page](https://github.com/edgeleap/diffsense/releases) to see the new release
2. Verify that both assets are attached:
   - `diffsense.sh` (downloadable via: `https://github.com/edgeleap/diffsense/releases/latest/download/diffsense.sh`)
   - `Diffsense.shortcut` (downloadable via: `https://github.com/edgeleap/diffsense/releases/latest/download/Diffsense.shortcut`)
3. Test the download links in a new browser/incognito window

## Rollback (if needed)

If you need to delete a release:

```bash
# Delete the tag locally and remotely
git tag -d "diffsense@${SHORT_SHA}"
git push origin --delete "diffsense@${SHORT_SHA}"

# The GitHub release will be automatically deleted by the workflow
```
