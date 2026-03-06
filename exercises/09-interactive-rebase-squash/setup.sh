#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="$SCRIPT_DIR/../../workspace/exercise-09"

echo "============================================"
echo "  Exercise 09: Interactive Rebase - Squash"
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
	ID       int
	Title    string
	Done     bool
	Priority int
}

// NewTask creates a new task.
func NewTask(id int, title string) Task {
	return Task{ID: id, Title: title}
}

// String returns a formatted string.
func (t Task) String() string {
	status := "[ ]"
	if t.Done {
		status = "[x]"
	}
	return fmt.Sprintf("%s #%d: %s", status, t.ID, t.Title)
}
GOFILE

cat > main.go << 'GOFILE'
package main

import (
	"fmt"
	"taskmanager/task"
)

func main() {
	fmt.Println("TaskManager v1.0.0")
	t := task.NewTask(1, "Hello")
	fmt.Println(t)
}
GOFILE

git add .
git commit -m "initial commit: base task manager"

# Create feature branch with 5 commits where some modify the same lines
git checkout -b feature/validation

# Commit 1: add basic validation
cat > task/validate.go << 'GOFILE'
package task

import (
	"errors"
	"strings"
)

// Validate checks that a task has valid data.
func Validate(t Task) error {
	if t.Title == "" {
		return errors.New("title is required")
	}
	if strings.TrimSpace(t.Title) == "" {
		return errors.New("title cannot be only whitespace")
	}
	return nil
}
GOFILE

git add .
git commit -m "add basic title validation"

# Commit 2: improve validation (modifies same lines as commit 1)
cat > task/validate.go << 'GOFILE'
package task

import (
	"errors"
	"fmt"
	"strings"
)

// MaxTitleLength is the maximum allowed length for a task title.
const MaxTitleLength = 200

// Validate checks that a task has valid data.
func Validate(t Task) error {
	if t.Title == "" {
		return errors.New("title is required")
	}
	title := strings.TrimSpace(t.Title)
	if title == "" {
		return errors.New("title cannot be only whitespace")
	}
	if len(title) > MaxTitleLength {
		return fmt.Errorf("title too long: %d chars (max %d)", len(title), MaxTitleLength)
	}
	return nil
}
GOFILE

git add .
git commit -m "add title length validation"

# Commit 3: add priority validation
cat > task/validate.go << 'GOFILE'
package task

import (
	"errors"
	"fmt"
	"strings"
)

// MaxTitleLength is the maximum allowed length for a task title.
const MaxTitleLength = 200

// MinPriority and MaxPriority define the valid priority range.
const (
	MinPriority = 0
	MaxPriority = 5
)

// Validate checks that a task has valid data.
func Validate(t Task) error {
	if t.Title == "" {
		return errors.New("title is required")
	}
	title := strings.TrimSpace(t.Title)
	if title == "" {
		return errors.New("title cannot be only whitespace")
	}
	if len(title) > MaxTitleLength {
		return fmt.Errorf("title too long: %d chars (max %d)", len(title), MaxTitleLength)
	}
	if t.Priority < MinPriority || t.Priority > MaxPriority {
		return fmt.Errorf("priority must be between %d and %d, got %d", MinPriority, MaxPriority, t.Priority)
	}
	return nil
}

// ValidatePriority checks only the priority field.
func ValidatePriority(priority int) error {
	if priority < MinPriority || priority > MaxPriority {
		return fmt.Errorf("priority must be between %d and %d", MinPriority, MaxPriority)
	}
	return nil
}
GOFILE

git add .
git commit -m "add priority validation"

# Commit 4: refactor validation to return multiple errors (modifies same lines as commit 3)
cat > task/validate.go << 'GOFILE'
package task

import (
	"fmt"
	"strings"
)

// MaxTitleLength is the maximum allowed length for a task title.
const MaxTitleLength = 200

// MinPriority and MaxPriority define the valid priority range.
const (
	MinPriority = 0
	MaxPriority = 5
)

// ValidationError holds multiple validation errors.
type ValidationError struct {
	Errors []string
}

func (e *ValidationError) Error() string {
	return "validation failed: " + strings.Join(e.Errors, "; ")
}

// HasErrors returns true if there are any validation errors.
func (e *ValidationError) HasErrors() bool {
	return len(e.Errors) > 0
}

// Validate checks that a task has valid data and returns all errors at once.
func Validate(t Task) error {
	ve := &ValidationError{}

	if t.Title == "" {
		ve.Errors = append(ve.Errors, "title is required")
	} else {
		title := strings.TrimSpace(t.Title)
		if title == "" {
			ve.Errors = append(ve.Errors, "title cannot be only whitespace")
		}
		if len(title) > MaxTitleLength {
			ve.Errors = append(ve.Errors, fmt.Sprintf("title too long: %d chars (max %d)", len(title), MaxTitleLength))
		}
	}

	if t.Priority < MinPriority || t.Priority > MaxPriority {
		ve.Errors = append(ve.Errors, fmt.Sprintf("priority must be between %d and %d, got %d", MinPriority, MaxPriority, t.Priority))
	}

	if ve.HasErrors() {
		return ve
	}
	return nil
}

// ValidatePriority checks only the priority field.
func ValidatePriority(priority int) error {
	if priority < MinPriority || priority > MaxPriority {
		return fmt.Errorf("priority must be between %d and %d", MinPriority, MaxPriority)
	}
	return nil
}
GOFILE

git add .
git commit -m "refactor validation to collect multiple errors"

# Commit 5: add ID validation
cat > task/validate.go << 'GOFILE'
package task

import (
	"fmt"
	"strings"
)

// MaxTitleLength is the maximum allowed length for a task title.
const MaxTitleLength = 200

// MinPriority and MaxPriority define the valid priority range.
const (
	MinPriority = 0
	MaxPriority = 5
)

// ValidationError holds multiple validation errors.
type ValidationError struct {
	Errors []string
}

func (e *ValidationError) Error() string {
	return "validation failed: " + strings.Join(e.Errors, "; ")
}

// HasErrors returns true if there are any validation errors.
func (e *ValidationError) HasErrors() bool {
	return len(e.Errors) > 0
}

// Validate checks that a task has valid data and returns all errors at once.
func Validate(t Task) error {
	ve := &ValidationError{}

	if t.ID <= 0 {
		ve.Errors = append(ve.Errors, "ID must be a positive integer")
	}

	if t.Title == "" {
		ve.Errors = append(ve.Errors, "title is required")
	} else {
		title := strings.TrimSpace(t.Title)
		if title == "" {
			ve.Errors = append(ve.Errors, "title cannot be only whitespace")
		}
		if len(title) > MaxTitleLength {
			ve.Errors = append(ve.Errors, fmt.Sprintf("title too long: %d chars (max %d)", len(title), MaxTitleLength))
		}
	}

	if t.Priority < MinPriority || t.Priority > MaxPriority {
		ve.Errors = append(ve.Errors, fmt.Sprintf("priority must be between %d and %d, got %d", MinPriority, MaxPriority, t.Priority))
	}

	if ve.HasErrors() {
		return ve
	}
	return nil
}

// ValidatePriority checks only the priority field.
func ValidatePriority(priority int) error {
	if priority < MinPriority || priority > MaxPriority {
		return fmt.Errorf("priority must be between %d and %d", MinPriority, MaxPriority)
	}
	return nil
}

// ValidateID checks that a task ID is valid.
func ValidateID(id int) error {
	if id <= 0 {
		return fmt.Errorf("ID must be a positive integer, got %d", id)
	}
	return nil
}
GOFILE

git add .
git commit -m "add ID validation"

echo ""
echo "============================================"
echo "  Setup Complete!"
echo "============================================"
echo ""
echo "A feature branch with 5 commits has been created."
echo "The commits build on each other, with commits 2 and 4"
echo "modifying the same lines as commits 1 and 3."
echo ""
echo "Your task: use interactive rebase to squash these into 2 commits:"
echo "  - Commit A: title validation (squash commits 1 + 2)"
echo "  - Commit B: priority and ID validation (squash commits 3 + 4 + 5)"
echo ""
echo "This will produce conflicts when squashing because the commits"
echo "modified the same lines."
echo ""
echo "Next steps:"
echo "  1. cd $WORKSPACE"
echo "  2. lazygit"
echo "  3. Follow the instructions in exercises/09-interactive-rebase-squash/README.md"
echo ""
