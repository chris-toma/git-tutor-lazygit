# Exercise 08: Simple Rebase Conflict

## Concept

Rebasing replays your commits on top of another branch, one at a time. If any replayed commit conflicts with the target branch, you must resolve the conflict before the rebase can continue. This is fundamentally different from a merge conflict because:

1. You may need to resolve conflicts multiple times (once per replayed commit).
2. **"Ours" and "theirs" are swapped** compared to a merge.

## Scenario

You are on the `feature/filter-tasks` branch, which branched off `main` before a search feature was added. Now you want to rebase your branch onto the updated `main`.

- **`main`** has a new commit that added `Search`, `FindCompleted`, and `FindPending` functions to `task/search.go`, and updated `main.go` with a `search` command.
- **`feature/filter-tasks`** added `FilterByTitle`, `FilterByPriority`, and `FilterDone` functions to `task/search.go`, and updated `main.go` with a `filter` command.

Both branches modified `task/search.go` and `main.go`, creating conflicts when the feature commit is replayed on top of main.

## What the Conflict Looks Like

The rebase has been started and paused at the first (and only) commit being replayed. You will see conflicts in:

1. **`task/search.go`**: Both branches added new functions to this file, and both added `"strings"` to the import.
2. **`main.go`**: Both branches added different switch cases and a different third sample task.

## Understanding "Ours" vs "Theirs" -- THIS IS CRITICAL

During a **rebase**, the labels are **swapped** from what you might expect:

- **"Ours" / HEAD** = `main` (the branch you are rebasing **onto**). This contains the search functionality.
- **"Theirs"** = `feature/filter-tasks` (YOUR branch -- the commit being replayed). This contains the filter functionality.

**Why is it swapped?** During rebase, git first checks out the target branch (`main`), making it the current branch (HEAD / "ours"). Then it replays your commits on top. So at the moment of conflict, git's HEAD is on the target branch, and your commit is the "incoming" change ("theirs").

This is the **#1 source of confusion** with rebase conflicts. Many people accidentally discard their own work by picking "ours" thinking it means "my changes."

## Shortcuts Used in This Exercise

| Key | Where | What It Does |
|-----|-------|-------------|
| `2` | Anywhere | Switch to the Files panel |
| `4` | Anywhere | Switch to the Commits panel |
| `j` / `k` | Any list | Move cursor down / up (or use arrow keys) |
| `<enter>` | Files panel (on a conflicted file) | Open the conflict resolution view |
| `<up>` / `<down>` | Conflict view | Move between "ours" and "theirs" sections |
| `<space>` | Conflict view | Pick the currently highlighted section |
| `[` / `]` | Conflict view | Jump to previous / next conflict hunk |
| `e` | Files panel or conflict view | Open the file in your external editor (`$EDITOR`) |
| `<escape>` | Conflict view | Exit back to the Files panel |
| `<space>` | Files panel | Stage / unstage the selected file |
| `m` | Anywhere (during rebase) | Open merge/rebase options popup |
| `q` | Anywhere | Quit LazyGit |

## Step-by-Step Instructions (LazyGit)

1. **Open LazyGit**:
   ```bash
   cd workspace/exercise-08
   lazygit
   ```

2. **Notice the rebase state.** LazyGit should show that a rebase is in progress -- look for a banner or indicator at the top of the screen, or the word "rebasing" in the Status panel. This means the rebase has already started and is paused at a conflict.

3. **Switch to the Files panel** by pressing `2`. You should see conflicted files with `UU` markers (likely `task/search.go` and `main.go`).

4. **Resolve `task/search.go` first:**
   - Press `j`/`k` to move the cursor to `task/search.go`
   - Press `e` to open the file in your external editor (manual editing is needed because you want to keep BOTH sets of functions)
   - In your editor: combine the imports (keep all `import` entries from both sides), keep the Search/FindCompleted/FindPending functions from main AND the FilterByTitle/FilterByPriority/FilterDone functions from your branch
   - Remove all conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`)
   - Save the file and close your editor to return to LazyGit

5. **Resolve `main.go`:**
   - Press `j`/`k` to move the cursor to `main.go`
   - Press `e` to open in your editor (or press `<enter>` to use the conflict view)
   - If using the conflict view: for each hunk, press `<up>` or `<down>` to select a side, press `<space>` to pick it, press `]` for the next hunk
   - If editing manually: keep both the `search` and `filter` commands in the switch statement, and keep all sample tasks
   - Remove all conflict markers, save, and close to return to LazyGit

6. **Stage all resolved files:** In the Files panel, press `j`/`k` to highlight each file, then press `<space>` to stage it. Repeat for every resolved file.

7. **Continue the rebase:**
   - Press `m` to open the merge/rebase options popup
   - Press `j`/`k` to highlight `continue`
   - Press `<enter>` to confirm

8. **The rebase should complete.** Switch to the Commits panel by pressing `4` and verify that your feature commit now sits on top of main's commits (your commit should be at the top of the list).

### If Something Goes Wrong

- **Undo the last action:** Press `z` to undo the most recent git action LazyGit performed.
- **See available keybindings:** Press `?` at any time to see all keybindings for the current panel.
- **Abort the rebase:** Press `m` to open the merge/rebase options popup, then press `j`/`k` to highlight `abort`, then press `<enter>` to confirm. This returns the repository to its state before the rebase started.
- **Quit LazyGit:** Press `q` to exit.
- **Start completely over:** Quit LazyGit, then re-run the exercise setup script to reset the workspace.

## Verification

```bash
# Check that rebase completed (no .git/rebase-merge directory)
test ! -d .git/rebase-merge && echo "Rebase complete"

# Check commit log -- your commit should be on top of main's commit
git log --oneline -5

# Both search and filter functions should exist
grep 'func Search' task/search.go
grep 'func FilterByTitle' task/search.go

# Valid Go
go build ./...
```

## Deep Dive: How Rebase Works Internally

When you run `git rebase main` from a feature branch, git does the following:

1. **Identifies commits to replay.** Git finds all commits on your feature branch that are not on `main`. These are the commits that will be replayed.

2. **Checks out the target branch.** Git moves HEAD to the tip of `main`. Your working tree now looks like `main`.

3. **Replays commits one by one.** For each commit on your feature branch (oldest first):
   a. Git attempts to apply the commit's changes (as a patch) on top of the current HEAD.
   b. If the patch applies cleanly, a new commit is created with the same message but a **new SHA** (because it has a different parent).
   c. If the patch conflicts, git pauses and asks you to resolve.

4. **After resolution**, you run `git rebase --continue` (or in LazyGit, select "continue" from the rebase menu). Git creates the new commit and moves on to the next one.

5. **After all commits are replayed**, git moves your branch pointer to the new tip. Your branch now has a linear history on top of `main`.

**Key implications:**

- Rebase **rewrites history**. Your commits get new SHAs. Never rebase commits that others have based work on.
- During step 2, git is "on" the target branch. That is why "ours" = target and "theirs" = your commits.
- If you have 5 commits and only the 3rd one conflicts, git will cleanly replay commits 1 and 2, pause at 3 for your resolution, then attempt 4 and 5 (which may or may not conflict).

**ORIG_HEAD:** Before starting the rebase, git saves the current HEAD to `ORIG_HEAD`. If something goes wrong, you can abort with `git rebase --abort` to return to the original state. The reflog also contains all the information needed to recover.
