#!/bin/bash
# =============================================================================
# The Necromancer - Linux Dependency Installer
# =============================================================================
# This script installs runtime dependencies for The Necromancer on
# Debian-based systems (Debian, Ubuntu, Linux Mint, Pop!_OS, etc.)
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_msg() {
    local color=$1
    shift
    echo -e "${color}$*${NC}"
}

print_header() {
    echo ""
    print_msg "$BLUE" "=============================================="
    print_msg "$BLUE" "  The Necromancer - Dependency Installer"
    print_msg "$BLUE" "=============================================="
    echo ""
}

# Check if running as root or with sudo
check_sudo() {
    if [ "$EUID" -ne 0 ]; then
        if ! command -v sudo &> /dev/null; then
            print_msg "$RED" "ERROR: This script requires root privileges."
            print_msg "$YELLOW" "Please run as root or install sudo."
            exit 1
        fi
        SUDO="sudo"
    else
        SUDO=""
    fi
}

# Detect the package manager
detect_package_manager() {
    if command -v apt-get &> /dev/null; then
        PKG_MANAGER="apt"
        print_msg "$GREEN" "Detected package manager: APT (Debian/Ubuntu/Mint)"
    elif command -v dnf &> /dev/null; then
        PKG_MANAGER="dnf"
        print_msg "$GREEN" "Detected package manager: DNF (Fedora/RHEL)"
    elif command -v pacman &> /dev/null; then
        PKG_MANAGER="pacman"
        print_msg "$GREEN" "Detected package manager: Pacman (Arch)"
    else
        print_msg "$RED" "ERROR: Could not detect package manager."
        print_msg "$YELLOW" "Please install the following packages manually:"
        print_msg "$YELLOW" "  - libx11 (X11 runtime library)"
        print_msg "$YELLOW" "  - ncurses (terminal UI library)"
        exit 1
    fi
}

# Install packages based on detected package manager
install_packages() {
    print_msg "$BLUE" "Installing runtime dependencies..."
    echo ""

    case $PKG_MANAGER in
        apt)
            $SUDO apt-get update
            $SUDO apt-get install -y libx11-6 libncurses6 libncursesw6
            ;;
        dnf)
            $SUDO dnf install -y libX11 ncurses-libs
            ;;
        pacman)
            $SUDO pacman -S --noconfirm libx11 ncurses
            ;;
    esac
}

# Verify installation
verify_installation() {
    echo ""
    print_msg "$BLUE" "Verifying installation..."

    local all_ok=true

    # Check X11
    if ldconfig -p 2>/dev/null | grep -q "libX11" || [ -f /usr/lib/x86_64-linux-gnu/libX11.so* ]; then
        print_msg "$GREEN" "  [OK] libX11 found"
    else
        print_msg "$YELLOW" "  [WARN] libX11 not found (X11 mode may not work)"
    fi

    # Check ncurses
    if ldconfig -p 2>/dev/null | grep -q "libncurses" || [ -f /usr/lib/x86_64-linux-gnu/libncurses* ]; then
        print_msg "$GREEN" "  [OK] libncurses found"
    else
        print_msg "$RED" "  [FAIL] libncurses not found"
        all_ok=false
    fi

    echo ""
    if $all_ok; then
        print_msg "$GREEN" "All dependencies installed successfully!"
    else
        print_msg "$RED" "Some dependencies may be missing. The game may not work correctly."
    fi
}

# Main
print_header
check_sudo
detect_package_manager
install_packages
verify_installation

echo ""
print_msg "$GREEN" "=============================================="
print_msg "$GREEN" "  Installation complete!"
print_msg "$GREEN" "=============================================="
echo ""
print_msg "$BLUE" "To play The Necromancer, run:"
print_msg "$YELLOW" "    ./run-necromancer.sh"
echo ""
print_msg "$BLUE" "Or directly:"
print_msg "$YELLOW" "    ./necromancer -mx11     # For graphical mode"
print_msg "$YELLOW" "    ./necromancer -mgcu     # For terminal mode"
echo ""
