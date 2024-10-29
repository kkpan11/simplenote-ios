#!/bin/bash -eu

# Checks out to the "release/$1" branch.
#
# Our CI system, Buildkite, by default checks out a specific commit.
# For many release actions, we need to be on a release branch instead.

RELEASE_VERSION=${1:-}

if [[ -z "${RELEASE_VERSION}" ]]; then
    printf "Usage %s release_version.\n\nExample:\n" "$0"
    printf "\t%s 1.2\n" "$0"
    exit 1
fi

echo '--- :git: Checkout Release Branch'

BRANCH_NAME="release/${RELEASE_VERSION}"

git fetch origin "$BRANCH_NAME"
git checkout "$BRANCH_NAME"
