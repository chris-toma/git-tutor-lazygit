# Exercise 12: Three-Way Merge -- Understanding the Base

## Concept

Every merge conflict resolution benefits from understanding the **merge base** -- the common ancestor of both branches. Without it, you are just comparing two versions and guessing which is "right." With it, you can see what each side **intended to change** relative to the original, which leads to better resolutions.

## Scenario

`task/validate.go` originally had a simple `ValidateTask` function that only checked `len(t.Title) == 0` (title is not empty).

Two branches independently enhanced it:

- **`feature/enhanced-validation`** (current / ours):
  - Kept the `len(t.Title) == 0` check
  - Added a reserved title check (rejects "untitled", "todo", "temp", "test")
  - Added priority range validation (0-5)
  - Added `ValidatePriority` and `IsReservedTitle` helper functions

- **`feature/strict-validation`** (incoming / theirs):
  - Changed `len(t.Title) == 0` to `len(title) < 3` (stricter minimum length)
  - Added a check that the title starts with a letter
  - Added description length validation (max 500 chars)
  - Added `ValidateDescription` helper function

## The Merge Base

The merge base version of `ValidateTask` was:

```go
func ValidateTask(t Task) error {
    if len(t.Title) == 0 {
        return fmt.Errorf("task title cannot be empty")
    }
    return nil
}
```

You can view this during the exercise with:
```bash
git show :1:task/validate.go    # Stage 1 = merge base
git show :2:task/validate.go    # Stage 2 = ours
git show :3:task/validate.go    # Stage 3 = theirs
```

## Why the Base Matters

Without the base, you see two different validation functions and cannot tell what each one **changed**. With the base, you can reason:

- **Branch A changed** the title length check from `== 0` to `< 3`, AND added a "starts with letter" check AND added description validation. Intent: stricter title rules + description checking.
- **Branch B kept** the title length check as `== 0` but added reserved word checking AND priority validation. Intent: content rules + priority checking.

The correct resolution should incorporate ALL the new checks from both branches:
1. The stricter title length (>= 3) from Branch A
2. The "starts with letter" check from Branch A
3. The reserved title check from Branch B
4. The priority validation from Branch B
5. The description validation from Branch A

## Understanding "Ours" vs "Theirs"

This is a **merge**, so:
- **Ours (HEAD)** = `feature/enhanced-validation` -- reserved titles + priority validation
- **Theirs** = `feature/strict-validation` -- stricter title + description validation

## Shortcuts Used in This Exercise

| Key | Where | What It Does |
|-----|-------|-------------|
| `2` | Anywhere | Switch to the Files panel |
| `j` / `k` | Any list | Move cursor down / up (or use arrow keys) |
| `e` | Files panel (on a file) | Open the file in your external editor (`$EDITOR`) |
| `<space>` | Files panel | Stage / unstage the selected file |
| `c` | Files panel | Open commit message editor |
| `@` | Anywhere | Open command log (see what git commands LazyGit ran) |
| `q` | Anywhere | Quit LazyGit |

## Step-by-Step Instructions (LazyGit)

1. **Open LazyGit**:
   ```bash
   cd workspace/exercise-12
   lazygit
   ```

2. **Before resolving, examine the merge base.** Open a separate terminal window (keep LazyGit running) and run:
   ```bash
   cd workspace/exercise-12
   git show :1:task/validate.go   # The original version (merge base)
   git show :2:task/validate.go   # Our version
   git show :3:task/validate.go   # Their version
   ```
   Compare each against the base to understand what each branch changed. This is the key skill in this exercise -- understanding the three-way merge.

3. **Switch back to LazyGit.** Press `2` to switch to the Files panel. You should see `task/validate.go` listed with a `UU` marker.

4. **Select `task/validate.go`** by pressing `j`/`k` to move the cursor to it (it may already be selected).

5. **Open the file in your editor** by pressing `e`. This resolution requires careful manual editing because you need to combine validation logic from both branches.

6. **Write the combined validation function.** The ideal resolution includes all checks from both branches:

   ```go
   package task

   import (
       "fmt"
       "strings"
       "unicode"
   )

   const MinTitleLength = 3
   const MaxDescriptionLength = 500

   const (
       MinPriority = 0
       MaxPriority = 5
   )

   var reservedTitles = []string{"untitled", "todo", "temp", "test"}

   func ValidateTask(t Task) error {
       title := strings.TrimSpace(t.Title)

       // From Branch A: stricter title length
       if len(title) < MinTitleLength {
           return fmt.Errorf("task title must be at least %d characters, got %d",
               MinTitleLength, len(title))
       }

       // From Branch A: title must start with a letter
       if !unicode.IsLetter(rune(title[0])) {
           return fmt.Errorf("task title must start with a letter, got '%c'", title[0])
       }

       // From Branch B: reserved title check
       titleLower := strings.ToLower(title)
       for _, reserved := range reservedTitles {
           if titleLower == reserved {
               return fmt.Errorf("title '%s' is reserved and cannot be used", t.Title)
           }
       }

       // From Branch A: description validation
       if len(t.Description) > MaxDescriptionLength {
           return fmt.Errorf("description too long: %d chars (max %d)",
               len(t.Description), MaxDescriptionLength)
       }

       // From Branch B: priority validation
       if t.Priority < MinPriority || t.Priority > MaxPriority {
           return fmt.Errorf("priority must be between %d and %d, got %d",
               MinPriority, MaxPriority, t.Priority)
       }

       return nil
   }
   ```

   Also keep the helper functions from both branches: `ValidateDescription`, `ValidatePriority`, `IsReservedTitle`.

7. **Remove ALL conflict markers** (`<<<<<<<`, `=======`, `>>>>>>>`) -- search for `<<<<<<<` in your editor to confirm none remain. Save the file and close your editor to return to LazyGit.

8. **Stage the file:** In the Files panel, make sure `task/validate.go` is highlighted, then press `<space>` to stage it. The `UU` marker should disappear.

9. **Create the merge commit** by pressing `c`. Accept the pre-filled merge message by pressing `<enter>`, or type a custom message and then press `<enter>`.

10. **Optionally, review what happened:** Press `@` to open the command log and see what git commands LazyGit executed during the resolution.

### If Something Goes Wrong

- **Undo the last action:** Press `z` to undo the most recent git action LazyGit performed.
- **See available keybindings:** Press `?` at any time to see all keybindings for the current panel.
- **Abort the merge:** Press `m` to open the merge/rebase options popup, then press `j`/`k` to highlight `abort`, then press `<enter>` to confirm. This resets to the state before the merge started.
- **Quit LazyGit:** Press `q` to exit.
- **Start completely over:** Quit LazyGit, then re-run the exercise setup script to reset the workspace.

## Verification

```bash
# No conflict markers
grep -c '<<<<<<' task/validate.go  # Should be 0

# All validations present
grep 'MinTitleLength' task/validate.go
grep 'reservedTitles' task/validate.go
grep 'MinPriority' task/validate.go
grep 'MaxDescriptionLength' task/validate.go
grep 'unicode.IsLetter' task/validate.go

# All helper functions present
grep 'func ValidateDescription' task/validate.go
grep 'func ValidatePriority' task/validate.go
grep 'func IsReservedTitle' task/validate.go

# Valid Go
go build ./...
```

## Deep Dive: The Three-Way Merge Algorithm

### How it works

The three-way merge algorithm compares three versions of each file:

```
         Base (B)
        /        \
    Ours (O)   Theirs (T)
```

For each section of the file, git checks:

| Base | Ours | Theirs | Result |
|------|------|--------|--------|
| A | A | A | A (no change) |
| A | A | B | B (theirs changed, accept) |
| A | B | A | B (ours changed, accept) |
| A | B | B | B (both changed same way, accept) |
| A | B | C | CONFLICT (both changed differently) |

The key insight: **git only flags a conflict when both sides changed the same section differently.** If only one side changed something, git accepts that change automatically.

### Why the base is essential

Without the base, git would see two different files and not know which differences are intentional changes and which are just the original code. The base tells git: "this is what the file looked like before anyone changed it."

Consider this exercise's title validation:
- Base: `len(t.Title) == 0`
- Ours: `len(t.Title) == 0` (unchanged)
- Theirs: `len(title) < MinTitleLength` (changed)

Because git can see that only theirs changed this line (ours kept it the same as base), it would normally auto-accept theirs' version. But in this case, both sides added additional lines around this check, creating a larger conflict region that includes the title check.

### Viewing the base during a conflict

While a merge is in progress, git stores all three versions in the index (staging area):

```bash
git show :1:path/to/file    # Stage 1 = merge base
git show :2:path/to/file    # Stage 2 = ours (HEAD)
git show :3:path/to/file    # Stage 3 = theirs (incoming)
```

You can also use `git diff` with special arguments:

```bash
git diff :1:path/to/file :2:path/to/file    # What ours changed from base
git diff :1:path/to/file :3:path/to/file    # What theirs changed from base
```

### Finding the merge base commit

To find the actual commit that serves as the merge base:

```bash
git merge-base feature/enhanced-validation feature/strict-validation
```

This returns the SHA of the common ancestor commit. You can examine it with `git show <sha>`.

### Using merge base awareness for better resolutions

When resolving conflicts, always ask:
1. What did the base look like?
2. What did ours change from the base? (What was their intent?)
3. What did theirs change from the base? (What was their intent?)
4. Can both sets of changes coexist? If so, combine them.
5. If they contradict, which intent should win? (This requires human judgment.)

This disciplined approach leads to correct resolutions far more often than simply picking whichever side "looks right."
