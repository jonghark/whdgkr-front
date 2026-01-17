#!/bin/bash
# macOS 실행/포그라운드 실패 자동 진단 및 복구 스크립트

set -e

APP_NAME="whdgkr"
APP_PATH="/Users/moneystar/whdgkr-front/build/macos/Build/Products/Debug/whdgkr.app"
BUNDLE_ID="com.whdgkr.whdgkr"

echo "=== macOS Launch Diagnostic Tool ==="

# STEP 1: 실행 여부 판정
echo ""
echo "[STEP 1] Checking if app is running..."
PID=$(pgrep -f "${APP_PATH}/Contents/MacOS/${APP_NAME}" || echo "")

if [ -n "$PID" ]; then
    echo "[LAUNCH_DIAG] running=true pid=$PID"

    # STEP 2: 포그라운드 시도
    echo ""
    echo "[STEP 2] Attempting to bring app to foreground..."

    # AppleScript로 activate 시도
    osascript -e "tell application \"${APP_NAME}\" to activate" 2>/dev/null && {
        echo "[LAUNCH_DIAG] activate=ok"
        echo ""
        echo "✓ App successfully brought to foreground"
        exit 0
    } || {
        echo "[LAUNCH_DIAG] activate=fail"
        echo "[LAUNCH_DIAG] reason=focus_permission"
        echo ""
        echo "⚠️  Failed to activate app. Possible causes:"
        echo "   - macOS accessibility/automation permissions not granted"
        echo "   - App is in background but unresponsive"
        echo ""
        echo "Attempting force kill and restart..."

        # SIGTERM 먼저 시도
        kill -TERM "$PID" 2>/dev/null || true
        sleep 2

        # 아직 살아있으면 SIGKILL
        if pgrep -f "${APP_PATH}/Contents/MacOS/${APP_NAME}" > /dev/null; then
            kill -KILL "$PID" 2>/dev/null || true
            sleep 1
        fi

        echo "[LAUNCH_DIAG] killed pid=$PID"

        # 재실행은 사용자가 flutter run으로 수동 실행
        echo ""
        echo "✓ App process terminated. Please run 'flutter run -d macos' again."
        exit 0
    }
else
    echo "[LAUNCH_DIAG] running=false"

    # STEP 3: 실행 자체가 안된 케이스
    echo ""
    echo "[STEP 3] App not running. Diagnosing launch failure..."

    # 원인 진단
    REASON=""

    # 크래시 로그 확인
    if ls -t ~/Library/Logs/DiagnosticReports/${APP_NAME}*.crash 2>/dev/null | head -1 | grep -q .; then
        LATEST_CRASH=$(ls -t ~/Library/Logs/DiagnosticReports/${APP_NAME}*.crash 2>/dev/null | head -1)
        REASON="crash_exit"
        echo "[LAUNCH_DIAG] reason=crash_exit"
        echo ""
        echo "⚠️  App crashed on launch. Check crash log:"
        echo "   $LATEST_CRASH"
    else
        # LaunchServices 캐시 문제 가능성
        REASON="launchservices_cache"
        echo "[LAUNCH_DIAG] reason=launchservices_cache"
        echo ""
        echo "⚠️  Possible LaunchServices cache corruption"
        echo "   Try: /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user"
    fi

    echo ""
    echo "Please run 'flutter run -d macos' to start the app."
    exit 1
fi
