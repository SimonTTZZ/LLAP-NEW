#!/bin/bash
set -e

PROJECT_NAME="llap"
SCHEME="llap"
CONFIGURATION="Release"

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="${PROJECT_DIR}/build"
ARCHIVE_PATH="${BUILD_DIR}/${PROJECT_NAME}.xcarchive"
EXPORT_PATH="${BUILD_DIR}/ipa"

XCODE_DIR=$(xcode-select -p)
echo "Using Xcode: ${XCODE_DIR}"
xcodebuild -version

BUILD_LOG="${BUILD_DIR}/build.log"

rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

run_xcodebuild() {
    if command -v xcpretty >/dev/null 2>&1; then
        xcodebuild "$@" 2>&1 | tee "${BUILD_LOG}" | xcpretty
        return ${PIPESTATUS[0]}
    else
        xcodebuild "$@" 2>&1 | tee "${BUILD_LOG}"
        return ${PIPESTATUS[0]}
    fi
}

echo ""
echo "=== Cleaning ==="
run_xcodebuild \
    -project "${PROJECT_DIR}/${PROJECT_NAME}.xcodeproj" \
    -scheme "${SCHEME}" \
    -configuration "${CONFIGURATION}" \
    -sdk iphoneos \
    clean

echo ""
echo "=== Archiving (unsigned) ==="
run_xcodebuild \
    -project "${PROJECT_DIR}/${PROJECT_NAME}.xcodeproj" \
    -scheme "${SCHEME}" \
    -configuration "${CONFIGURATION}" \
    -sdk iphoneos \
    -archivePath "${ARCHIVE_PATH}" \
    archive \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGN_STYLE=Manual

if [ ! -d "${ARCHIVE_PATH}" ]; then
    echo ""
    echo "!!! Archive failed, check errors above !!!"
    exit 1
fi

APP_PATH="${ARCHIVE_PATH}/Products/Applications/${PROJECT_NAME}.app"
if [ ! -d "${APP_PATH}" ]; then
    echo ""
    echo "!!! App bundle not found at ${APP_PATH} !!!"
    exit 1
fi

echo ""
echo "=== Packaging unsigned IPA ==="
IPA_NAME="${PROJECT_NAME}.ipa"
STAGING_DIR="${BUILD_DIR}/ipa-staging"
rm -rf "${STAGING_DIR}"
mkdir -p "${STAGING_DIR}/Payload"
cp -R "${APP_PATH}" "${STAGING_DIR}/Payload/"

mkdir -p "${EXPORT_PATH}"
(
    cd "${STAGING_DIR}"
    zip -qr "${EXPORT_PATH}/${IPA_NAME}" Payload
)

IPA_FILE="${EXPORT_PATH}/${IPA_NAME}"
if [ ! -f "${IPA_FILE}" ]; then
    echo ""
    echo "!!! IPA packaging failed !!!"
    exit 1
fi

echo ""
echo "=== Done ==="
echo "IPA generated: ${IPA_FILE}"
echo "Size: $(du -h "${IPA_FILE}" | cut -f1)"
echo "Project dir: ${PROJECT_DIR}"
