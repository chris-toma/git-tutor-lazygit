# Exercise 05: Delete vs Modify Conflict (Edit/Delete)

## Concept

An edit/delete conflict occurs when one branch modifies a piece of code while another branch deletes it entirely. Git cannot merge these changes because one side assumes the code exists (and improved it) while the other removed it completely.

This is fundamentally different from a content conflict. Git is not asking "which version of these lines?" -- it is asking "should this code exist at all?"

## Scenario

`task/store.go` was changed in incompatible ways by two branches:

- **`feature/multi-format-export`** (current / ours): Enhanced `SaveToFile` significantly -- added `FileFormat` type, support for JSON, CSV, and plain text output, format auto-detection from file extension, and several helper functions.
- **`feature/database-storage`** (incoming / theirs): Deleted `SaveToFile` entirely and replaced the whole file with `SaveToDatabase`, `LoadFromDatabase`, and `InitDatabase` functions using `database/sql`.

The entire file content diverged. One side is a complete rewrite while the other is a substantial enhancement of the original.

## What the Conflict Looks Like

In the Files panel, `task/store.go` may appear with a `UU` marker, or possibly `UD` (deleted by us) or `DU` (deleted by them) depending on the exact conflict type. The conflict will span most or all of the file because the two versions share very little code.

You may also see a conflict in `main.go` since Branch A changed it to reference database storage.

## Understanding "Ours" vs "Theirs"

This is a **merge**, so:
- **Ours (HEAD)** = `feature/multi-format-export` -- the enhanced multi-format SaveToFile
- **Theirs** = `feature/database-storage` -- the database-backed storage replacement

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

## Step-by-Step Instructions (LazyGit)

1. **Open LazyGit**:
   ```bash
   cd workspace/exercise-05
   lazygit
   ```

2. **Switch to the Files panel** by pressing `2`. Look at the conflicted files -- you should see `task/store.go` (and possibly `main.go`) with `UU` markers.

3. **Select `task/store.go`** by pressing `j`/`k` to move the cursor until it is highlighted.

4. **Decide on your resolution strategy.** You have three options:

   **Option A -- Keep ours (multi-format file export):**
   Press `<enter>` to open the conflict view. For each hunk, press `<up>` to highlight the "ours" section (top), then press `<space>` to pick it. Press `]` to move to the next hunk and repeat. After all hunks are resolved, press `<escape>` to return to the Files panel.

   **Option B -- Keep theirs (database storage):**
   Press `<enter>` to open the conflict view. For each hunk, press `<down>` to highlight the "theirs" section (bottom), then press `<space>` to pick it. Press `]` to move to the next hunk and repeat. After all hunks are resolved, press `<escape>` to return to the Files panel.

   **Option C -- Keep both (recommended for learning):**
   Press `e` to open the file in your external editor. Combine both sets of functionality into the same file.

5. **For this exercise, try Option C** to practice manual conflict resolution. After pressing `e`, in your editor:
   - Merge the import blocks (you will need `"database/sql"`, `"encoding/csv"`, `"encoding/json"`, `"fmt"`, `"os"`, `"path/filepath"`, `"strconv"`)
   - Keep the `FileFormat` type and constants from ours
   - Keep `SaveToFile` and its helpers from ours
   - Keep `SaveToDatabase`, `LoadFromDatabase`, `InitDatabase` from theirs
   - Keep `LoadFromFile` from ours
   - Remove all conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`) -- search for `<<<<<<<` to confirm none remain
   - Save the file and close your editor to return to LazyGit

6. **If `main.go` also has a conflict**, resolve it next:
   - Press `j`/`k` in the Files panel to highlight `main.go`
   - Press `<enter>` to open the conflict view (or `e` to edit manually)
   - If using the conflict view: press `<up>` or `<down>` to choose ours or theirs for each hunk, then press `<space>` to pick it. Press `]` to move between hunks. Press `<escape>` when done.

7. **Stage all resolved files:** In the Files panel, select each file with `j`/`k` and press `<space>` to stage it. Repeat for every resolved file.

8. **Create the merge commit** by pressing `c`. Accept the pre-filled merge message by pressing `<enter>`, or type a custom message and then press `<enter>`.

### If Something Goes Wrong

- **Undo the last action:** Press `z` to undo the most recent git action LazyGit performed.
- **See available keybindings:** Press `?` at any time to see all keybindings for the current panel.
- **Abort the merge:** Press `m` to open the merge/rebase options popup, then press `j`/`k` to highlight `abort`, then press `<enter>` to confirm. This resets to the state before the merge started.
- **Quit LazyGit:** Press `q` to exit.
- **Start completely over:** Quit LazyGit, then re-run the exercise setup script to reset the workspace.

## Verification

```bash
# No conflict markers
grep -rn '<<<<<<' task/ main.go  # Should find nothing

# Check that both storage approaches exist (if you chose Option C)
grep 'func SaveToFile' task/store.go
grep 'func SaveToDatabase' task/store.go

# Valid Go (note: database/sql import requires a driver to actually run,
# but it should compile)
go build ./...

# Check merge commit
git log --oneline -3
```

## Deep Dive: Edit/Delete Conflicts

Edit/delete conflicts are among the hardest to resolve because they require understanding the *intent* behind each branch's changes:

- **Why did one side delete the code?** Was it obsolete? Being replaced by something better? Moved to another file?
- **Why did the other side modify it?** Was it being improved? Was the functionality still needed?

Understanding the intent tells you what the right resolution is:

1. **Replacement scenario** (like this exercise): One branch replaced old functionality with a new approach. The other branch improved the old approach. You might want to keep the replacement AND port over the improvements from the other branch to the new code. Or you might keep both and let the user choose at runtime.

2. **Moved code**: If one branch moved a function to a different file and the other modified it, you need to apply the modifications to the function in its new location.

3. **Truly obsolete**: If the code was deleted because it is no longer needed, then the modifications are also unnecessary. Keep the deletion.

**How git represents edit/delete conflicts:**

When one side deletes a file (or a function) and the other modifies it, git may:
- Show the file with a `UD` marker (deleted by us) or `DU` (deleted by them)
- Include the entire modified version in conflict markers
- In some cases, leave the file as unmerged without markers

In LazyGit, you will see these in the Files panel. You can resolve by:
- Pressing `a` to accept the current version (keeping the file as-is from one side)
- Pressing `d` to delete the file (accepting the deletion)
- Pressing `e` to edit and create a combined version
