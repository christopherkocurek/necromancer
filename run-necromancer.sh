#!/bin/bash
# =============================================================================
# The Necromancer - Linux Launcher
# =============================================================================
# This script launches The Necromancer with automatic display mode detection.
# Run with -h or --help for usage information.
# =============================================================================

set -e

# Get the directory where this script is located and change to it
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || { echo "ERROR: Cannot change to game directory"; exit 1; }
GAME_BIN="./necromancer"
GAME_LIB="./lib"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Print colored message
print_msg() {
    local color=$1
    shift
    echo -e "${color}$*${NC}"
}

# Show help
show_help() {
    cat << 'EOF'
The Necromancer - Linux Launcher

USAGE:
    ./run-necromancer.sh [OPTIONS]

OPTIONS:
    -x, --x11       Force X11 graphical mode
    -t, --terminal  Force terminal (ncurses) mode
    -h, --help      Show this help message

DISPLAY MODE:
    By default, the launcher automatically detects the best display mode:
    - If DISPLAY is set (running in X11/Wayland), uses X11 mode
    - Otherwise, uses terminal (ncurses) mode

EXAMPLES:
    ./run-necromancer.sh           # Auto-detect display mode
    ./run-necromancer.sh -x        # Force X11 mode
    ./run-necromancer.sh -t        # Force terminal mode (good for SSH)

TROUBLESHOOTING:
    If the game fails to start, try running:
        ./install.sh
    to install any missing dependencies.

    For terminal color issues, ensure your terminal supports 256 colors:
        export TERM=xterm-256color

EOF
    exit 0
}

# Check for required libraries
check_dependencies() {
    local missing=()
    local warnings=()

    # Check for X11 library (needed for -mx11)
    if ! ldconfig -p 2>/dev/null | grep -q "libX11.so"; then
        if [ -f /usr/lib/x86_64-linux-gnu/libX11.so* ] || [ -f /usr/lib/libX11.so* ]; then
            : # Library exists but not in ldconfig cache
        else
            warnings+=("libX11 (X11 mode may not work)")
        fi
    fi

    # Check for ncurses library (needed for -mgcu)
    if ! ldconfig -p 2>/dev/null | grep -q "libncurses"; then
        if [ -f /usr/lib/x86_64-linux-gnu/libncurses* ] || [ -f /usr/lib/libncurses* ]; then
            : # Library exists but not in ldconfig cache
        else
            missing+=("libncurses6")
        fi
    fi

    # Report missing critical dependencies
    if [ ${#missing[@]} -gt 0 ]; then
        print_msg "$RED" "ERROR: Missing required libraries: ${missing[*]}"
        print_msg "$YELLOW" "Install them with: sudo apt-get install ${missing[*]}"
        print_msg "$YELLOW" "Or run: ./install.sh"
        exit 1
    fi

    # Report warnings
    if [ ${#warnings[@]} -gt 0 ]; then
        print_msg "$YELLOW" "WARNING: Some optional libraries may be missing: ${warnings[*]}"
        print_msg "$YELLOW" "X11 graphical mode may not be available."
    fi
}

# Check if game binary exists
check_binary() {
    if [ ! -f "$GAME_BIN" ]; then
        print_msg "$RED" "ERROR: Game binary not found at: $GAME_BIN"
        print_msg "$YELLOW" "If you're building from source, run:"
        print_msg "$YELLOW" "    cd src && make -f Makefile.std && make -f Makefile.std install"
        exit 1
    fi

    if [ ! -x "$GAME_BIN" ]; then
        print_msg "$YELLOW" "Making game binary executable..."
        chmod +x "$GAME_BIN"
    fi
}

# Check if lib directory exists
check_lib() {
    if [ ! -d "$GAME_LIB" ]; then
        print_msg "$RED" "ERROR: Game data directory not found at: $GAME_LIB"
        print_msg "$YELLOW" "Make sure the lib/ directory is in the same location as this script."
        exit 1
    fi
}

# Parse command line arguments
MODE=""
while [[ $# -gt 0 ]]; do
    case $1 in
        -x|--x11)
            MODE="x11"
            shift
            ;;
        -t|--terminal)
            MODE="gcu"
            shift
            ;;
        -h|--help)
            show_help
            ;;
        *)
            print_msg "$RED" "Unknown option: $1"
            print_msg "$YELLOW" "Use --help for usage information."
            exit 1
            ;;
    esac
done

# Auto-detect mode if not specified
if [ -z "$MODE" ]; then
    if [ -n "$DISPLAY" ] || [ -n "$WAYLAND_DISPLAY" ]; then
        MODE="x11"
        print_msg "$GREEN" "Detected graphical environment, using X11 mode..."
    else
        MODE="gcu"
        print_msg "$GREEN" "No graphical environment detected, using terminal mode..."
    fi
fi

# Run checks
check_binary
check_lib
check_dependencies

# Launch the game (don't pass extra args to avoid injection risks)
print_msg "$GREEN" "Starting The Necromancer..."
echo ""

if [ "$MODE" = "x11" ]; then
    exec ./necromancer -mx11
else
    exec ./necromancer -mgcu
fi
