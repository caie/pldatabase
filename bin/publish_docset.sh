#!/bin/sh

# Name of the project
PROJECT_NAME="pldatabase"

PUBLIC_SVN_URL="http://pldatabase.googlecode.com/svn/"

DOCSET_ID="com.plausiblelabs.PLDatabase"

# Parse script arguments
print_usage () {
    echo "Usage: $0 <tag version>"
}

VERSION=$1

if [ -z "$VERSION" ]; then
    print_usage
    exit 1
fi

# Project root
ROOT_PATH="`dirname $0`/../"

# Determine the tag path
TAG_NAME="${PROJECT_NAME}-${VERSION}"
TAG_DIR="${ROOT_PATH}/tags/${TAG_NAME}"

# Verify the tag exists
if [ ! -d "$TAG_DIR" ]; then
    echo "Tag $TAG_DIR does not exist, aborting."
    exit 1
fi

# Docset paths
DOCSET_DIR="${ROOT_PATH}/xcode-docset"
DOCSET_ATOM="${DOCSET_DIR}/feed.atom"
DOCSET_INPUT_FILE="${DOCSET_ID}.docset"
DOCSET_OUTPUT_FILE="${DOCSET_ID}-${VERSION}.xar"
DOCSET_PUBLIC_URL="${PUBLIC_SVN_URL}/xcode-docset/"

# Xcode paths
XCODE_BASE=`xcode-select -print-path`
DOCSET_UTIL="${XCODE_BASE}/usr/bin/docsetutil"

if [ -z "$XCODE_BASE" ]; then
    echo "Could not determine Xcode installation path"
    exit 1
fi

# Build the Xcode docset
make -C "${TAG_DIR}/docs"

# Populate the feed URL and docset version
/usr/libexec/PlistBuddy -c "Add :DocSetFeedURL string ${DOCSET_PUBLIC_URL}/${DOCSET_OUTPUT_FILE}" "${TAG_DIR}/docs/${DOCSET_INPUT_FILE}/Contents/Info.plist" 
/usr/libexec/PlistBuddy -c "Add :CFBundleVersion string ${VERSION}" "${TAG_DIR}/docs/${DOCSET_INPUT_FILE}/Contents/Info.plist" 

# Output the .xar package and the atom file.
"${DOCSET_UTIL}" package -output "${DOCSET_DIR}/${DOCSET_OUTPUT_FILE}" -atom "${DOCSET_ATOM}" \
	-download-url="${DOCSET_PUBLIC_URL}/${DOCSET_OUTPUT_FILE}" "${TAG_DIR}/docs/${DOCSET_INPUT_FILE}"
rm -rf "${TAG_DIR}/docs/${DOCSET_INPUT_FILE}"

svn add "${DOCSET_DIR}/${DOCSET_OUTPUT_FILE}"

# Validate the build worked
if [ $? -gt 0 ]; then
    echo "Build failed, aborting tagging process."
    exit 1
fi