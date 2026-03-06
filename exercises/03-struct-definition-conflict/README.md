# Exercise 03: Struct Definition Conflict

## Concept

Sometimes a conflict arises because two branches independently added new content to the same location in a file. Neither side is "wrong" -- you want to keep changes from both. This requires manual editing rather than simply picking one side.

## Scenario

The `Task` struct in `task/task.go` was extended by two branches:

- **`feature/task-scheduling`** (current / ours): Added `DueDate time.Time`, `Category string`, `Notes string` along with setter methods.
- **`feature/task-metadata`** (incoming / theirs): Added `Priority int`, `Tags []string`, `CreatedAt time.Time` along with related methods.

Both branches modified the struct definition, the `String()` method, and the `NewTask()` constructor. The imports also differ (one needs `"strings"`, both need `"time"`).

## What the Conflict Looks Like

Multiple conflict regions in `task/task.go`:
1. **Imports**: both sides added `"time"`, one also added `"strings"`
2. **Struct fields**: each side added different fields after the base `Done bool` field
3. **String() method**: each side formats the new fields differently
4. **NewTask() constructor**: each side initializes different fields
5. **New methods**: each branch added its own methods (these may or may not conflict depending on placement)

## Understanding "Ours" vs "Theirs"

This is a **merge**, so:
- **Ours (HEAD)** = `feature/task-scheduling` -- DueDate, Category, Notes
- **Theirs** = `feature/task-metadata` -- Priority, Tags, CreatedAt

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
   cd workspace/exercise-03
   lazygit
   ```

2. **Switch to the Files panel** by pressing `2`. You should see `task/task.go` listed with a `UU` marker.

3. **Select `task/task.go`** by pressing `j`/`k` to move the cursor until it is highlighted.

4. **Open the file in your external editor** by pressing `e`. This exercise requires manual editing because you need to combine fields from both branches -- LazyGit's pick-one-side approach will not work here, as you would lose fields from the side you did not pick. Your editor (set by `$EDITOR`) will open with the file contents including conflict markers.

5. **In your editor, resolve each conflict by keeping ALL new fields from both branches:**

   **Imports** -- find the conflict in the import block and combine to include all needed packages:
   ```go
   import (
       "fmt"
       "strings"
       "time"
   )
   ```

   **Struct** -- find the conflict in the struct definition and include all fields from both branches:
   ```go
   type Task struct {
       ID        int
       Title     string
       Done      bool
       Priority  int
       Tags      []string
       CreatedAt time.Time
       DueDate   time.Time
       Category  string
       Notes     string
   }
   ```

   **String() method** -- combine the formatting logic from both sides to display all fields.

   **NewTask() constructor** -- initialize all fields.

   **Methods** -- keep all new methods from both branches (`SetPriority`, `AddTag`, `SetDueDate`, `SetCategory`, `AddNote`).

6. **Remove ALL conflict markers** (`<<<<<<<`, `=======`, `>>>>>>>`). Search for `<<<<<<<` in your editor to make sure none remain.

7. **Save the file** and close your editor to return to LazyGit.

8. **Stage the file:** Back in the Files panel, make sure `task/task.go` is highlighted, then press `<space>` to stage it. The `UU` marker should disappear.

9. **Create the merge commit** by pressing `c`. LazyGit will open a commit message editor. Accept the pre-filled merge message by pressing `<enter>`, or type a custom message and then press `<enter>`.

### If Something Goes Wrong

- **Undo the last action:** Press `z` to undo the most recent git action LazyGit performed.
- **See available keybindings:** Press `?` at any time to see all keybindings for the current panel.
- **Abort the merge:** Press `m` to open the merge/rebase options popup, then press `j`/`k` to highlight `abort`, then press `<enter>` to confirm. This resets to the state before the merge started.
- **Quit LazyGit:** Press `q` to exit.
- **Start completely over:** Quit LazyGit, then re-run the exercise setup script to reset the workspace.

## Verification

```bash
# Check no conflict markers remain
grep -c '<<<<<<' task/task.go  # Should be 0

# Verify all fields exist
grep 'Priority' task/task.go
grep 'Tags' task/task.go
grep 'CreatedAt' task/task.go
grep 'DueDate' task/task.go
grep 'Category' task/task.go
grep 'Notes' task/task.go

# Build to verify valid Go
go build ./...

# Check merge commit exists
git log --oneline -3
```

## Deep Dive: When to Pick a Side vs Edit Manually

LazyGit's conflict view lets you pick "ours" or "theirs" for each hunk. This works well when one side is clearly correct, or when you do not need content from the other side. But there are common situations where manual editing is necessary:

1. **Additive conflicts** (like this exercise): Both sides added new content. You want all of it. Picking one side would discard the other's additions.

2. **Partial overlap**: You want some lines from ours and some from theirs within the same hunk. The hunk-level pick does not support line-level granularity.

3. **Neither side is correct**: Sometimes the right resolution is something different from both sides -- a new implementation that incorporates ideas from each.

**Workflow for manual editing in LazyGit:**
- Press `e` on a conflicted file to open it in `$EDITOR`
- Search for `<<<<<<<` to find each conflict region
- Edit the file to the desired final state
- Save and return to LazyGit
- Stage the file and continue

The `$EDITOR` environment variable determines which editor opens. Set it in your shell configuration (e.g., `export EDITOR=vim` or `export EDITOR="code --wait"`).

Remember: git does not care how you resolve a conflict. It only requires that the conflict markers are removed and the file is staged. Your resolution can be completely different from either side.
