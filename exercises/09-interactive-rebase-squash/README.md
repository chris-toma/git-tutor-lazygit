# Exercise 09: Interactive Rebase -- Squash with Conflicts

## Concept

Interactive rebase lets you rewrite history by reordering, editing, squashing, or dropping commits. **Squashing** combines multiple commits into one. When the commits being squashed modified the same lines, conflicts can arise during the squash operation.

## Scenario

The `feature/validation` branch has 5 commits:

1. "add basic title validation" -- creates `task/validate.go` with basic checks
2. "add title length validation" -- adds max length check (modifies same lines as commit 1)
3. "add priority validation" -- adds priority range check and constants
4. "refactor validation to collect multiple errors" -- rewrites function to return multiple errors (modifies same lines as commit 3)
5. "add ID validation" -- adds ID check

Your task is to squash these into 2 clean commits:
- **Commit A**: Squash commits 1 + 2 into "add title validation"
- **Commit B**: Squash commits 3 + 4 + 5 into "add priority and ID validation"

Conflicts will arise because commits 2 and 4 modify the same lines as commits 1 and 3.

## What the Conflict Looks Like

When squashing commit 2 into commit 1, you will see a conflict in `task/validate.go` where the title validation function was modified. The base version (commit 1) has the basic check, and the squashed version (commit 2) adds the length check.

## Understanding "Ours" vs "Theirs"

During a **squash** (which is a form of rebase):
- **Ours** = the result so far (the commit you are squashing INTO)
- **Theirs** = the commit being squashed (the one being folded in)

For the first squash: ours = commit 1's version, theirs = commit 2's changes.

## Interactive Rebase Concepts

Before starting, understand the available operations:

| Operation | Short | Description |
|-----------|-------|-------------|
| **pick** | p | Use the commit as-is |
| **squash** | s | Combine with previous commit, edit combined message |
| **fixup** | f | Like squash, but discard this commit's message |
| **reword** | r | Use the commit but edit its message |
| **edit** | e | Pause after this commit for amending |
| **drop** | d | Delete the commit entirely |

## Shortcuts Used in This Exercise

| Key | Where | What It Does |
|-----|-------|-------------|
| `2` | Anywhere | Switch to the Files panel |
| `4` | Anywhere | Switch to the Commits panel |
| `j` / `k` | Any list | Move cursor down / up (or use arrow keys) |
| `e` | Commits panel | Start interactive rebase from the selected commit |
| `s` | Commits panel (during interactive rebase) | Mark commit for squash into the one below it |
| `f` | Commits panel (during interactive rebase) | Fixup -- squash but discard this commit's message |
| `<enter>` | Files panel (on a conflicted file) | Open the conflict resolution view |
| `<up>` / `<down>` | Conflict view | Move between "ours" and "theirs" sections |
| `<space>` | Conflict view | Pick the currently highlighted section |
| `e` | Files panel | Open the file in your external editor (`$EDITOR`) |
| `<escape>` | Conflict view | Exit back to the Files panel |
| `<space>` | Files panel | Stage / unstage the selected file |
| `m` | Anywhere (during rebase) | Open merge/rebase options popup |
| `q` | Anywhere | Quit LazyGit |

## Resolution Flow

```
  lazygit → `4` (Commits)
       │
       ▼
  Navigate to commit 2 → `s` (squash into commit 1)
  Navigate to commit 4 → `s` (squash into commit 3)
  Navigate to commit 5 → `s` (squash into commit 3+4)
       │
       ▼
  Squash begins → Conflict!
       │
       ▼
  `2` (Files) → resolve → `<space>` (stage) → `m` → `continue`
       │
       ▼
  Edit commit message → `<enter>`
       │
       ▼
  Another conflict? → resolve → stage → continue → edit message
       │
       ▼
  All squashes done → `4` (Commits) → verify 2 commits ✓
```

## Step-by-Step Instructions (LazyGit)

1. **Open LazyGit**:
   ```bash
   cd workspace/exercise-09
   lazygit
   ```

2. **Switch to the Commits panel** by pressing `4`. You should see the 5 feature commits plus the initial commit. The commits are listed with the most recent at the top:
   - "add ID validation" (commit 5 -- top)
   - "refactor validation to collect multiple errors" (commit 4)
   - "add priority validation" (commit 3)
   - "add title length validation" (commit 2)
   - "add basic title validation" (commit 1)
   - Initial commit (bottom)

3. **Mark commits for squash.** You will mark specific commits to be squashed into the commit below them:

   - Press `j` to move the cursor down to commit 2 ("add title length validation")
   - Press `s` to mark it for squash (it will be squashed into commit 1 below it). The commit should show a "squash" label.
   - Press `j` to move down to commit 4 ("refactor validation to collect multiple errors")
   - Press `s` to mark it for squash into commit 3 below it
   - Press `k` to move up to commit 5 ("add ID validation")
   - Press `s` to mark it for squash into the resulting commit 3+4

   **Note:** If the commits are not in the expected order, press `j`/`k` to find the right ones by reading the commit messages.

4. **A conflict may appear** when the squash operation encounters commits that modify the same lines. LazyGit will pause the rebase and show conflicted files.

5. **When a conflict occurs:**
   - Press `2` to switch to the Files panel
   - Press `j`/`k` to move the cursor to the conflicted file (it will have a `UU` marker)
   - Press `<enter>` to open the conflict resolution view
   - You typically want the later commit's version since it is the improved version: press `<down>` to highlight "theirs" (the commit being squashed in), then press `<space>` to pick it
   - If there are multiple hunks, press `]` to move to the next hunk and repeat
   - Press `<escape>` to return to the Files panel
   - Alternatively, press `e` on the file in the Files panel to open in your editor for manual resolution
   - Press `<space>` on the file in the Files panel to stage it

6. **Continue the rebase** by pressing `m` to open the merge/rebase options popup, then press `j`/`k` to highlight `continue`, then press `<enter>` to confirm.

7. **Edit the commit message** when prompted. LazyGit may show a message editor combining both commit messages. Write a clean summary (e.g., "add title validation" for the first squash, "add priority and ID validation" for the second).

8. **Repeat steps 5-7 for any subsequent conflicts** during the squash operation.

9. **After the rebase completes**, press `4` to switch to the Commits panel. You should see 2 feature commits (plus the initial commit) instead of 5.

### If Something Goes Wrong

- **Undo the last action:** Press `z` to undo the most recent git action LazyGit performed.
- **See available keybindings:** Press `?` at any time to see all keybindings for the current panel.
- **Abort the rebase:** Press `m` to open the merge/rebase options popup, then press `j`/`k` to highlight `abort`, then press `<enter>` to confirm. This returns the repository to its state before the rebase started.
- **Quit LazyGit:** Press `q` to exit.
- **Start completely over:** Quit LazyGit, then re-run the exercise setup script to reset the workspace.

## Verification

```bash
# Check commit count (should be 3: initial + 2 squashed)
git log --oneline | wc -l  # Should output 3

# Check commit messages
git log --oneline

# Verify final file content matches the last commit's version
grep 'func Validate' task/validate.go
grep 'ValidateID' task/validate.go
grep 'ValidationError' task/validate.go

# Valid Go
go build ./...
```

## Deep Dive: Interactive Rebase and Why Squashing Causes Conflicts

### How squash works internally

When you squash commit B into commit A:

1. Git starts with the parent of commit A as the base.
2. It applies commit A's changes.
3. It then tries to apply commit B's changes on top.
4. If both A and B modified the same lines, git sees a conflict because it is essentially replaying B's diff on top of A's result, and the diff's context does not match.

### Why squashing related commits conflicts

Consider commits 1 and 2 in this exercise:
- Commit 1 created the `Validate` function with basic checks
- Commit 2 modified the `Validate` function to add length checking

When squashing, git attempts to apply commit 2's diff onto commit 1's result. But commit 2's diff was created relative to commit 1's state, and the diff includes context lines that may not match exactly when applied as a patch. This can produce a conflict.

### Tips for clean squashing

1. **Use fixup (`f`) instead of squash (`s`)** when you do not need the squashed commit's message. Fixup is like squash but automatically discards the folded commit's message.

2. **Squash in chronological order.** Squash later commits into earlier ones, not the reverse.

3. **Consider the result you want.** When resolving a squash conflict, you almost always want the LATER commit's version, since it represents the refined code. The earlier version was an intermediate step.

4. **Interactive rebase in LazyGit** is much more visual than the command line. You can see the rebase plan in the Commits panel, move commits up/down, and mark operations with single keystrokes.
