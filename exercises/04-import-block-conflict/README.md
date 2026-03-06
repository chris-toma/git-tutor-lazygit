# Exercise 04: Import Block Conflict

## Concept

Go import blocks are a frequent source of conflicts because they sit at the top of the file and multiple features naturally add different dependencies. When two branches add different imports, the import block conflicts even though the additions do not logically interfere with each other.

## Scenario

`utils/helpers.go` was extended by two branches:

- **`feature/sort-filter`** (current / ours): Added `"sort"` and `"strings"` imports along with `SortTasks`, `FilterTasks`, and `FilterByPriority` functions.
- **`feature/json-export`** (incoming / theirs): Added `"encoding/json"` and `"os"` imports along with `ExportJSON` and `ImportJSON` functions.

Both branches modified the import block and added new functions to the same file.

## What the Conflict Looks Like

You will see conflicts in:
1. **The import block**: Each side added different packages. The import block must be merged to include all packages from both sides.
2. **Possibly the function area**: If git cannot determine the boundary between the new functions, you may see a conflict there too.

## Understanding "Ours" vs "Theirs"

This is a **merge**, so:
- **Ours (HEAD)** = `feature/sort-filter` -- sort/strings imports, sorting and filtering functions
- **Theirs** = `feature/json-export` -- encoding/json and os imports, JSON export/import functions

## Shortcuts Used in This Exercise

| Key | Where | What It Does |
|-----|-------|-------------|
| `2` | Anywhere | Switch to the Files panel |
| `j` / `k` | Any list | Move cursor down / up (or use arrow keys) |
| `e` | Files panel (on a file) | Open the file in your external editor (`$EDITOR`) |
| `<space>` | Files panel | Stage / unstage the selected file |
| `c` | Files panel | Open commit message editor |
| `q` | Anywhere | Quit LazyGit |

## Step-by-Step Instructions (LazyGit)

1. **Open LazyGit**:
   ```bash
   cd workspace/exercise-04
   lazygit
   ```

2. **Switch to the Files panel** by pressing `2`. You should see `utils/helpers.go` listed with a `UU` marker.

3. **Select `utils/helpers.go`** by pressing `j`/`k` to move the cursor until it is highlighted.

4. **Open the file in your external editor** by pressing `e`. This conflict requires manual editing because you need imports from both branches -- picking one side would discard the other's imports and functions.

5. **Resolve the import block.** Find the conflict markers in the import block and replace the entire conflicted section with a combined import that contains ALL packages from both branches:
   ```go
   import (
       "encoding/json"
       "fmt"
       "os"
       "sort"
       "strings"

       "taskmanager/task"
   )
   ```
   Note: Go convention groups standard library imports separately from third-party/local imports with a blank line.

6. **Keep ALL functions from both branches.** If there are conflict markers around the function definitions, resolve them by keeping everything. Make sure the file contains:
   - `PrintHeader` (from base)
   - `Pluralize` (from base)
   - `SortTasks` (from ours)
   - `FilterTasks` (from ours)
   - `FilterByPriority` (from ours)
   - `ExportJSON` (from theirs)
   - `ImportJSON` (from theirs)

7. **Remove all conflict markers** (`<<<<<<<`, `=======`, `>>>>>>>`). Search for `<<<<<<<` in your editor to confirm none remain.

8. **Save the file** and close your editor to return to LazyGit.

9. **Stage the file:** Back in the Files panel, make sure `utils/helpers.go` is highlighted, then press `<space>` to stage it.

10. **Create the merge commit** by pressing `c`. Accept the pre-filled merge message by pressing `<enter>`, or type a custom message and then press `<enter>`.

### If Something Goes Wrong

- **Undo the last action:** Press `z` to undo the most recent git action LazyGit performed.
- **See available keybindings:** Press `?` at any time to see all keybindings for the current panel.
- **Abort the merge:** Press `m` to open the merge/rebase options popup, then press `j`/`k` to highlight `abort`, then press `<enter>` to confirm. This resets to the state before the merge started.
- **Quit LazyGit:** Press `q` to exit.
- **Start completely over:** Quit LazyGit, then re-run the exercise setup script to reset the workspace.

## Verification

```bash
# No conflict markers
grep -c '<<<<<<' utils/helpers.go  # Should be 0

# All imports present
grep 'encoding/json' utils/helpers.go
grep '"sort"' utils/helpers.go
grep '"strings"' utils/helpers.go
grep '"os"' utils/helpers.go

# All functions present
grep 'func SortTasks' utils/helpers.go
grep 'func FilterTasks' utils/helpers.go
grep 'func ExportJSON' utils/helpers.go
grep 'func ImportJSON' utils/helpers.go

# Valid Go
go build ./...
```

## Deep Dive: Import Block Conflicts in Go

Import blocks are one of the most common sources of merge conflicts in Go projects. This happens because:

1. **Centralized location**: All imports for a file are in one block at the top. Any new functionality that requires a new package touches this same block.

2. **Alphabetical ordering**: Go tools like `goimports` sort imports alphabetically. Two branches adding imports at different alphabetical positions still conflict because git sees the block as a whole.

3. **Grouped imports**: Go convention separates standard library imports from third-party imports with a blank line. Both branches may restructure the grouping.

**Strategies to reduce import conflicts in real projects:**

- Use `goimports` or your editor's auto-import feature. After resolving the functional code, run `goimports` to fix the import block automatically.
- Some teams configure `goimports` as a pre-commit hook, ensuring consistent formatting.

**In LazyGit**, import blocks are usually best handled by pressing `e` (edit in editor) rather than trying to pick ours/theirs, because you almost always need elements from both sides.

After manual editing, you can run `gofmt` or `goimports` from the terminal to clean up formatting before staging:

```bash
goimports -w utils/helpers.go  # if goimports is installed
# or
gofmt -w utils/helpers.go      # at minimum, format the file
```
