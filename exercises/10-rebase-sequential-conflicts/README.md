# Exercise 10: Rebase with Sequential Conflicts

## Concept

When rebasing a branch with multiple commits, each commit is replayed individually. If several commits touch the same area that was also changed on the target branch, you may encounter a conflict at **every single commit replay**. Each resolution affects the context for the next replay, creating a chain of dependent conflict resolutions.

## Scenario

The `main` branch has evolved: the `Task` struct now includes `UpdatedAt time.Time`, methods update timestamps, `String()` shows more detail, and `TaskList` has a `Summary()` method.

Your `feature/task-operations` branch has 3 commits, each adding methods to `TaskList`:

1. **Commit 1**: Adds `Remove` method
2. **Commit 2**: Adds `FindByID`, `Update`, and `Rename` methods
3. **Commit 3**: Adds `Filter`, `Search`, and `Pending` methods

All three commits modify `task/task.go`, and each was written against the OLD version of the file (before timestamps were added). The rebase will conflict at each step because each commit's diff expects the old struct and method signatures.

## What the Conflict Looks Like

The rebase has already been started and is paused at the first conflict (commit 1 being replayed). After you resolve and continue, you will hit a second conflict (commit 2), and then a third (commit 3).

Each conflict gets progressively more complex because:
- The resolved state from the previous step becomes the new "ours" base
- The next commit's diff was created against an even older version
- You are essentially performing three mini-merges in sequence

## Understanding "Ours" vs "Theirs"

During each rebase step:
- **Ours** = the current HEAD at that step (initially `main`, then `main + your resolved commit 1`, then `main + your resolved commits 1 + 2`)
- **Theirs** = the feature branch commit currently being replayed

## Shortcuts Used in This Exercise

| Key | Where | What It Does |
|-----|-------|-------------|
| `2` | Anywhere | Switch to the Files panel |
| `4` | Anywhere | Switch to the Commits panel |
| `j` / `k` | Any list | Move cursor down / up (or use arrow keys) |
| `e` | Files panel (on a file) | Open the file in your external editor (`$EDITOR`) |
| `<space>` | Files panel | Stage / unstage the selected file |
| `m` | Anywhere (during rebase) | Open merge/rebase options popup |
| `q` | Anywhere | Quit LazyGit |

## Resolution Flow

```
  lazygit (rebase in progress, conflict 1/3!)
       │
       ▼
  ┌─ Round 1: commit 1 being replayed ─┐
  │                                     │
  │  `2` → `e` (edit task/task.go)      │
  │  Combine main + your commit 1       │
  │  Stage → `m` → continue             │
  └─────────────────────────────────────┘
       │
       ▼
  ┌─ Round 2: commit 2 being replayed ─┐
  │                                     │
  │  New conflict! (based on Round 1)   │
  │  `2` → `e` (edit task/task.go)      │
  │  Add commit 2's methods             │
  │  Stage → `m` → continue             │
  └─────────────────────────────────────┘
       │
       ▼
  ┌─ Round 3: commit 3 being replayed ─┐
  │                                     │
  │  New conflict! (based on Round 2)   │
  │  `2` → `e` (edit task/task.go)      │
  │  Add commit 3's methods             │
  │  Stage → `m` → continue             │
  └─────────────────────────────────────┘
       │
       ▼
  Rebase complete ✓
```

## Step-by-Step Instructions (LazyGit)

### Round 1: Replaying Commit 1 (Remove method)

1. **Open LazyGit**:
   ```bash
   cd workspace/exercise-10
   lazygit
   ```

2. **Switch to the Files panel** by pressing `2`. You should see `task/task.go` with a `UU` marker. The rebase is already in progress and paused at the first conflict.

3. **Select `task/task.go`** by pressing `j`/`k` to move the cursor to it (it may already be selected).

4. **Open the file in your editor** by pressing `e`. You need to combine:
   - Main's changes: `UpdatedAt` field, timestamp updates in methods, new `String()` format, `Summary()` method
   - Your commit 1: the `Remove` method

5. **Resolve in your editor:** Keep main's updated struct and methods, and add the `Remove` method. Make sure `Remove` works with the updated struct (it should, since it only uses `ID`). Remove all conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`). Save the file and close your editor to return to LazyGit.

6. **Stage the file:** In the Files panel, make sure `task/task.go` is highlighted, then press `<space>` to stage it.

7. **Continue the rebase:** Press `m` to open the merge/rebase options popup, then press `j`/`k` to highlight `continue`, then press `<enter>` to confirm.

### Round 2: Replaying Commit 2 (FindByID, Update, Rename)

8. **A new conflict appears.** Press `2` to make sure you are in the Files panel. You should see `task/task.go` with a `UU` marker again. The file now has your resolved version from Round 1 as "ours," and commit 2's diff as "theirs."

9. **Select `task/task.go`** by pressing `j`/`k` to move the cursor to it.

10. **Open the file in your editor** by pressing `e`. Add the `FindByID`, `Update`, and `Rename` methods while keeping everything from Round 1 (main's changes + the `Remove` method). Remove all conflict markers. Save and close.

11. **Stage the file** by pressing `<space>` on `task/task.go` in the Files panel.

12. **Continue the rebase** by pressing `m`, then `j`/`k` to highlight `continue`, then `<enter>`.

### Round 3: Replaying Commit 3 (Filter, Search, Pending)

13. **Another conflict appears.** Press `2` to go to the Files panel. "Ours" now includes everything from Rounds 1 and 2.

14. **Select `task/task.go`** by pressing `j`/`k` to move the cursor to it.

15. **Open the file in your editor** by pressing `e`. Add `Filter`, `Search`, and `Pending` methods. Make sure to include the `"strings"` import needed for `Search`. Remove all conflict markers. Save and close.

16. **Stage the file** by pressing `<space>` on `task/task.go` in the Files panel.

17. **Continue the rebase** by pressing `m`, then `j`/`k` to highlight `continue`, then `<enter>`.

18. **The rebase should now complete.** Press `4` to switch to the Commits panel and verify all three commits were replayed on top of main's commits (your three commits should be at the top of the list).

### If Something Goes Wrong

- **Undo the last action:** Press `z` to undo the most recent git action LazyGit performed.
- **See available keybindings:** Press `?` at any time to see all keybindings for the current panel.
- **Abort the rebase:** Press `m` to open the merge/rebase options popup, then press `j`/`k` to highlight `abort`, then press `<enter>` to confirm. This returns the repository to its state before the rebase started. Note: this undoes ALL rounds of resolution, not just the current one.
- **Quit LazyGit:** Press `q` to exit.
- **Start completely over:** Quit LazyGit, then re-run the exercise setup script to reset the workspace. This is often the safest option if you made a mistake in an early round, since errors propagate through subsequent rounds.

## Verification

```bash
# Rebase completed
test ! -d .git/rebase-merge && echo "Rebase complete"

# All commits should be present
git log --oneline  # Should show 5 commits (initial + main's + 3 rebased)

# All methods should exist
grep 'func.*Remove' task/task.go
grep 'func.*FindByID' task/task.go
grep 'func.*Update' task/task.go
grep 'func.*Filter' task/task.go
grep 'func.*Search' task/task.go
grep 'func.*Pending' task/task.go
grep 'func.*Summary' task/task.go

# Timestamps should be present
grep 'UpdatedAt' task/task.go

# Valid Go
go build ./...
```

## Deep Dive: Why the Same Conflict Repeats

### The cascading effect

Imagine the rebase as three operations in sequence:

```
Step 1: main's HEAD + patch(commit 1) = CONFLICT -> resolve -> new-commit-1
Step 2: new-commit-1  + patch(commit 2) = CONFLICT -> resolve -> new-commit-2
Step 3: new-commit-2  + patch(commit 3) = CONFLICT -> resolve -> new-commit-3
```

At each step, the "patch" was created against the OLD branch state, not the current HEAD. The patch says something like "at line 40, after the text '// Count returns...', add these lines." But line 40 now has different content because main's changes shifted things around. So git flags a conflict.

### How your resolutions propagate

After you resolve Step 1, the result becomes the base for Step 2. Your resolution created a new version of the file that includes BOTH main's changes and your Remove method. Commit 2's patch was not written against this combined version, so it conflicts again.

This is why it is critical to resolve each step correctly. A mistake in Round 1 will propagate through Rounds 2 and 3, potentially making each subsequent conflict harder.

### Strategies for sequential rebase conflicts

1. **Be meticulous in early rounds.** Get Round 1 exactly right, because Rounds 2 and 3 build on it.

2. **Keep a mental model** of what the file should look like after each step. Before resolving, think: "After this round, the file should have main's changes plus commits 1 through N."

3. **Use the editor**, not the hunk picker. Multi-round rebases almost always require manual editing because you need to carefully combine code from different contexts.

4. **If it goes wrong, abort.** Press `m` in LazyGit and select "abort rebase." Re-run the setup script and try again. There is no shame in resetting -- even experienced developers abort and retry.

5. **Consider squashing first.** If your feature branch has many small commits that touch the same code, squashing them into fewer commits BEFORE rebasing reduces the number of conflict rounds. (This is what Exercise 09 practiced.)
