#!/bin/bash
# Usage: tools/test-failure-annotations.sh IMAGE
#
# Makes tools/test-kismet-build.sh fail on purpose in IMAGE and checks that it
# names the failed step: in a GitHub error annotation when GITHUB_ACTIONS is
# set, as a plain message otherwise.

set -euo pipefail

image="${1:?usage: $0 IMAGE}"
here="$(cd "$(dirname "$0")" && pwd)"
this_repo="https://github.com/kismetwireless/kismet-docker-ubuntu-noble-build-environment.git"
fail=0

# Prints the script's output with "::" broken up, so that on GitHub it doesn't
# turn into real annotations.
attempt() {
	local want="$1" out
	shift
	if out="$(env "$@" "${here}/test-kismet-build.sh" "${image}" 2>&1)"; then
		echo "FAIL ${want}: the build passed"
		fail=1
	elif grep -qxF -- "${want}" <<< "${out}"; then
		echo "ok   ${want}"
	else
		echo "FAIL ${want}: not in the output:"
		sed 's/::/: :/g; s/^/    /' <<< "${out}"
		fail=1
	fi
}

attempt "::error title=Kismet clone failed::git clone of https://github.com/kismetwireless/kismet.git no-such-branch failed" \
	GITHUB_ACTIONS=true KISMET_REF=no-such-branch

# This repository clones fine but has no configure.
rev="$(git ls-remote "${this_repo}" refs/heads/main | cut -c1-7)"
attempt "::error title=default-build.sh failed::default-build.sh failed building Kismet ${rev} in ${image}" \
	GITHUB_ACTIONS=true KISMET_REPO="${this_repo}" KISMET_REF=main

attempt "git clone of https://github.com/kismetwireless/kismet.git no-such-branch failed" \
	-u GITHUB_ACTIONS KISMET_REF=no-such-branch

exit "${fail}"
