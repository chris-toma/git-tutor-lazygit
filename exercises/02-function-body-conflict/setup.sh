#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="$SCRIPT_DIR/../../workspace/exercise-02"

echo "============================================"
echo "  Exercise 02: Function Body Conflict"
echo "============================================"
echo ""
echo "Setting up workspace..."

# Clean up any existing workspace
rm -rf "$WORKSPACE"
mkdir -p "$WORKSPACE"
cd "$WORKSPACE"

# Initialize repo
git init
git config user.email "learner@example.com"
git config user.name "Git Learner"

# Create go.mod
cat > go.mod << 'GOMOD'
module taskmanager

go 1.21
GOMOD

# Create base task package
mkdir -p task

cat > task/task.go << 'GOFILE'
package task

import "fmt"

// Task represents a single task in the task manager.
type Task struct {
	ID       int
	Title    string
	Done     bool
	Priority int
}

// FormatTask returns a human-readable string representation of a task.
func FormatTask(t Task) string {
	status := "[ ]"
	if t.Done {
		status = "[x]"
	}
	return fmt.Sprintf("%s #%d: %s", status, t.ID, t.Title)
}

// NewTask creates a new task with the given title and ID.
func NewTask(id int, title string) Task {
	return Task{
		ID:       id,
		Title:    title,
		Done:     false,
		Priority: 0,
	}
}
GOFILE

cat > main.go << 'GOFILE'
package main

import (
	"fmt"
	"os"

	"taskmanager/task"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Println("TaskManager v1.0.0")
		fmt.Println("Usage: taskmanager <command>")
		os.Exit(0)
	}

	// Demo: show a sample task
	sample := task.NewTask(1, "Learn git conflicts")
	fmt.Println(task.FormatTask(sample))
}
GOFILE

git add .
git commit -m "initial commit: task manager with FormatTask"

# Branch A: rewrite FormatTask with fmt.Sprintf detailed output
git checkout -b feature/detailed-format

cat > task/task.go << 'GOFILE'
package task

import "fmt"

// Task represents a single task in the task manager.
type Task struct {
	ID       int
	Title    string
	Done     bool
	Priority int
}

// FormatTask returns a human-readable string representation of a task.
// This version provides detailed multi-line output including priority.
func FormatTask(t Task) string {
	status := "PENDING"
	if t.Done {
		status = "COMPLETED"
	}

	priorityLabel := "Normal"
	switch {
	case t.Priority >= 3:
		priorityLabel = "Critical"
	case t.Priority == 2:
		priorityLabel = "High"
	case t.Priority == 1:
		priorityLabel = "Medium"
	}

	return fmt.Sprintf(
		"Task #%d\n  Title:    %s\n  Status:   %s\n  Priority: %s (%d)",
		t.ID,
		t.Title,
		status,
		priorityLabel,
		t.Priority,
	)
}

// NewTask creates a new task with the given title and ID.
func NewTask(id int, title string) Task {
	return Task{
		ID:       id,
		Title:    title,
		Done:     false,
		Priority: 0,
	}
}
GOFILE

git add .
git commit -m "rewrite FormatTask with detailed multi-line Sprintf output"

# Branch B: rewrite FormatTask with strings.Builder and color
git checkout main
git checkout -b feature/colored-format

cat > task/task.go << 'GOFILE'
package task

import (
	"fmt"
	"strings"
)

// Task represents a single task in the task manager.
type Task struct {
	ID       int
	Title    string
	Done     bool
	Priority int
}

// ANSI color codes for terminal output.
const (
	colorReset  = "\033[0m"
	colorRed    = "\033[31m"
	colorGreen  = "\033[32m"
	colorYellow = "\033[33m"
	colorCyan   = "\033[36m"
)

// FormatTask returns a human-readable string representation of a task.
// This version uses strings.Builder for efficient string construction
// and ANSI color codes for terminal display.
func FormatTask(t Task) string {
	var b strings.Builder

	// Write status indicator with color
	if t.Done {
		b.WriteString(colorGreen)
		b.WriteString("[DONE] ")
		b.WriteString(colorReset)
	} else {
		b.WriteString(colorRed)
		b.WriteString("[TODO] ")
		b.WriteString(colorReset)
	}

	// Write task ID
	b.WriteString(colorCyan)
	b.WriteString(fmt.Sprintf("#%04d", t.ID))
	b.WriteString(colorReset)
	b.WriteString(" ")

	// Write priority indicator
	if t.Priority > 0 {
		b.WriteString(colorYellow)
		b.WriteString(strings.Repeat("!", t.Priority))
		b.WriteString(colorReset)
		b.WriteString(" ")
	}

	// Write title
	b.WriteString(t.Title)

	return b.String()
}

// NewTask creates a new task with the given title and ID.
func NewTask(id int, title string) Task {
	return Task{
		ID:       id,
		Title:    title,
		Done:     false,
		Priority: 0,
	}
}
GOFILE

git add .
git commit -m "rewrite FormatTask with strings.Builder and ANSI colors"

# Merge: merge detailed-format into colored-format to create conflict
git merge feature/detailed-format || true

echo ""
echo "============================================"
echo "  Setup Complete!"
echo "============================================"
echo ""
echo "A merge conflict has been created in task/task.go."
echo "Both branches completely rewrote the FormatTask function body."
echo "Branch A uses fmt.Sprintf with detailed output."
echo "Branch B uses strings.Builder with ANSI colors."
echo ""
echo "Next steps:"
echo "  1. cd $WORKSPACE"
echo "  2. lazygit"
echo "  3. Follow the instructions in exercises/02-function-body-conflict/README.md"
echo ""
