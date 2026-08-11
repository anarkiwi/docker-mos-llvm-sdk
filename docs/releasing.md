# Releasing

The pinned upstream release is the two `ARG` lines at the top of `Dockerfile`:

    ARG LLVM_MOS_VERSION=v23.0.1
    ARG LLVM_MOS_SHA256=bd76dd5a...

`LLVM_MOS_VERSION` is the single source of truth for the release version. The tarball is
verified against `LLVM_MOS_SHA256` at build time.

## Workflows

| Workflow | Trigger | Action |
| --- | --- | --- |
| `ci` | pull request, push to main | hadolint, shellcheck, build, `tests/smoke.sh` |
| `release` | push to main touching `Dockerfile`, manual | build, smoke test, push images, create GitHub release |
| `upstream-bump` | daily 05:17 UTC, manual | open a PR bumping the pins to the latest SDK release |

`upstream-bump` reads the release asset digest from the GitHub API, so it does not download
the tarball. Dependabot covers the Debian base image and the actions used here; it cannot
track upstream GitHub releases, which is what `upstream-bump` exists for.

Merging a bump PR publishes `vX.Y.Z`, `X.Y.Z` and `latest`, and creates the matching GitHub
release. Re-running `release` for an existing version refreshes the images (for example after
a base image update) and leaves the existing GitHub release alone.

## Secrets and variables

| Name | Kind | Required | Purpose |
| --- | --- | --- | --- |
| `GITHUB_TOKEN` | built in | yes | GHCR push, release creation |
| `DOCKERHUB_USERNAME` | secret | no | Docker Hub push |
| `DOCKERHUB_TOKEN` | secret | no | Docker Hub access token; absent disables Docker Hub push |
| `DOCKERHUB_IMAGE` | variable | no | Docker Hub repository, default `anarkiwi/mos-llvm-sdk` |
| `BUMP_TOKEN` | secret | no | PAT (`repo` scope) so bump PRs trigger `ci`; falls back to `GITHUB_TOKEN` |

PRs opened with `GITHUB_TOKEN` do not start workflow runs, so without `BUMP_TOKEN` a bump PR
must be checked by re-running `ci` manually or by pushing to its branch.

## Manual release

Edit the two `ARG` lines and merge to main, or run the `release` workflow by hand
(`workflow_dispatch`) to rebuild the currently pinned version.
