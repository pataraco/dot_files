# Project Tasks

This file tracks planned improvements and fixes for the dot_files project. Mark items as complete by changing `[ ]` to `[x]`.

---

## Code Quality

### [ ] Fix ShellCheck Warnings (GitHub Issue #7)

**Description:** Clean up 19 shellcheck warnings across 8 bash configuration files.

**GitHub Issue:** [#7 - Fix shellcheck warnings across all bash files](https://github.com/pataraco/dot_files/issues/7)

**Files to fix:**
- `.bash_aliases` (5 warnings)
- `.bash_aliases_aws` (6 warnings)
- `.bash_aliases_ag` (2 warnings)
- `.bash_aliases_chef` (1 warning)
- `.bash_aliases_r5s` (2 warnings)
- `.bash_aliases_innovyze` (1 warning)
- `.bash_profile` (1 warning)
- `.git-hooks/pre-commit` (1 warning)

**Common issues:**
- Quoting variables to prevent word splitting
- Using `${var//search/replace}` instead of sed
- Avoiding iteration over `ls` output
- Proper array handling

**Testing:**
```bash
shellcheck .bash_aliases .bash_aliases_* .bash_logout .bash_profile .bashrc setup.sh .git-hooks/pre-commit
```

**Reference:** See GitHub issue #7 for detailed checklist of each warning

---

### [ ] Rename bash_aliases_innovyze to bash_aliases_autodesk

**Description:** Rename company-specific bash aliases file from Innovyze to Autodesk and update all references. Move costfplan alias from chef file to autodesk file.

**Changes required:**

1. **Rename the file:**
   ```bash
   mv .bash_aliases_innovyze .bash_aliases_autodesk
   ```

2. **Update .bash_profile (line 37):**
   ```bash
   # Change from:
   export COMPANY="innovyze"
   # To:
   export COMPANY="autodesk"
   ```
   This automatically updates `COMPANY_SHIT` to point to the new file.

3. **Update file header comment:**
   - In `.bash_aliases_autodesk` line 3, change `innovyze` to `autodesk`

4. **Update repo paths in aliases:**
   - Lines 242-244: Change `innovyze/devops-tools` to `autodesk/aec-water/wlc-devops-tools`

5. **Move costfplan alias:**
   - Remove from `.bash_aliases_chef` (line 1024)
   - Add to `.bash_aliases_autodesk`:
     ```bash
     alias costfplan="~/repos/autodesk/aec-water/wlc-devops-tools/scripts/cloudos-terraform-plan.sh"
     ```

6. **Update this TASKS.md:**
   - Change shellcheck reference from `.bash_aliases_innovyze` to `.bash_aliases_autodesk`

**Testing:**
```bash
# Reload bash profile
source ~/.bash_profile

# Verify COMPANY_SHIT points to new file
echo $COMPANY_SHIT  # Should output: /Users/racop/.bash_aliases_autodesk

# Reload aliases
source ~/.bash_aliases

# Test costfplan alias
type costfplan
```

---

## Tmux Configuration Improvements

### High Priority - Core Improvements

### [ ] 1. Add Session Persistence Plugins
**Description:** Install and configure tmux-resurrect and tmux-continuum for automatic session saving/restoration.

**Add to .tmux.conf:**
```tmux
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'
set -g @continuum-restore 'on'
set -g @resurrect-capture-pane-contents 'on'
set -g @resurrect-strategy-vim 'session'
```

**After adding:** Run `prefix + I` (Ctrl-a then Shift-I) to install plugins

---

### [ ] 2. Enhance Copy Mode with Better Vi-Mode Bindings
**Description:** Add modern vi-style copy mode bindings for more intuitive text selection and copying.

**Add to .tmux.conf:**
```tmux
# Better copy mode bindings
bind-key -T copy-mode-vi 'v' send -X begin-selection
bind-key -T copy-mode-vi 'y' send -X copy-pipe-and-cancel "reattach-to-user-namespace pbcopy"
bind-key -T copy-mode-vi MouseDragEnd1Pane send -X copy-pipe-and-cancel "reattach-to-user-namespace pbcopy"
bind-key -T copy-mode-vi 'C-v' send -X rectangle-toggle
bind-key -T copy-mode-vi Escape send -X cancel
```

**Usage:** Enter copy mode (prefix + [), press 'v' to select, 'y' to copy

---

### [ ] 3. Add Smart Window Management Settings
**Description:** Configure automatic window renumbering and better pane number display.

**Add to .tmux.conf:**
```tmux
# Auto-renumber when windows are closed
set -g renumber-windows on

# Show pane numbers longer (3 seconds)
set -g display-panes-time 3000

# More responsive scrolling
bind -T copy-mode-vi WheelUpPane send -N3 -X scroll-up
bind -T copy-mode-vi WheelDownPane send -N3 -X scroll-down
```

---

### [ ] 4. Add Synchronize Panes Toggle
**Description:** Add ability to toggle typing in all panes simultaneously (useful for multi-server work).

**Add to .tmux.conf:**
```tmux
# Toggle synchronize panes
bind S setw synchronize-panes \; display-message "Sync panes: #{?synchronize-panes,ON,OFF}"
```

**Usage:** `prefix + Shift-S` to toggle sync mode on/off

---

### [ ] 5. Improve True Color and Terminal Support
**Description:** Update terminal settings for better RGB/true color support and vim integration.

**Replace existing terminal settings (lines 80-83) with:**
```tmux
set -g default-terminal "tmux-256color"
set -ga terminal-overrides ",*256col*:Tc"
set -ga terminal-overrides ",xterm-256color:RGB"
set -as terminal-features ",xterm-256color:RGB"
set -g focus-events on  # Critical for vim/neovim
setw -g aggressive-resize on  # Better multi-monitor support
```

---

### Optional Enhancements - Plugins

### [ ] 6. Add tmux-fzf Plugin for Fuzzy Finding
**Description:** Install tmux-fzf plugin for fuzzy finding sessions, windows, and panes.

**Prerequisites:**
```bash
brew install fzf
```

**Add to .tmux.conf (in plugins section):**
```tmux
set -g @plugin 'sainnhe/tmux-fzf'
set -g @tmux-fzf-launch-key 'C-f'
```

**After adding:** Run `prefix + I` to install
**Usage:** `Ctrl-a` then `Ctrl-f` to open fuzzy finder

---

### [ ] 7. Add System Monitoring to Status Bar
**Description:** Add CPU and battery monitoring plugins to enhance status bar.

**Add to .tmux.conf (in plugins section):**
```tmux
set -g @plugin 'tmux-plugins/tmux-cpu'
set -g @plugin 'tmux-plugins/tmux-battery'
```

**Update status-right (line 175) to include:**
```tmux
set -g status-right '#[bg=#191970]#[fg=#FFD700]CPU:#{cpu_percentage} #[fg=#FF69B4]#{battery_percentage} #[fg=#00BFFF]#(uptime|sed s/averages:/@/|cut -d'@' -f2) #[fg=#00FF00]%d-%b-%Y #[fg=#7CFC00]%H:%M #[fg=#ADFF2F][#{version}]#[default]'
```

**After adding:** Run `prefix + I` to install plugins

---

### [ ] 8. Add Quality of Life Keybindings
**Description:** Add convenient keybindings for common operations.

**Add to .tmux.conf:**
```tmux
# Kill pane without confirmation
bind x kill-pane

# Break pane to new window
bind b break-pane -d

# Join pane from another window
bind j command-prompt -p "Join pane from window: " "join-pane -h -s '%%'"

# Clear screen and history
bind C-l send-keys C-l \; clear-history
```

**Update existing split bindings to open in current directory (modify lines 45-47):**
```tmux
bind | split-window -h -c "#{pane_current_path}"
bind \\ split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
```

**Update new window binding (line 36) to open in current directory:**
```tmux
bind c new-window -c "#{pane_current_path}" \; command-prompt -p "new window name?" "rename-window '%%'" \; split-window -h \; split-window -h \; split-window -h \; select-layout main-horizontal
```

---

### [ ] 9. Add tmux-fingers Plugin for Fast Text Copying
**Description:** Install tmux-fingers for lightning-fast text copying (alternative to mouse selection).

**Add to .tmux.conf (in plugins section):**
```tmux
set -g @plugin 'Morantron/tmux-fingers'
set -g @fingers-key F
```

**After adding:** Run `prefix + I` to install
**Usage:** `prefix + F` to activate fingers mode, then type the letter hint to copy text

---

### [ ] 10. Add Status Bar Indicators for Prefix and Sync Mode
**Description:** Enhance status bar to show visual indicators when prefix is pressed or panes are synchronized.

**Update status-right (line 175) to prepend these indicators:**
```tmux
set -g status-right '#{?client_prefix,#[reverse]<Prefix>#[noreverse] ,}#{?pane_synchronized,#[bg=red]SYNC#[default] ,}#[bg=#191970]#[fg=#FFD700]CPU:#{cpu_percentage} #[fg=#FF69B4]#{battery_percentage} #[fg=#00BFFF]#(uptime|sed s/averages:/@/|cut -d'@' -f2) #[fg=#00FF00]%d-%b-%Y #[fg=#7CFC00]%H:%M #[fg=#ADFF2F][#{version}]#[default]'
```

**Benefit:** Provides visual feedback for prefix key press and sync mode status

---

### [ ] 11. Add tmux-logging Plugin for Session Logging
**Description:** Install tmux-logging plugin to save pane output to files (useful for debugging and record-keeping).

**Add to .tmux.conf (in plugins section):**
```tmux
set -g @plugin 'tmux-plugins/tmux-logging'
```

**After adding:** Run `prefix + I` to install

**Usage:**
- `prefix + Shift-P`: Start/stop logging current pane
- `prefix + Alt-P`: Capture visible pane content
- `prefix + Alt-Shift-P`: Save complete pane history to file

**Note:** Logs are saved to `~/tmux-[timestamp].log`

---

### Final Step

### [ ] 12. Test and Validate All Improvements
**Description:** After implementing improvements, test the updated configuration.

**Testing steps:**
1. Reload tmux config: `prefix + r` (Ctrl-a then r)
2. Verify TPM installed all plugins: check `~/.tmux/plugins/` directory
3. Test key bindings: splits, navigation, copy mode, sync toggle
4. Test plugins: fzf (Ctrl-f), fingers (prefix + F), logging (prefix + Shift-P)
5. Verify status bar shows: CPU, battery, uptime, date/time
6. Test session persistence: exit tmux, restart, verify sessions restored
7. Check colors and rendering in different terminal emulators

**If any issues:** Check tmux server messages with `tmux show-messages`

---

### Quick Reference

**Recommended Order:**
1. Complete items 1-5 first (core improvements)
2. Add items 6-11 based on your preferences (optional enhancements)
3. Run item 12 after each batch of changes

**Install plugins after adding them:**
```bash
# Inside tmux, press: Ctrl-a then Shift-I
# Or reload config: Ctrl-a then r
```

**Useful Commands:**
- `prefix + r` - Reload config
- `prefix + I` - Install new plugins
- `prefix + U` - Update plugins
- `tmux show-messages` - Debug issues
