#!/bin/bash

set -e

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
echo "🤖 Running Android unit tests..."
cd android
./gradlew testProdReleaseUnitTest
cd ..
echo "✅ Android tests passed"

# Step 8: Build appbundle
echo "🏗️ Building appbundle..."
flutter build appbundle --flavor prod --release

# Step 9: Git commit
echo "📝 Committing version bump..."
git add pubspec.yaml
git commit -m "chore: release v$new_full"
# git tag "v$new_full" (optional)

echo "🎉 Release complete: $new_full"
