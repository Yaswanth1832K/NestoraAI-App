#!/bin/bash

# Exit on error
set -e

echo "--- Installing Flutter ---"
git clone https://github.com/flutter/flutter.git -b stable --depth 1
export PATH="$PATH:`pwd`/flutter/bin"

echo "--- Flutter Version ---"
flutter --version

echo "--- Building for Web ---"
flutter config --enable-web
flutter pub get
flutter build web --release

echo "--- Build Complete ---"
