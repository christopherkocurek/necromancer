# The Necromancer - Linux Test Checklist

Hi! Please test The Necromancer on your Linux Mint system and check off each item below.
Report any issues by describing what happened vs. what you expected.

---

## System Information

**Please fill this out:**
- Linux Distribution: _________________ (e.g., Linux Mint 21.2 Cinnamon)
- Desktop Environment: _________________ (e.g., Cinnamon, MATE, Xfce)
- Terminal: _________________ (e.g., GNOME Terminal, Konsole)

---

## Part 1: Installation

### 1.1 Extract Package
- [ ] Downloaded the .tar.gz file
- [ ] Extracted successfully: `tar -xzvf necromancer-*-linux-*.tar.gz`
- [ ] Can see the `necromancer-linux` folder

### 1.2 Check Contents
Inside the folder, you should see:
- [ ] `necromancer` (the game binary)
- [ ] `run-necromancer.sh` (launcher script)
- [ ] `install.sh` (dependency installer)
- [ ] `README-LINUX.txt` (instructions)
- [ ] `lib/` folder (game data)

### 1.3 Install Dependencies (if needed)
- [ ] Ran `./install.sh` (requires sudo password)
- [ ] No errors during installation
- [ ] Or: Dependencies were already installed

---

## Part 2: Terminal Mode (ncurses)

### 2.1 Launch Test
Run: `./run-necromancer.sh -t` or `./necromancer -mgcu`

- [ ] Game window appears in terminal
- [ ] Main menu is visible
- [ ] Text is readable (not garbled)

### 2.2 Visual Test
- [ ] Colors display correctly (different colors for different elements)
- [ ] No weird characters or broken lines
- [ ] Screen updates smoothly when navigating

### 2.3 Basic Gameplay
- [ ] Can select "New Game"
- [ ] Can create a new character (pick race, house, name)
- [ ] Character creation completes successfully
- [ ] Game starts and dungeon is visible

### 2.4 Controls Test
- [ ] Arrow keys move character (or numpad if available)
- [ ] `i` opens inventory
- [ ] `?` opens help
- [ ] Movement feels responsive

### 2.5 Save & Quit
- [ ] Press `Q` or `ESC` to quit
- [ ] Game prompts to save
- [ ] Quit completes without error

---

## Part 3: Graphical Mode (X11)

### 3.1 Launch Test
Run: `./run-necromancer.sh -x` or `./necromancer -mx11`

- [ ] Separate game window opens
- [ ] Window has proper title
- [ ] Main menu is visible

### 3.2 Visual Test
- [ ] Graphics render correctly
- [ ] Text is readable
- [ ] Colors look good
- [ ] Window can be resized

### 3.3 Basic Gameplay
- [ ] Can create and play a character
- [ ] Keyboard input works
- [ ] Game is playable

### 3.4 Window Management
- [ ] Can minimize window
- [ ] Can restore window
- [ ] Can close window (X button)
- [ ] Closing window doesn't crash system

---

## Part 4: Auto-Detection

### 4.1 Test Automatic Mode
Run just: `./run-necromancer.sh` (no flags)

- [ ] Launcher detects display mode automatically
- [ ] Shows message about which mode it's using
- [ ] Game starts in appropriate mode (X11 if in desktop, terminal if SSH)

---

## Part 5: Save System

### 5.1 Save Test
1. Start new game, create character
2. Play for a minute (move around, explore)
3. Save and quit

- [ ] Save completed without errors

### 5.2 Load Test
1. Start game again
2. Look for "Continue" or saved character

- [ ] Saved character appears
- [ ] Can load and continue playing
- [ ] Character is where you left them

### 5.3 Find Save Location
Run: `ls ~/Documents/Sil/` or `ls ~/.angband/`

- [ ] Save files exist in one of these locations
- [ ] Location: _________________________

---

## Part 6: Stress Tests (Optional)

### 6.1 Long Session
Play for 15+ minutes:
- [ ] No crashes
- [ ] No memory issues (game doesn't slow down)
- [ ] Performance stays consistent

### 6.2 Multiple Sessions
- [ ] Can quit and restart multiple times
- [ ] Saves persist between sessions
- [ ] No leftover processes after quitting

---

## Issues Found

**Please describe any problems here:**

### Issue 1
- What happened: _________________________________
- What you expected: _________________________________
- Steps to reproduce: _________________________________

### Issue 2
- What happened: _________________________________
- What you expected: _________________________________
- Steps to reproduce: _________________________________

### Issue 3
- What happened: _________________________________
- What you expected: _________________________________
- Steps to reproduce: _________________________________

---

## Overall Verdict

- [ ] **PASS** - Game works well, ready for regular play
- [ ] **PASS WITH ISSUES** - Playable but has some problems (list above)
- [ ] **FAIL** - Major issues prevent playing

**Additional Comments:**
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________

---

**Thank you for testing!**

Send this completed checklist back with your results.
