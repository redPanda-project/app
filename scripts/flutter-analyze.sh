#!/bin/sh
# flutter analyze exists with exit code 1 even if only info
# github issue: https://github.com/flutter/flutter/issues/20855
OUTPUT="$(flutter analyze)"
echo "$OUTPUT"
echo
if grep -q "error •" <<< "$OUTPUT"; then
    echo "flutter analyze found errors"
    exit 1
else
    echo "flutter analyze didn't find any errors"
    exit 0
fi