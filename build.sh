#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Usage function
usage() {
    echo -e "${BLUE}Usage: $0 [major|minor|patch]${NC}"
    echo ""
    echo "Build the PCO Alfred workflow with semantic versioning"
    echo ""
    echo "Arguments:"
    echo "  major    Increment major version (X.0.0)"
    echo "  minor    Increment minor version (x.Y.0)"
    echo "  patch    Increment patch version (x.y.Z)"
    echo ""
    echo "Examples:"
    echo "  $0 patch    # 1.0.0 -> 1.0.1"
    echo "  $0 minor    # 1.0.1 -> 1.1.0"
    echo "  $0 major    # 1.1.0 -> 2.0.0"
    exit 1
}

# Check if argument is provided
if [ $# -eq 0 ]; then
    echo -e "${RED}Error: No version increment specified${NC}"
    usage
fi

VERSION_TYPE=$1

# Validate version type
if [[ ! "$VERSION_TYPE" =~ ^(major|minor|patch)$ ]]; then
    echo -e "${RED}Error: Invalid version type '$VERSION_TYPE'${NC}"
    usage
fi

# Check if required files exist
required_files=("info.plist" "search.py" "items.json" "icon.png")
for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        echo -e "${RED}Error: Required file '$file' not found${NC}"
        exit 1
    fi
done

if [ ! -d "icons" ]; then
    echo -e "${RED}Error: Icons directory not found${NC}"
    exit 1
fi

# Get current version from plist
current_version=$(plutil -extract version raw info.plist 2>/dev/null || echo "0.0.0")
echo -e "${BLUE}Current version: ${NC}$current_version"

# Parse version components
IFS='.' read -ra VERSION_PARTS <<< "$current_version"
major=${VERSION_PARTS[0]:-0}
minor=${VERSION_PARTS[1]:-0}
patch=${VERSION_PARTS[2]:-0}

# Increment version based on type
case $VERSION_TYPE in
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
esac

new_version="$major.$minor.$patch"
echo -e "${GREEN}New version: ${NC}$new_version"

# Update version in plist
echo -e "${YELLOW}Updating version in info.plist...${NC}"
plutil -replace version -string "$new_version" info.plist

# Validate plist syntax
echo -e "${YELLOW}Validating plist syntax...${NC}"
if ! plutil -lint info.plist > /dev/null 2>&1; then
    echo -e "${RED}Error: Invalid plist syntax${NC}"
    exit 1
fi

# Test the search script
echo -e "${YELLOW}Testing search script...${NC}"
if ! python3 search.py "test" > /dev/null 2>&1; then
    echo -e "${RED}Error: Search script test failed${NC}"
    exit 1
fi

# Clean up any existing workflow file
workflow_file="pco-app-env-alfred.alfredworkflow"
if [ -f "$workflow_file" ]; then
    echo -e "${YELLOW}Removing existing workflow file...${NC}"
    rm "$workflow_file"
fi

# Build the workflow
echo -e "${YELLOW}Building Alfred workflow...${NC}"
if ! zip -r "$workflow_file" info.plist search.py items.json icon.png F4B2C123-A456-4B78-9C01-2D3E4F5G6H7I.png icons/ > /dev/null 2>&1; then
    echo -e "${RED}Error: Failed to create workflow file${NC}"
    exit 1
fi

# Verify the workflow file was created
if [ ! -f "$workflow_file" ]; then
    echo -e "${RED}Error: Workflow file was not created${NC}"
    exit 1
fi

file_size=$(du -h "$workflow_file" | cut -f1)
echo -e "${GREEN}✓ Successfully built workflow: ${NC}$workflow_file (${file_size})"
echo -e "${GREEN}✓ Version: ${NC}$new_version"
echo ""
echo -e "${BLUE}Ready to install:${NC} Double-click $workflow_file to install in Alfred"