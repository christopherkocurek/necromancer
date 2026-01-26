#!/bin/bash
# =============================================================================
# The Necromancer - Linux Release Builder
# =============================================================================
# This script builds a complete Linux distribution package.
# Run this on a Linux system with build dependencies installed.
# =============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_msg() {
    local color=$1
    shift
    echo -e "${color}$*${NC}"
}

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Configuration
VERSION="${VERSION:-1.0.1-beta}"
ARCH="$(uname -m)"
DIST_NAME="necromancer-${VERSION}-linux-${ARCH}"
DIST_DIR="${SCRIPT_DIR}/${DIST_NAME}"

print_msg "$BLUE" "=============================================="
print_msg "$BLUE" "  The Necromancer - Linux Release Builder"
print_msg "$BLUE" "=============================================="
print_msg "$BLUE" "  Version: ${VERSION}"
print_msg "$BLUE" "  Architecture: ${ARCH}"
echo ""

# Step 1: Check build dependencies
print_msg "$BLUE" "[1/6] Checking build dependencies..."
MISSING_DEPS=()

command -v gcc >/dev/null 2>&1 || MISSING_DEPS+=("gcc")
command -v make >/dev/null 2>&1 || MISSING_DEPS+=("make")

if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    print_msg "$RED" "Missing build dependencies: ${MISSING_DEPS[*]}"
    print_msg "$YELLOW" "Install with: sudo apt-get install build-essential libx11-dev libncurses-dev"
    exit 1
fi

# Check for development headers
if [ ! -f /usr/include/X11/Xlib.h ] && [ ! -f /usr/include/x86_64-linux-gnu/X11/Xlib.h ]; then
    print_msg "$YELLOW" "Warning: X11 development headers may be missing"
    print_msg "$YELLOW" "Install with: sudo apt-get install libx11-dev"
fi

if [ ! -f /usr/include/ncurses.h ] && [ ! -f /usr/include/ncurses/ncurses.h ]; then
    print_msg "$YELLOW" "Warning: ncurses development headers may be missing"
    print_msg "$YELLOW" "Install with: sudo apt-get install libncurses-dev"
fi

print_msg "$GREEN" "Dependencies OK"

# Step 2: Clean previous builds
print_msg "$BLUE" "[2/6] Cleaning previous builds..."
rm -rf "$DIST_DIR"
rm -f "${DIST_NAME}.tar.gz"
cd src
make -f Makefile.std clean 2>/dev/null || true
print_msg "$GREEN" "Clean complete"

# Step 3: Build the binary
print_msg "$BLUE" "[3/6] Building necromancer..."
make -f Makefile.std
if [ ! -f necromancer ]; then
    print_msg "$RED" "Build failed - necromancer binary not created"
    exit 1
fi

# Verify library dependencies
print_msg "$BLUE" "Verifying library dependencies..."
if ldd necromancer 2>/dev/null | grep -q "not found"; then
    print_msg "$RED" "Build failed - binary has missing library dependencies:"
    ldd necromancer | grep "not found"
    exit 1
fi
print_msg "$GREEN" "Build complete"

# Step 4: Create distribution directory
print_msg "$BLUE" "[4/6] Creating distribution package..."
cd "$SCRIPT_DIR"

mkdir -p "$DIST_DIR"

# Copy binary
cp src/necromancer "$DIST_DIR/"
chmod +x "$DIST_DIR/necromancer"

# Copy game data
cp -r lib "$DIST_DIR/"

# Remove any save files or user data from distribution (safely)
if [ -d "$DIST_DIR/lib/save" ] && [ ! -L "$DIST_DIR/lib/save" ]; then
    rm -rf "${DIST_DIR}/lib/save/"* 2>/dev/null || true
fi
if [ -d "$DIST_DIR/lib/user" ] && [ ! -L "$DIST_DIR/lib/user" ]; then
    rm -rf "${DIST_DIR}/lib/user/"* 2>/dev/null || true
fi

# Copy scripts
cp run-necromancer.sh "$DIST_DIR/"
cp install.sh "$DIST_DIR/"
chmod +x "$DIST_DIR/run-necromancer.sh"
chmod +x "$DIST_DIR/install.sh"

# Copy documentation
cp README-LINUX.txt "$DIST_DIR/"
cp README.md "$DIST_DIR/" 2>/dev/null || true
cp LICENSE.md "$DIST_DIR/" 2>/dev/null || true
cp CHANGELOG.md "$DIST_DIR/" 2>/dev/null || true
cp "The Necromancer Manual.pdf" "$DIST_DIR/" 2>/dev/null || true

print_msg "$GREEN" "Distribution directory created"

# Step 5: Create tarball
print_msg "$BLUE" "[5/6] Creating tarball..."
tar -czvf "${DIST_NAME}.tar.gz" "${DIST_NAME}/"

print_msg "$GREEN" "Tarball created: ${DIST_NAME}.tar.gz"

# Step 6: Verify package
print_msg "$BLUE" "[6/6] Verifying package..."

# Check tarball contents
echo ""
print_msg "$BLUE" "Package contents:"
tar -tzvf "${DIST_NAME}.tar.gz" | head -20
echo "..."

# Check package size
echo ""
PACKAGE_SIZE=$(ls -lh "${DIST_NAME}.tar.gz" | awk '{print $5}')
print_msg "$BLUE" "Package size: ${PACKAGE_SIZE}"

# Verify critical files
echo ""
print_msg "$BLUE" "Verifying critical files in package..."
REQUIRED_FILES=(
    "${DIST_NAME}/necromancer"
    "${DIST_NAME}/run-necromancer.sh"
    "${DIST_NAME}/install.sh"
    "${DIST_NAME}/README-LINUX.txt"
    "${DIST_NAME}/lib/edit/monster.txt"
)

ALL_OK=true
for file in "${REQUIRED_FILES[@]}"; do
    if tar -tzf "${DIST_NAME}.tar.gz" | grep -q "^${file}$"; then
        print_msg "$GREEN" "  [OK] ${file}"
    else
        print_msg "$RED" "  [MISSING] ${file}"
        ALL_OK=false
    fi
done

echo ""
if $ALL_OK; then
    print_msg "$GREEN" "=============================================="
    print_msg "$GREEN" "  BUILD SUCCESSFUL!"
    print_msg "$GREEN" "=============================================="
    echo ""
    print_msg "$BLUE" "Distribution package: ${DIST_NAME}.tar.gz"
    print_msg "$BLUE" "Send this file to your brother!"
    echo ""
    print_msg "$YELLOW" "To test locally:"
    print_msg "$YELLOW" "  tar -xzvf ${DIST_NAME}.tar.gz"
    print_msg "$YELLOW" "  cd ${DIST_NAME}"
    print_msg "$YELLOW" "  ./run-necromancer.sh"
else
    print_msg "$RED" "=============================================="
    print_msg "$RED" "  BUILD FAILED - Missing files in package"
    print_msg "$RED" "=============================================="
    exit 1
fi
