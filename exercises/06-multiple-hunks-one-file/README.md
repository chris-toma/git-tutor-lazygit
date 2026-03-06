# Exercise 06: Multiple Hunks in One File

## Concept

A single file can have multiple independent conflict regions (called "hunks"). Each hunk represents a separate area where both branches made incompatible changes. You must resolve each hunk independently, navigating between them.

## Scenario

`cmd/cli.go` was modified by two branches that changed three different functions in the same file:

- **`feature/subcommands`** (current / ours): Added a `Subcommand` struct, subcommand validation in `parseArgs()`, updated `printHelp()` to list subcommands dynamically, added `printSubcommandHelp()`, and updated `executeCommand()` with `remove` and `search` subcommands.
- **`feature/flag-support`** (incoming / theirs): Added a `Flags` struct, flag parsing in `parseArgs()`, updated `printHelp()` with flag documentation, added `parsePriority()`, and updated `executeCommand()` to accept and use flags.

Both branches modified the same three functions (`parseArgs`, `printHelp`, `executeCommand`), creating **three separate conflict hunks** in the same file.

## What the Conflict Looks Like

You will see three conflict regions in `cmd/cli.go`:

1. **Hunk 1 -- `parseArgs()`**: One side parses flags and returns a `Flags` struct; the other validates subcommand names against a registry.
2. **Hunk 2 -- `printHelp()`**: One side lists flags; the other dynamically lists subcommands.
3. **Hunk 3 -- `executeCommand()`**: One side uses a `Flags` parameter; the other has additional subcommand cases.

There may also be conflicts in the type definitions and imports at the top of the file.

## Understanding "Ours" vs "Theirs"

This is a **merge**, so:
- **Ours (HEAD)** = `feature/subcommands` -- subcommand validation and help
- **Theirs** = `feature/flag-support` -- flag parsing and verbose output

## Shortcuts Used in This Exercise

| Key | Where | What It Does |
|-----|-------|-------------|
| `2` | Anywhere | Switch to the Files panel |
| `j` / `k` | Any list | Move cursor down / up (or use arrow keys) |
| `<enter>` | Files panel (on a conflicted file) | Open the conflict resolution view |
| `<up>` / `<down>` | Conflict view | Move between "ours" and "theirs" sections within a hunk |
| `<space>` | Conflict view | Pick the currently highlighted section |
| `[` / `]` | Conflict view | Jump to previous / next conflict hunk |
| `b` | Conflict view | Pick both sections (keep ours AND theirs) |
| `e` | Files panel or conflict view | Open the file in your external editor (`$EDITOR`) |
| `<escape>` | Conflict view | Exit back to the Files panel |
| `<space>` | Files panel | Stage / unstage the selected file |
| `c` | Files panel | Open commit message editor |
| `q` | Anywhere | Quit LazyGit |

## Step-by-Step Instructions (LazyGit)

1. **Open LazyGit**:
   ```bash
   cd workspace/exercise-06
   lazygit
   ```

2. **Switch to the Files panel** by pressing `2`. You should see `cmd/cli.go` listed with a `UU` marker.

3. **Select `cmd/cli.go`** by pressing `j`/`k` to move the cursor until it is highlighted.

4. **Open the conflict resolution view** by pressing `<enter>`.

5. **You should see the first conflict hunk highlighted.** Before resolving anything, scan all the hunks to understand the full picture:
   - Press `]` to jump to the next conflict hunk
   - Press `[` to jump to the previous conflict hunk
   - Count the hunks -- you should have at least three (LazyGit shows the hunk number, e.g., "1/3")
   - Note what each side did in each hunk before making choices

6. **Navigate back to the first hunk** by pressing `[` until you reach hunk 1/N.

7. **Resolve each hunk one at a time:**

   **Hunk 1 (likely `parseArgs()`):**
   - Press `<up>` to highlight the "ours" section (top -- subcommand validation)
   - OR press `<down>` to highlight the "theirs" section (bottom -- flag parsing)
   - Press `<space>` to pick the highlighted section

   **Move to hunk 2** by pressing `]`.

   **Hunk 2 (likely `printHelp()`):**
   - Press `<up>` or `<down>` to highlight the section you want
   - Press `<space>` to pick it

   **Move to hunk 3** by pressing `]`.

   **Hunk 3 (likely `executeCommand()`):**
   - Press `<up>` or `<down>` to highlight the section you want
   - Press `<space>` to pick it

   **Repeat** for any additional hunks.

   **Tip:** You can pick "ours" for one hunk and "theirs" for another -- each hunk is an independent decision.

8. **If the hunks are too complex to resolve with pick-one-side**, press `<escape>` to exit the conflict view, then press `e` on the file in the Files panel to open it in your editor. This is likely needed here because the function signatures changed in incompatible ways (one branch changed `parseArgs` to return 3 values, the other kept 2). Remove all conflict markers manually, write the combined version, save, and close the editor to return to LazyGit.

9. **After resolving all hunks**, press `<escape>` to return to the Files panel. The file should no longer show a `UU` marker.

10. **Stage the file** by making sure `cmd/cli.go` is highlighted in the Files panel, then pressing `<space>`.

11. **Create the merge commit** by pressing `c`. Accept the pre-filled merge message by pressing `<enter>`, or type a custom message and then press `<enter>`.

### If Something Goes Wrong

- **Undo the last action:** Press `z` to undo the most recent git action LazyGit performed.
- **See available keybindings:** Press `?` at any time to see all keybindings for the current panel.
- **Abort the merge:** Press `m` to open the merge/rebase options popup, then press `j`/`k` to highlight `abort`, then press `<enter>` to confirm. This resets to the state before the merge started.
- **Quit LazyGit:** Press `q` to exit.
- **Start completely over:** Quit LazyGit, then re-run the exercise setup script to reset the workspace.

## Verification

```bash
# No conflict markers
grep -c '<<<<<<' cmd/cli.go  # Should be 0

# Verify the file has the key functions
grep 'func parseArgs' cmd/cli.go
grep 'func printHelp' cmd/cli.go
grep 'func executeCommand' cmd/cli.go

# Valid Go
go build ./...

# Check log
git log --oneline -3
```

## Deep Dive: How Git Identifies Hunks

When git detects conflicts in a file, it tries to produce the smallest possible conflict regions by looking for unchanged "context" lines between the conflicting sections.

**How hunks are separated:**

1. Git walks through the file line by line, comparing three versions (base, ours, theirs).
2. When it encounters a section where both sides differ from the base AND from each other, it starts a conflict hunk.
3. The conflict hunk continues until git finds lines that match in all three versions (or that only one side changed).
4. Those matching lines become the boundary between hunks.

**Why multiple hunks matter:**

Each hunk is an independent decision. The functions between the hunks did not conflict, so git merged them automatically. This means:

- You do not need to resolve hunks in order (though it is natural to go top-to-bottom).
- You can pick different sides for different hunks.
- If you resolve one hunk incorrectly, you only need to redo that hunk (though in LazyGit it is usually easier to re-run the setup script and start over).

**Navigating hunks in LazyGit:**

- `]` -- jump to the next conflict hunk
- `[` -- jump to the previous conflict hunk
- The current hunk is highlighted, and LazyGit shows the hunk number (e.g., "1/3")

**Common strategy for multiple hunks:** Quickly scan all hunks first (press `]` repeatedly) to understand the full picture before resolving any of them. This helps you make consistent choices -- for example, if you pick "ours" for the function signature in hunk 1, you should also pick "ours" for the function body in hunk 3 to maintain consistency.
