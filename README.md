# Kismet Ubuntu Noble build environment

Simple Ubuntu Noble based build environment leveraged for check-in tests in the
Github workflow for Kismet.

The Github Ubuntu runners seem to constantly suffer from malformed package repos
which cause apt errors installing dependencies, so this is the next best option.

## Images

| Dockerfile | Image |
| --- | --- |
| `Dockerfile.alpine` | `ghcr.io/<owner>/kismet/build-alpine-amd64` |
| `Dockerfile.ubuntu2404` | `ghcr.io/<owner>/kismet/build-ubuntu-noble-amd64` |
| `Dockerfile.ubuntu2604` | `ghcr.io/<owner>/kismet/build-ubuntu-resolute-amd64` |

The `build` workflow builds each image every Thursday, on changes and on
demand. It then builds the latest Kismet in each image with `default-build.sh`,
`all-build.sh` and `all-no-wext-build.sh`, running `make clean` between them.
Only when all three builds pass, and only on `main`, does it push the image as
`latest` and as the build date (`YYYYMMDD`).

A failure shows as an error annotation in the run summary naming the step that
failed: the image build, the Kismet clone, which build script or `make clean`,
the registry login, or the push of which tag.

## Testing an image locally

```sh
docker build -f Dockerfile.ubuntu2404 -t kismet-build-ubuntu:24.04 .
./tools/test-kismet-build.sh kismet-build-ubuntu:24.04
```

The script clones Kismet into a temporary docker volume, so no root-owned files
are left behind. Set `KISMET_REPO` and `KISMET_REF` to test another
repository or branch.

`tools/test-failure-annotations.sh IMAGE` makes the clone and a build script
fail on purpose and checks that the error names the failed step, as an
annotation under GitHub Actions and as a plain message otherwise. The workflow
runs it too.
