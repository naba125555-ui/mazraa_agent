#!/usr/bin/env bash
set -euo pipefail
if [ ! -f android/gradlew ]; then
  flutter create --no-pub --platforms=android --org com.mazraa --project-name mazraa_agent .
fi
