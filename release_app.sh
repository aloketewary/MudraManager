#!/bin/bash

set -e

# Check if argument is passed
if [ -z "$1" ]; then
  echo "❗ Please provide a version bump type: major, minor, or patch."
  exit 1
fi

bump_type=$1
echo "🚀 Starting $bump_type release..."

# Step 1: Read current version
version_line=$(grep 'version:' pubspec.yaml)
current_version=$(echo "$version_line" | sed 's/version: //' | cut -d "+" -f1)
build_number=$(echo "$version_line" | sed 's/version: //' | cut -d "+" -f2)

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

# Step 3: Update pubspec.yaml
sed -i '' "s/version: .*/version: $new_version+$new_build_number/" pubspec.yaml
echo "✅ New version: $new_version+$new_build_number"

# Step 4: Flutter clean and get
echo "🧹 Cleaning..."
flutter clean
echo "📦 Getting packages..."
flutter pub get

# Step 5: Build APK
echo "🏗️ Building appbundle..."
flutter build appbundle --release

# Step 6: Git commit (Optional)
echo "📝 Committing version bump..."
git add pubspec.yaml
git commit -m "chore: release v$new_version+$new_build_number"
# git tag "v$new_version+$new_build_number" (optional)

echo "🎉 $bump_type Release complete!"
