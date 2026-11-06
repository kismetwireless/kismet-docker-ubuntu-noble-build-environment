#!/bin/bash
# Usage: tools/test-kismet-build.sh IMAGE
#
# Clones the latest Kismet (KISMET_REPO, KISMET_REF) into a docker volume and
# runs each build script of IMAGE on it in a fresh container, as Kismet's
# workflows do, with a make clean in between.

set -euo pipefail

image="${1:?usage: $0 IMAGE}"
repo="${KISMET_REPO:-https://github.com/kismetwireless/kismet.git}"
ref="${KISMET_REF:-master}"
scripts=(default-build.sh all-build.sh all-no-wext-build.sh)

# The scripts run as root, so the tree lives in a volume rather than in a
# host directory that would be left full of root-owned files.
volume="kismet-build-test-$$"
docker volume create "${volume}" > /dev/null
trap 'docker volume rm -f "${volume}" > /dev/null' EXIT

run() {
	docker run --rm -v "${volume}:/github/workspace" -w /github/workspace "$@"
}

group() {
	if [ -n "${GITHUB_ACTIONS:-}" ]; then echo "::group::$*"; else echo "=== $*"; fi
}

endgroup() {
	if [ -n "${GITHUB_ACTIONS:-}" ]; then echo "::endgroup::"; fi
}

group "Clone ${repo} ${ref}"
run --entrypoint git "${image}" -c safe.directory='*' clone --depth 1 --branch "${ref}" "${repo}" .
run --entrypoint git "${image}" -c safe.directory='*' log -1 --format='Kismet %H %cI %s'
endgroup

first=1
for script in "${scripts[@]}"; do
	if [ -z "${first}" ]; then
		group "make clean"
		run --entrypoint make "${image}" clean
		endgroup
	fi
	first=
	group "${script}"
	if ! run --entrypoint "/${script}" "${image}"; then
		endgroup
		echo "${script} failed in ${image}" >&2
		exit 1
	fi
	endgroup
done

echo "All builds passed in ${image}"
