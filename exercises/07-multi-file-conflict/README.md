# Exercise 07: Multi-File Conflict

## Concept

Real-world conflicts often span multiple files. When two branches implement different architectural approaches, the changes touch many files. Resolving these conflicts requires making consistent choices across all files -- you cannot pick "ours" in one file and "theirs" in another if they use incompatible interfaces.

## Scenario

Two branches implemented different configuration strategies:

- **`feature/env-config`** (current / ours): Reads configuration from environment variables (`TASKMANAGER_*`), adds a `Debug` mode and `Port` field. `NewTask` and `Validate` accept a `debug bool` parameter.
- **`feature/yaml-config`** (incoming / theirs): Parses a YAML-like config file, adds `LogLevel` and `LogFile` fields. `NewTask` accepts `defaultPriority int` and `Validate` accepts `maxID int`.

Three files have conflicts:
1. **`config/config.go`** -- entirely different `LoadConfig` implementations and Config struct fields
2. **`task/task.go`** -- different function signatures for `NewTask` and `Validate`, different `String()` formatting
3. **`main.go`** -- different config loading patterns and different arguments passed to task functions

## What the Conflict Looks Like

Each file has one or more conflict hunks. The key challenge is consistency: whatever you choose in `config/config.go` must match what `main.go` expects, which must match the `task/task.go` function signatures.

## Understanding "Ours" vs "Theirs"

This is a **merge**, so:
- **Ours (HEAD)** = `feature/env-config` -- environment variable configuration
- **Theirs** = `feature/yaml-config` -- YAML file configuration

## Shortcuts Used in This Exercise

| Key | Where | What It Does |
|-----|-------|-------------|
| `2` | Anywhere | Switch to the Files panel |
| `j` / `k` | Any list | Move cursor down / up (or use arrow keys) |
| `<enter>` | Files panel (on a conflicted file) | Open the conflict resolution view |
| `<up>` / `<down>` | Conflict view | Move between "ours" and "theirs" sections |
| `<space>` | Conflict view | Pick the currently highlighted section |
| `[` / `]` | Conflict view | Jump to previous / next conflict hunk |
| `e` | Files panel or conflict view | Open the file in your external editor (`$EDITOR`) |
| `<escape>` | Conflict view | Exit back to the Files panel |
| `<space>` | Files panel | Stage / unstage the selected file |
| `c` | Files panel | Open commit message editor |
| `q` | Anywhere | Quit LazyGit |

## Resolution Flow

```
  lazygit → `2` (Files) → Plan resolution strategy first!
       │
       ▼
  File 1: config/config.go ── `j`/`k` → `e` or `<enter>` → resolve
       │
       ▼
  `<space>` (stage file 1)
       │
       ▼
  File 2: task/task.go ─────── `j`/`k` → `e` or `<enter>` → resolve
       │                        (must be consistent with file 1!)
       ▼
  `<space>` (stage file 2)
       │
       ▼
  File 3: main.go ─────────── `j`/`k` → `e` or `<enter>` → resolve
       │                        (must be consistent with files 1 & 2!)
       ▼
  `<space>` (stage file 3) → `c` (commit) → Done ✓
```

## Step-by-Step Instructions (LazyGit)

1. **Open LazyGit**:
   ```bash
   cd workspace/exercise-07
   lazygit
   ```

2. **Switch to the Files panel** by pressing `2`. You should see multiple files with `UU` markers (likely `config/config.go`, `task/task.go`, and `main.go`).

3. **Plan your resolution before editing.** Scroll through the file list by pressing `j`/`k` to see all conflicted files. Decide: do you want the env-var approach (ours), the YAML approach (theirs), or a combination? For your first attempt, pick one side consistently across all files.

4. **Resolve each file in order** (start with the "primary" file that defines the design decision):

   **File 1: `config/config.go`**
   - Press `j`/`k` to move the cursor to `config/config.go`
   - Press `<enter>` to open the conflict resolution view
   - For each conflict hunk: press `<up>` to highlight "ours" (env-var config) or `<down>` to highlight "theirs" (YAML config), then press `<space>` to pick it
   - Press `]` to move to the next hunk, repeat until all hunks are resolved
   - Press `<escape>` to return to the Files panel
   - Note which fields exist in the `Config` struct (e.g., `Debug` for env-config, `LogLevel` for yaml-config) -- you will need consistency in the other files
   - Alternatively, press `e` instead of `<enter>` to resolve in your editor if you want to combine both approaches

   **File 2: `task/task.go`**
   - Press `j`/`k` to move the cursor to `task/task.go`
   - Press `<enter>` to open the conflict resolution view
   - Resolve each hunk the same way: press `<up>` or `<down>` to select a side, press `<space>` to pick it, press `]` for the next hunk
   - The function signatures must match what `main.go` will call:
     - If you chose env-config: `NewTask(id, title, debug)` and `Validate(debug)`
     - If you chose yaml-config: `NewTask(id, title, defaultPriority)` and `Validate(maxID)`
   - Press `<escape>` to return to the Files panel

   **File 3: `main.go`**
   - Press `j`/`k` to move the cursor to `main.go`
   - Press `<enter>` to open the conflict resolution view
   - Resolve each hunk consistently with your previous choices:
     - If env-config: pick the side that calls `LoadConfig("")` and passes `cfg.Debug`
     - If yaml-config: pick the side that calls `LoadConfig("config.yaml")` and passes `cfg.DefaultPri` and `cfg.MaxTasks`
   - Press `<escape>` to return to the Files panel

5. **Stage each resolved file:** For each file in the Files panel, press `j`/`k` to highlight it, then press `<space>` to stage it. Repeat for every resolved file.

6. **Once all files are staged and no conflicts remain**, press `c` to create the merge commit. Accept the pre-filled merge message by pressing `<enter>`, or type a custom message and then press `<enter>`.

### If Something Goes Wrong

- **Undo the last action:** Press `z` to undo the most recent git action LazyGit performed.
- **See available keybindings:** Press `?` at any time to see all keybindings for the current panel.
- **Abort the merge:** Press `m` to open the merge/rebase options popup, then press `j`/`k` to highlight `abort`, then press `<enter>` to confirm. This resets to the state before the merge started.
- **Quit LazyGit:** Press `q` to exit.
- **Start completely over:** Quit LazyGit, then re-run the exercise setup script to reset the workspace.

## Verification

```bash
# No conflict markers in any file
grep -rn '<<<<<<' config/ task/ main.go  # Should find nothing

# Build should succeed -- this confirms all function signatures match
go build ./...

# Check all three files were modified in the merge commit
git log --oneline -1
git diff-tree --no-commit-id --name-only -r HEAD
```

## Deep Dive: Cross-File Consistency in Conflict Resolution

Multi-file conflicts are where conflict resolution becomes a design decision, not just a text-editing task. The challenge is **consistency**.

**Why consistency matters:**

In a Go project, if `config/config.go` defines a `Config` struct with a `Debug` field, and `main.go` references `cfg.Debug`, but you resolved the config conflict by picking the YAML version (which has `LogLevel` instead), then `main.go` will not compile.

**Strategy for multi-file conflicts:**

1. **Survey all conflicted files first.** In LazyGit, scroll through the Files panel and note which files conflict. Do not start resolving immediately.

2. **Identify the "primary" file.** Usually there is one file where the core design decision is made (here, `config/config.go`). Resolve that first.

3. **Let the primary decision guide the rest.** Once you decide on env-vars vs YAML, the other files' resolutions follow logically.

4. **Build after each file** if possible. Running `go build ./...` after resolving each file helps catch inconsistencies early. You can do this from LazyGit by pressing `:` to open a command prompt (if your LazyGit version supports it) or from another terminal.

5. **Consider resolving in dependency order.** Resolve packages that others depend on first (e.g., `config/` before `main.go`), then resolve dependents.

**In LazyGit:** You can see all conflicted files in the Files panel. The number of conflicted files is shown in the panel header. Work through them one by one, staging each as you go. LazyGit will not let you commit until all conflicts are resolved and staged.
