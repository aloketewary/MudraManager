#!/bin/bash

# Quick Deploy Script for Mudra Manager
# This script helps you deploy to Play Store via GitHub Actions

set -e

echo "🚀 Mudra Manager - Play Store Deployment Helper"
echo "================================================"
echo ""

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
  echo "❌ Error: pubspec.yaml not found. Run this from project root."
  exit 1
fi

# Get current version
current_version=$(grep 'version:' pubspec.yaml | sed 's/version: //')
echo "📦 Current version: $current_version"
echo ""

# Ask for version bump type
echo "Select version bump type:"
echo "1) Patch (3.0.4 → 3.0.5)"
echo "2) Minor (3.0.4 → 3.1.0)"
echo "3) Major (3.0.4 → 4.0.0)"
echo "4) Custom"
echo "5) Deploy current version"
read -p "Enter choice (1-5): " choice

case $choice in
  1|2|3)
    ./release_app.sh $([ "$choice" = "1" ] && echo "patch" || [ "$choice" = "2" ] && echo "minor" || echo "major")
    new_version=$(grep 'version:' pubspec.yaml | sed 's/version: //')
    ;;
  4)
    read -p "Enter new version (e.g., 3.1.0+14): " new_version
    sed -i '' "s/version: .*/version: $new_version/" pubspec.yaml
    echo "✅ Version updated to: $new_version"
    ;;
  5)
    new_version=$current_version
    echo "✅ Using current version: $new_version"
    ;;
  *)
    echo "❌ Invalid choice"
    exit 1
    ;;
esac

echo ""
echo "📋 Pre-deployment checklist:"
echo "  ✓ Version updated to: $new_version"
echo ""

# Ask for confirmation
read -p "🔍 Have you set up GitHub Secrets? (y/n): " secrets_ready
if [ "$secrets_ready" != "y" ]; then
  echo "⚠️  Please set up GitHub Secrets first. See GITHUB_ACTIONS_SETUP.md"
  exit 1
fi

read -p "🔍 Ready to deploy to Play Store? (y/n): " confirm
if [ "$confirm" != "y" ]; then
  echo "❌ Deployment cancelled"
  exit 1
fi

# Create and push tag
tag_name="v${new_version%+*}"
echo ""
echo "🏷️  Creating tag: $tag_name"

git add pubspec.yaml
git commit -m "chore: bump version to $new_version" || echo "No changes to commit"
git tag -a "$tag_name" -m "Release $tag_name"

echo ""
echo "📤 Pushing to GitHub..."
git push origin main
git push origin "$tag_name"

echo ""
echo "✅ Deployment triggered!"
echo ""
echo "📊 Monitor progress:"
echo "   GitHub Actions: https://github.com/YOUR_USERNAME/mudra_manager/actions"
echo "   Play Console: https://play.google.com/console"
echo ""
echo "⏱️  Deployment usually takes 5-10 minutes"
echo "📧 You'll receive an email when it's ready for testing"
