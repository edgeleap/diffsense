Use `diffsense@<short-git-sha>` everywhere, no SemVer.

## Tag format

- Tag pattern: `diffsense@<short-git-sha>` (for example: `diffsense@a1b2c3d`).[1][2]
- No `vX.Y.Z` or mixed formats; all releases are identified solely by commit hash.[3][4]

## Release flow (local, hash-only)

```bash
# 1. Be on the release branch and up to date
git checkout main
git pull

# 2. Ensure all release changes are committed

# 3. Capture short SHA of the release commit
SHORT_SHA=$(git rev-parse --short HEAD)

# 4. Create an annotated release tag
git tag -a "diffsense@${SHORT_SHA}" -m "Release diffsense @ ${SHORT_SHA}"

# 5. Push the tag
git push origin "diffsense@${SHORT_SHA}"
```


## GitHub Releases

- If you want a GitHub Release, create it from the `diffsense@<short-git-sha>` tag in the Releases UI (or via CI)