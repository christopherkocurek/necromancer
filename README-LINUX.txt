================================================================================
                    THE NECROMANCER - LINUX EDITION
                         Version 1.0.1-beta
================================================================================

A roguelike adventure set in Tolkien's Third Age of Middle-earth, when the
shadow returned to Dol Guldur and the Necromancer claimed his dark tower.

================================================================================
                           QUICK START
================================================================================

1. Extract the archive:
       tar -xzvf necromancer-*-linux-*.tar.gz

2. Enter the game directory:
       cd necromancer-linux

3. (First time only) Install dependencies:
       ./install.sh

4. Run the game:
       ./run-necromancer.sh


================================================================================
                         SYSTEM REQUIREMENTS
================================================================================

Operating System:
    - Linux Mint 20+ (Cinnamon, MATE, Xfce)
    - Ubuntu 20.04+
    - Debian 11+
    - Any modern Linux distribution

Required Libraries:
    - libncurses6 (for terminal mode)
    - libx11-6 (for graphical mode)

These are typically pre-installed on most desktop Linux systems.
If not, run ./install.sh to install them.


================================================================================
                          RUNNING THE GAME
================================================================================

AUTOMATIC MODE DETECTION:
    ./run-necromancer.sh

    The launcher automatically detects whether you're running in a graphical
    environment (X11/Wayland) or a text terminal and chooses the appropriate
    display mode.

FORCE GRAPHICAL MODE (X11):
    ./run-necromancer.sh -x
    or
    ./necromancer -mx11

FORCE TERMINAL MODE (ncurses):
    ./run-necromancer.sh -t
    or
    ./necromancer -mgcu

    Terminal mode is useful for:
    - Playing over SSH
    - Low-resource systems
    - Accessibility (works with screen readers)


================================================================================
                            CONTROLS
================================================================================

Movement:       Arrow keys or numpad (8-way movement with diagonals)
Attack:         Move into enemies
Inventory:      i
Equipment:      e
Character:      c
Full Map:       m
Help:           ?
Save & Quit:    ESC or Q


================================================================================
                          SAVE FILES
================================================================================

Save files are stored in:
    ~/Documents/Sil/Sil-Q/

Or if that doesn't exist:
    ~/.angband/Sil-Q/

Each character gets their own save file. The game uses permadeath - if your
character dies, the save file is deleted!


================================================================================
                        TROUBLESHOOTING
================================================================================

PROBLEM: "Game won't start"
SOLUTION:
    1. Run ./install.sh to install dependencies
    2. Make sure the binary is executable: chmod +x necromancer
    3. Check for error messages in the terminal

PROBLEM: "No colors in terminal mode"
SOLUTION:
    Ensure your terminal supports colors:
        export TERM=xterm-256color
    Then restart the game.

PROBLEM: "X11 mode fails to open window"
SOLUTION:
    1. Make sure you're running in a graphical environment
    2. Check that DISPLAY variable is set: echo $DISPLAY
    3. Try terminal mode instead: ./run-necromancer.sh -t

PROBLEM: "Permission denied"
SOLUTION:
    Make scripts executable:
        chmod +x run-necromancer.sh install.sh necromancer

PROBLEM: "Library not found" errors
SOLUTION:
    Install missing libraries:
        sudo apt-get install libx11-6 libncurses6

PROBLEM: "Game data not found"
SOLUTION:
    Make sure the lib/ directory is in the same folder as the necromancer
    binary. Do not move the binary without the lib/ folder.


================================================================================
                        BUILDING FROM SOURCE
================================================================================

If you want to build from source instead of using the pre-built binary:

1. Install build dependencies:
       sudo apt-get install build-essential gcc make libx11-dev libncurses-dev

2. Build the game:
       cd src
       make -f Makefile.std clean
       make -f Makefile.std
       make -f Makefile.std install

The binary will be created in the parent directory.


================================================================================
                         REPORTING BUGS
================================================================================

Please report bugs at:
    https://github.com/christopherkocurek/necromancer/issues

When reporting, include:
    - Linux distribution and version (e.g., "Linux Mint 21.2 Cinnamon")
    - Display mode used (X11 or terminal)
    - Steps to reproduce the issue
    - Any error messages shown
    - Character dump if relevant (press | then f in-game)


================================================================================
                            CREDITS
================================================================================

The Necromancer is built upon:
    - Sil by Scatha and Fingolfin
    - Sil-Q maintained by the Sil-Q community
    - Original Angband by Ben Harrison and many contributors

Licensed under the GNU General Public License v2.


================================================================================
        "In the shadows of Mirkwood's eaves, a darkness stirs..."
================================================================================
