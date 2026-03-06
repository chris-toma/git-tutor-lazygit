# Exercise 11: Cherry-Pick Conflict

## Concept

Cherry-picking applies a single commit from one branch to another. Unlike merge (which integrates entire branch histories) or rebase (which replays a sequence of commits), cherry-pick takes exactly one commit's changes and applies them in isolation.

Conflicts arise when the cherry-picked commit depends on context (prior commits) that does not exist in the target branch, or when the target branch has diverged in the same area of code.

## Scenario

The `feature/logging` branch has 4 commits that incrementally built up the logging system:

1. **Add component-based logging and request tracking** -- `Component` field, `WithComponent()`, `LogRequest`, `LogResponse` methods
2. **Add error context logging with caller info** -- `ErrorWithContext`, `Fatal` methods using `runtime.Caller`
3. **Add log filtering and level parsing** -- `Filters`, `AddFilter`, `shouldLog`, `ParseLevel`
4. **Add performance logging with metrics** -- `StartTimer`, `PrintMetrics`, `PerfMetrics`

The `hotfix/quick-logging` branch diverged from `main` and added its own error handling approach: an `ErrOut` field (separate error output stream), an `Errorf` method (formatted errors), and a `LogAndReturn` convenience method. This changed the `Logger` struct and the code area around the `Error` method.

You cherry-picked **commit 2** ("add error context logging with caller info") from `feature/logging` into `hotfix/quick-logging`. This conflicts because:
- Commit 2's diff adds `ErrorWithContext` and `Fatal` near the `Error` method, but the hotfix branch has its own additions (`Errorf`, `LogAndReturn`) in the same area
- Commit 2's diff references the `Component` field (from commit 1) which does not exist on the hotfix branch
- The `Logger` struct differs (hotfix added `ErrOut`, feature added `Component`)

## What the Conflict Looks Like

`logging/logger.go` has conflicts in the `Logger` struct area and around the `Error`/error-handling methods. The cherry-picked commit tries to add code that assumes a different version of the file than what exists on the hotfix branch.

## Understanding "Ours" vs "Theirs"

During a **cherry-pick**, the semantics are similar to a merge:
- **Ours (HEAD)** = `hotfix/quick-logging` -- the branch you are cherry-picking INTO (with `ErrOut`, `Errorf`, `LogAndReturn`)
- **Theirs** = the cherry-picked commit (commit 2 from `feature/logging`, adding `ErrorWithContext` and `Fatal`)

## Shortcuts Used in This Exercise

| Key | Where | What It Does |
|-----|-------|-------------|
| `2` | Anywhere | Switch to the Files panel |
| `3` | Anywhere | Switch to the Branches panel |
| `4` | Anywhere | Switch to the Commits panel |
| `j` / `k` | Any list | Move cursor down / up (or use arrow keys) |
| `e` | Files panel (on a file) | Open the file in your external editor (`$EDITOR`) |
| `<space>` | Files panel | Stage / unstage the selected file |
| `m` | Anywhere (during cherry-pick) | Open merge/rebase options popup |
| `q` | Anywhere | Quit LazyGit |

## Resolution Flow

```
  lazygit (cherry-pick in progress, conflict!)
       │
       ▼
  `2` (Files) → logging/logger.go has conflict
       │
       ▼
  `e` (open editor) → adapt cherry-picked code to hotfix context
       │               (cannot just pick "theirs" — context differs!)
       │               remove conflict markers → save → close
       ▼
  `<space>` (stage) → `m` → `continue`
       │
       ▼
  Cherry-pick complete ✓
```

## Step-by-Step Instructions (LazyGit)

1. **Open LazyGit**:
   ```bash
   cd workspace/exercise-11
   lazygit
   ```

2. **Switch to the Files panel** by pressing `2`. You should see `logging/logger.go` listed with a `UU` marker. The cherry-pick is already in progress and paused at the conflict.

3. **Select `logging/logger.go`** by pressing `j`/`k` to move the cursor to it (it may already be selected).

4. **Open the file in your editor** by pressing `e`. This conflict requires manual resolution because you need to adapt the cherry-picked functionality to work with the hotfix branch's code -- you cannot simply pick "theirs" because `ErrorWithContext` references a `Component` field that does not exist in the hotfix branch's `Logger` struct.

5. **Resolution approach in your editor:**

   - Keep the hotfix branch's `Logger` struct (with `ErrOut io.Writer`) -- this is in the "ours" / top section of the conflict
   - Keep the hotfix branch's `Error`, `Errorf`, and `LogAndReturn` methods
   - Add the `ErrorWithContext` method from the cherry-picked commit, but adapt it to work with the hotfix's Logger (it does not need `Component`, but the `log` method signature differs)
   - Add the `Fatal` method from the cherry-picked commit
   - Add the `"runtime"` import to the import block
   - Remove ALL conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`) -- search for `<<<<<<<` to confirm none remain

   Example adapted `ErrorWithContext`:
   ```go
   // ErrorWithContext logs an error with additional context and caller info.
   func (l *Logger) ErrorWithContext(err error, context string) {
       if err == nil {
           return
       }
       _, file, line, ok := runtime.Caller(1)
       if ok {
           l.log(ERROR, fmt.Sprintf("%s: %v (at %s:%d)", context, err, file, line))
       } else {
           l.log(ERROR, fmt.Sprintf("%s: %v", context, err))
       }
   }
   ```

6. **Save the file** and close your editor to return to LazyGit.

7. **Stage the file:** In the Files panel, make sure `logging/logger.go` is highlighted, then press `<space>` to stage it. The `UU` marker should disappear.

8. **Continue the cherry-pick:** Press `m` to open the merge/rebase options popup, then press `j`/`k` to highlight `continue`, then press `<enter>` to confirm.

9. **Verify the result:** Press `4` to switch to the Commits panel. You should see the cherry-picked commit at the top of the log.

### If Something Goes Wrong

- **Undo the last action:** Press `z` to undo the most recent git action LazyGit performed.
- **See available keybindings:** Press `?` at any time to see all keybindings for the current panel.
- **Abort the cherry-pick:** Press `m` to open the merge/rebase options popup, then press `j`/`k` to highlight `abort`, then press `<enter>` to confirm. This returns the repository to its state before the cherry-pick started.
- **Quit LazyGit:** Press `q` to exit.
- **Start completely over:** Quit LazyGit, then re-run the exercise setup script to reset the workspace.

## Verification

```bash
# Cherry-pick completed
git log --oneline -3  # Should show the cherry-picked commit on top

# Both hotfix and cherry-picked functionality exist
grep 'func.*ErrorWithContext' logging/logger.go
grep 'func.*Fatal' logging/logger.go
grep 'func.*Errorf' logging/logger.go
grep 'func.*LogAndReturn' logging/logger.go
grep 'ErrOut' logging/logger.go

# Valid Go
go build ./...
```

## Deep Dive: Cherry-Pick vs Merge vs Rebase

### Cherry-pick

```
Before:  A -- B -- C -- D (feature/logging)
               \
                E (hotfix/quick-logging)

Cherry-pick C onto hotfix:

After:   A -- B -- C -- D (feature/logging)
               \
                E -- C' (hotfix/quick-logging)
```

`C'` is a new commit with the same changes as `C`, but applied to a different base (`E` instead of `B`). The commit gets a new SHA. Cherry-pick does NOT create any relationship between the branches -- git does not know that `C'` came from `C`.

### When cherry-pick conflicts

Cherry-pick applies a commit's **diff** (the changes between the commit and its parent) to the current HEAD. This diff includes context lines for patch application. If the target branch has different code in those context areas, the patch cannot apply cleanly.

In this exercise, commit 2's diff says "after the `Error` method, add `ErrorWithContext`..." But on the hotfix branch, the code after the `Error` method is different -- it has `Errorf` and `LogAndReturn`. The diff's context does not match, causing a conflict.

### Why context matters

Each commit in git is stored as a snapshot, but when applying it as a cherry-pick, git computes the diff between the commit and its parent. This diff includes a few lines of surrounding context to help git find the right place to apply changes.

When git tries to apply this diff to a different branch, the context lines may not match. The hotfix has different code at the locations where the diff expects to insert the new methods. Git cannot confidently apply the patch, so it asks you to resolve.

### Adapting cherry-picked code

When cherry-picking across diverged branches, you often cannot use the cherry-picked code as-is. The code may reference:
- Types or fields that do not exist on the target branch
- Functions that were introduced in earlier commits on the source branch
- Different method signatures or APIs

This means your resolution is not just "pick ours or theirs" -- it is "adapt theirs to work in ours' context." This is a code integration task, not just a text merge.

### When to cherry-pick vs merge vs rebase

- **Cherry-pick**: When you want one specific commit from another branch. Common for backporting bug fixes to release branches, or grabbing a specific feature without the full branch.
- **Merge**: When you want to integrate all changes from one branch into another, preserving the relationship between branches.
- **Rebase**: When you want to replay your branch's commits on top of another branch to create linear history.

Cherry-pick is the most surgical option but also the most likely to conflict when the source and target branches have diverged significantly, because it lacks the full history context that merge and rebase have.
