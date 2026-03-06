# Git Conflict Resolution and Rebasing with LazyGit

A hands-on tutorial project for learning git conflict resolution and rebasing workflows using [LazyGit](https://github.com/jesseduffield/lazygit). The example code throughout is a functional Go CLI application -- a task manager.

## Prerequisites

You need the following installed:

- **git** (2.30+) -- the version control system itself
- **Go** (1.20+) -- needed so the example code is valid and compilable
- **lazygit** -- the terminal UI for git ([install instructions](https://github.com/jesseduffield/lazygit#installation))

Verify your setup:

```bash
git --version
go version
lazygit --version
```

## How LazyGit Works

LazyGit is a terminal-based UI (TUI) for git. It organizes information into panels that you navigate with keyboard shortcuts.

### Panels

| Panel | Description | Key to focus |
|-------|-------------|--------------|
| Status | Current branch, repo name | `1` |
| Files | Staged/unstaged changes, conflicts | `2` |
| Branches | Local branches, remotes, tags | `3` |
| Commits | Commit log for current branch | `4` |
| Stash | Stashed changes | `5` |

### Essential Keybindings

| Key | Action |
|-----|--------|
| `h` / `l` | Switch between panels (left/right) |
| `j` / `k` | Move up/down within a panel |
| `<space>` | Stage/unstage a file (in Files panel) |
| `<enter>` | View file diff, or enter sub-menu |
| `c` | Commit staged changes |
| `e` | Open file in your `$EDITOR` |
| `?` | Show all keybindings for current panel |
| `q` | Quit lazygit |
| `[` / `]` | Navigate between conflict hunks |
| `<up>` / `<down>` | Select ours/theirs for a conflict hunk |
| `<space>` | Pick the selected side of a conflict |
| `M` | Open merge/rebase options |

### Merge Conflict View

When you have a merge conflict, selecting the conflicted file and pressing `<enter>` opens the conflict resolution view. In this view:

- Each conflict hunk is highlighted
- You can pick "ours" (top), "theirs" (bottom), or both
- Navigate between hunks with `[` and `]`
- Press `<space>` to accept the highlighted choice
- Press `e` to open in your editor for manual resolution

## Key Concepts

Before starting the exercises, familiarize yourself with these terms. They are explained in more depth within each exercise's "Deep Dive" section.

### HEAD

A pointer to the current commit you have checked out. It usually points to a branch name (e.g., `HEAD -> main`), which in turn points to a commit. When you make a new commit, HEAD (through the branch) advances to the new commit.

### Index / Staging Area

An intermediate area between your working tree and the repository. When you `git add` a file, its changes move into the index. When you `git commit`, the index becomes the new commit snapshot. The index is also where conflict resolution happens -- you "resolve" a conflict by staging the corrected version of the file.

### Working Tree

The actual files on disk in your repository directory. These can differ from what is in the index (unstaged changes) and from what is in the latest commit (uncommitted changes).

### Merge vs Rebase

Both integrate changes from one branch into another, but they work differently:

- **Merge** creates a new "merge commit" that has two parents, combining the histories. The original branch history is preserved as-is.
- **Rebase** replays your commits one by one on top of another branch. This rewrites commit history to create a linear sequence, as if you had started your work from the tip of the other branch.

### Conflict Markers

When git cannot automatically merge changes, it inserts conflict markers into the file:

```
<<<<<<< HEAD (or <<<<<<< ours)
Code from the current branch
=======
Code from the incoming branch
>>>>>>> branch-name (or >>>>>>> theirs)
```

- Everything between `<<<<<<<` and `=======` is "ours" (current branch)
- Everything between `=======` and `>>>>>>>` is "theirs" (incoming branch)

### Ours vs Theirs (and How They Flip During Rebase)

This is one of the most confusing aspects of git:

- **During a merge**: "ours" = the branch you are ON (the one you ran `git merge` from). "theirs" = the branch being merged IN.
- **During a rebase**: "ours" = the branch you are rebasing ONTO (the upstream/target). "theirs" = YOUR commits being replayed. This is the opposite of what most people expect! The reason is that during rebase, git checks out the target branch first, then replays your commits on top -- so from git's perspective at each replay step, the target branch is "ours" and your commit is "theirs."

### Fast-Forward

When merging a branch that is strictly ahead of the current branch (no divergence), git can simply move the branch pointer forward. No merge commit is created. This is called a "fast-forward merge."

### Three-Way Merge

When two branches have diverged, git performs a three-way merge using three reference points:

1. **Merge base** -- the common ancestor commit of both branches
2. **Ours** -- the tip of the current branch
3. **Theirs** -- the tip of the branch being merged

Git compares each side against the merge base to determine what changed. If only one side changed a particular section, that change is accepted automatically. If both sides changed the same section differently, you get a conflict.

### Merge Base

The most recent common ancestor of two branches. You can find it with `git merge-base branch-a branch-b`. Understanding the merge base is critical for understanding why a conflict occurred and what each side intended.

### ORIG_HEAD

A reference git sets before "dangerous" operations like merge, rebase, or reset. It points to where HEAD was before the operation, allowing you to undo it with `git reset ORIG_HEAD`.

### MERGE_HEAD

During a merge conflict, this reference points to the commit being merged in (the "theirs" side). It exists only while a merge is in progress.

### Reflog

A log of every change to HEAD (and other refs) in your local repository. Even if you "lose" commits through rebase or reset, the reflog usually still has them. View it with `git reflog`. Entries expire after 90 days by default.

## How to Use the Exercises

Each exercise is self-contained. The workflow is:

1. **Run the setup script** -- it creates a git repository in the `workspace/` directory with a conflict already in progress:

   ```bash
   ./exercises/01-simple-line-conflict/setup.sh
   ```

2. **Navigate to the workspace** -- the setup script will print the exact path:

   ```bash
   cd workspace/exercise-01
   ```

3. **Open LazyGit**:

   ```bash
   lazygit
   ```

4. **Follow the exercise README** -- each exercise has step-by-step instructions for resolving the conflict using LazyGit:

   ```
   exercises/01-simple-line-conflict/README.md
   ```

5. **Verify your resolution** -- each README includes verification steps.

You can re-run any setup script at any time to reset the exercise and start over.

## Exercises

| # | Exercise | Concept | Difficulty |
|---|----------|---------|------------|
| 01 | [Simple Line Conflict](exercises/01-simple-line-conflict/README.md) | Single-line merge conflict | Beginner |
| 02 | [Function Body Conflict](exercises/02-function-body-conflict/README.md) | Multi-line block conflict | Beginner |
| 03 | [Struct Definition Conflict](exercises/03-struct-definition-conflict/README.md) | Manual editing to keep both sides | Intermediate |
| 04 | [Import Block Conflict](exercises/04-import-block-conflict/README.md) | Import and function conflicts | Intermediate |
| 05 | [Delete vs Modify Conflict](exercises/05-delete-vs-modify-conflict/README.md) | Edit/delete conflict | Intermediate |
| 06 | [Multiple Hunks in One File](exercises/06-multiple-hunks-one-file/README.md) | Multiple conflict regions | Intermediate |
| 07 | [Multi-File Conflict](exercises/07-multi-file-conflict/README.md) | Conflicts across multiple files | Intermediate |
| 08 | [Simple Rebase Conflict](exercises/08-simple-rebase-conflict/README.md) | Rebase onto updated branch | Intermediate |
| 09 | [Interactive Rebase -- Squash](exercises/09-interactive-rebase-squash/README.md) | Squashing commits with conflicts | Advanced |
| 10 | [Rebase with Sequential Conflicts](exercises/10-rebase-sequential-conflicts/README.md) | Repeated conflicts during rebase | Advanced |
| 11 | [Cherry-Pick Conflict](exercises/11-cherry-pick-conflict/README.md) | Cherry-pick with missing context | Advanced |
| 12 | [Three-Way Merge -- Understanding the Base](exercises/12-three-way-merge-base/README.md) | Merge base and three-way merge | Advanced |

## Tips for Using LazyGit's Merge Conflict Panel

1. **Do not panic.** Conflicts look intimidating but they are a normal part of collaborative development. LazyGit makes them visual and manageable.

2. **Read both sides before choosing.** Use `<enter>` on a conflicted file to see the full conflict. Understand what each side intended before picking.

3. **You can always edit manually.** Press `e` to open the file in your editor. Sometimes manual editing is the right choice, especially when you need parts of both sides.

4. **Navigate hunks with `[` and `]`.** When a file has multiple conflict regions, these keys jump between them.

5. **Stage when done.** After resolving all conflicts in a file, stage it with `<space>` in the Files panel. Once all conflicted files are staged, you can continue the merge/rebase.

6. **Aborting is always an option.** If things go wrong, press `M` to access merge/rebase options, and select "abort." You can re-run the setup script to start fresh.

7. **Use the reflog as a safety net.** Press `4` to go to the Commits panel, and you can browse the reflog. Almost nothing in git is truly lost.

8. **Check `git status` mentally.** The Files panel in LazyGit IS your `git status`. Red = unstaged/conflicted. Green = staged. Pay attention to the markers: `UU` = both modified (conflict), `UD` = deleted by them, `DU` = deleted by us.
