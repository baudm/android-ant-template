#!/bin/sh

PROJECT_NAME=""

# Make sure that we're in the correct directory
cd "$(dirname "$0")"

PATH="$PATH:$ANDROID_HOME/tools"

TARGET="$(sed -n 's|.*android:targetSdkVersion="\([0-9]*\)".*|\1|p' AndroidManifest.xml)"
android update project --name "$PROJECT_NAME" --target "android-$TARGET" --subprojects --path .

# Fetch dependencies
git submodule init && git submodule update

# Generate project files for ant build
find . -name project.properties -type f -exec grep android\.library=true {} + | while read dep; do
    dir="$(dirname "$dep")"
    target="$(sed -n 's|.*android:targetSdkVersion="\([0-9]*\)".*|\1|p' "$dir/AndroidManifest.xml")"
    [ -n "$target" ] || target="$(grep target=android "$dir/project.properties" | cut -d'-' -f2)"
    [ "$target" -le $TARGET ] || echo "[WARNING] $dir: Target API level $target higher than project's (API level $TARGET)"
    echo "[PROCESS] $dir"
    android update lib-project --target "android-$target" --path "$dir" >/dev/null
    if [ $? -ne 0 ]; then
        echo "[WARNING] $dir: falling back to project's API level (android-$TARGET)"
        android update lib-project --target "android-$TARGET" --path "$dir" >/dev/null
    fi
done

# Use only one version of the v4 support library
find . -name android-support-v4.jar -type f | while read jar; do
    cp -va libs/android-support-v4.jar "$jar"
done
