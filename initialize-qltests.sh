#!/bin/sh

# This script copies Exercise#.c files from the
# tests-common directory to the appropriate sub-directories
# in the  solutions-tests and exercises-tests QLTest directories.
[[ $(git rev-parse --show-toplevel) == $(pwd) ]] || {
    echo "This script must be run from the root of the workshop repository."
    exit 1
}

SRCDIR=$(pwd)/tests-common

target_dirs=(
    $(pwd)/solutions-tests
    $(pwd)/exercises-tests
)

for dir in "${target_dirs[@]}"; do
    for i in {1..4}; do
        cp $SRCDIR/test.c $dir/Exercise$i/test.c
    done
done

exit 0