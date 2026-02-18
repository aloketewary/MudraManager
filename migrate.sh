#!/bin/bash

# Clean Architecture Migration Script
# Run this to migrate files to new structure

echo "🚀 Starting Clean Architecture Migration..."

# Create backup
echo "📦 Creating backup..."
cp -r lib lib_backup_$(date +%Y%m%d_%H%M%S)

# Phase 1: Core files
echo "📁 Phase 1: Moving core files..."
# Already done manually

# Phase 2: Update imports in new files
echo "🔄 Phase 2: Updating imports..."

# Update imports in core/constants
find lib/core/constants -name "*.dart" -exec sed -i '' 's|package:mudra_manager/util/|package:mudra_manager/core/constants/|g' {} +

# Update imports in core/utils
find lib/core/utils -name "*.dart" -exec sed -i '' 's|package:mudra_manager/util/|package:mudra_manager/core/utils/|g' {} +

# Update imports in shared/widgets
find lib/shared/widgets -name "*.dart" -exec sed -i '' 's|package:mudra_manager/components/|package:mudra_manager/shared/widgets/|g' {} +
find lib/shared/widgets -name "*.dart" -exec sed -i '' 's|package:mudra_manager/util/|package:mudra_manager/core/utils/|g' {} +

echo "✅ Migration complete!"
echo "📝 Next steps:"
echo "   1. Run: flutter pub get"
echo "   2. Run: flutter test"
echo "   3. Fix any remaining import errors"
echo "   4. Remove old folders after verification"
