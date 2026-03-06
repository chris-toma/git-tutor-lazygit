#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="$SCRIPT_DIR/../../workspace/exercise-12"

echo "============================================"
echo "  Exercise 12: Three-Way Merge"
echo "           Understanding the Base"
echo "============================================"
echo ""
echo "Setting up workspace..."

rm -rf "$WORKSPACE"
mkdir -p "$WORKSPACE"
cd "$WORKSPACE"

git init
git config user.email "learner@example.com"
git config user.name "Git Learner"

cat > go.mod << 'GOMOD'
module taskmanager

go 1.21
GOMOD

mkdir -p task

cat > task/task.go << 'GOFILE'
package task

import "fmt"

// Task represents a single task.
type Task struct {
	ID          int
	Title       string
	Description string
	Done        bool
	Priority    int
}

// NewTask creates a new task.
func NewTask(id int, title string) Task {
	return Task{ID: id, Title: title}
}

// String returns a formatted task string.
func (t Task) String() string {
	return fmt.Sprintf("#%d: %s", t.ID, t.Title)
}
GOFILE

cat > task/validate.go << 'GOFILE'
package task

import "fmt"

// ValidateTask checks that a task meets all requirements.
// Currently only checks that the title is not empty.
func ValidateTask(t Task) error {
	if len(t.Title) == 0 {
		return fmt.Errorf("task title cannot be empty")
	}
	return nil
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
		os.Exit(0)
	}

	t := task.NewTask(1, os.Args[1])
	if err := task.ValidateTask(t); err != nil {
		fmt.Fprintf(os.Stderr, "Validation error: %v\n", err)
		os.Exit(1)
	}
	fmt.Printf("Task created: %s\n", t)
}
GOFILE

git add .
git commit -m "initial commit: task manager with basic validation"

# Branch A: stricter title validation + description validation
git checkout -b feature/strict-validation

cat > task/validate.go << 'GOFILE'
package task

import (
	"fmt"
	"strings"
	"unicode"
)

// MinTitleLength is the minimum acceptable length for a task title.
const MinTitleLength = 3

// MaxDescriptionLength is the maximum length for a task description.
const MaxDescriptionLength = 500

// ValidateTask checks that a task meets all requirements.
// Title must be at least 3 characters long and start with a letter.
// Description, if provided, must not exceed the maximum length.
func ValidateTask(t Task) error {
	title := strings.TrimSpace(t.Title)

	if len(title) < MinTitleLength {
		return fmt.Errorf("task title must be at least %d characters, got %d",
			MinTitleLength, len(title))
	}

	if !unicode.IsLetter(rune(title[0])) {
		return fmt.Errorf("task title must start with a letter, got '%c'", title[0])
	}

	if len(t.Description) > MaxDescriptionLength {
		return fmt.Errorf("description too long: %d chars (max %d)",
			len(t.Description), MaxDescriptionLength)
	}

	return nil
}

// ValidateDescription checks just the description field.
func ValidateDescription(description string) error {
	if len(description) > MaxDescriptionLength {
		return fmt.Errorf("description too long: %d chars (max %d)",
			len(description), MaxDescriptionLength)
	}
	return nil
}
GOFILE

git add .
git commit -m "add strict title validation and description validation"

# Branch B: title uniqueness check + priority validation
git checkout main
git checkout -b feature/enhanced-validation

cat > task/validate.go << 'GOFILE'
package task

import (
	"fmt"
	"strings"
)

// ValidPriorities defines the acceptable priority range.
const (
	MinPriority = 0
	MaxPriority = 5
)

// reservedTitles are titles that cannot be used for tasks.
var reservedTitles = []string{"untitled", "todo", "temp", "test"}

// ValidateTask checks that a task meets all requirements.
// Title must not be empty, must not be a reserved word,
// and priority must be within valid range.
func ValidateTask(t Task) error {
	if len(t.Title) == 0 {
		return fmt.Errorf("task title cannot be empty")
	}

	titleLower := strings.ToLower(strings.TrimSpace(t.Title))
	for _, reserved := range reservedTitles {
		if titleLower == reserved {
			return fmt.Errorf("title '%s' is reserved and cannot be used", t.Title)
		}
	}

	if t.Priority < MinPriority || t.Priority > MaxPriority {
		return fmt.Errorf("priority must be between %d and %d, got %d",
			MinPriority, MaxPriority, t.Priority)
	}

	return nil
}

// ValidatePriority checks just the priority field.
func ValidatePriority(priority int) error {
	if priority < MinPriority || priority > MaxPriority {
		return fmt.Errorf("priority must be between %d and %d, got %d",
			MinPriority, MaxPriority, priority)
	}
	return nil
}

// IsReservedTitle checks if a title is in the reserved list.
func IsReservedTitle(title string) bool {
	titleLower := strings.ToLower(strings.TrimSpace(title))
	for _, reserved := range reservedTitles {
		if titleLower == reserved {
			return true
		}
	}
	return false
}
GOFILE

git add .
git commit -m "add reserved title check and priority validation"

# Merge strict-validation into enhanced-validation
git merge feature/strict-validation || true

echo ""
echo "============================================"
echo "  Setup Complete!"
echo "============================================"
echo ""
echo "A three-way merge conflict has been created in task/validate.go."
echo ""
echo "The MERGE BASE (common ancestor) had:"
echo "  - ValidateTask that only checked title length > 0"
echo ""
echo "Branch A (feature/strict-validation / theirs) changed to:"
echo "  - Check title length >= 3 (stricter)"
echo "  - Check title starts with a letter"
echo "  - Add description validation"
echo ""
echo "Branch B (feature/enhanced-validation / ours) changed to:"
echo "  - Keep title length > 0 check"
echo "  - Add reserved title check ('untitled', 'todo', etc.)"
echo "  - Add priority range validation"
echo ""
echo "Understanding the MERGE BASE is critical to resolving this correctly."
echo "You can see the base with: git show :1:task/validate.go"
echo ""
echo "Next steps:"
echo "  1. cd $WORKSPACE"
echo "  2. lazygit"
echo "  3. Follow the instructions in exercises/12-three-way-merge-base/README.md"
echo ""
