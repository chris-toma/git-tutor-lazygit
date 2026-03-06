#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="$SCRIPT_DIR/../../workspace/exercise-04"

echo "============================================"
echo "  Exercise 04: Import Block Conflict"
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
mkdir -p utils

cat > task/task.go << 'GOFILE'
package task

// Task represents a single task in the task manager.
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
GOFILE

cat > utils/helpers.go << 'GOFILE'
package utils

import "fmt"

// PrintHeader prints a formatted header to the console.
func PrintHeader(title string) {
	fmt.Println("====================")
	fmt.Printf("  %s\n", title)
	fmt.Println("====================")
}

// Pluralize returns the singular or plural form based on count.
func Pluralize(count int, singular, plural string) string {
	if count == 1 {
		return singular
	}
	return plural
}
GOFILE

cat > main.go << 'GOFILE'
package main

import (
	"fmt"
	"os"

	"taskmanager/task"
	"taskmanager/utils"
)

func main() {
	utils.PrintHeader("TaskManager")

	if len(os.Args) < 2 {
		fmt.Println("Usage: taskmanager <command>")
		os.Exit(0)
	}

	t := task.NewTask(1, "Example")
	fmt.Printf("Task: %s\n", t.Title)
}
GOFILE

git add .
git commit -m "initial commit: task manager with utils/helpers.go"

# Branch A: add JSON export functionality
git checkout -b feature/json-export

cat > utils/helpers.go << 'GOFILE'
package utils

import (
	"encoding/json"
	"fmt"
	"os"

	"taskmanager/task"
)

// PrintHeader prints a formatted header to the console.
func PrintHeader(title string) {
	fmt.Println("====================")
	fmt.Printf("  %s\n", title)
	fmt.Println("====================")
}

// Pluralize returns the singular or plural form based on count.
func Pluralize(count int, singular, plural string) string {
	if count == 1 {
		return singular
	}
	return plural
}

// ExportJSON writes the given tasks to a JSON file at the specified path.
// It creates the file if it does not exist, or overwrites it if it does.
func ExportJSON(tasks []task.Task, filepath string) error {
	data, err := json.MarshalIndent(tasks, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to marshal tasks: %w", err)
	}

	err = os.WriteFile(filepath, data, 0644)
	if err != nil {
		return fmt.Errorf("failed to write file %s: %w", filepath, err)
	}

	fmt.Printf("Exported %d %s to %s\n",
		len(tasks),
		Pluralize(len(tasks), "task", "tasks"),
		filepath,
	)
	return nil
}

// ImportJSON reads tasks from a JSON file and returns them.
func ImportJSON(filepath string) ([]task.Task, error) {
	data, err := os.ReadFile(filepath)
	if err != nil {
		return nil, fmt.Errorf("failed to read file %s: %w", filepath, err)
	}

	var tasks []task.Task
	err = json.Unmarshal(data, &tasks)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal tasks: %w", err)
	}

	return tasks, nil
}
GOFILE

git add .
git commit -m "add JSON export and import functions to helpers"

# Branch B: add sort and filter functionality
git checkout main
git checkout -b feature/sort-filter

cat > utils/helpers.go << 'GOFILE'
package utils

import (
	"fmt"
	"sort"
	"strings"

	"taskmanager/task"
)

// PrintHeader prints a formatted header to the console.
func PrintHeader(title string) {
	fmt.Println("====================")
	fmt.Printf("  %s\n", title)
	fmt.Println("====================")
}

// Pluralize returns the singular or plural form based on count.
func Pluralize(count int, singular, plural string) string {
	if count == 1 {
		return singular
	}
	return plural
}

// SortTasks returns a new slice of tasks sorted by the given criteria.
// Supported sort keys: "id", "title", "priority", "done".
func SortTasks(tasks []task.Task, sortBy string) []task.Task {
	sorted := make([]task.Task, len(tasks))
	copy(sorted, tasks)

	switch sortBy {
	case "title":
		sort.Slice(sorted, func(i, j int) bool {
			return sorted[i].Title < sorted[j].Title
		})
	case "priority":
		sort.Slice(sorted, func(i, j int) bool {
			return sorted[i].Priority > sorted[j].Priority
		})
	case "done":
		sort.Slice(sorted, func(i, j int) bool {
			return !sorted[i].Done && sorted[j].Done
		})
	default: // "id" or anything else
		sort.Slice(sorted, func(i, j int) bool {
			return sorted[i].ID < sorted[j].ID
		})
	}

	return sorted
}

// FilterTasks returns tasks whose title contains the query string.
// The search is case-insensitive.
func FilterTasks(tasks []task.Task, query string) []task.Task {
	if query == "" {
		return tasks
	}

	query = strings.ToLower(query)
	var result []task.Task
	for _, t := range tasks {
		if strings.Contains(strings.ToLower(t.Title), query) {
			result = append(result, t)
		}
	}
	return result
}

// FilterByPriority returns tasks with priority >= minPriority.
func FilterByPriority(tasks []task.Task, minPriority int) []task.Task {
	var result []task.Task
	for _, t := range tasks {
		if t.Priority >= minPriority {
			result = append(result, t)
		}
	}
	return result
}
GOFILE

git add .
git commit -m "add sort and filter functions to helpers"

# Merge json-export into sort-filter
git merge feature/json-export || true

echo ""
echo "============================================"
echo "  Setup Complete!"
echo "============================================"
echo ""
echo "A merge conflict has been created in utils/helpers.go."
echo "Branch A added JSON import/export with 'encoding/json' and 'os' imports."
echo "Branch B added sort/filter with 'sort' and 'strings' imports."
echo "Both sets of imports and functions should be kept."
echo ""
echo "Next steps:"
echo "  1. cd $WORKSPACE"
echo "  2. lazygit"
echo "  3. Follow the instructions in exercises/04-import-block-conflict/README.md"
echo ""
