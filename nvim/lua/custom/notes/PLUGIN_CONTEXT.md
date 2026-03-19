# Notes Plugin for Neovim

## Project Context

This is a custom Neovim plugin for personal note-taking with bullet journaling capabilities.

### Dependencies
- **zk CLI**: Plain text note-taking assistant (https://github.com/zk-org/zk)
- **zk-nvim**: Neovim integration for zk (`zk-org/zk-nvim`)
- **Neovim**: 0.10+

### Notes Directory Structure
- **Root**: `/home/tilupe/notes/`
- **Daily notes**: `/home/tilupe/notes/daily/` (format: `YYYY-MM-DD.md`)
- **zk config**: `/home/tilupe/notes/.zk/config.toml`
- **Templates**: `/home/tilupe/notes/.zk/templates/`

### Configuration

```lua
require('custom.notes').setup({
  notebook_root = vim.env.ZK_NOTEBOOK_DIR or '/home/tilupe/notes',
  daily_dir = 'daily',
  bullet_journal_heading = '## Bullet Journal',
  bullet_journal_end = '<!-- END BULLET JOURNAL -->',
  due_date_tag = '#due:',
  overdue_warning = true,
  enable_highlighting = true,
})
```

### Daily Note Format
Daily notes use the `daily` group in zk config:
- Filename: `{{format-date now '%Y-%m-%d'}}.md`
- Template: `daily.md`

---

## Bullet Types (Signifiers)

| Marker | Type | Description | Migratable |
|--------|------|-------------|------------|
| `[ ]` | Task | Something to do | Yes |
| `[x]` | Done | Completed task | No |
| `[>]` | Migrated | Moved to future day | No |
| `[<]` | Scheduled | Moved to future log | No |
| `[o]` | Event | Something that happened | No |
| `[-]` | Note | Information to remember | No |
| `[!]` | Priority | Important/urgent task | Yes |
| `[?]` | Explore | Research/think about | Yes |

### Bullet Journal Section
```markdown
## Bullet Journal

- [ ] Regular task
- [!] Priority task
- [?] Something to explore
- [o] Meeting with team
- [-] Remember this info
<!-- END BULLET JOURNAL -->
```

---

## Commands

| Command | Description |
|---------|-------------|
| `:DailyNote` | Open/create today's note with selective migration |
| `:DailyNote!` | Open/create today's note, skip migration picker |
| `:Bullet` | Show picker to add any bullet type |
| `:BulletTask [text]` | Add task `[ ]` |
| `:BulletEvent [text]` | Add event `[o]` |
| `:BulletNote [text]` | Add note `[-]` |
| `:BulletPriority [text]` | Add priority `[!]` |
| `:BulletExplore [text]` | Add explore `[?]` |
| `:BulletToggle` | Cycle bullet state on current line |
| `:BulletCapture [type]` | Quick capture in floating window |
| `:BulletDue` | Add task with due date picker |
| `:BulletSearch [type]` | Search uncompleted bullets (all/task/priority/explore) |
| `:BulletTags` | Search by #tag |
| `:BulletOverdue` | Show overdue items |
| `:WeeklyReview` | Review uncompleted items from past 7 days |

---

## Keybindings

| Key | Action |
|-----|--------|
| `<leader>nj` | Daily note (journal) |
| `<leader>nb` | Add bullet (picker) |
| `<leader>n.` | Add task |
| `<leader>n!` | Add priority |
| `<leader>n?` | Add explore |
| `<leader>no` | Add event |
| `<leader>n-` | Add note |
| `<leader>nx` | Toggle bullet state (markdown only) |
| `<leader>nc` | Quick capture (floating window) |
| `<leader>nd` | Add task with due date |
| `<leader>ns` | Search bullets |
| `<leader>nw` | Weekly review |
| `<leader>n#` | Search tags |
| `<leader>nt` | Add todo (legacy) |

---

## Implementation Tasks

### Feature 1: DailyNote Command
**Status**: Complete

- [x] Create plugin file structure
- [x] Implement daily note creation with zk
- [x] Implement todo migration from previous day
- [x] Mark migrated todos as `[>]` in source file
- [x] Add keybinding

### Feature 2: Extended Bullet Types
**Status**: Complete

- [x] Define bullet type registry
- [x] Mark migrated todos with `[>]` instead of leaving `[ ]`
- [x] Support priority `[!]` and explore `[?]` in migration

### Feature 3: Quick Capture Commands
**Status**: Complete

- [x] Add commands for each bullet type
- [x] Add bullet picker command
- [x] Add keybindings for quick capture
- [x] Implement toggle bullet function

### Feature 4: Selective Migration
**Status**: Complete

- [x] Migration picker UI with floating window
- [x] Per-todo actions: migrate, done, skip
- [x] Bulk actions (M/D/S to set all)
- [x] `:DailyNote!` to skip picker

### Feature 5: Due Dates
**Status**: Complete

- [x] Due date tag support (`#due:YYYY-MM-DD`)
- [x] Due date picker with presets
- [x] Overdue detection
- [x] `:BulletOverdue` command

### Feature 6: Cross-Note Search
**Status**: Complete

- [x] Search bullets across all daily notes
- [x] Filter by type (task/priority/explore)
- [x] Snacks picker integration with fallback to quickfix
- [x] `:BulletSearch` command

### Feature 7: Quick Capture
**Status**: Complete

- [x] Floating window for rapid entry
- [x] Tab to cycle bullet types
- [x] `:BulletCapture` command and `<leader>nc` keybind

### Feature 8: Weekly Review
**Status**: Complete

- [x] Aggregate uncompleted items from past 7 days
- [x] Group by date
- [x] Highlight overdue items
- [x] Jump to item on Enter

### Feature 9: Tag Aggregation
**Status**: Complete

- [x] Extract #tags from notes
- [x] Tag picker with counts
- [x] Navigate to tagged items

### Feature 10: Visual Highlighting
**Status**: Complete

- [x] Syntax highlighting for bullet types
- [x] Color-coded by type (priority=red, done=dim, etc.)
- [x] Due date highlighting

### Feature 11: Configurable Setup
**Status**: Complete

- [x] `M.setup(opts)` accepts configuration overrides
- [x] All settings can be customized

### Remaining Tasks
- [ ] Test all new features
- [ ] Test Snacks picker integration

---

## File Locations

| File | Purpose |
|------|---------|
| `lua/custom/notes/daily.lua` | Daily note, bullets, migration logic |
| `lua/custom/notes/todos.lua` | Legacy todo capture functionality |
| `lua/custom/notes/init.lua` | Module exports and setup |
| `lua/plugins/zk.lua` | zk-nvim plugin configuration |
| `~/nixos/scripts/capture-note.sh` | Rofi quick note capture (uses `[-]`) |
| `~/nixos/scripts/capture-todo.sh` | Rofi todo capture (uses `[ ]`, `[!]`, `[?]`) |

---

## Testing Instructions

### Quick Capture Keys

When using `:BulletCapture` or `<leader>nc`:

| Key | Action |
|-----|--------|
| `<Tab>` | Cycle bullet type (task → priority → explore → event → note) |
| `<CR>` | Submit and add to today's note |
| `<Esc>` | Cancel |

---

### Migration Picker Keys

When creating a new daily note with uncompleted todos, a picker appears:

| Key | Action |
|-----|--------|
| `m` | Mark current todo for migration |
| `d` | Mark current todo as done |
| `s` | Skip current todo (leave as-is) |
| `M` | Set ALL todos to migrate |
| `D` | Set ALL todos to done |
| `S` | Set ALL todos to skip |
| `<CR>` | Confirm and create note |
| `q` / `<Esc>` | Cancel |

---

### Daily Note Migration
1. Add some uncompleted todos to an existing daily note:
   ```markdown
   ## Bullet Journal

   - [ ] Test task one
   - [!] Priority item
   - [x] Already done (should NOT migrate)
   <!-- END BULLET JOURNAL -->
   ```
2. Run `:DailyNote` on a new day
3. Migration picker appears:
   - Use `j/k` to navigate between todos
   - Press `m` to migrate, `d` to mark done, `s` to skip
   - Press `<CR>` to confirm
4. Verify:
   - New note is created with migrated todos only
   - Original note: migrated items marked `[>]`, done items marked `[x]`
5. Alternative: `:DailyNote!` skips picker and creates empty note

### Quick Capture
1. Run `:Bullet` or `<leader>nb` - should show picker
2. Run `:BulletTask Buy groceries` - should add to today's note
3. Run `<leader>n!` then type text - should add priority bullet

### Toggle Bullet
1. Open a daily note with bullets
2. Place cursor on a `- [ ]` line
3. Run `<leader>nx` - should cycle: `[ ]` -> `[x]` -> `[>]` -> `[ ]`

---

## Bash Scripts (Rofi Integration)

Both scripts in `~/nixos/scripts/` use rofi for quick capture from anywhere:

### capture-note.sh
- Prompts for note text
- Adds as `- [-] [HH:MM] note text` under Bullet Journal
- Creates daily note if needed

### capture-todo.sh
- Prompts for task text
- Lets you choose bullet type: `[ ]`, `[!]`, `[?]`
- Optional due date with presets (today, tomorrow, next week)
- Adds tag `#due:YYYY-MM-DD` if date selected
- Creates daily note if needed

### Usage
Bind these to global shortcuts (e.g., in Hyprland/Sway config):
```
bind = $mod, N, exec, ~/nixos/scripts/capture-note.sh
bind = $mod SHIFT, N, exec, ~/nixos/scripts/capture-todo.sh
```

---

## Future Feature Ideas

- [ ] Monthly note rollup
- [ ] Habit tracker section
- [ ] Future log with scheduled dates (`[<]` items)
- [ ] Recurring/repeating tasks
- [ ] Time tracking on completion
- [ ] Statistics dashboard
