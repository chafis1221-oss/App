#!/bin/bash

echo "========================================"
echo "QRIS Monitor - Project Checker"
echo "========================================"
echo ""

ERRORS=0
WARNINGS=0

# Check 1: main.dart - unused import dart:isolate
echo "[1] Checking main.dart for unused import..."
if grep -q "import 'dart:isolate';" lib/main.dart; then
    echo "  ⚠️  WARNING: 'dart:isolate' imported but not used in main.dart"
    ((WARNINGS++))
else
    echo "  ✅ OK"
fi
echo ""

# Check 2: main.dart - ForegroundTaskOptions compatibility
echo "[2] Checking main.dart for ForegroundTaskOptions..."
if grep -q "ForegroundTaskOptions" lib/main.dart; then
    echo "  ⚠️  WARNING: ForegroundTaskOptions might not exist in current version"
    echo "     Check if flutter_foreground_task 6.5+ supports this"
    ((WARNINGS++))
else
    echo "  ✅ OK"
fi
echo ""

# Check 3: foreground_service.dart - TaskStarter type
echo "[3] Checking foreground_service.dart for TaskStarter..."
if grep -q "TaskStarter" lib/services/foreground_service.dart; then
    echo "  ❌ ERROR: 'TaskStarter' not found in flutter_foreground_task 6.5+"
    echo "     Use 'SendPort?' instead"
    ((ERRORS++))
else
    echo "  ✅ OK"
fi
echo ""

# Check 4: foreground_service.dart - SendPort import
echo "[4] Checking foreground_service.dart for SendPort import..."
if grep -q "import 'dart:isolate';" lib/services/foreground_service.dart; then
    echo "  ✅ OK"
else
    echo "  ❌ ERROR: Missing 'import dart:isolate' for SendPort"
    ((ERRORS++))
fi
echo ""

# Check 5: notification_service.dart - Color class
echo "[5] Checking notification_service.dart for Color() usage..."
if grep -q "Color(" lib/services/notification_service.dart; then
    echo "  ❌ ERROR: 'Color()' not available, use 'const Color(0xFF...)' or remove"
    ((ERRORS++))
else
    echo "  ✅ OK"
fi
echo ""

# Check 6: All files exist
echo "[6] Checking all required files..."
REQUIRED_FILES=(
    "lib/main.dart"
    "lib/models/history_model.dart"
    "lib/screens/home_screen.dart"
    "lib/screens/settings_screen.dart"
    "lib/screens/history_screen.dart"
    "lib/services/websocket_service.dart"
    "lib/services/audio_service.dart"
    "lib/services/notification_service.dart"
    "lib/services/foreground_service.dart"
    "lib/utils/prefs_helper.dart"
    "lib/utils/history_manager.dart"
    "pubspec.yaml"
    "analysis_options.yaml"
    ".github/workflows/build_apk.yml"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✅ $file"
    else
        echo "  ❌ MISSING: $file"
        ((ERRORS++))
    fi
done
echo ""

# Check 7: pubspec.yaml dependencies
echo "[7] Checking pubspec.yaml dependencies..."
REQUIRED_DEPS=("provider" "web_socket_channel" "audioplayers" "shared_preferences" "flutter_local_notifications" "flutter_foreground_task" "intl")

for dep in "${REQUIRED_DEPS[@]}"; do
    if grep -q "$dep:" pubspec.yaml; then
        echo "  ✅ $dep"
    else
        echo "  ❌ MISSING: $dep"
        ((ERRORS++))
    fi
done
echo ""

# Check 8: pubspec.yaml - uses-material-design
echo "[8] Checking pubspec.yaml for uses-material-design..."
if grep -q "uses-material-design: true" pubspec.yaml; then
    echo "  ✅ OK"
else
    echo "  ❌ ERROR: Missing uses-material-design: true"
    ((ERRORS++))
fi
echo ""

# Check 9: Workflow - Kotlin fix
echo "[9] Checking workflow for Kotlin fix..."
if grep -q 'sed -i.*kotlin.*version' .github/workflows/build_apk.yml; then
    echo "  ✅ OK"
else
    echo "  ⚠️  WARNING: No Kotlin version fix in workflow"
    ((WARNINGS++))
fi
echo ""

# Check 10: Workflow - minSdk fix
echo "[10] Checking workflow for minSdk fix..."
if grep -q 'minSdkVersion 23' .github/workflows/build_apk.yml; then
    echo "  ✅ OK"
else
    echo "  ⚠️  WARNING: No minSdk fix in workflow"
    ((WARNINGS++))
fi
echo ""

# Check 11: No forbidden colors
echo "[11] Checking for forbidden neon/gaming colors..."
FORBIDDEN=("#FF00FF" "#00FF00" "#FF0000" "#00FFFF" "#FF1493" "#7FFF00" "#FF4500" "#8A2BE2")
FOUND=0
for color in "${FORBIDDEN[@]}"; do
    if grep -rq "$color" lib/ 2>/dev/null; then
        echo "  ⚠️  Found forbidden color: $color"
        FOUND=1
        ((WARNINGS++))
    fi
done
if [ $FOUND -eq 0 ]; then
    echo "  ✅ No neon colors found"
fi
echo ""

# Summary
echo "========================================"
echo "SUMMARY"
echo "========================================"
echo "Errors  : $ERRORS"
echo "Warnings: $WARNINGS"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo "✅ All checks passed! Ready to push."
elif [ $ERRORS -eq 0 ]; then
    echo "⚠️  Warnings found but no critical errors. Safe to push."
else
    echo "❌ $ERRORS error(s) found. Fix before pushing."
fi
