# Exercise 02: Function Body Conflict

## Concept

When two branches completely rewrite the same function, you get a large multi-line conflict block. Unlike a simple one-line conflict, you need to understand what each implementation does before choosing (or combining) them.

## Scenario

The `FormatTask` function in `task/task.go` was rewritten by two branches:

- **`feature/colored-format`** (current branch / ours): Uses `strings.Builder` to construct output with ANSI color codes for terminal display. Shows `[DONE]`/`[TODO]` in color, zero-padded IDs, and exclamation marks for priority.
- **`feature/detailed-format`** (incoming / theirs): Uses `fmt.Sprintf` to produce detailed multi-line output showing title, status as `PENDING`/`COMPLETED`, and a named priority level (`Normal`, `Medium`, `High`, `Critical`).

Both branches also changed the import block (one uses `"fmt"` only, the other uses `"fmt"` and `"strings"`).

## What the Conflict Looks Like

The conflict spans a large portion of the file. You will see conflict markers wrapping:
1. The import block (one side has `"strings"`, the other does not)
2. The color constants (only present in the colored-format branch)
3. The entire `FormatTask` function body

## Understanding "Ours" vs "Theirs"

This is a **merge**, so:
- **Ours (HEAD)** = `feature/colored-format` -- the `strings.Builder` + ANSI color version
- **Theirs** = `feature/detailed-format` -- the `fmt.Sprintf` multi-line version

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
  lazygit → `2` (Files) → `j`/`k` to task/task.go → `<enter>`
       │
       ├── Pick one side: `↑`/`↓` → `<space>` → `]` next hunk → repeat
       │
       └── Manual edit: `e` (open editor) → combine both → save → close
       │
       ▼
  `<escape>` → `<space>` (stage) → `c` (commit) → Done ✓
```

## Step-by-Step Instructions (LazyGit)

1. **Open LazyGit**:
   ```bash
   cd workspace/exercise-02
   lazygit
   ```

2. **Switch to the Files panel** by pressing `2`. You should see `task/task.go` listed with a `UU` marker (meaning both branches modified it).

3. **Select `task/task.go`** by pressing `j`/`k` to move the cursor until it is highlighted.

4. **Open the conflict resolution view** by pressing `<enter>`.

5. **You will see the first conflict hunk highlighted.** There may be multiple conflict regions in this file. Press `]` to jump to the next hunk and `[` to jump to the previous hunk. Count how many there are -- you may see conflicts in:
   - The `import` block
   - The color constants section
   - The `FormatTask` function body

6. **Navigate to the first conflict hunk** by pressing `[` until you are at the top. For each conflict hunk:
   - Press `<up>` to highlight the "ours" section (top -- the `strings.Builder` + ANSI color version)
   - OR press `<down>` to highlight the "theirs" section (bottom -- the `fmt.Sprintf` detailed version)
   - Press `<space>` to pick the highlighted section
   - Press `]` to jump to the next conflict hunk
   - Repeat for every hunk

   **Recommendation:** Pick one side consistently across all hunks. The colored-format version (ours / top) is a good choice since it is the current branch's work. Alternatively, pick theirs (bottom) if you prefer the detailed output.

7. **If you want both features** (colors AND detailed output), you will need to edit manually instead. Press `e` to open the file in your external editor (`$EDITOR`). Remove all conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`), and write a combined implementation. Save and close the editor to return to LazyGit.

8. **After resolving all hunks**, press `<escape>` to return to the Files panel. The file should no longer show a `UU` marker.

9. **Stage the resolved file:** Make sure `task/task.go` is highlighted in the Files panel, then press `<space>` to stage it.

10. **Create the merge commit** by pressing `c`. LazyGit will open a commit message editor. Accept the pre-filled merge message by pressing `<enter>`, or type a custom message and then press `<enter>`.

### If Something Goes Wrong

- **Undo the last action:** Press `z` to undo the most recent git action LazyGit performed.
- **See available keybindings:** Press `?` at any time to see all keybindings for the current panel.
- **Abort the merge:** Press `m` to open the merge/rebase options popup, then press `j`/`k` to highlight `abort`, then press `<enter>` to confirm. This resets to the state before the merge started.
- **Quit LazyGit:** Press `q` to exit.
- **Start completely over:** Quit LazyGit, then re-run the exercise setup script to reset the workspace.

## Verification

```bash
# Check merge completed
git log --oneline -3

# Verify the file has no conflict markers
grep -c '<<<<<<' task/task.go  # Should output 0 or "no match"

# Verify valid Go
go build ./...
```

## Deep Dive: Multi-Line Conflict Blocks

When git detects a conflict, it tries to identify the smallest region of disagreement. But when both branches rewrote an entire function, the conflict block can span dozens of lines.

Git determines conflict boundaries by looking for unchanged "context lines" that match between the two sides. If both branches changed the function from line 15 to line 45, but lines 1-14 and 46-60 are unchanged, git marks lines 15-45 as the conflict.

In this exercise, the entire function body differs, so the conflict block is large. This is common in real codebases when two developers independently refactor the same function.

**Strategies for large conflicts:**

1. **Pick one side** if one implementation is clearly better or more complete. You can always improve it in a follow-up commit.

2. **Edit manually** when you need elements from both sides. Press `e` in LazyGit to open your editor. Remove the conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`), then write the combined version.

3. **Pick one side, then amend.** Pick one side to resolve the conflict quickly, commit, then make additional changes in a new commit. This keeps the merge commit clean.

The key insight is that resolving a conflict does not mean you must pick one side exactly as-is. The resolved version can be anything you want -- git only cares that the conflict markers are removed and the file is staged.
