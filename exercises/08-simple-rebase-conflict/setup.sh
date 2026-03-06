#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="$SCRIPT_DIR/../../workspace/exercise-08"

echo "============================================"
echo "  Exercise 08: Simple Rebase Conflict"
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

// String returns a formatted task string.
func (t Task) String() string {
	status := "[ ]"
	if t.Done {
		status = "[x]"
	}
	return fmt.Sprintf("%s #%d: %s", status, t.ID, t.Title)
}
GOFILE

cat > task/search.go << 'GOFILE'
package task

// FindByID returns the task with the given ID, or nil if not found.
func FindByID(tasks []Task, id int) *Task {
	for i := range tasks {
		if tasks[i].ID == id {
			return &tasks[i]
		}
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
	fmt.Println("TaskManager v1.0.0")

	if len(os.Args) < 2 {
		fmt.Println("Usage: taskmanager <command>")
		os.Exit(0)
	}

	tasks := []task.Task{
		task.NewTask(1, "Learn git"),
		task.NewTask(2, "Practice rebasing"),
	}

	for _, t := range tasks {
		fmt.Println(t)
	}
}
GOFILE

git add .
git commit -m "initial commit: base task manager"

# Create feature branch from initial commit
git checkout -b feature/filter-tasks

# Now advance main with search functionality
git checkout main

cat > task/search.go << 'GOFILE'
package task

import "strings"

// FindByID returns the task with the given ID, or nil if not found.
func FindByID(tasks []Task, id int) *Task {
	for i := range tasks {
		if tasks[i].ID == id {
			return &tasks[i]
		}
	}
	return nil
}

// Search returns all tasks whose title contains the query string.
// The search is case-insensitive.
func Search(tasks []Task, query string) []Task {
	if query == "" {
		return tasks
	}
	query = strings.ToLower(query)
	var results []Task
	for _, t := range tasks {
		if strings.Contains(strings.ToLower(t.Title), query) {
			results = append(results, t)
		}
	}
	return results
}

// FindCompleted returns all tasks that are marked as done.
func FindCompleted(tasks []Task) []Task {
	var results []Task
	for _, t := range tasks {
		if t.Done {
			results = append(results, t)
		}
	}
	return results
}

// FindPending returns all tasks that are not yet done.
func FindPending(tasks []Task) []Task {
	var results []Task
	for _, t := range tasks {
		if !t.Done {
			results = append(results, t)
		}
	}
	return results
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
	fmt.Println("TaskManager v1.0.0")

	if len(os.Args) < 2 {
		fmt.Println("Usage: taskmanager <command>")
		os.Exit(0)
	}

	tasks := []task.Task{
		task.NewTask(1, "Learn git"),
		task.NewTask(2, "Practice rebasing"),
		task.NewTask(3, "Master search"),
	}

	switch os.Args[1] {
	case "list":
		for _, t := range tasks {
			fmt.Println(t)
		}
	case "search":
		if len(os.Args) < 3 {
			fmt.Fprintln(os.Stderr, "Error: search requires a query")
			os.Exit(1)
		}
		results := task.Search(tasks, os.Args[2])
		fmt.Printf("Found %d results:\n", len(results))
		for _, t := range results {
			fmt.Println(t)
		}
	default:
		fmt.Fprintf(os.Stderr, "Unknown command: %s\n", os.Args[1])
	}
}
GOFILE

git add .
git commit -m "add search functionality to main branch"

# Now switch to feature branch and add filter functionality (touches same files)
git checkout feature/filter-tasks

cat > task/search.go << 'GOFILE'
package task

import "strings"

// FindByID returns the task with the given ID, or nil if not found.
func FindByID(tasks []Task, id int) *Task {
	for i := range tasks {
		if tasks[i].ID == id {
			return &tasks[i]
		}
	}
	return nil
}

// FilterByTitle returns tasks whose title contains the given substring.
func FilterByTitle(tasks []Task, substr string) []Task {
	if substr == "" {
		return tasks
	}
	substr = strings.ToLower(substr)
	var filtered []Task
	for _, t := range tasks {
		if strings.Contains(strings.ToLower(t.Title), substr) {
			filtered = append(filtered, t)
		}
	}
	return filtered
}

// FilterByPriority returns tasks with priority >= minPriority.
func FilterByPriority(tasks []Task, minPriority int) []Task {
	var filtered []Task
	for _, t := range tasks {
		if t.Priority >= minPriority {
			filtered = append(filtered, t)
		}
	}
	return filtered
}

// FilterDone returns tasks filtered by completion status.
func FilterDone(tasks []Task, done bool) []Task {
	var filtered []Task
	for _, t := range tasks {
		if t.Done == done {
			filtered = append(filtered, t)
		}
	}
	return filtered
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
	fmt.Println("TaskManager v1.0.0")

	if len(os.Args) < 2 {
		fmt.Println("Usage: taskmanager <command>")
		os.Exit(0)
	}

	tasks := []task.Task{
		task.NewTask(1, "Learn git"),
		task.NewTask(2, "Practice rebasing"),
		task.NewTask(3, "Master filtering"),
	}

	switch os.Args[1] {
	case "list":
		for _, t := range tasks {
			fmt.Println(t)
		}
	case "filter":
		if len(os.Args) < 3 {
			fmt.Fprintln(os.Stderr, "Error: filter requires a keyword")
			os.Exit(1)
		}
		filtered := task.FilterByTitle(tasks, os.Args[2])
		fmt.Printf("Filtered %d results:\n", len(filtered))
		for _, t := range filtered {
			fmt.Println(t)
		}
	default:
		fmt.Fprintf(os.Stderr, "Unknown command: %s\n", os.Args[1])
	}
}
GOFILE

git add .
git commit -m "add filter functionality to feature branch"

# Rebase feature branch onto main
git rebase main || true

echo ""
echo "============================================"
echo "  Setup Complete!"
echo "============================================"
echo ""
echo "A rebase conflict has been created."
echo "The feature/filter-tasks branch is being rebased onto main."
echo "Both branches added functions to task/search.go and updated main.go."
echo ""
echo "IMPORTANT: During rebase, 'ours' and 'theirs' are SWAPPED!"
echo "  - 'Ours' = main (the branch you are rebasing ONTO)"
echo "  - 'Theirs' = YOUR commits from feature/filter-tasks"
echo ""
echo "Next steps:"
echo "  1. cd $WORKSPACE"
echo "  2. lazygit"
echo "  3. Follow the instructions in exercises/08-simple-rebase-conflict/README.md"
echo ""
