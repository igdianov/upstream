#!/usr/bin/env bash
set -e

# Fixes issue: jx step changelog cannot auto detect all commits between prev and last tags on the release branch...
export VERSION=`cat VERSION`

# Alternatively grab latest annotated tag with
# export REV=`git rev-list --tags --max-count=1 --grep '^Release'`
export REV=`git show-ref --hash -- v$VERSION`
export PREVIOUS_REV=`git rev-list --tags --max-count=1 --skip=1 --grep '^Release'`

echo Creating Github Changelog Release: $VERSION of `git show-ref --hash -- v$VERSION`

echo Found commits between `git describe $PREVIOUS_REV` and `git describe $REV`:

git rev-list $PREVIOUS_REV..$REV --first-parent --pretty

jx step changelog --version v$VERSION --generate-yaml=false --rev=$REV --previous-rev=$PREVIOUS_REV