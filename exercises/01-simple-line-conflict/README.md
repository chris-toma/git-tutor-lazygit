# Exercise 01: Simple Line Conflict

## Concept

This is the most basic type of merge conflict: two branches both changed the same lines in the same file to different values. Git cannot decide which version to keep, so it asks you to resolve the conflict manually.

## Scenario

You are on the `feature/update-branding` branch, which changed `AppVersion` to `"2.0.0"` and `AppName` to `"TaskManager Pro"`. You are merging in `feature/update-version`, which changed `AppVersion` to `"1.5.0"` and `AppName` to `"TaskManager Plus"`.

Both branches modified the same two `const` lines in `main.go`, so git raises a conflict.

## What the Conflict Looks Like

In `main.go`, you will see something like this:

```go
<<<<<<< HEAD
const AppVersion = "2.0.0"
const AppName = "TaskManager Pro"
=======
const AppVersion = "1.5.0"
const AppName = "TaskManager Plus"
>>>>>>> feature/update-version
```

## Understanding "Ours" vs "Theirs"

In this exercise we are performing a **merge** (not a rebase), so:

- **"Ours" / HEAD** = `feature/update-branding` (the branch you are currently on). This is the top section: version `"2.0.0"`, name `"TaskManager Pro"`.
- **"Theirs"** = `feature/update-version` (the branch being merged in). This is the bottom section: version `"1.5.0"`, name `"TaskManager Plus"`.

## Shortcuts Used in This Exercise

| Key | Where | What It Does |
|-----|-------|-------------|
| `2` | Anywhere | Switch to the Files panel |
| `j` / `k` | Any list | Move cursor down / up (or use arrow keys) |
| `<enter>` | Files panel (on a conflicted file) | Open the conflict resolution view |
| `<up>` / `<down>` | Conflict view | Move between "ours" and "theirs" sections |
| `<space>` | Conflict view | Pick the currently highlighted section |
| `<escape>` | Conflict view | Exit back to the Files panel |
| `<space>` | Files panel | Stage / unstage the selected file |
| `c` | Files panel | Open commit message editor |
| `q` | Anywhere | Quit LazyGit |

## Resolution Flow

```
  lazygit → `2` (Files) → `j`/`k` to main.go → `<enter>` (conflict view)
       │
       ▼
  `↑` or `↓` to select ours/theirs → `<space>` to pick
       │
       ▼
  `<escape>` → `<space>` (stage) → `c` (commit) → Done ✓
```

## Step-by-Step Instructions (LazyGit)

1. **Open LazyGit** in the workspace directory:
   ```bash
   cd workspace/exercise-01
   lazygit
   ```

2. **Switch to the Files panel** by pressing `2`. You should see `main.go` listed with a `UU` marker -- this means "both modified" (i.e., a conflict).

3. **Select `main.go`** by pressing `j` or `k` (or arrow keys) to move the cursor until `main.go` is highlighted. It may already be selected if it is the only file.

4. **Open the conflict resolution view** by pressing `<enter>` while `main.go` is highlighted.

5. **You are now in the merge conflict view.** You will see the conflict highlighted with two sections:
   - The **top section** (labeled "ours" / HEAD): the `feature/update-branding` version (`"2.0.0"` / `"TaskManager Pro"`)
   - The **bottom section** (labeled "theirs"): the `feature/update-version` version (`"1.5.0"` / `"TaskManager Plus"`)

6. **Select which side to keep:**
   - Press `<up>` to highlight the "ours" section (top), then press `<space>` to pick it
   - OR press `<down>` to highlight the "theirs" section (bottom), then press `<space>` to pick it
   - For this exercise, press `<up>` to highlight "ours" (the `"2.0.0"` / `"TaskManager Pro"` version), then press `<space>` to accept it -- since we are on the branding branch and want those values.

7. **Exit the conflict view** by pressing `<escape>`. You are now back in the Files panel. The file should no longer show a `UU` marker.

8. **Stage the file** if it is not already staged: make sure `main.go` is highlighted, then press `<space>` to stage it. You should see it move to the staged section.

9. **Create the merge commit** by pressing `c`. LazyGit will open a commit message editor. It may pre-fill with a merge commit message like "Merge branch 'feature/update-version'". Press `<enter>` to accept the message (or type a new one, then press `<enter>`).

### If Something Goes Wrong

- **Undo the last action:** Press `z` to undo the most recent git action LazyGit performed.
- **See available keybindings:** Press `?` at any time to see all keybindings for the current panel.
- **Abort the merge:** Press `m` to open the merge/rebase options popup, then press `j`/`k` to highlight `abort`, then press `<enter>` to confirm. This resets to the state before the merge started.
- **Quit LazyGit:** Press `q` to exit.
- **Start completely over:** Quit LazyGit, then re-run the exercise setup script to reset the workspace.

## Verification

After completing the merge:

1. Press `<escape>` to return to the main view, or quit lazygit with `q`.
2. Run the following to verify:
   ```bash
   # Check that the merge completed
   git log --oneline -5

   # Verify the chosen values
   grep 'AppVersion' main.go
   grep 'AppName' main.go

   # Make sure the Go code is valid
   go build .
   ```
3. You should see a merge commit in the log, and the constants should have the values you chose.

## Deep Dive: What Is a Merge Conflict?

A merge conflict occurs when git's automatic merge algorithm cannot reconcile changes from two branches. Specifically, a conflict happens when:

1. Both branches modified the **same lines** of the **same file** since their common ancestor (the "merge base").
2. The modifications are **different** from each other.

Git uses a **three-way merge** algorithm. It looks at three versions of each file:
- The **merge base** (common ancestor) -- in this case, the original `main` branch version with `"1.0.0"` and `"TaskManager"`
- **Ours** (HEAD) -- the current branch's version
- **Theirs** -- the incoming branch's version

If only one side changed a line compared to the base, git accepts that change automatically. But when both sides changed the same line differently compared to the base, git cannot decide and raises a conflict.

In this exercise, both branches changed `AppVersion` from `"1.0.0"` to different values (`"2.0.0"` vs `"1.5.0"`), so git correctly identifies this as a conflict that requires human judgment.

The conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`) are literal text that git writes into the file. Any resolution tool (including LazyGit) works by removing these markers and keeping the desired content.
