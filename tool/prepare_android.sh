#!/usr/bin/env bash
set -euo pipefail
if [ ! -f android/gradlew ]; then
  flutter create --no-pub --platforms=android --org com.mazraa --project-name mazraa_agent .
fi
# Flutter's platform generator may write a template lockfile. Only enforce a
# dependency lock that was actually reviewed and committed to this repository.
if ! git ls-files --error-unmatch pubspec.lock >/dev/null 2>&1; then
  rm -f pubspec.lock
fi
