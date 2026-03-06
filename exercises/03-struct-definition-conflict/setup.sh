#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="$SCRIPT_DIR/../../workspace/exercise-03"

echo "============================================"
echo "  Exercise 03: Struct Definition Conflict"
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

// Task represents a single task in the task manager.
type Task struct {
	ID    int
	Title string
	Done  bool
}

// String returns a simple string representation of a Task.
func (t Task) String() string {
	status := "[ ]"
	if t.Done {
		status = "[x]"
	}
	return fmt.Sprintf("%s #%d: %s", status, t.ID, t.Title)
}

// Complete marks the task as done.
func (t *Task) Complete() {
	t.Done = true
}

// NewTask creates a new task with the given ID and title.
func NewTask(id int, title string) Task {
	return Task{
		ID:    id,
		Title: title,
		Done:  false,
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
		os.Exit(0)
	}

	t := task.NewTask(1, "Sample task")
	fmt.Println(t)
}
GOFILE

git add .
git commit -m "initial commit: task struct with basic fields"

# Branch A: add Priority, Tags, CreatedAt
git checkout -b feature/task-metadata

cat > task/task.go << 'GOFILE'
package task

import (
	"fmt"
	"strings"
	"time"
)

// Task represents a single task in the task manager.
type Task struct {
	ID        int
	Title     string
	Done      bool
	Priority  int
	Tags      []string
	CreatedAt time.Time
}

// String returns a simple string representation of a Task.
func (t Task) String() string {
	status := "[ ]"
	if t.Done {
		status = "[x]"
	}
	tagStr := ""
	if len(t.Tags) > 0 {
		tagStr = " [" + strings.Join(t.Tags, ", ") + "]"
	}
	return fmt.Sprintf("%s #%d (P%d): %s%s", status, t.ID, t.Priority, t.Title, tagStr)
}

// Complete marks the task as done.
func (t *Task) Complete() {
	t.Done = true
}

// SetPriority sets the priority level of the task.
// Priority levels: 0 = none, 1 = low, 2 = medium, 3 = high, 4 = critical.
func (t *Task) SetPriority(level int) {
	if level < 0 {
		level = 0
	}
	if level > 4 {
		level = 4
	}
	t.Priority = level
}

// AddTag adds a tag to the task if it does not already exist.
func (t *Task) AddTag(tag string) {
	for _, existing := range t.Tags {
		if existing == tag {
			return
		}
	}
	t.Tags = append(t.Tags, tag)
}

// NewTask creates a new task with the given ID and title.
func NewTask(id int, title string) Task {
	return Task{
		ID:        id,
		Title:     title,
		Done:      false,
		Priority:  0,
		Tags:      nil,
		CreatedAt: time.Now(),
	}
}
GOFILE

git add .
git commit -m "add Priority, Tags, CreatedAt fields to Task struct"

# Branch B: add DueDate, Category, Notes
git checkout main
git checkout -b feature/task-scheduling

cat > task/task.go << 'GOFILE'
package task

import (
	"fmt"
	"time"
)

// Task represents a single task in the task manager.
type Task struct {
	ID       int
	Title    string
	Done     bool
	DueDate  time.Time
	Category string
	Notes    string
}

// String returns a simple string representation of a Task.
func (t Task) String() string {
	status := "[ ]"
	if t.Done {
		status = "[x]"
	}
	cat := ""
	if t.Category != "" {
		cat = " (" + t.Category + ")"
	}
	due := ""
	if !t.DueDate.IsZero() {
		due = " due:" + t.DueDate.Format("2006-01-02")
	}
	return fmt.Sprintf("%s #%d: %s%s%s", status, t.ID, t.Title, cat, due)
}

// Complete marks the task as done.
func (t *Task) Complete() {
	t.Done = true
}

// SetDueDate sets the due date for the task.
func (t *Task) SetDueDate(date time.Time) {
	t.DueDate = date
}

// SetCategory assigns a category to the task.
func (t *Task) SetCategory(category string) {
	t.Category = category
}

// AddNote appends a note to the task's notes field.
func (t *Task) AddNote(note string) {
	if t.Notes != "" {
		t.Notes += "\n"
	}
	t.Notes += note
}

// NewTask creates a new task with the given ID and title.
func NewTask(id int, title string) Task {
	return Task{
		ID:    id,
		Title: title,
		Done:  false,
	}
}
GOFILE

git add .
git commit -m "add DueDate, Category, Notes fields to Task struct"

# Merge metadata into scheduling to create conflict
git merge feature/task-metadata || true

echo ""
echo "============================================"
echo "  Setup Complete!"
echo "============================================"
echo ""
echo "A merge conflict has been created in task/task.go."
echo "Branch A added Priority, Tags, CreatedAt to the Task struct."
echo "Branch B added DueDate, Category, Notes to the Task struct."
echo "You need to keep ALL fields from BOTH branches."
echo ""
echo "Next steps:"
echo "  1. cd $WORKSPACE"
echo "  2. lazygit"
echo "  3. Follow the instructions in exercises/03-struct-definition-conflict/README.md"
echo ""
