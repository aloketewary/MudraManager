#!/bin/bash
#!/usr/bin/env bash

set -e

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
android_dir="$project_dir/android"

ensure_gradle_wrapper() {
  if [ -x "$android_dir/gradlew" ]; then
    return
  fi

  if ! command -v gradle >/dev/null 2>&1; then
    echo "❌ Android Gradle wrapper is missing: $android_dir/gradlew"
    echo "   Install Gradle or restore the Android Gradle wrapper files, then retry."
    return 1
  fi

  wrapper_properties="$android_dir/gradle/wrapper/gradle-wrapper.properties"
  gradle_version="$(sed -n 's/.*gradle-\([0-9][0-9.]*\)-.*/\1/p' "$wrapper_properties" | head -n 1)"
  if [ -z "$gradle_version" ]; then
    echo "❌ Could not determine Gradle version from $wrapper_properties"
    return 1
  fi

  echo "🧰 Gradle wrapper missing; generating Gradle $gradle_version wrapper..."
  temp_dir="$(mktemp -d "${TMPDIR:-/tmp}/mudra-gradle-wrapper.XXXXXX")"

  if ! (
    cd "$temp_dir"
    printf '%s\n' "rootProject.name = 'gradle-wrapper-bootstrap'" > settings.gradle
    printf '%s\n' "plugins { id 'base' }" > build.gradle
    gradle --no-daemon wrapper --gradle-version "$gradle_version"
  ); then
    rm -rf "$temp_dir"
    echo "❌ Could not generate the Gradle wrapper with the installed Gradle command."
    return 1
  fi

  mkdir -p "$android_dir/gradle/wrapper"
  cp "$temp_dir/gradlew" "$android_dir/gradlew"
  cp "$temp_dir/gradlew.bat" "$android_dir/gradlew.bat"
  cp "$temp_dir/gradle/wrapper/gradle-wrapper.jar" \
    "$android_dir/gradle/wrapper/gradle-wrapper.jar"
  chmod +x "$android_dir/gradlew"
  rm -rf "$temp_dir"

  if [ ! -x "$android_dir/gradlew" ]; then
    echo "❌ Gradle wrapper generation did not create $android_dir/gradlew"
    return 1
  fi
}

cd "$project_dir"

# Check if argument is passed
if [ -z "$1" ]; then
  echo "❗ Please provide a version bump type: major, minor, or patch."
  exit 1
fi

bump_type=$1

# Step 1: Read current version
version_line=$(grep 'version:' pubspec.yaml)
original_version=$(echo "$version_line" | sed 's/version: //')
current_version=$(echo "$original_version" | cut -d "+" -f1)
build_number=$(echo "$original_version" | cut -d "+" -f2)

if [ -z "$build_number" ]; then
  build_number=0
fi

IFS='.' read -r major minor patch <<< "$current_version"

# Step 2: Bump version based on type
case "$bump_type" in
  major)
    major=$((major + 1))
    minor=0
    patch=0
    ;;
  minor)
    minor=$((minor + 1))
    patch=0
    ;;
  patch)
    patch=$((patch + 1))
    ;;
  *)
    echo "❗ Invalid bump type: use major, minor, or patch."
    exit 1
    ;;
esac

new_version="$major.$minor.$patch"
new_build_number=$((build_number + 1))
new_full="$new_version+$new_build_number"

# Revert version on any failure
rollback() {
  echo ""
  echo "❌ Release failed! Reverting version to $original_version..."
  sed -i '' "s/version: .*/version: $original_version/" pubspec.yaml
  echo "↩️  Version reverted."
}
trap rollback ERR

# Step 3: Update pubspec.yaml
sed -i '' "s/version: .*/version: $new_full/" pubspec.yaml

echo "🚀 Starting $bump_type release: $original_version → $new_full"

# Step 4: Flutter clean and get
echo "🧹 Cleaning..."
flutter clean
echo "📦 Getting packages..."
flutter pub get

# Step 5: Static analysis
echo "🔍 Running flutter analyze..."
flutter analyze --no-fatal-infos
echo "✅ Analysis passed"

# Step 6: Flutter tests
echo "🧪 Running Flutter tests..."
flutter test
echo "✅ Flutter tests passed"

# Step 7: Android unit tests
ensure_gradle_wrapper
echo "🤖 Running Android unit tests..."
(
  cd "$android_dir"
  ./gradlew testProdReleaseUnitTest
)
echo "✅ Android tests passed"

# Step 8: Build appbundle
echo "🏗️ Building appbundle $new_version (versionCode $new_build_number)..."
flutter build appbundle \
  --flavor prod \
  --release \
  --build-name "$new_version" \
  --build-number "$new_build_number"

# Step 9: Verify generated Android version before committing.
manifest_metadata="$project_dir/build/app/intermediates/merged_manifests/prodRelease/processProdReleaseManifest/output-metadata.json"
if [ ! -f "$manifest_metadata" ] || ! grep -q "\"versionCode\": $new_build_number" "$manifest_metadata"; then
  echo "❌ Generated bundle does not contain versionCode $new_build_number"
  exit 1
fi

echo "✅ Generated bundle version verified: $new_version+$new_build_number"

# Step 10: Git commit
echo "📝 Committing version bump..."
git add pubspec.yaml
git commit -m "chore: release v$new_full"
# git tag "v$new_full" (optional)

echo "🎉 Release complete: $new_full"
